#!/bin/bash
# Script para iniciar Bootnode - CORREÇÃO PARA /tmp COM noexec
# VM: 172.23.105.105 (ou qualquer bootnode)
# Configuração automática de IP e correção RocksDB

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

VM_IP="172.23.105.107"

# Verificar se estamos no diretório padrão ou no projeto
if [[ "$SCRIPT_DIR" == "/opt/idbra/bradesco_besu_network"* ]]; then
    PROJECT_DIR="/opt/idbra/bradesco_besu_network"
    CONFIG_DIR="$PROJECT_DIR/config"
    DATA_DIR="$CONFIG_DIR/data"
else
    PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
    CONFIG_DIR="$PROJECT_DIR/config"
    DATA_DIR="$CONFIG_DIR/data"
fi

# CORREÇÃO CRÍTICA: Criar e configurar diretório temporário EXECUTÁVEL
BESU_TEMP_DIR="/var/lib/besu/tmp"
mkdir -p "$BESU_TEMP_DIR"
chmod 755 "$BESU_TEMP_DIR"

# FORÇAR todas as variáveis de temp ANTES de qualquer comando Java
export TMPDIR="$BESU_TEMP_DIR"
export TMP="$BESU_TEMP_DIR"
export TEMP="$BESU_TEMP_DIR"
export JAVA_IO_TMPDIR="$BESU_TEMP_DIR"

echo "=== CORREÇÃO noexec - Verificações ==="
echo "Temp dir: $BESU_TEMP_DIR"
echo "TMPDIR: $TMPDIR"
echo "TMP: $TMP"
echo "TEMP: $TEMP"

# Limpar bibliotecas antigas
find /tmp -name "*rocksdbjni*" -delete 2>/dev/null || true
find "$BESU_TEMP_DIR" -name "*rocksdbjni*" -delete 2>/dev/null || true

echo "=== Verificações pré-inicialização ==="
echo "Diretório do projeto: $PROJECT_DIR"
echo "Diretório de configuração: $CONFIG_DIR"
echo "Diretório de dados: $DATA_DIR"
echo "IP da VM: $VM_IP"

# 1. Configurar variáveis de ambiente
echo "1. Configurando variáveis de ambiente..."
# Usar Java da imagem Docker (já configurado)
export JAVA_HOME=$(dirname $(dirname $(which java)))
export BESU_HOME=/opt/besu
export PATH=$JAVA_HOME/bin:$BESU_HOME/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Verificar se existem arquivos de perfil e carregá-los
if [ -f "/etc/profile.d/java.sh" ]; then
    source /etc/profile.d/java.sh
    echo "✅ Variáveis de ambiente do Java carregadas do perfil"
fi

if [ -f "/etc/profile.d/besu.sh" ]; then
    source /etc/profile.d/besu.sh
    echo "✅ Variáveis de ambiente do Besu carregadas do perfil"
fi

echo "JAVA_HOME: $JAVA_HOME"
echo "BESU_HOME: $BESU_HOME"
echo "PATH: $PATH"

# 2. Verificar Java
echo ""
echo "2. Verificando Java JDK..."
if command -v java >/dev/null 2>&1; then
    JAVA_VERSION=$(java --version 2>&1 | head -n 1)
    echo "✅ Java encontrado: $JAVA_VERSION"
else
    echo "❌ Java não encontrado no PATH: $PATH"
    echo "Tentando caminhos alternativos..."

    # Tentar caminhos comuns do Java
    JAVA_PATHS=(
        "/usr/lib/jvm/java-21-openjdk/bin/java"
        "/usr/lib/jvm/java-21-openjdk-21.0.8.0.9-1.el9.alma.1.x86_64/bin/java"
        "/usr/java/jdk-21/bin/java"
        "/usr/bin/java"
    )

    for java_path in "${JAVA_PATHS[@]}"; do
        if [ -x "$java_path" ]; then
            export JAVA_HOME=$(dirname $(dirname "$java_path"))
            export PATH=$JAVA_HOME/bin:$PATH
            echo "✅ Java encontrado em: $java_path"
            break
        fi
    done

    if ! command -v java >/dev/null 2>&1; then
        echo "❌ Java não encontrado em nenhum caminho conhecido"
        exit 1
    fi
fi

# 3. Verificar Besu
echo ""
echo "3. Verificando Hyperledger Besu..."
if command -v besu >/dev/null 2>&1; then
    BESU_VERSION=$(besu --version 2>&1 | head -n 1)
    echo "✅ Besu encontrado: $BESU_VERSION"
else
    echo "❌ Besu não encontrado no PATH: $PATH"
    echo "Tentando caminhos alternativos..."

    # Tentar caminhos comuns do Besu
    BESU_PATHS=(
        "/opt/besu/bin/besu"
        "/usr/local/bin/besu"
        "/usr/bin/besu"
    )

    for besu_path in "${BESU_PATHS[@]}"; do
        if [ -x "$besu_path" ]; then
            export BESU_HOME=$(dirname $(dirname "$besu_path"))
            export PATH=$BESU_HOME/bin:$PATH
            echo "✅ Besu encontrado em: $besu_path"
            break
        fi
    done

    if ! command -v besu >/dev/null 2>&1; then
        echo "❌ Besu não encontrado em nenhum caminho conhecido"
        echo "Verifique se o Besu está instalado em:"
        echo "  - /opt/besu/bin/besu"
        echo "  - /usr/local/bin/besu"
        exit 1
    fi
fi

# 4. Verificar arquivos de configuração
echo ""
echo "4. Verificando arquivos de configuração..."

if [ ! -d "$CONFIG_DIR" ]; then
    echo "❌ Diretório de configuração não encontrado: $CONFIG_DIR"
    exit 1
fi

if [ ! -f "$CONFIG_DIR/genesis.json" ]; then
    echo "❌ Arquivo genesis.json não encontrado: $CONFIG_DIR/genesis.json"
    exit 1
fi

if [ ! -d "$DATA_DIR" ]; then
    echo "Criando diretório de dados: $DATA_DIR"
    mkdir -p "$DATA_DIR"
fi

# Verificar se os arquivos de permissão existem
PERMISSIONS_FILE="$DATA_DIR/permissions_config.toml"
if [ ! -f "$PERMISSIONS_FILE" ]; then
    echo "⚠️  Arquivo de permissões não encontrado: $PERMISSIONS_FILE"
    echo "ATENÇÃO: Execute o script de configuração inicial primeiro!"
    echo "O arquivo de permissões deve existir antes de iniciar o Besu"
    exit 1
fi

echo "✅ Arquivo de permissões encontrado: $PERMISSIONS_FILE"
echo "✅ Arquivos de configuração verificados"

# 5. CONFIGURAR JAVA_OPTS CRÍTICO PARA ROCKSDB
echo ""
echo "5. Configurando opções JVM críticas..."

# FORÇAR o RocksDB usar diretório executável - MÚLTIPLAS ESTRATÉGIAS
export JAVA_OPTS="-Djava.io.tmpdir=$BESU_TEMP_DIR"
export JAVA_OPTS="$JAVA_OPTS -Djna.tmpdir=$BESU_TEMP_DIR"
export JAVA_OPTS="$JAVA_OPTS -Dorg.rocksdb.tmpdir=$BESU_TEMP_DIR"
export JAVA_OPTS="$JAVA_OPTS -Djava.library.tmpdir=$BESU_TEMP_DIR"
export JAVA_OPTS="$JAVA_OPTS -Drocksdb.native.library.path=$BESU_TEMP_DIR"
export JAVA_OPTS="$JAVA_OPTS -Djava.library.path=$BESU_TEMP_DIR"

# Opções de performance
export JAVA_OPTS="$JAVA_OPTS -XX:+UseG1GC"
export JAVA_OPTS="$JAVA_OPTS -Djava.util.logging.manager=org.apache.logging.log4j.jul.LogManager"

echo "JAVA_OPTS configurado: $JAVA_OPTS"

# 6. Informações de inicialização
echo ""
echo "=== Iniciando Hyperledger Besu ==="
echo "Configurações:"
echo "  Data Path: $DATA_DIR"
echo "  Genesis File: $CONFIG_DIR/genesis.json"
echo "  Permissions File: $PERMISSIONS_FILE"
echo "  IP da VM: $VM_IP"
echo "  Temp dir: $BESU_TEMP_DIR"
echo "  Java: $(which java)"
echo "  Besu: $(which besu)"
echo ""

# FORÇAR variáveis de ambiente uma última vez antes de executar
export TMPDIR="$BESU_TEMP_DIR"
export TMP="$BESU_TEMP_DIR"
export TEMP="$BESU_TEMP_DIR"
exec besu \
  --data-path="$DATA_DIR" \
  --genesis-file="$CONFIG_DIR/genesis.json" \
  --bootnodes=enode://93677b2fd0864ea2af0d514fa323f7e51f9d3126cab42c9c4c624f10174bcf6b2df731a63b0d22cf560d0ca8511faaf9245b7972483c109c6b86afa36c765657@172.23.105.82:30303,enode://1d3a0a388d491c87cb60c7c27b68c8252861f1e229e11d66d972094bbfbedde1d54505313907985acd8e313e9fd1b4f79558add2aa8997cfbee310d0db29684d@172.23.105.99:30303,enode://b0bb7ec6bae41524ba247527be974bac194ee543c57ec1671087e392fc2ac77b47653c749d44154687e33fae1d5f7cbb54cb09e38492af8e5efca1a200c0f2e7@172.23.105.105:30303 \
  --rpc-http-enabled \
  --rpc-http-api=ETH,NET,QBFT,ADMIN,DEBUG,PERM \
  --host-allowlist="*" \
  --rpc-http-cors-origins="all" \
  --rpc-http-host="$VM_IP" \
  --rpc-http-port=8545 \
  --p2p-host="$VM_IP" \
  --p2p-port=30303 \
  --profile=ENTERPRISE \
  --metrics-enabled \
  --discovery-enabled=true \
  --max-peers=25 \
  --sync-mode=FULL \
  --network-id=381660001 \
  --data-storage-format=FOREST \
  --permissions-accounts-config-file-enabled=true \
  --permissions-accounts-config-file="/opt/besu/config/data/permissions_config.toml" \
  --permissions-nodes-config-file-enabled=true \
  --permissions-nodes-config-file="/opt/besu/config/data/permissions_config.toml"
