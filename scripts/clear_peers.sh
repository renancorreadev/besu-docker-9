#!/bin/bash

# Script para limpar peers e forçar reconexão P2P
# Solução não-destrutiva para destravar consenso QBFT

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Limpeza de Peers - Destravamento QBFT ===${NC}"

# Função para verificar se está minerando
check_mining() {
    local block_number=$(curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
        http://localhost:8545 | jq -r '.result' 2>/dev/null)

    if [ "$block_number" != "null" ] && [ "$block_number" != "0x0" ]; then
        echo -e "${GREEN}✅ Minerando (bloco: $((block_number)))${NC}"
        return 0
    else
        echo -e "${RED}❌ NÃO está minerando${NC}"
        return 1
    fi
}

# Função para limpar peers de um nó
clear_peers() {
    local port=$1
    local node_name=$2

    echo -n "Limpando peers de $node_name (porta $port)... "

    # Listar peers atuais
    local peers=$(curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"admin_peers","params":[],"id":1}' \
        http://localhost:$port | jq -r '.result[].enode' 2>/dev/null)

    if [ -n "$peers" ]; then
        # Remover cada peer
        for peer in $peers; do
            curl -s -X POST -H "Content-Type: application/json" \
                --data "{\"jsonrpc\":\"2.0\",\"method\":\"admin_removePeer\",\"params\":[\"$peer\"],\"id\":1}" \
                http://localhost:$port >/dev/null 2>&1
        done
        echo -e "${GREEN}✅ Limpo${NC}"
    else
        echo -e "${YELLOW}⚠️  Sem peers${NC}"
    fi
}

# Função para adicionar peers específicos
add_specific_peers() {
    local port=$1
    local node_name=$2

    echo -n "Reconectando $node_name... "

    # Lista de enodes dos bootnodes
    local bootnodes=(
        "enode://93677b2fd0864ea2af0d514fa323f7e51f9d3126cab42c9c4c624f10174bcf6b2df731a63b0d22cf560d0ca8511faaf9245b7972483c109c6b86afa36c765657@172.23.105.82:30303"
        "enode://1d3a0a388d491c87cb60c7c27b68c8252861f1e229e11d66d972094bbfbedde1d54505313907985acd8e313e9fd1b4f79558add2aa8997cfbee310d0db29684d@172.23.105.99:30303"
        "enode://b0bb7ec6bae41524ba247527be974bac194ee543c57ec1671087e392fc2ac77b47653c749d44154687e33fae1d5f7cbb54cb09e38492af8e5efca1a200c0f2e7@172.23.105.105:30303"
    )

    # Adicionar bootnodes
    for bootnode in "${bootnodes[@]}"; do
        curl -s -X POST -H "Content-Type: application/json" \
            --data "{\"jsonrpc\":\"2.0\",\"method\":\"admin_addPeer\",\"params\":[\"$bootnode\"],\"id\":1}" \
            http://localhost:$port >/dev/null 2>&1
    done

    echo -e "${GREEN}✅ Reconectado${NC}"
}

echo "1. Estado inicial:"
check_mining

echo ""
echo "2. Limpando peers de todos os nós..."

# Limpar peers de todos os nós ativos
clear_peers 8545 "vmazupraplx7962"
clear_peers 8546 "vmazupraplx2694"
clear_peers 8547 "vmazupraplx9942"
clear_peers 8548 "vmazupraplx9278"
clear_peers 8549 "vmazupraplx4002"
clear_peers 8550 "vmazupraplx8934"
clear_peers 8551 "vmazuprapix4156"
clear_peers 8552 "vmazupraplx6452"
clear_peers 8553 "vmazupraplx8278"

echo ""
echo "3. Aguardando 10 segundos..."
sleep 10

echo ""
echo "4. Reconectando peers específicos..."

# Reconectar peers específicos
add_specific_peers 8545 "vmazupraplx7962"
add_specific_peers 8546 "vmazupraplx2694"
add_specific_peers 8547 "vmazupraplx9942"
add_specific_peers 8548 "vmazupraplx9278"
add_specific_peers 8549 "vmazupraplx4002"
add_specific_peers 8550 "vmazupraplx8934"
add_specific_peers 8551 "vmazuprapix4156"
add_specific_peers 8552 "vmazupraplx6452"
add_specific_peers 8553 "vmazupraplx8278"

echo ""
echo "5. Aguardando sincronização (30 segundos)..."
sleep 30

echo ""
echo "6. Verificando estado final:"
check_mining

echo ""
echo "7. Verificando peers conectados:"
for port in 8545 8546 8547 8548 8549 8550 8551 8552 8553; do
    peer_count=$(curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"admin_peers","params":[],"id":1}' \
        http://localhost:$port | jq '.result | length' 2>/dev/null)
    echo "Porta $port: $peer_count peers"
done

echo ""
echo -e "${YELLOW}Se ainda não estiver funcionando, pode ser necessário:${NC}"
echo "1. Reiniciar apenas os nós travados: docker-compose restart [nomes]"
echo "2. Verificar logs: docker-compose logs -f"
echo "3. Aguardar mais tempo para sincronização"
