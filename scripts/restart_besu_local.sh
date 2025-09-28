#!/bin/bash

# Script para reiniciar Besu localmente em cada VM
# Execute este script em cada VM de produção

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Reinicialização Local do Besu ===${NC}"
echo "VM: $(hostname)"
echo "IP: $(hostname -I | awk '{print $1}')"
echo "Data: $(date)"
echo ""

# Função para parar Besu
stop_besu() {
    echo "1. Parando Besu..."

    # Método 1: systemctl
    if systemctl is-active --quiet besu; then
        echo "Parando via systemctl..."
        sudo systemctl stop besu
        sleep 3
    fi

    # Método 2: pkill
    if pgrep -f besu >/dev/null; then
        echo "Parando via pkill..."
        sudo pkill -f besu
        sleep 3
    fi

    # Método 3: killall
    if pgrep -f besu >/dev/null; then
        echo "Parando via killall..."
        sudo killall besu
        sleep 3
    fi

    # Verificar se parou
    if pgrep -f besu >/dev/null; then
        echo -e "${RED}❌ Besu ainda está rodando${NC}"
        return 1
    else
        echo -e "${GREEN}✅ Besu parado com sucesso${NC}"
        return 0
    fi
}

# Função para iniciar Besu
start_besu() {
    echo "2. Iniciando Besu..."

    # Método 1: systemctl
    if systemctl list-unit-files | grep -q besu; then
        echo "Iniciando via systemctl..."
        sudo systemctl start besu
        sleep 5
    fi

    # Método 2: script direto
    if [ -f "/opt/besu/start_node.sh" ]; then
        echo "Iniciando via script direto..."
        cd /opt/besu
        nohup ./start_node.sh > /var/log/besu.log 2>&1 &
        sleep 5
    fi

    # Método 3: comando direto
    if [ -f "/usr/local/bin/besu" ]; then
        echo "Iniciando via comando direto..."
        # Ajuste os parâmetros conforme sua configuração
        nohup besu --data-path=/var/lib/besu --genesis-file=/opt/besu/genesis.json > /var/log/besu.log 2>&1 &
        sleep 5
    fi

    # Verificar se iniciou
    if pgrep -f besu >/dev/null; then
        echo -e "${GREEN}✅ Besu iniciado com sucesso${NC}"
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
        echo -e "${GREEN}✅ Besu está rodando${NC}"

        # Verificar se está respondendo na API
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

# Função para mostrar logs recentes
show_logs() {
    echo "4. Logs recentes:"
    echo "---"
    if [ -f "/var/log/besu.log" ]; then
        tail -10 /var/log/besu.log
    elif [ -f "/var/log/syslog" ]; then
        grep -i besu /var/log/syslog | tail -5
    else
        echo "Nenhum log encontrado"
    fi
    echo "---"
}

# Executar sequência
echo "Iniciando reinicialização..."
echo ""

stop_besu
echo ""

start_besu
echo ""

check_status
echo ""

show_logs
echo ""

echo -e "${YELLOW}Reinicialização concluída!${NC}"
echo "Execute este script em todas as VMs na mesma ordem."
echo ""
echo "Para monitorar: tail -f /var/log/besu.log"
echo "Para verificar API: curl -X POST -H 'Content-Type: application/json' --data '{\"jsonrpc\":\"2.0\",\"method\":\"eth_blockNumber\",\"params\":[],\"id\":1}' http://localhost:8545"

