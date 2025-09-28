#!/bin/bash

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Iniciando instalação do Java JDK 21 e Hyperledger Besu ===${NC}"

# Verificar se o script está sendo executado como sudo
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Este script precisa ser executado com sudo${NC}"
    exit 1
fi

# Verificar status atual do SELinux
echo -e "${YELLOW}Status atual do SELinux:${NC}"
sestatus

# Desabilitar SELinux temporariamente
echo -e "${YELLOW}Desabilitando SELinux temporariamente...${NC}"
setenforce 0

# Desabilitar SELinux permanentemente
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
echo -e "${GREEN}SELinux foi desabilitado. Será necessário reiniciar o sistema.${NC}"

echo -e "${GREEN}=== Instalando Java JDK 21 ===${NC}"

# Obter o diretório atual onde está o script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Verificar se o arquivo RPM existe
RPM_FILE="$PROJECT_DIR/jdk_21/jdk-21_linux-x64_bin.rpm"
if [ ! -f "$RPM_FILE" ]; then
    echo -e "${RED}Arquivo RPM não encontrado: $RPM_FILE${NC}"
    echo -e "${YELLOW}Procurando arquivo RPM no diretório atual...${NC}"
    RPM_FILE=$(find "$SCRIPT_DIR" -name "jdk-21*.rpm" | head -1)
    if [ ! -f "$RPM_FILE" ]; then
        echo -e "${RED}Nenhum arquivo RPM do JDK encontrado!${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}Arquivo RPM encontrado: $RPM_FILE${NC}"

# Instalar Java JDK 21 usando dnf (mais confiável que rpm)
echo -e "${YELLOW}Instalando Java JDK 21...${NC}"
dnf install -y "$RPM_FILE"

# Verificar onde o Java foi instalado
JAVA_INSTALL_DIR=""

# Tentar diferentes locais onde o JDK pode estar instalado
POSSIBLE_PATHS=(
    "/usr/java"
    "/usr/lib/jvm"
    "/usr/local"
    "/opt"
)

for base_path in "${POSSIBLE_PATHS[@]}"; do
    if [ -d "$base_path" ]; then
        # Procurar por diretórios que contenham "jdk" e "21"
        found_dir=$(find "$base_path" -maxdepth 2 -type d \( -name "*jdk*21*" -o -name "*jdk-21*" -o -name "*jdk21*" \) 2>/dev/null | head -1)
        if [ -n "$found_dir" ] && [ -f "$found_dir/bin/java" ]; then
            JAVA_INSTALL_DIR="$found_dir"
            break
        fi
    fi
done

# Se ainda não encontrou, tentar usar o java do PATH
if [ -z "$JAVA_INSTALL_DIR" ]; then
    echo -e "${YELLOW}Tentando encontrar Java via PATH...${NC}"
    java_path=$(which java 2>/dev/null)
    if [ -n "$java_path" ]; then
        # Resolver o link simbólico para encontrar o diretório real
        real_java_path=$(readlink -f "$java_path" 2>/dev/null)
        if [ -n "$real_java_path" ]; then
            JAVA_INSTALL_DIR=$(dirname "$(dirname "$real_java_path")")
            echo -e "${GREEN}Java encontrado via PATH: $JAVA_INSTALL_DIR${NC}"
        fi
    fi
fi

# Verificação final
if [ -z "$JAVA_INSTALL_DIR" ] || [ ! -f "$JAVA_INSTALL_DIR/bin/java" ]; then
    echo -e "${RED}Não foi possível encontrar a instalação do Java!${NC}"
    echo -e "${YELLOW}Locais verificados:${NC}"
    for path in "${POSSIBLE_PATHS[@]}"; do
        if [ -d "$path" ]; then
            echo "  - $path"
            find "$path" -maxdepth 2 -name "*jdk*" -type d 2>/dev/null | head -5
        fi
    done
    echo -e "${YELLOW}Java no PATH: $(which java 2>/dev/null || echo 'não encontrado')${NC}"
    exit 1
fi

echo -e "${GREEN}Java instalado em: $JAVA_INSTALL_DIR${NC}"

# Configurar variáveis de ambiente do Java
echo -e "${YELLOW}Configurando variáveis de ambiente do Java...${NC}"
tee /etc/profile.d/java.sh << EOF
export JAVA_HOME=$JAVA_INSTALL_DIR
export PATH=\$JAVA_HOME/bin:\$PATH
EOF

chmod +x /etc/profile.d/java.sh
source /etc/profile.d/java.sh

# Configurar alternatives
alternatives --install /usr/bin/java java $JAVA_INSTALL_DIR/bin/java 20000
alternatives --install /usr/bin/javac javac $JAVA_INSTALL_DIR/bin/javac 20000

# Verificar instalação do Java
echo -e "${YELLOW}Verificando instalação do Java...${NC}"
export JAVA_HOME=$JAVA_INSTALL_DIR
export PATH=$JAVA_HOME/bin:$PATH
$JAVA_HOME/bin/java -version

if [ $? -ne 0 ]; then
    echo -e "${RED}Erro na instalação do Java!${NC}"
    exit 1
fi

echo -e "${GREEN}=== Java instalado com sucesso! ===${NC}"

echo -e "${GREEN}=== Instalando Hyperledger Besu ===${NC}"

# Verificar se o arquivo Besu existe
BESU_FILE="$PROJECT_DIR/hyperledger_besu/besu-24.9.1.tar.gz"
if [ ! -f "$BESU_FILE" ]; then
    echo -e "${RED}Arquivo Besu não encontrado: $BESU_FILE${NC}"
    echo -e "${YELLOW}Procurando arquivo Besu no diretório atual...${NC}"
    BESU_FILE=$(find "$SCRIPT_DIR" -name "besu-*.tar.gz" | head -1)
    if [ ! -f "$BESU_FILE" ]; then
        echo -e "${RED}Nenhum arquivo Besu encontrado!${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}Arquivo Besu encontrado: $BESU_FILE${NC}"

# Extrair Besu
BESU_DIR=$(dirname "$BESU_FILE")
cd "$BESU_DIR"
tar -xzf "$(basename "$BESU_FILE")"

# Encontrar diretório extraído
EXTRACTED_DIR=$(find "$BESU_DIR" -maxdepth 1 -name "besu-*" -type d | head -1)
if [ -z "$EXTRACTED_DIR" ]; then
    echo -e "${RED}Erro ao extrair Besu!${NC}"
    exit 1
fi

# Mover para diretório do sistema
rm -rf /opt/besu 2>/dev/null || true
mv "$EXTRACTED_DIR" /opt/besu

# Criar link simbólico
ln -sf /opt/besu /opt/besu-current

# Configurar permissões
chmod +x /opt/besu/bin/besu
chmod +x /opt/besu/bin/evmtool

# Adicionar ao PATH
tee /etc/profile.d/besu.sh << 'EOF'
export BESU_HOME=/opt/besu
export PATH=$BESU_HOME/bin:$PATH
# Desabilitar warnings do Java para Besu
export BESU_OPTS="--enable-native-access=ALL-UNNAMED"
export JAVA_OPTS="--enable-native-access=ALL-UNNAMED"
EOF

chmod +x /etc/profile.d/besu.sh
source /etc/profile.d/besu.sh

# Criar usuário para o Besu
useradd -r -s /bin/false besu 2>/dev/null || true
chown -R besu:besu /opt/besu

# Verificar instalação do Besu
echo -e "${YELLOW}Verificando instalação do Besu...${NC}"
export PATH=/opt/besu/bin:$PATH
/opt/besu/bin/besu --version

if [ $? -ne 0 ]; then
    echo -e "${RED}Erro na instalação do Besu!${NC}"
    exit 1
fi

echo -e "${GREEN}=== Configurando diretório de execução ===${NC}"

# Criar diretório padrão para execução
mkdir -p /opt/idbra/bradesco_besu_network

# Copiar script de inicialização
RUN_SCRIPT="$PROJECT_DIR/run/start_node.sh"
if [ -f "$RUN_SCRIPT" ]; then
    echo -e "${GREEN}Copiando start_node.sh...${NC}"
    cp "$RUN_SCRIPT" /opt/idbra/bradesco_besu_network/
    chmod +x /opt/idbra/bradesco_besu_network/start_node.sh
    echo -e "${GREEN}✅ Script copiado com sucesso${NC}"
else
    echo -e "${YELLOW}⚠️ Script start_node.sh não encontrado em $RUN_SCRIPT${NC}"
fi

# Copiar arquivos de configuração
CONFIG_DIR="$PROJECT_DIR/config"
if [ -d "$CONFIG_DIR" ]; then
    echo -e "${GREEN}Copiando arquivos de configuração...${NC}"
    cp -r "$CONFIG_DIR" /opt/idbra/bradesco_besu_network/
    echo -e "${GREEN}✅ Configurações copiadas com sucesso${NC}"
else
    echo -e "${YELLOW}⚠️ Diretório de configuração não encontrado em $CONFIG_DIR${NC}"
fi

# Ajustar permissões
chown -R besu:besu /opt/idbra/bradesco_besu_network

echo -e "${GREEN}=== Instalação concluída com sucesso! ===${NC}"
echo ""
echo -e "${GREEN}=== Verificações finais ===${NC}"
echo -e "${YELLOW}Java JDK 21:${NC}"
echo "JAVA_HOME: $JAVA_INSTALL_DIR"
$JAVA_INSTALL_DIR/bin/java -version

echo ""
echo -e "${YELLOW}Hyperledger Besu:${NC}"
/opt/besu/bin/besu --version

echo ""
echo -e "${YELLOW}Status do SELinux:${NC}"
sestatus

echo ""
echo -e "${GREEN}=== IMPORTANTE ===${NC}"
echo -e "${YELLOW}1. Reinicie o sistema para aplicar a desabilitação permanente do SELinux${NC}"
echo -e "${YELLOW}2. Após o reinício, execute: sestatus para confirmar que está desabilitado${NC}"
echo -e "${YELLOW}3. O Besu está pronto para uso!${NC}"
echo -e "${YELLOW}4. Scripts copiados para /opt/idbra/bradesco_besu_network/${NC}"
echo ""
echo -e "${GREEN}Para executar o Besu: sudo -u besu /opt/besu/bin/besu --help${NC}"

# Fazer source das variáveis de ambiente
echo -e "${YELLOW}Carregando variáveis de ambiente...${NC}"
source /etc/profile.d/java.sh
source /etc/profile.d/besu.sh

# Verificar se o Besu está disponível no PATH
if command -v besu >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Besu está disponível no PATH${NC}"
    besu --version
else
    echo -e "${YELLOW}⚠️ Besu não está no PATH, mas pode ser executado diretamente:${NC}"
    echo -e "${YELLOW}  /opt/besu/bin/besu --version${NC}"
fi
