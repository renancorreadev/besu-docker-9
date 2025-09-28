#!/bin/bash

echo "=== Remoção completa do serviço besu-node ==="

SERVICE_NAME="besu-node"
INSTALL_DIR="/opt/idbra"

# 1. Parar o serviço se estiver ativo
echo "Parando serviço $SERVICE_NAME..."
sudo systemctl stop "$SERVICE_NAME" 2>/dev/null || true

# 2. Desabilitar o serviço no boot
echo "Desabilitando serviço $SERVICE_NAME..."
sudo systemctl disable "$SERVICE_NAME" 2>/dev/null || true

# 3. Remover arquivo systemd
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"
if [ -f "$SERVICE_FILE" ]; then
    echo "Removendo arquivo de serviço: $SERVICE_FILE"
    sudo rm -f "$SERVICE_FILE"
else
    echo "⚠️  Arquivo de serviço não encontrado: $SERVICE_FILE"
fi

# 4. Recarregar systemd
echo "Recarregando systemd..."
sudo systemctl daemon-reload

# 5. Remover diretório de instalação
if [ -d "$INSTALL_DIR" ]; then
    echo "Removendo diretório: $INSTALL_DIR"
    sudo rm -rf "$INSTALL_DIR"
else
    echo "⚠️  Diretório não encontrado: $INSTALL_DIR"
fi

# 6. (Opcional) Remover o usuário 'besu' se ele existir e não for usado por outro processo
if id "besu" &>/dev/null; then
    echo "Usuário 'besu' existe. Deseja removê-lo? (s/n)"
    read -r CONFIRM
    if [[ "$CONFIRM" == "s" || "$CONFIRM" == "S" ]]; then
        echo "Removendo usuário 'besu'..."
        sudo userdel -r besu 2>/dev/null || echo "⚠️  Não foi possível remover a home ou o usuário está em uso"
    else
        echo "Usuário 'besu' mantido."
    fi
else
    echo "Usuário 'besu' não existe."
fi

echo ""
echo "✅ Remoção concluída!"
