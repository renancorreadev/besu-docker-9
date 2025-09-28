#!/bin/bash

# Script para testar conectividade entre containers da rede QBFT
# Autor: Sistema de Rede Blockchain
# Data: $(date)

echo "=== Teste de Conectividade - Rede QBFT Hyperledger Besu ==="
echo "Data: $(date)"
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para testar conectividade de rede
test_network_connectivity() {
    local container1=$1
    local container2=$2
    local port=$3

    echo -n "Testando $container1 -> $container2:$port ... "

    # Testar conectividade usando timeout e /dev/tcp
    if docker-compose exec -T $container1 timeout 3 bash -c "echo > /dev/tcp/$container2/$port" 2>/dev/null; then
        echo -e "${GREEN}✅ OK${NC}"
        return 0
    else
        echo -e "${RED}❌ FALHOU${NC}"
        return 1
    fi
}

# Função para testar RPC endpoint
test_rpc_endpoint() {
    local container=$1
    local port=$2
    local name=$3

    echo -n "Testando RPC $name ($container:$port) ... "

    response=$(docker-compose exec -T $container curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
        --connect-timeout 5 \
        localhost:$port 2>/dev/null)

    if [ $? -eq 0 ] && echo "$response" | grep -q "result"; then
        echo -e "${GREEN}✅ OK${NC}"
        return 0
    else
        echo -e "${RED}❌ FALHOU${NC}"
        return 1
    fi
}

# Função para testar P2P discovery
test_p2p_discovery() {
    local container=$1
    local name=$2

    echo -n "Testando P2P Discovery $name ... "

    # Verificar se o container está rodando
    if ! docker-compose ps $container | grep -q "Up"; then
        echo -e "${RED}❌ Container não está rodando${NC}"
        return 1
    fi

    # Verificar logs para enode
    enode=$(docker-compose logs $container 2>/dev/null | grep "Enode URL" | tail -1 | sed 's/.*Enode URL //')
    if [ -n "$enode" ]; then
        echo -e "${GREEN}✅ Enode: $enode${NC}"
        return 0
    else
        echo -e "${RED}❌ Enode não encontrado${NC}"
        return 1
    fi
}

# Verificar se docker-compose está disponível
if ! command -v docker-compose > /dev/null 2>&1; then
    echo -e "${RED}❌ docker-compose não encontrado${NC}"
    exit 1
fi

echo -e "${BLUE}1. Verificando status dos containers...${NC}"
echo ""

# Verificar status dos containers
docker-compose ps

echo ""
echo -e "${BLUE}2. Testando conectividade de rede entre containers...${NC}"
echo ""

# Lista de containers
containers=("vmazupraplx7962" "vmazupraplx2694" "vmazupraplx9942" "vmazupraplx9278" "vmazupraplx4002" "vmazupraplx8934" "vmazuprapix4156" "vmazupraplx6452" "vmazupraplx8278")

# Testar conectividade P2P entre todos os containers
total_tests=0
successful_tests=0

for container1 in "${containers[@]}"; do
    for container2 in "${containers[@]}"; do
        if [ "$container1" != "$container2" ]; then
            total_tests=$((total_tests + 1))
            if test_network_connectivity $container1 $container2 30303; then
                successful_tests=$((successful_tests + 1))
            fi
        fi
    done
done

echo ""
echo -e "${BLUE}3. Testando endpoints RPC...${NC}"
echo ""

# Testar endpoints RPC
rpc_tests=0
rpc_success=0

# Mapeamento de containers para portas RPC
declare -A rpc_ports=(
    ["vmazupraplx7962"]="8545"
    ["vmazupraplx2694"]="8545"
    ["vmazupraplx9942"]="8545"
    ["vmazupraplx9278"]="8545"
    ["vmazupraplx4002"]="8545"
    ["vmazupraplx8934"]="8545"
    ["vmazuprapix4156"]="8545"
    ["vmazupraplx6452"]="8545"
    ["vmazupraplx8278"]="8545"
)

for container in "${containers[@]}"; do
    rpc_tests=$((rpc_tests + 1))
    if test_rpc_endpoint $container ${rpc_ports[$container]} $container; then
        rpc_success=$((rpc_success + 1))
    fi
done

echo ""
echo -e "${BLUE}4. Testando P2P Discovery (Enodes)...${NC}"
echo ""

# Testar P2P discovery
p2p_tests=0
p2p_success=0

for container in "${containers[@]}"; do
    p2p_tests=$((p2p_tests + 1))
    if test_p2p_discovery $container $container; then
        p2p_success=$((p2p_success + 1))
    fi
done

echo ""
echo -e "${BLUE}5. Testando conectividade específica entre bootnodes...${NC}"
echo ""

# Testar conectividade específica entre bootnodes
bootnodes=("vmazupraplx7962" "vmazupraplx9278" "vmazuprapix4156")
bootnode_tests=0
bootnode_success=0

for bootnode1 in "${bootnodes[@]}"; do
    for bootnode2 in "${bootnodes[@]}"; do
        if [ "$bootnode1" != "$bootnode2" ]; then
            bootnode_tests=$((bootnode_tests + 1))
            if test_network_connectivity $bootnode1 $bootnode2 30303; then
                bootnode_success=$((bootnode_success + 1))
            fi
        fi
    done
done

echo ""
echo -e "${BLUE}6. Verificando logs de conectividade P2P...${NC}"
echo ""

# Verificar logs de conectividade P2P
for container in "${containers[@]}"; do
    echo -e "${YELLOW}--- Logs de conectividade $container ---${NC}"
    docker-compose logs $container 2>/dev/null | grep -E "(peer|discovery|bootnode|Connected|Disconnected)" | tail -5
    echo ""
done

echo ""
echo -e "${BLUE}7. Resumo dos Testes${NC}"
echo ""

echo "Conectividade de Rede: $successful_tests/$total_tests"
echo "Endpoints RPC: $rpc_success/$rpc_tests"
echo "P2P Discovery: $p2p_success/$p2p_tests"
echo "Bootnodes: $bootnode_success/$bootnode_tests"

echo ""
echo -e "${BLUE}8. Status da Rede${NC}"
echo ""

# Verificar se há peers conectados
echo "Verificando peers conectados..."
for container in "${containers[@]}"; do
    echo -n "$container: "
    peer_count=$(docker-compose exec -T $container curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"admin_peers","params":[],"id":1}' \
        localhost:8545 2>/dev/null | grep -o '"result":\[.*\]' | grep -o 'enode' | wc -l 2>/dev/null || echo "0")
    echo "$peer_count peers"
done

echo ""
echo -e "${BLUE}9. Próximos Passos${NC}"
echo ""

if [ $successful_tests -gt 0 ] && [ $rpc_success -gt 0 ]; then
    echo -e "${GREEN}✅ Rede está funcionando!${NC}"
    echo "- Containers estão se comunicando"
    echo "- Endpoints RPC estão respondendo"
    echo "- Use './test_network.sh' para testes mais detalhados"
else
    echo -e "${RED}❌ Há problemas na rede${NC}"
    echo "- Verifique se todos os containers estão rodando: docker-compose ps"
    echo "- Verifique logs: docker-compose logs"
    echo "- Verifique configurações de rede no docker-compose.yml"
fi

echo ""
echo "Para monitorar em tempo real:"
echo "  docker-compose logs -f"
echo ""
echo "Para testar funcionalidade completa:"
echo "  ./test_network.sh"
