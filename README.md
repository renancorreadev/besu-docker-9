# Rede QBFT Hyperledger Besu - Docker Compose

Este projeto configura uma rede blockchain QBFT (QBFT Consensus) usando Hyperledger Besu com 9 nós distribuídos em containers Docker.

## Arquitetura da Rede

### Bootnodes (3 nós)
- **vmazupraplx7962**: 172.23.105.82:30303
- **vmazupraplx9278**: 172.23.105.99:30303
- **vmazuprapix4156**: 172.23.105.105:30303

### Validadores (6 nós)
- **vmazupraplx2694**: 172.23.105.98:30303
- **vmazupraplx9942**: 172.23.105.101:30303
- **vmazupraplx4002**: 172.23.105.104:30303
- **vmazupraplx8934**: 172.23.105.110:30303
- **vmazupraplx6452**: 172.23.105.108:30303
- **vmazupraplx8278**: 172.23.105.107:30303

## Configuração da Rede

- **Chain ID**: 381660001
- **Consenso**: QBFT
- **Período de Bloco**: 3 segundos
- **Epoch Length**: 30000 blocos
- **Request Timeout**: 6 segundos
- **Storage Format**: FOREST
- **Sync Mode**: FULL

## RPC Endpoints

Cada nó expõe um endpoint RPC HTTP na porta 8545:

- Bootnode 1: http://localhost:8545
- Validador 1: http://localhost:8546
- Validador 2: http://localhost:8547
- Bootnode 2: http://localhost:8548
- Validador 3: http://localhost:8549
- Validador 4: http://localhost:8550
- Bootnode 3: http://localhost:8551
- Validador 5: http://localhost:8552
- Validador 6: http://localhost:8553

## Scripts de Gerenciamento

### Iniciar a Rede
```bash
./start_network.sh
```

### Parar a Rede
```bash
./stop_network.sh
```

### Verificar Status
```bash
./check_network.sh
```

### Comandos Docker Compose Diretos

#### Iniciar todos os serviços
```bash
docker-compose up -d
```

#### Parar todos os serviços
```bash
docker-compose down
```

#### Ver logs em tempo real
```bash
docker-compose logs -f
```

#### Ver logs de um container específico
```bash
docker-compose logs -f vmazupraplx7962
```

#### Acessar um container
```bash
docker-compose exec vmazupraplx7962 bash
```

## Estrutura de Arquivos

```
network/
├── docker-compose.yml          # Configuração principal do Docker Compose
├── start_network.sh            # Script para iniciar a rede
├── stop_network.sh             # Script para parar a rede
├── check_network.sh            # Script para verificar status
├── README.md                   # Este arquivo
└── setup/                      # Configurações de cada VM
    ├── vmazupraplx7962/        # Bootnode 1
    │   ├── Dockerfile
    │   ├── config/
    │   │   ├── genesis.json
    │   │   └── data/
    │   │       ├── key
    │   │       ├── key.pub
    │   │       └── permissions_config.toml
    │   └── run/
    │       └── start_node.sh
    ├── vmazupraplx2694/        # Validador 1
    ├── vmazupraplx9942/        # Validador 2
    ├── vmazupraplx9278/        # Bootnode 2
    ├── vmazupraplx4002/        # Validador 3
    ├── vmazupraplx8934/        # Validador 4
    ├── vmazuprapix4156/        # Bootnode 3
    ├── vmazupraplx6452/        # Validador 5
    └── vmazupraplx8278/        # Validador 6
```

## Pré-requisitos

- Docker
- Docker Compose
- Linux/macOS (testado em Linux)

## Configurações de Segurança

A rede está configurada com:
- Lista de permissões de nós (nodes-allowlist)
- Lista de permissões de contas (accounts-allowlist)
- Chaves privadas configuradas para cada nó
- Configurações de permissões em TOML

## Monitoramento

### Verificar Conectividade P2P
```bash
# Verificar peers conectados
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"admin_peers","params":[],"id":1}' \
  http://localhost:8545
```

### Verificar Status da Rede
```bash
# Verificar informações da rede
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
  http://localhost:8545
```

### Verificar Blocos
```bash
# Verificar último bloco
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  http://localhost:8545
```

## Troubleshooting

### Container não inicia
1. Verificar logs: `docker-compose logs <container_name>`
2. Verificar se as portas estão disponíveis
3. Verificar se os arquivos de configuração existem

### Problemas de conectividade
1. Verificar se todos os containers estão rodando
2. Verificar configurações de rede no docker-compose.yml
3. Verificar se os IPs estão corretos nos arquivos de configuração

### Problemas de permissões
1. Verificar se os arquivos key e key.pub existem
2. Verificar se o permissions_config.toml está correto
3. Verificar permissões dos arquivos no container

## Suporte

Para problemas ou dúvidas, verifique:
1. Logs dos containers
2. Configurações de rede
3. Arquivos de permissões
4. Conectividade entre containers
