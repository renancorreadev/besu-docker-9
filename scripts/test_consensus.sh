#!/bin/bash

# Script para testar consenso QBFT
# Testa derrubando validadores gradualmente

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Teste de Consenso QBFT ===${NC}"
echo "Data: $(date)"
echo ""

# Função para verificar se a rede está minerando
check_mining() {
    local container=$1
    local port=$2
    echo -n "Verificando mineração em $container... "

    # Verificar se há blocos sendo criados
    local block_number=$(curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
        http://localhost:$port | jq -r '.result' 2>/dev/null)

    if [ "$block_number" != "null" ] && [ "$block_number" != "0x0" ]; then
        echo -e "${GREEN}✅ Minerando (bloco: $((block_number)))${NC}"
        return 0
    else
        echo -e "${RED}❌ Não está minerando${NC}"
        return 1
    fi
}

# Função para verificar peers conectados
check_peers() {
    local container=$1
    local port=$2
    local peer_count=$(curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"admin_peers","params":[],"id":1}' \
        http://localhost:$port | jq '.result | length' 2>/dev/null)

    echo "Peers conectados em $container: $peer_count"
    return $peer_count
}

# Função para derrubar validadores
stop_validators() {
    local validators=("$@")
    echo -e "${YELLOW}Derrubando validadores: ${validators[*]}${NC}"

    for validator in "${validators[@]}"; do
        echo "Parando $validator..."
        docker-compose stop $validator
        sleep 2
    done
}

# Função para subir validadores
start_validators() {
    local validators=("$@")
    echo -e "${YELLOW}Subindo validadores: ${validators[*]}${NC}"

    for validator in "${validators[@]}"; do
        echo "Iniciando $validator..."
        docker-compose start $validator
        sleep 5
    done
}

echo "1. Estado inicial da rede:"
echo "Verificando todos os nós..."
for i in {1..9}; do
    port=$((8544 + i))
    case $i in
        1) container="vmazupraplx7962" ;;
        2) container="vmazupraplx2694" ;;
        3) container="vmazupraplx9942" ;;
        4) container="vmazupraplx9278" ;;
        5) container="vmazupraplx4002" ;;
        6) container="vmazupraplx8934" ;;
        7) container="vmazuprapix4156" ;;
        8) container="vmazupraplx6452" ;;
        9) container="vmazupraplx8278" ;;
    esac
    check_mining $container $port
done

echo ""
echo "2. Teste 1: Derrubando 1 validador (deve continuar minerando)"
stop_validators "vmazupraplx2694"
sleep 10

echo "Verificando se ainda está minerando..."
check_mining "vmazupraplx7962" 8545
check_peers "vmazupraplx7962" 8545

echo ""
echo "3. Teste 2: Derrubando 2 validadores (deve continuar minerando)"
stop_validators "vmazupraplx9942"
sleep 10

echo "Verificando se ainda está minerando..."
check_mining "vmazupraplx7962" 8545
check_peers "vmazupraplx7962" 8545

echo ""
echo "4. Teste 3: Derrubando 3 validadores (deve PARAR de minerar)"
stop_validators "vmazupraplx4002"
sleep 15

echo "Verificando se parou de minerar..."
check_mining "vmazupraplx7962" 8545
check_peers "vmazupraplx7962" 8545

echo ""
echo "5. Teste 4: Subindo 1 validador (deve voltar a minerar)"
start_validators "vmazupraplx2694"
sleep 15

echo "Verificando se voltou a minerar..."
check_mining "vmazupraplx7962" 8545
check_peers "vmazupraplx7962" 8545

echo ""
echo "6. Restaurando todos os validadores..."
start_validators "vmazupraplx9942" "vmazupraplx4002"
sleep 15

echo "Verificação final..."
check_mining "vmazupraplx7962" 8545
check_peers "vmazupraplx7962" 8545

echo ""
echo -e "${GREEN}=== Teste de Consenso Concluído ===${NC}"
echo "Para monitorar logs em tempo real: docker-compose logs -f"
echo "Para parar todos os nós: docker-compose down"

