#!/bin/bash

# Script para mapear validadores com seus IPs e endereços
echo "=== MAPEAMENTO COMPLETO: VALIDADOR -> IP -> ENDEREÇO ==="
echo "Data: $(date)"
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Array com containers, portas e IPs esperados
declare -A containers=(
    ["vmazupraplx7962"]="8545:172.23.105.82"
    ["vmazupraplx2694"]="8546:172.23.105.98"
    ["vmazupraplx9942"]="8547:172.23.105.101"
    ["vmazupraplx9278"]="8548:172.23.105.99"
    ["vmazupraplx4002"]="8549:172.23.105.104"
    ["vmazupraplx8934"]="8550:172.23.105.110"
    ["vmazuprapix4156"]="8551:172.23.105.105"
    ["vmazupraplx6452"]="8552:172.23.105.108"
    ["vmazupraplx8278"]="8553:172.23.105.107"
)

echo -e "${BLUE}1. Obtendo lista de validadores ativos...${NC}"
echo ""

# Obter lista de validadores
validators=$(curl -s -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"qbft_getValidatorsByBlockNumber","params":["latest"],"id":1}' \
    http://localhost:8545 | jq -r '.result[]?' 2>/dev/null)

if [ -z "$validators" ]; then
    echo -e "${RED}❌ Erro ao obter lista de validadores${NC}"
    exit 1
fi

echo "Validadores encontrados:"
echo "$validators" | nl
echo ""

echo -e "${BLUE}2. Mapeando containers com endereços de validadores...${NC}"
echo ""

printf "%-20s %-8s %-18s %-45s %-10s\n" "CONTAINER" "PORTA" "IP" "ENDEREÇO VALIDADOR" "STATUS"
printf "%-20s %-8s %-18s %-45s %-10s\n" "--------------------" "--------" "------------------" "---------------------------------------------" "----------"

for container in "${!containers[@]}"; do
    IFS=':' read -r port ip <<< "${containers[$container]}"
    
    # Verificar se container está rodando
    if ! docker-compose ps "$container" | grep -q "Up"; then
        printf "%-20s %-8s %-18s %-45s %-10s\n" "$container" "$port" "$ip" "N/A" "PARADO"
        continue
    fi
    
    # Obter endereço do validador (coinbase)
    validator_address=$(curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_coinbase","params":[],"id":1}' \
        http://localhost:$port | jq -r '.result // "N/A"' 2>/dev/null)
    
    # Verificar se é um validador ativo
    if echo "$validators" | grep -q "$validator_address"; then
        status="${GREEN}ATIVO${NC}"
    else
        status="${YELLOW}INATIVO${NC}"
    fi
    
    printf "%-20s %-8s %-18s %-45s " "$container" "$port" "$ip" "$validator_address"
    echo -e "$status"
done

echo ""
echo -e "${BLUE}3. Verificando IPs reais dos containers...${NC}"
echo ""

printf "%-20s %-18s %-18s %-10s\n" "CONTAINER" "IP CONFIGURADO" "IP REAL" "STATUS"
printf "%-20s %-18s %-18s %-10s\n" "--------------------" "------------------" "------------------" "----------"

for container in "${!containers[@]}"; do
    IFS=':' read -r port expected_ip <<< "${containers[$container]}"
    
    # Obter IP real do container
    real_ip=$(docker inspect "$container" 2>/dev/null | jq -r '.[0].NetworkSettings.Networks[].IPAddress // "N/A"' 2>/dev/null)
    
    if [ "$real_ip" = "$expected_ip" ]; then
        status="${GREEN}OK${NC}"
    elif [ "$real_ip" = "N/A" ]; then
        status="${RED}ERRO${NC}"
    else
        status="${YELLOW}DIFERENTE${NC}"
    fi
    
    printf "%-20s %-18s %-18s " "$container" "$expected_ip" "$real_ip"
    echo -e "$status"
done

echo ""
echo -e "${BLUE}4. Obtendo enodes com IPs...${NC}"
echo ""

printf "%-20s %-18s %-45s\n" "CONTAINER" "IP" "ENODE"
printf "%-20s %-18s %-45s\n" "--------------------" "------------------" "---------------------------------------------"

for container in "${!containers[@]}"; do
    IFS=':' read -r port ip <<< "${containers[$container]}"
    
    if docker-compose ps "$container" | grep -q "Up"; then
        # Obter enode do container
        enode=$(docker-compose logs "$container" 2>/dev/null | grep "Enode URL" | tail -1 | sed 's/.*Enode URL //' 2>/dev/null)
        
        if [ -n "$enode" ]; then
            # Extrair apenas a parte do pubkey para exibição
            pubkey=$(echo "$enode" | cut -d'@' -f1 | cut -d'/' -f3 | cut -c1-20)
            printf "%-20s %-18s enode://%s...@%s:30303\n" "$container" "$ip" "$pubkey" "$ip"
        else
            printf "%-20s %-18s %-45s\n" "$container" "$ip" "Enode não encontrado"
        fi
    else
        printf "%-20s %-18s %-45s\n" "$container" "$ip" "Container parado"
    fi
done

echo ""
echo -e "${BLUE}5. Peers conectados com IPs...${NC}"
echo ""

# Obter peers conectados
peers=$(curl -s -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"admin_peers","params":[],"id":1}' \
    http://localhost:8545 | jq -r '.result[]?' 2>/dev/null)

if [ -n "$peers" ]; then
    echo "Peers conectados:"
    curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"admin_peers","params":[],"id":1}' \
        http://localhost:8545 | jq -r '.result[] | "IP: " + .network.remoteAddress + " | Enode: " + (.enode | split("@")[0] | split("/")[2] | .[0:20]) + "..."' 2>/dev/null
else
    echo "Nenhum peer conectado ou erro ao obter peers"
fi

echo ""
echo -e "${BLUE}6. Comandos úteis para investigação...${NC}"
echo ""

echo "🔍 Para verificar endereço de um validador específico:"
echo "curl -s -X POST -H \"Content-Type: application/json\" \\"
echo "  --data '{\"jsonrpc\":\"2.0\",\"method\":\"eth_coinbase\",\"params\":[],\"id\":1}' \\"
echo "  http://localhost:PORTA | jq '.result'"
echo ""

echo "🔍 Para verificar IP real de um container:"
echo "docker inspect NOME_CONTAINER | jq '.[0].NetworkSettings.Networks[].IPAddress'"
echo ""

echo "🔍 Para verificar enode de um container:"
echo "docker-compose logs NOME_CONTAINER | grep \"Enode URL\" | tail -1"
echo ""

echo "🔍 Para testar conectividade com IP específico:"
echo "curl -X POST -H \"Content-Type: application/json\" \\"
echo "  --data '{\"jsonrpc\":\"2.0\",\"method\":\"net_peerCount\",\"params\":[],\"id\":1}' \\"
echo "  http://IP:8545"
echo ""

echo -e "${BLUE}7. Resumo final...${NC}"
echo ""

# Contar validadores ativos
active_validators=$(echo "$validators" | wc -l)
running_containers=$(docker-compose ps | grep "Up" | wc -l)

echo "📊 Validadores ativos: $active_validators"
echo "📊 Containers rodando: $running_containers"
echo "📊 Total de containers: ${#containers[@]}"

echo ""
echo "✅ Para usar um endereço específico nos comandos QBFT, use os endereços da coluna 'ENDEREÇO VALIDADOR'"
echo "✅ Para conectar via IP, use os IPs da coluna 'IP REAL'"