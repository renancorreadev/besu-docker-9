Passo a passo do fluxo:

# 0. Verificar o estado da rede atual

0.1 Verificar quantas maquinas estao conectada na rede:
```bash

curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
  http://172.23.105.82:8545

```

0.2 Verificar detalhes dos nós:

```bash

curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"admin_peers","params":[],"id":1}' \
  http://172.23.105.82:8545 | jq '.result | length'

```

0.3 Verificar os enodes permitidos na rede

```bash

curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"perm_getNodesAllowlist","params":[],"id":1}' \
  http://172.23.105.82:8545

```



# 1. Instalar e configurar a rede na vmazupraplx4002

1.1 cd setup/vmazupraplx4002/setup
1.2 sudo chmod +x install_besu.sh && sudo chmod +x install_service.sh
1.3 sudo ./install_besu.sh
1.4 sudo reboot
---------------------------- x ------------------

Após reiniciar iniciar o serviço:

1.5 sudo systemctl start besu-node

Aguardar 15 segundos

1.6 sudo journalctl -u besu-node -f -n 500


# 2. Instalar e configurar a rede na vmazupraplx8934

2.1 cd setup/vmazupraplx4002/setup
2.2 sudo chmod +x install_besu.sh && sudo chmod +x install_service.sh
2.3 sudo ./install_besu.sh
2.4 sudo reboot
---------------------------- x ------------------

Após reiniciar iniciar o serviço:

2.5 sudo systemctl start besu-node

Aguardar 15 segundos

2.6 sudo journalctl -u besu-node -f -n 500


# 3 Parar toda a rede em todas maquinas

Maquinas ativas:

vmazupraplx7962 => 172.23.105.82 | Bootnode
vmazupraplx9278 => 172.23.105.99 | Bootnode
vmazupraplx9942 => 172.23.105.101
vmazupraplx6452 => 172.23.105.108
vmazupraplx8278 => 172.23.105.107
vmazupraplx4002 => 172.23.105.104
vmazupraplx8934 => 172.25.206.4


3.1 Acessar vmazupraplx7962 e rodar: sudo systemctl stop besu-node
3.2 Acessar vmazupraplx9942 e rodar: sudo systemctl stop besu-node
3.3 Acessar vmazupraplx9278 e rodar: sudo systemctl stop besu-node
3.4 Acessar vmazupraplx6452 e rodar: sudo systemctl stop besu-node
3.5 Acessar vmazupraplx8278 e rodar: sudo systemctl stop besu-node
3.6 Acessar vmazupraplx4002 e rodar: sudo systemctl stop besu-node
3.7 Acessar vmazupraplx8934 e rodar: sudo systemctl stop besu-node

# 4. Iniciar a rede novamente sequencialmente para sincronizar

* É importante rodar o comando sudo systemctl start besu-node sequenciamente o mais rapido possivel para nao atrasar a subida dos nós

4.1 Abrir todas maquinas lado a lado
4.2 colar o comando sudo systemctl start besu-node

Após fazer isso todas vms irão subir no mesmo round.

# 5. Como mudou o ip da vmazupraplx8934 devemos adicionar o enode com ip correto na rede pra ser aprovada a entrar no consenso:

```bash

curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"perm_addNodesToAllowlist","params":[["enode://20f2e99c2450c84a4b281c4bbe58584d6e621d91fa7ae172de3cec44c336596847e73a573fb6e5efdfbdb8e12d4682adf4318f817b6dcd5834e53d41c5a99f67@172.25.206.4:30303"]],"id":1}' \
  http://172.23.105.82:8545

```

# 6. Verificar Peers conectados:

```bash
curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"admin_peers","params":[],"id":1}' \
  http://172.23.105.82:8545 | jq '.result | length'

```

# 7. Ver o log e estado da rede:

7.1 Acessar vmazupraplx7962
7.2 sudo journalctl -u besu-node -f -n 500
