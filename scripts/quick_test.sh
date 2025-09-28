#!/bin/bash

# Script rápido para testar conectividade da rede QBFT
# Autor: Sistema de Rede Blockchain

echo "=== Teste Rápido - Rede QBFT ==="
echo "Data: $(date)"
echo ""

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "1. Status dos containers:"
docker-compose ps --format "table {{.Name}}\t{{.Status}}"

echo ""
echo "2. Testando conectividade P2P básica..."

# Testar se containers conseguem se comunicar
containers=("vmazupraplx7962" "vmazupraplx9278" "vmazuprapix4156")

for container in "${containers[@]}"; do
    echo -n "Testando $container ... "
    if docker-compose exec -T $container timeout 3 bash -c "echo > /dev/tcp/vmazupraplx7962/30303" 2>/dev/null; then
        echo -e "${GREEN}✅ OK${NC}"
    else
        echo -e "${RED}❌ FALHOU${NC}"
    fi
done

echo ""
echo "3. Testando RPC endpoints..."

# Testar RPC endpoints
rpc_ports=("8545" "8546" "8547" "8548" "8549" "8550" "8551" "8552" "8553")
rpc_names=("vmazupraplx7962" "vmazupraplx2694" "vmazupraplx9942" "vmazupraplx9278" "vmazupraplx4002" "vmazupraplx8934" "vmazuprapix4156" "vmazupraplx6452" "vmazupraplx8278")

for i in "${!rpc_ports[@]}"; do
    port=${rpc_ports[$i]}
    name=${rpc_names[$i]}
    echo -n "Testando $name (porta $port) ... "

    response=$(curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
        --connect-timeout 3 \
        localhost:$port 2>/dev/null)

    if [ $? -eq 0 ] && echo "$response" | grep -q "result"; then
        echo -e "${GREEN}✅ OK${NC}"
    else
        echo -e "${RED}❌ FALHOU${NC}"
    fi
done

echo ""
echo "4. Verificando peers conectados..."

# Verificar peers do primeiro container
echo "Peers conectados em vmazupraplx7962:"
peer_response=$(curl -s -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"admin_peers","params":[],"id":1}' \
    localhost:8545 2>/dev/null)

if [ $? -eq 0 ]; then
    peer_count=$(echo "$peer_response" | grep -o 'enode' | wc -l)
    echo "Número de peers: $peer_count"
    if [ "$peer_count" -gt 0 ]; then
        echo -e "${GREEN}✅ Rede P2P funcionando!${NC}"
    else
        echo -e "${YELLOW}⚠️  Nenhum peer conectado ainda${NC}"
    fi
else
    echo -e "${RED}❌ Não foi possível verificar peers${NC}"
fi

echo ""
echo "5. Logs recentes de conectividade:"
docker-compose logs --tail=3 vmazupraplx7962 | grep -E "(peer|discovery|bootnode|Connected)" || echo "Nenhum log de conectividade encontrado"

echo ""
echo "Para testes mais detalhados: ./test_connectivity.sh"
echo "Para monitorar logs: docker-compose logs -f"
