# 🔗 Gerenciamento da Rede Hyperledger Besu QBFT

Este README contém todos os comandos curl necessários para gerenciar sua rede blockchain Hyperledger Besu com consenso QBFT.

## 📋 Índice

- [1. Visualizar Peers Conectados](#1-visualizar-peers-conectados)
- [2. Visualizar Nodos/Máquinas](#2-visualizar-nodosmáquinas)
- [3. Visualizar Validadores](#3-visualizar-validadores)
- [4. Remover Validador](#4-remover-validador)
- [5. Adicionar Validador](#5-adicionar-validador)
- [6. Gerenciar Permissions de Enodes](#6-gerenciar-permissions-de-enodes)
- [7. Comandos Adicionais Úteis](#7-comandos-adicionais-úteis)
- [8. Exemplos Práticos](#8-exemplos-práticos)

---

## 🌐 Configuração Base

**Endpoints disponíveis em sua rede:**
- `http://localhost:8545` - vmazupraplx7962 (Bootnode 1)
- `http://localhost:8546` - vmazupraplx2694 (Validator 1)
- `http://localhost:8547` - vmazupraplx9942 (Validator 2)
- `http://localhost:8548` - vmazupraplx9278 (Bootnode 2)
- `http://localhost:8549` - vmazupraplx4002 (Validator 1 Z2)
- `http://localhost:8550` - vmazupraplx8934 (Validator 2 Z2)
- `http://localhost:8551` - vmazuprapix4156 (Bootnode 3)
- `http://localhost:8552` - vmazupraplx6452 (Validator 1 Z3)
- `http://localhost:8553` - vmazupraplx8278 (Validator 2 Z3)

---

## 1. 📊 Visualizar Peers Conectados

### Contar número de peers conectados
```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
  http://localhost:8545
```

### Listar todos os peers detalhadamente
```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"admin_peers","params":[],"id":1}' \
  http://localhost:8545
```

### Ver informações do nodo atual
```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"admin_nodeInfo","params":[],"id":1}' \
  http://localhost:8545
```

### Formatação JSON com jq (opcional)
```bash
curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"admin_peers","params":[],"id":1}' \
  http://localhost:8545 | jq '.result | length'
```

---

## 2. 🖥️ Visualizar Nodos/Máquinas

### Ver nodos conectados (contagem)
```bash
curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"admin_peers","params":[],"id":1}' \
  http://localhost:8545 | jq '.result | length'
```

### Listar enodes na allowlist
```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"perm_getNodesAllowlist","params":[],"id":1}' \
  http://localhost:8545
```

### Ver detalhes dos peers conectados
```bash
curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"admin_peers","params":[],"id":1}' \
  http://localhost:8545 | jq '.result[] | {enode: .enode, name: .name, remoteAddress: .network.remoteAddress}'
```

---

## 3. ✅ Visualizar Validadores

### Listar todos os validadores ativos
```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"qbft_getValidatorsByBlockNumber","params":["latest"],"id":1}' \
  http://localhost:8545
```

### Ver validadores em um bloco específico
```bash
# Exemplo para bloco 100 (0x64 em hexadecimal)
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"qbft_getValidatorsByBlockNumber","params":["0x64"],"id":1}' \
  http://localhost:8545
```

### Ver métricas dos signatários
```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"qbft_getSignerMetrics","params":["latest"],"id":1}' \
  http://localhost:8545
```

### Contar número de validadores
```bash
curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"qbft_getValidatorsByBlockNumber","params":["latest"],"id":1}' \
  http://localhost:8545 | jq '.result | length'
```

---

## 4. ❌ Remover Validador

### Propor remoção de validador
```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"qbft_proposeValidatorVote","params":["ENDEREÇO_DO_VALIDADOR",false],"id":1}' \
  http://localhost:8545
```

**⚠️ Substitua `ENDEREÇO_DO_VALIDADOR` pelo endereço real (formato: 0x...)**

### Verificar propostas pendentes
```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"qbft_getPendingVotes","params":[],"id":1}' \
  http://localhost:8545
```

### Descartar uma proposta
```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"qbft_discardValidatorVote","params":["ENDEREÇO_DO_VALIDADOR"],"id":1}' \
  http://localhost:8545
```

---

## 5. ➕ Adicionar Validador

### Propor adição de validador
```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"qbft_proposeValidatorVote","params":["ENDEREÇO_DO_NOVO_VALIDADOR",true],"id":1}' \
  http://localhost:8545
```

**⚠️ Substitua `ENDEREÇO_DO_NOVO_VALIDADOR` pelo endereço real (formato: 0x...)**

### Verificar se a proposta foi aceita
```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"qbft_getValidatorsByBlockNumber","params":["latest"],"id":1}' \
  http://localhost:8545
```

---

## 6. 🔐 Gerenciar Permissions de Enodes

### Adicionar enode à allowlist
```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"perm_addNodesToAllowlist","params":[["enode://ENODE_COMPLETO"]],"id":1}' \
  http://localhost:8545
```

**📝 Formato do enode: `enode://pubkey@ip:port`**

### Remover enode da allowlist
```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"perm_removeNodesFromAllowlist","params":[["enode://ENODE_COMPLETO"]],"id":1}' \
  http://localhost:8545
```

### Ver todos os enodes permitidos
```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"perm_getNodesAllowlist","params":[],"id":1}' \
  http://localhost:8545
```

### Recarregar permissions do arquivo
```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"perm_reloadPermissionsFromFile","params":[],"id":1}' \
  http://localhost:8545
```

---

## 7. 🛠️ Comandos Adicionais Úteis

### Ver número do bloco atual
```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  http://localhost:8545
```

### Ver detalhes do último bloco
```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest",true],"id":1}' \
  http://localhost:8545
```

### Ver status de sincronização
```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
  http://localhost:8545
```

### Ver versão do cliente Besu
```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"web3_clientVersion","params":[],"id":1}' \
  http://localhost:8545
```

### Ver ID da rede
```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"net_version","params":[],"id":1}' \
  http://localhost:8545
```

### Ver se o nodo está minerando/validando
```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_mining","params":[],"id":1}' \
  http://localhost:8545
```

---

## 8. 📋 Exemplos Práticos

### Exemplo: Adicionar validador específico
```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"qbft_proposeValidatorVote","params":["0x1234567890123456789012345678901234567890",true],"id":1}' \
  http://localhost:8545
```

### Exemplo: Adicionar enode específico
```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"perm_addNodesToAllowlist","params":[["enode://93677b2fd0864ea2af0d514fa323f7e51f9d3126cab42c9c4c624f10174bcf6b2df731a63b0d22cf560d0ca8511faaf9245b7972483c109c6b86afa36c765657@192.168.1.100:30303"]],"id":1}' \
  http://localhost:8545
```

### Exemplo: Monitoramento completo
```bash
# Script para monitoramento completo
echo "=== Status da Rede ==="
echo "Peers conectados:"
curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
  http://localhost:8545 | jq '.result'

echo "Validadores ativos:"
curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"qbft_getValidatorsByBlockNumber","params":["latest"],"id":1}' \
  http://localhost:8545 | jq '.result | length'

echo "Bloco atual:"
curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  http://localhost:8545 | jq '.result'
```

---

## 📌 Notas Importantes

### 🔍 **Descobrir Endereços dos Validadores**

Para obter os endereços dos validadores atuais:
```bash
curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"qbft_getValidatorsByBlockNumber","params":["latest"],"id":1}' \
  http://localhost:8545 | jq '.result[]'
```

### 🔍 **Descobrir Enodes dos Peers**

Para obter os enodes dos peers conectados:
```bash
curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"admin_peers","params":[],"id":1}' \
  http://localhost:8545 | jq '.result[].enode'
```

### ⚠️ **Requisitos para Votação**

- **Maioria simples**: Para adicionar/remover validadores, é necessário que mais de 50% dos validadores atuais votem a favor
- **Múltiplos nodos**: Execute o comando de votação em diferentes nodos para acelerar o processo
- **Monitoramento**: Use `qbft_getPendingVotes` para acompanhar o status das votações

### 🔄 **Endpoints Alternativos**

Se um endpoint não responder, teste com outros nodos:
```bash
# Teste em diferentes portas
for port in 8545 8546 8547 8548 8549 8550 8551 8552 8553; do
  echo "Testando porta $port..."
  curl -s -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
    http://localhost:$port | jq '.result'
done
```

### 📚 **Documentação Oficial**

- [Hyperledger Besu JSON-RPC API](https://besu.hyperledger.org/en/stable/Reference/API-Methods/)
- [QBFT Consensus](https://besu.hyperledger.org/en/stable/HowTo/Configure/Consensus/QBFT/)
- [Node Permissions](https://besu.hyperledger.org/en/stable/HowTo/Limit-Access/Specify-Perm-Nodes/)

---

## 🚀 Scripts de Automação

### Script para Status Completo
```bash
#!/bin/bash
# status_rede.sh

echo "=== STATUS COMPLETO DA REDE BESU ==="
echo "Data: $(date)"
echo ""

# Peers
peers=$(curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
  http://localhost:8545 | jq -r '.result')
echo "🔗 Peers conectados: $((16#${peers#0x}))"

# Validadores
validators=$(curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"qbft_getValidatorsByBlockNumber","params":["latest"],"id":1}' \
  http://localhost:8545 | jq '.result | length')
echo "✅ Validadores ativos: $validators"

# Bloco atual
block=$(curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  http://localhost:8545 | jq -r '.result')
echo "📦 Bloco atual: $((16#${block#0x}))"

# Versão
version=$(curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"web3_clientVersion","params":[],"id":1}' \
  http://localhost:8545 | jq -r '.result')
echo "🔧 Versão: $version"
```

---

