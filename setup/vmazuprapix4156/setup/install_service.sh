#!/bin/bash

echo "=== Configurando serviço systemd para Besu - VERSÃO CORRIGIDA ==="

# Verificar se estamos executando como root ou com sudo
if [ "$EUID" -eq 0 ]; then
    echo "⚠️  Executando como root"
else
    echo "✅ Executando como usuário normal com sudo"
fi

# Detectar o diretório do projeto e mover para /opt/idbra/bradesco_besu_network
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORIGINAL_DIR="$(dirname "$SCRIPT_DIR")"
TARGET_DIR="/opt/idbra/bradesco_besu_network"

echo "Movendo projeto para $TARGET_DIR..."
sudo mkdir -p "$TARGET_DIR"
sudo cp -r "$ORIGINAL_DIR"/* "$TARGET_DIR/"
PROJECT_DIR="$TARGET_DIR"

echo "Diretório do projeto: $PROJECT_DIR"

# 1. CONFIGURAR FIREWALL ANTES DE CRIAR O SERVIÇO
echo ""
echo "=== Configurando firewall ==="
if command -v firewall-cmd >/dev/null 2>&1; then
    echo "Configurando portas no firewall..."
    sudo firewall-cmd --permanent --add-port=30303/tcp 2>/dev/null || echo "⚠️  Falha ao adicionar porta 30303/tcp"
    sudo firewall-cmd --permanent --add-port=30303/udp 2>/dev/null || echo "⚠️  Falha ao adicionar porta 30303/udp"
    sudo firewall-cmd --permanent --add-port=8545/tcp 2>/dev/null || echo "⚠️  Falha ao adicionar porta 8545/tcp"
    sudo firewall-cmd --reload 2>/dev/null || echo "⚠️  Falha ao recarregar firewall"
    echo "✅ Firewall configurado (ignorando falhas)"
else
    echo "⚠️  Firewall não detectado. Configure manualmente se necessário"
fi

# 2. LOCALIZAR JAVA E BESU
echo ""
echo "=== Localizando Java e Besu ==="

# Encontrar Java
JAVA_HOME=""
JAVA_PATHS=(
    "/usr/lib/jvm/java-21-openjdk-21.0.8.0.9-1.el9.alma.1.x86_64"
    "/usr/lib/jvm/java-21-openjdk"
    "/usr/java/jdk-21"
    "/usr/lib/jvm/default-java"
)

for java_path in "${JAVA_PATHS[@]}"; do
    if [ -d "$java_path" ] && [ -x "$java_path/bin/java" ]; then
        JAVA_HOME="$java_path"
        echo "✅ Java encontrado em: $JAVA_HOME"
        break
    fi
done

if [ -z "$JAVA_HOME" ]; then
    echo "❌ Java não encontrado. Verifique a instalação"
    exit 1
fi

# Encontrar Besu
BESU_HOME=""
BESU_PATHS=(
    "/opt/besu"
    "/usr/local/besu"
    "/opt/hyperledger/besu"
)

for besu_path in "${BESU_PATHS[@]}"; do
    if [ -d "$besu_path" ] && [ -x "$besu_path/bin/besu" ]; then
        BESU_HOME="$besu_path"
        echo "✅ Besu encontrado em: $BESU_HOME"
        break
    fi
done

if [ -z "$BESU_HOME" ]; then
    echo "❌ Besu não encontrado. Verifique a instalação"
    echo "Tentando localizar besu no sistema..."
    BESU_BINARY=$(which besu 2>/dev/null)
    if [ -n "$BESU_BINARY" ]; then
        BESU_HOME=$(dirname $(dirname "$BESU_BINARY"))
        echo "✅ Besu encontrado em: $BESU_HOME (via which)"
    else
        echo "❌ Comando 'besu' não encontrado no PATH"
        echo "Instale o Besu ou verifique se está no PATH"
        exit 1
    fi
fi

# 3. CRIAR ARQUIVO DE SERVIÇO SYSTEMD OTIMIZADO
echo ""
echo "=== Criando arquivo de serviço systemd ==="

sudo tee /etc/systemd/system/besu-node.service << EOF
[Unit]
Description=Hyperledger Besu Node - Bradesco Network
Documentation=https://besu.hyperledger.org/
After=network.target

[Service]
Type=simple
User=besu
Group=besu
WorkingDirectory=$PROJECT_DIR

# Script de inicialização
ExecStart=$PROJECT_DIR/run/start_node.sh

# Configurações de reinicialização
Restart=always
RestartSec=30
StartLimitInterval=300
StartLimitBurst=5

# Logs
StandardOutput=journal
StandardError=journal
SyslogIdentifier=besu-node

# Variáveis de ambiente críticas
Environment=JAVA_HOME=$JAVA_HOME
Environment=BESU_HOME=$BESU_HOME
Environment=PATH=$JAVA_HOME/bin:$BESU_HOME/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
Environment=USER=besu
Environment=HOME=/home/besu

# Limites de recursos
LimitNOFILE=65536
LimitNPROC=32768
LimitCORE=0

# Timeout para inicialização
TimeoutStartSec=120
TimeoutStopSec=30

# Segurança (remover sudo do contexto)
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

echo "✅ Arquivo de serviço criado: /etc/systemd/system/besu-node.service"

# 4. CRIAR/VERIFICAR USUÁRIO BESU
echo ""
echo "=== Configurando usuário besu ==="
if id "besu" &>/dev/null; then
    echo "✅ Usuário besu já existe"
else
    echo "Criando usuário besu..."
    sudo useradd -r -s /bin/bash -d /home/besu -m besu
    echo "✅ Usuário besu criado com diretório home"
fi

# 5. CONFIGURAR PERMISSÕES
echo ""
echo "=== Configurando permissões ==="
sudo chown -R besu:besu "$PROJECT_DIR"
sudo chmod -R 755 "$PROJECT_DIR"

# Garantir que o script seja executável
sudo chmod +x "$PROJECT_DIR/run/start_node.sh"
sudo chown besu:besu "$PROJECT_DIR/run/start_node.sh"

# Verificar se o script existe
if [ ! -f "$PROJECT_DIR/run/start_node.sh" ]; then
    echo "❌ ERRO: Script start_node.sh não encontrado em $PROJECT_DIR/run/"
    exit 1
fi

# Criar diretórios necessários
sudo mkdir -p "$PROJECT_DIR/config/data"
sudo chown -R besu:besu "$PROJECT_DIR/config"
sudo chmod -R 775 "$PROJECT_DIR/config"

# Configurar diretório home do usuário besu
sudo mkdir -p /home/besu
sudo chown besu:besu /home/besu
sudo chmod 755 /home/besu

echo "✅ Permissões configuradas"

# 6. CONFIGURAR SELINUX (se necessário)
if command -v sestatus >/dev/null 2>&1; then
    echo ""
    echo "=== Configurando SELinux ==="
    sudo setenforce 0 2>/dev/null || true
    sudo semanage fcontext -a -t bin_t "$PROJECT_DIR/run/start_node.sh" 2>/dev/null || true
    sudo restorecon -v "$PROJECT_DIR/run/start_node.sh" 2>/dev/null || true
    echo "✅ SELinux configurado"
fi

# 7. RECARREGAR SYSTEMD E HABILITAR SERVIÇO
echo ""
echo "=== Finalizando configuração ==="
sudo systemctl daemon-reload

# Verificar se o serviço foi criado
if ! sudo systemctl list-unit-files | grep -q besu-node; then
    echo "❌ ERRO: Serviço besu-node não foi criado corretamente"
    exit 1
fi

# Habilitar serviço
sudo systemctl enable besu-node
echo "✅ Serviço habilitado para início automático"

# 8. TESTE RÁPIDO DO SCRIPT
echo ""
echo "=== Teste de configuração ==="
echo "Testando se o usuário besu consegue executar o script..."

# Teste básico das permissões
sudo -u besu test -x "$PROJECT_DIR/run/start_node.sh" && echo "✅ Script executável pelo usuário besu" || echo "❌ Problema de permissões"

# Teste básico dos comandos
sudo -u besu bash -c "
    export JAVA_HOME=$JAVA_HOME
    export BESU_HOME=$BESU_HOME
    export PATH=$JAVA_HOME/bin:$BESU_HOME/bin:\$PATH
    command -v java >/dev/null && echo '✅ Java acessível pelo usuário besu' || echo '❌ Java não acessível'
    command -v besu >/dev/null && echo '✅ Besu acessível pelo usuário besu' || echo '❌ Besu não acessível'
"

echo ""
echo "✅ Serviço besu-node instalado e configurado!"
echo ""
echo "=== Informações de configuração ==="
echo "Diretório: $PROJECT_DIR"
echo "Java: $JAVA_HOME"
echo "Besu: $BESU_HOME"
echo "Usuário: besu"
echo ""
echo "=== Comandos úteis ==="
echo "Iniciar:       sudo systemctl start besu-node"
echo "Parar:         sudo systemctl stop besu-node"
echo "Status:        sudo systemctl status besu-node"
echo "Logs:          sudo journalctl -u besu-node -f"
echo "Logs recentes: sudo journalctl -u besu-node --since '1 hour ago'"
echo "Reiniciar:     sudo systemctl restart besu-node"
echo ""
echo "⚠️  IMPORTANTE: Execute 'sudo systemctl start besu-node' para iniciar"
