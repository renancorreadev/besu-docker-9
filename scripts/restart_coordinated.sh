#!/bin/bash

# Script para reinicialização coordenada sem SSH
# Execute este script em cada VM com um delay diferente

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Reinicialização Coordenada QBFT ===${NC}"

# Identificar a VM atual
CURRENT_IP=$(hostname -I | awk '{print $1}')
CURRENT_HOSTNAME=$(hostname)

echo "VM atual: $CURRENT_HOSTNAME ($CURRENT_IP)"
echo "Data: $(date)"
echo ""

# Definir ordem de reinicialização baseada no IP
case $CURRENT_IP in
    "172.23.105.82")   # vmazupraplx7962 - Bootnode 1
        DELAY=0
        VM_TYPE="Bootnode 1"
        ;;
    "172.23.105.99")   # vmazupraplx9278 - Bootnode 2
        DELAY=5
        VM_TYPE="Bootnode 2"
        ;;
    "172.23.105.105")  # vmazuprapix4156 - Bootnode 3
        DELAY=10
        VM_TYPE="Bootnode 3"
        ;;
    "172.23.105.98")   # vmazupraplx2694 - Validator 1
        DELAY=15
        VM_TYPE="Validator 1"
        ;;
    "172.23.105.101")  # vmazupraplx9942 - Validator 2
        DELAY=20
        VM_TYPE="Validator 2"
        ;;
    "172.23.105.104")  # vmazupraplx4002 - Validator 3
        DELAY=25
        VM_TYPE="Validator 3"
        ;;
    "172.23.105.110")  # vmazupraplx8934 - Validator 4
        DELAY=30
        VM_TYPE="Validator 4"
        ;;
    *)
        echo -e "${RED}❌ IP não reconhecido: $CURRENT_IP${NC}"
        echo "Execute este script apenas nas VMs da rede QBFT"
        exit 1
        ;;
esac

echo "Tipo: $VM_TYPE"
echo "Delay: $DELAY segundos"
echo ""

# Função para parar Besu
stop_besu() {
    echo "1. Parando Besu..."

    # Parar via systemctl
    if systemctl is-active --quiet besu; then
        echo "Parando via systemctl..."
        sudo systemctl stop besu
        sleep 3
    fi

    # Forçar parada se necessário
    if pgrep -f besu >/dev/null; then
        echo "Forçando parada..."
        sudo pkill -f besu
        sleep 3
    fi

    if pgrep -f besu >/dev/null; then
        echo -e "${RED}❌ Falha ao parar Besu${NC}"
        return 1
    else
        echo -e "${GREEN}✅ Besu parado${NC}"
        return 0
    fi
}

# Função para iniciar Besu
start_besu() {
    echo "2. Iniciando Besu..."

    # Iniciar via systemctl
    if systemctl list-unit-files | grep -q besu; then
        echo "Iniciando via systemctl..."
        sudo systemctl start besu
        sleep 5
    fi

    # Verificar se iniciou
    if pgrep -f besu >/dev/null; then
        echo -e "${GREEN}✅ Besu iniciado${NC}"
        return 0
    else
        echo -e "${RED}❌ Falha ao iniciar Besu${NC}"
        return 1
    fi
}

# Função para verificar status
check_status() {
    echo "3. Verificando status..."

    if pgrep -f besu >/dev/null; then
        echo -e "${GREEN}✅ Besu rodando${NC}"

        # Testar API
        if curl -s -X POST -H "Content-Type: application/json" \
            --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
            http://localhost:8545 >/dev/null 2>&1; then
            echo -e "${GREEN}✅ API respondendo${NC}"
        else
            echo -e "${YELLOW}⚠️  API não respondendo ainda${NC}"
        fi
    else
        echo -e "${RED}❌ Besu não está rodando${NC}"
    fi
}

# Aguardar delay baseado no tipo de VM
echo "Aguardando $DELAY segundos (ordem de reinicialização)..."
sleep $DELAY

echo ""
echo "Iniciando reinicialização em $CURRENT_HOSTNAME..."
echo ""

# Executar sequência
stop_besu
echo ""

start_besu
echo ""

check_status
echo ""

echo -e "${YELLOW}Reinicialização concluída em $CURRENT_HOSTNAME${NC}"
echo ""
echo "Para monitorar: journalctl -u besu -f"
echo "Para testar API: curl -X POST -H 'Content-Type: application/json' --data '{\"jsonrpc\":\"2.0\",\"method\":\"eth_blockNumber\",\"params\":[],\"id\":1}' http://localhost:8545"

