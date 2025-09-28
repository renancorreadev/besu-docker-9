#!/bin/bash

# Script avançado para corrigir quorum QBFT
# Tenta várias abordagens para reconfigurar o quorum

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Correção Avançada de Quorum QBFT ===${NC}"

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

# Função para verificar validadores ativos
check_validators() {
    echo "Verificando validadores ativos..."
    for port in 8545 8546 8547 8548 8549 8550 8551 8552 8553; do
        echo -n "Porta $port: "
        if curl -s -X POST -H "Content-Type: application/json" \
            --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
            http://localhost:$port >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Ativo${NC}"
        else
            echo -e "${RED}❌ Parado${NC}"
        fi
    done
}

echo "1. Estado atual:"
check_mining
check_validators

echo ""
echo "2. Tentativa 1: Verificar APIs disponíveis..."
echo "APIs QBFT disponíveis:"
curl -s -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"rpc_modules","params":[],"id":1}' \
    http://localhost:8545 | jq '.result | keys | map(select(test("qbft")))'

echo ""
echo "3. Tentativa 2: Verificar validadores atuais..."
validators=$(curl -s -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"qbft_getValidators","params":["latest"],"id":1}' \
    http://localhost:8545 | jq -r '.result[]' 2>/dev/null)

if [ -n "$validators" ]; then
    echo "Validadores configurados:"
    echo "$validators"
    validator_count=$(echo "$validators" | wc -l)
    echo "Total: $validator_count"
else
    echo "Não foi possível obter lista de validadores"
fi

echo ""
echo "4. Tentativa 3: Verificar se há transações de reconfiguração pendentes..."
pending_txs=$(curl -s -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"txpool_status","params":[],"id":1}' \
    http://localhost:8545 | jq -r '.result.pending' 2>/dev/null)

echo "Transações pendentes: $pending_txs"

echo ""
echo "5. Tentativa 4: Verificar logs de consenso..."
echo "Últimas mensagens de consenso:"
docker-compose logs --tail=10 vmazupraplx7962 | grep -i "round\|consensus\|quorum" | tail -5

echo ""
echo "6. Soluções recomendadas:"
echo "   a) Reiniciar a rede com genesis.json modificado (5 validadores)"
echo "   b) Usar transação de reconfiguração (se suportado)"
echo "   c) Verificar se há problema de sincronização de tempo"
echo "   d) Verificar conectividade entre nós"

echo ""
echo "7. Para reiniciar com configuração correta:"
echo "   - Modificar genesis.json para ter apenas 5 validadores"
echo "   - Executar: docker-compose down && docker-compose up -d"
echo "   - Aguardar sincronização completa"

echo ""
echo -e "${YELLOW}Nota: O QBFT pode não suportar reconfiguração dinâmica de quorum.${NC}"
echo -e "${YELLOW}A solução mais confiável é reiniciar com configuração correta.${NC}"

