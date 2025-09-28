#!/bin/bash

# Script de coordenação para reinicialização sequencial
# Execute este script em uma VM e siga as instruções

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Coordenação de Reinicialização QBFT ===${NC}"
echo ""

# Lista das VMs (ajuste conforme sua infraestrutura)
VMS=(
    "vmazupraplx7962:172.23.105.82"
    "vmazupraplx2694:172.23.105.98"
    "vmazupraplx9942:172.23.105.101"
    "vmazupraplx9278:172.23.105.99"
    "vmazupraplx4002:172.23.105.104"
    "vmazupraplx8934:172.23.105.110"
    "vmazuprapix4156:172.23.105.105"
)

echo "1. PARAR todas as VMs primeiro:"
echo "Execute o script restart_besu_local.sh em cada VM para PARAR o Besu"
echo ""

for vm in "${VMS[@]}"; do
    vm_name=$(echo $vm | cut -d: -f1)
    vm_ip=$(echo $vm | cut -d: -f2)
    echo "   - $vm_name ($vm_ip)"
done

echo ""
echo -e "${YELLOW}Pressione ENTER quando TODAS as VMs estiverem paradas...${NC}"
read

echo ""
echo "2. INICIAR as VMs em sequência:"
echo "Execute o script restart_besu_local.sh em cada VM na ordem abaixo:"
echo ""

# Ordem de inicialização (bootnodes primeiro)
bootnodes=("vmazupraplx7962" "vmazupraplx9278" "vmazuprapix4156")
validators=("vmazupraplx2694" "vmazupraplx9942" "vmazupraplx4002" "vmazupraplx8934")

echo "   FASE 1 - Bootnodes (inicie primeiro):"
for vm in "${bootnodes[@]}"; do
    for vm_info in "${VMS[@]}"; do
        if [[ $vm_info == $vm:* ]]; then
            vm_ip=$(echo $vm_info | cut -d: -f2)
            echo "   - $vm ($vm_ip)"
        fi
    done
done

echo ""
echo -e "${YELLOW}Pressione ENTER quando os bootnodes estiverem iniciados...${NC}"
read

echo ""
echo "   FASE 2 - Validators (inicie depois):"
for vm in "${validators[@]}"; do
    for vm_info in "${VMS[@]}"; do
        if [[ $vm_info == $vm:* ]]; then
            vm_ip=$(echo $vm_info | cut -d: -f2)
            echo "   - $vm ($vm_ip)"
        fi
    done
done

echo ""
echo -e "${YELLOW}Pressione ENTER quando todos os validators estiverem iniciados...${NC}"
read

echo ""
echo "3. Verificação final:"
echo "Execute o script de monitoramento para verificar se está funcionando:"
echo ""

# Script de verificação
cat > check_network.sh << 'EOF'
#!/bin/bash
echo "=== Verificação da Rede QBFT ==="
echo ""

# Verificar cada VM
VMS=("vmazupraplx7962:172.23.105.82" "vmazupraplx2694:172.23.105.98" "vmazupraplx9942:172.23.105.101" "vmazupraplx9278:172.23.105.99" "vmazupraplx4002:172.23.105.104" "vmazupraplx8934:172.23.105.110" "vmazuprapix4156:172.23.105.105")

for vm_info in "${VMS[@]}"; do
    vm_name=$(echo $vm_info | cut -d: -f1)
    vm_ip=$(echo $vm_info | cut -d: -f2)

    echo -n "Verificando $vm_name ($vm_ip)... "

    if curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
        http://$vm_ip:8545 >/dev/null 2>&1; then
        echo "✅ OK"
    else
        echo "❌ FALHOU"
    fi
done

echo ""
echo "Verificação concluída!"
EOF

chmod +x check_network.sh

echo "   ./check_network.sh"
echo ""
echo -e "${GREEN}Reinicialização coordenada concluída!${NC}"
echo ""
echo "Dicas importantes:"
echo "1. Pare TODAS as VMs primeiro"
echo "2. Inicie os bootnodes primeiro"
echo "3. Aguarde 30 segundos entre as fases"
echo "4. Monitore os logs durante a inicialização"
echo "5. Use o script de verificação para confirmar"

