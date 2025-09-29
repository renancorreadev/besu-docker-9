# Mapeamento da Rede Hyperledger Besu QBFT

## Tabela de Mapeamento Completo

| IP | Porta | Endereço do Validador | Container | Tipo | P2P Port |
|----|----|----------------------|-----------|------|----------|
| 172.23.105.82 | 8545 | 0x8e139ab53a6932ce45b4b2fa6fa407538e462e40 | vmazupraplx7962 | Bootnode 1 | 30303 |
| 172.23.105.98 | 8546 | 0xc4d69c8124f988616e4ac98d65188cef2ef2691c | vmazupraplx2694 | Validator 1 | 30304 |
| 172.23.105.101 | 8547 | 0xc10b1d45b7c11243d3e2f4f3724d562cc6371fc3 | vmazupraplx9942 | Validator 2 | 30305 |
| 172.23.105.99 | 8548 | 0x41282fba4661fc10caf98786a97eccbf57f7cadf | vmazupraplx9278 | Bootnode 2 | 30306 |
| 172.23.105.104 | 8549 | 0xc05317faf1145ded0a541b116fc367010e4c4e5c | vmazupraplx4002 | Validator 1 Z2 | 30307 |
| 172.23.105.110 | 8550 | 0xd4a8e7709a8c803004a607897ca5746f9de2b0f5 | vmazupraplx8934 | Validator 2 Z2 | 30308 |
| 172.23.105.105 | 8551 | 0x6320302dab568bec84d1f5f37f6e919e67ca4b81 | vmazuprapix4156 | Bootnode 3 | 30309 |
| 172.23.105.108 | 8552 | 0xd59a4dc7ff716c8c62508be4eef368984ac745a8 | vmazupraplx6452 | Validator 1 Z3 | 30310 |
| 172.23.105.107 | 8553 | 0xda9ea51aafcf8d04a5f6fc143781c9962ddc5199 | vmazupraplx8278 | Validator 2 Z3 | 30311 |

## Resumo da Rede

- **Total de Nodos**: 9
- **Bootnodes**: 3 (que também funcionam como validadores)
- **Validadores Dedicados**: 6
- **Total de Validadores Ativos**: 9
- **Subnet**: 172.23.105.0/24
- **Gateway**: 172.23.105.1

## Classificação por Tipo

### Bootnodes (3)
| Container | IP | Porta RPC | Endereço |
|-----------|----|----|----------|
| vmazupraplx7962 | 172.23.105.82 | 8545 | 0x8e139ab53a6932ce45b4b2fa6fa407538e462e40 |
| vmazupraplx9278 | 172.23.105.99 | 8548 | 0x41282fba4661fc10caf98786a97eccbf57f7cadf |
| vmazuprapix4156 | 172.23.105.105 | 8551 | 0x6320302dab568bec84d1f5f37f6e919e67ca4b81 |

### Validadores Zona 1 (2)
| Container | IP | Porta RPC | Endereço |
|-----------|----|----|----------|
| vmazupraplx2694 | 172.23.105.98 | 8546 | 0xc4d69c8124f988616e4ac98d65188cef2ef2691c |
| vmazupraplx9942 | 172.23.105.101 | 8547 | 0xc10b1d45b7c11243d3e2f4f3724d562cc6371fc3 |

### Validadores Zona 2 (2)
| Container | IP | Porta RPC | Endereço |
|-----------|----|----|----------|
| vmazupraplx4002 | 172.23.105.104 | 8549 | 0xc05317faf1145ded0a541b116fc367010e4c4e5c |
| vmazupraplx8934 | 172.23.105.110 | 8550 | 0xd4a8e7709a8c803004a607897ca5746f9de2b0f5 |

### Validadores Zona 3 (2)
| Container | IP | Porta RPC | Endereço |
|-----------|----|----|----------|
| vmazupraplx6452 | 172.23.105.108 | 8552 | 0xd59a4dc7ff716c8c62508be4eef368984ac745a8 |
| vmazupraplx8278 | 172.23.105.107 | 8553 | 0xda9ea51aafcf8d04a5f6fc143781c9962ddc5199 |

## Comandos de Exemplo

### Conectar por IP específico
```bash
# Conectar ao Bootnode 1
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
  http://172.23.105.82:8545

# Conectar ao Validator 1
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
  http://172.23.105.98:8545
```

### Remover validador específico
```bash
# Remover vmazupraplx2694 (Validator 1)
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"qbft_proposeValidatorVote","params":["0xc4d69c8124f988616e4ac98d65188cef2ef2691c",false],"id":1}' \
  http://172.23.105.82:8545
```

### Adicionar novo validador
```bash
# Propor novo validador via Bootnode 1
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"qbft_proposeValidatorVote","params":["NOVO_ENDEREÇO_AQUI",true],"id":1}' \
  http://172.23.105.82:8545
```

## Observações

- Todos os bootnodes também funcionam como validadores na rede
- A rede usa consenso QBFT com 9 validadores ativos
- Para aprovação de propostas, é necessária maioria simples (5 de 9 votos)
- Cada zona tem 2-3 nodos para alta disponibilidade