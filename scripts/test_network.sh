#!/bin/bash

# Script para testar a rede QBFT do Hyperledger Besu
# Autor: Sistema de Rede Blockchain
# Data: $(date)

echo "=== Testando Rede QBFT Hyperledger Besu ==="
echo "Data: $(date)"
echo ""

# Função para testar endpoint RPC
test_rpc_endpoint() {
    local name=$1
    local url=$2
    local port=$3

    echo "Testando $name ($url:$port)..."

    # Testar se o endpoint responde
    response=$(curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
        --connect-timeout 5 \
        $url:$port 2>/dev/null)

    if [ $? -eq 0 ] && echo "$response" | grep -q "result"; then
        echo "✅ $name: OK"
        echo "$response" | jq '.' 2>/dev/null || echo "$response"
    else
        echo "❌ $name: FALHOU"
    fi
    echo ""
}

# Verificar se jq está instalado
if ! command -v jq > /dev/null 2>&1; then
    echo "⚠️  jq não encontrado. Instalando..."
    if command -v apt-get > /dev/null 2>&1; then
        sudo apt-get update && sudo apt-get install -y jq
    elif command -v yum > /dev/null 2>&1; then
        sudo yum install -y jq
    else
        echo "❌ Não foi possível instalar jq automaticamente."
        echo "Por favor, instale manualmente para melhor formatação dos resultados."
    fi
fi

echo "=== Testando Endpoints RPC ==="
echo ""

# Testar todos os endpoints
test_rpc_endpoint "Bootnode 1" "http://localhost" "8545"
test_rpc_endpoint "Validador 1" "http://localhost" "8546"
test_rpc_endpoint "Validador 2" "http://localhost" "8547"
test_rpc_endpoint "Bootnode 2" "http://localhost" "8548"
test_rpc_endpoint "Validador 3" "http://localhost" "8549"
test_rpc_endpoint "Validador 4" "http://localhost" "8550"
test_rpc_endpoint "Bootnode 3" "http://localhost" "8551"
test_rpc_endpoint "Validador 5" "http://localhost" "8552"
test_rpc_endpoint "Validador 6" "http://localhost" "8553"

echo "=== Testando Conectividade P2P ==="
echo ""

# Testar conectividade P2P do primeiro bootnode
echo "Testando conectividade P2P (Bootnode 1)..."
peers_response=$(curl -s -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"admin_peers","params":[],"id":1}' \
    http://localhost:8545 2>/dev/null)

if [ $? -eq 0 ] && echo "$peers_response" | grep -q "result"; then
    echo "✅ Conectividade P2P: OK"
    peer_count=$(echo "$peers_response" | jq -r '.result | length' 2>/dev/null || echo "N/A")
    echo "Número de peers conectados: $peer_count"
    if [ "$peer_count" != "N/A" ] && [ "$peer_count" -gt 0 ]; then
        echo "✅ Rede P2P funcionando corretamente"
    else
        echo "⚠️  Nenhum peer conectado ainda (pode ser normal durante inicialização)"
    fi
else
    echo "❌ Conectividade P2P: FALHOU"
fi

echo ""
echo "=== Testando Geração de Blocos ==="
echo ""

# Verificar se blocos estão sendo gerados
echo "Verificando geração de blocos..."
block_response=$(curl -s -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
    http://localhost:8545 2>/dev/null)

if [ $? -eq 0 ] && echo "$block_response" | grep -q "result"; then
    echo "✅ Geração de blocos: OK"
    block_number=$(echo "$block_response" | jq -r '.result' 2>/dev/null || echo "N/A")
    echo "Último bloco: $block_number"

    # Converter hex para decimal
    if [ "$block_number" != "N/A" ] && [ "$block_number" != "0x0" ]; then
        block_decimal=$((16#${block_number#0x}))
        echo "Número decimal: $block_decimal"
        if [ "$block_decimal" -gt 0 ]; then
            echo "✅ Blocos sendo gerados corretamente"
        else
            echo "⚠️  Ainda no bloco genesis"
        fi
    else
        echo "⚠️  Ainda no bloco genesis"
    fi
else
    echo "❌ Geração de blocos: FALHOU"
fi

echo ""
echo "=== Resumo dos Testes ==="
echo ""

# Contar quantos endpoints estão funcionando
working_endpoints=0
total_endpoints=9

for port in 8545 8546 8547 8548 8549 8550 8551 8552 8553; do
    response=$(curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
        --connect-timeout 2 \
        http://localhost:$port 2>/dev/null)

    if [ $? -eq 0 ] && echo "$response" | grep -q "result"; then
        ((working_endpoints++))
    fi
done

echo "Endpoints funcionando: $working_endpoints/$total_endpoints"

if [ "$working_endpoints" -eq "$total_endpoints" ]; then
    echo "✅ Todos os endpoints estão funcionando!"
elif [ "$working_endpoints" -gt 0 ]; then
    echo "⚠️  Alguns endpoints estão funcionando ($working_endpoints/$total_endpoints)"
else
    echo "❌ Nenhum endpoint está funcionando"
fi

echo ""
echo "=== Próximos Passos ==="
echo "1. Se todos os endpoints estão funcionando, a rede está pronta para uso"
echo "2. Use 'docker-compose logs -f' para monitorar logs em tempo real"
echo "3. Use './check_network.sh' para verificar status periodicamente"
echo "4. Use './stop_network.sh' para parar a rede quando necessário"

