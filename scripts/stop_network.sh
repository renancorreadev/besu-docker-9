#!/bin/bash

# Script para parar a rede QBFT do Hyperledger Besu
# Autor: Sistema de Rede Blockchain
# Data: $(date)

echo "=== Parando Rede QBFT Hyperledger Besu ==="
echo "Data: $(date)"
echo ""

# Verificar se o docker-compose está disponível
if ! command -v docker-compose > /dev/null 2>&1; then
    echo "❌ docker-compose não encontrado."
    exit 1
fi

# Parar containers
echo "🛑 Parando containers..."
docker-compose down

# Remover containers parados
echo "🧹 Removendo containers parados..."
docker-compose rm -f

# Mostrar status final
echo ""
echo "=== Status Final ==="
docker-compose ps

echo ""
echo "✅ Rede QBFT parada com sucesso!"
echo "Use './start_network.sh' para reiniciar a rede"

