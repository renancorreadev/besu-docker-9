#!/bin/bash

# Script para verificar o status da rede QBFT do Hyperledger Besu
# Autor: Sistema de Rede Blockchain
# Data: $(date)

echo "=== Status da Rede QBFT Hyperledger Besu ==="
echo "Data: $(date)"
echo ""

# Verificar se o docker-compose está disponível
if ! command -v docker-compose > /dev/null 2>&1; then
    echo "❌ docker-compose não encontrado."
    exit 1
fi

# Verificar status dos containers
echo "=== Status dos Containers ==="
docker-compose ps

echo ""
echo "=== Logs Recentes ==="
echo "Últimos 5 logs de cada container:"
echo ""

for container in vmazupraplx7962 vmazupraplx2694 vmazupraplx9942 vmazupraplx9278 vmazupraplx4002 vmazupraplx8934 vmazuprapix4156 vmazupraplx6452 vmazupraplx8278; do
    echo "--- $container ---"
    docker-compose logs --tail=5 $container
    echo ""
done

echo "=== Informações de Rede ==="
echo "Para ver logs em tempo real: docker-compose logs -f"
echo "Para ver logs de um container específico: docker-compose logs -f <container_name>"
echo "Para acessar um container: docker-compose exec <container_name> bash"

