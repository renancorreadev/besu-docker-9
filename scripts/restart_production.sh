#!/bin/bash

# Script para reiniciar Besu em produção via SSH
# Configura as VMs e executa comandos remotamente

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Reinicialização de Produção QBFT ===${NC}"

# Configuração das VMs (ajuste conforme sua infraestrutura)
declare -A VMS=(
    ["vmazupraplx7962"]="172.23.105.82"
    ["vmazupraplx2694"]="172.23.105.98"
    ["vmazupraplx9942"]="172.23.105.101"
    ["vmazupraplx9278"]="172.23.105.99"
    ["vmazupraplx4002"]="172.23.105.104"
    ["vmazupraplx8934"]="172.23.105.110"
    ["vmazuprapix4156"]="172.23.105.105"
)

# Usuário SSH (ajuste conforme necessário)
SSH_USER="root"
# ou "ubuntu", "ec2-user", etc.

# Função para executar comando via SSH
ssh_execute() {
    local vm_name=$1
    local ip=$2
    local command=$3

    echo -n "Executando em $vm_name ($ip)... "

    if ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no $SSH_USER@$ip "$command" 2>/dev/null; then
        echo -e "${GREEN}✅ OK${NC}"
        return 0
    else
        echo -e "${RED}❌ FALHOU${NC}"
        return 1
    fi
}

# Função para verificar se VM está respondendo
check_vm() {
    local vm_name=$1
    local ip=$2

    echo -n "Verificando $vm_name ($ip)... "

    if ping -c 1 -W 3 $ip >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Online${NC}"
        return 0
    else
        echo -e "${RED}❌ Offline${NC}"
        return 1
    fi
}

# Função para parar Besu
stop_besu() {
    local vm_name=$1
    local ip=$2

    echo "Parando Besu em $vm_name..."

    # Tentar diferentes métodos de parada
    ssh_execute $vm_name $ip "sudo systemctl stop besu" || \
    ssh_execute $vm_name $ip "sudo pkill -f besu" || \
    ssh_execute $vm_name $ip "pkill -f besu"

    # Aguardar parada completa
    sleep 3
}

# Função para iniciar Besu
start_besu() {
    local vm_name=$1
    local ip=$2

    echo "Iniciando Besu em $vm_name..."

    # Tentar diferentes métodos de inicialização
    ssh_execute $vm_name $ip "sudo systemctl start besu" || \
    ssh_execute $vm_name $ip "nohup /path/to/start_node.sh > /dev/null 2>&1 &" || \
    ssh_execute $vm_name $ip "cd /opt/besu && nohup ./start_node.sh > /dev/null 2>&1 &"
}

# Função para verificar se Besu está rodando
check_besu() {
    local vm_name=$1
    local ip=$2

    echo -n "Verificando Besu em $vm_name... "

    # Verificar se processo está rodando
    if ssh_execute $vm_name $ip "pgrep -f besu" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Rodando${NC}"
        return 0
    else
        echo -e "${RED}❌ Parado${NC}"
        return 1
    fi
}

echo "1. Verificando conectividade das VMs..."
for vm_name in "${!VMS[@]}"; do
    check_vm $vm_name ${VMS[$vm_name]}
done

echo ""
echo "2. Parando Besu em todas as VMs..."
for vm_name in "${!VMS[@]}"; do
    stop_besu $vm_name ${VMS[$vm_name]}
done

echo ""
echo "3. Aguardando 10 segundos..."
sleep 10

echo ""
echo "4. Iniciando Besu em todas as VMs..."
for vm_name in "${!VMS[@]}"; do
    start_besu $vm_name ${VMS[$vm_name]}
done

echo ""
echo "5. Aguardando 30 segundos para estabilização..."
sleep 30

echo ""
echo "6. Verificando status final..."
for vm_name in "${!VMS[@]}"; do
    check_besu $vm_name ${VMS[$vm_name]}
done

echo ""
echo -e "${YELLOW}Nota: Ajuste as configurações no início do script:${NC}"
echo "- VMs: IPs e nomes das suas VMs"
echo "- SSH_USER: usuário para conexão SSH"
echo "- Comandos: caminhos corretos dos scripts"
echo ""
echo -e "${GREEN}Reinicialização concluída!${NC}"

