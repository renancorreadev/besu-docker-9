#!/bin/bash

# Script para iniciar a rede QBFT do Hyperledger Besu
# Autor: Sistema de Rede Blockchain
# Data: $(date)

echo "=== Iniciando Rede QBFT Hyperledger Besu ==="
echo "Data: $(date)"
echo ""

# Verificar se o Docker está rodando
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker não está rodando. Por favor, inicie o Docker primeiro."
    exit 1
fi

# Verificar se o docker-compose está disponível
if ! command -v docker-compose > /dev/null 2>&1; then
    echo "❌ docker-compose não encontrado. Instalando..."
    # Tentar instalar docker-compose
    if command -v apt-get > /dev/null 2>&1; then
        sudo apt-get update && sudo apt-get install -y docker-compose
    elif command -v yum > /dev/null 2>&1; then
        sudo yum install -y docker-compose
    else
        echo "❌ Não foi possível instalar docker-compose automaticamente."
        echo "Por favor, instale manualmente: https://docs.docker.com/compose/install/"
        exit 1
    fi
fi

echo "✅ Docker e docker-compose verificados"

# Parar containers existentes se houver
echo "🔄 Parando containers existentes..."
docker-compose down

# Construir as imagens
echo "🔨 Construindo imagens Docker..."
docker-compose build

# Iniciar a rede
echo "🚀 Iniciando rede QBFT..."
docker-compose up -d

# Aguardar um pouco para os containers iniciarem
echo "⏳ Aguardando containers iniciarem..."
sleep 10

# Verificar status dos containers
echo ""
echo "=== Status dos Containers ==="
docker-compose ps

echo ""
echo "=== Logs dos Bootnodes ==="
echo "Bootnode 1 (vmazupraplx7962):"
docker-compose logs --tail=10 vmazupraplx7962

echo ""
echo "Bootnode 2 (vmazupraplx9278):"
docker-compose logs --tail=10 vmazupraplx9278

echo ""
echo "Bootnode 3 (vmazuprapix4156):"
docker-compose logs --tail=10 vmazuprapix4156

echo ""
echo "=== Informações da Rede ==="
echo "Bootnodes:"
echo "  - vmazupraplx7962: 172.23.105.82:30303"
echo "  - vmazupraplx9278: 172.23.105.99:30303"
echo "  - vmazuprapix4156: 172.23.105.105:30303"
echo ""
echo "Validadores:"
echo "  - vmazupraplx2694: 172.23.105.98:30303"
echo "  - vmazupraplx9942: 172.23.105.101:30303"
echo "  - vmazupraplx4002: 172.23.105.104:30303"
echo "  - vmazupraplx8934: 172.25.206.4:30303"
echo "  - vmazupraplx6452: 172.23.105.108:30303"
echo "  - vmazupraplx8278: 172.23.105.107:30303"
echo ""
echo "RPC Endpoints:"
echo "  - Bootnode 1: http://localhost:8545"
echo "  - Validador 1: http://localhost:8546"
echo "  - Validador 2: http://localhost:8547"
echo "  - Bootnode 2: http://localhost:8548"
echo "  - Validador 3: http://localhost:8549"
echo "  - Validador 4: http://localhost:8550"
echo "  - Bootnode 3: http://localhost:8551"
echo "  - Validador 5: http://localhost:8552"
echo "  - Validador 6: http://localhost:8553"

echo ""
echo "✅ Rede QBFT iniciada com sucesso!"
echo "Use 'docker-compose logs -f' para acompanhar os logs em tempo real"
echo "Use './stop_network.sh' para parar a rede"
