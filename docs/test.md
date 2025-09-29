| IP  | Endereço do Validador | Container | Tipo | P2P Port |
|----|----|----------------------|-----------|------|----------|
| 172.23.105.82   | 0x8e139ab53a6932ce45b4b2fa6fa407538e462e40 | vmazupraplx7962 | Bootnode 1 | 30303 |
| 172.23.105.98   | 0xc4d69c8124f988616e4ac98d65188cef2ef2691c | vmazupraplx2694 | Validator 1 | 30304 |
| 172.23.105.101  | 0xc10b1d45b7c11243d3e2f4f3724d562cc6371fc3 | vmazupraplx9942 | Validator 2 | 30305 |
| 172.23.105.99   | 0x41282fba4661fc10caf98786a97eccbf57f7cadf | vmazupraplx9278 | Bootnode 2 | 30306 |
| 172.23.105.104  | 0xc05317faf1145ded0a541b116fc367010e4c4e5c | vmazupraplx4002 | Validator 1 Z2 | 30307 |
| 172.23.105.110  | 0xd4a8e7709a8c803004a607897ca5746f9de2b0f5 | vmazupraplx8934 | Validator 2 Z2 | 30308 |
| 172.23.105.105  | 0x6320302dab568bec84d1f5f37f6e919e67ca4b81 | vmazuprapix4156 | Bootnode 3 | 30309 |
| 172.23.105.108  | 0xd59a4dc7ff716c8c62508be4eef368984ac745a8 | vmazupraplx6452 | Validator 1 Z3 | 30310 |
| 172.23.105.107  | 0xda9ea51aafcf8d04a5f6fc143781c9962ddc5199 | vmazupraplx8278 | Validator 2 Z3 | 30311 |

Configurar hoje:
vmazupraplx4002 => 172.23.105.104  Mudou Nome
vmazupraplx8934 => 172.25.206.4    Mudou Nome e IP
 
Ja configuradas:
vmazupraplx7962 => 172.23.105.82  8545
vmazupraplx9942 => 172.23.105.101 8547
vmazupraplx9278 => 172.23.105.99  8548
vmazupraplx6452 => 172.23.105.108 8552
vmazupraplx8278 => 172.23.105.107 8553


DERRUBAR
| 172.23.105.104  | 0xc05317faf1145ded0a541b116fc367010e4c4e5c | vmazupraplx4002 | 
| 172.23.105.110  | 0xd4a8e7709a8c803004a607897ca5746f9de2b0f5 | vmazupraplx8934 | 
| 172.23.105.105  | 0x6320302dab568bec84d1f5f37f6e919e67ca4b81 | vmazuprapix4156 | 

CONF
| 172.23.105.104  | 0xc05317faf1145ded0a541b116fc367010e4c4e5c | vmazupraplx4002 | Validator 1 Z2 | 30307 |
| 172.23.105.120  | 0xd4a8e7709a8c803004a607897ca5746f9de2b0f5 | vmazupraplx8934 | Validator 2 Z2 | 30308 |


curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"perm_addNodesToAllowlist","params":[["enode://20f2e99c2450c84a4b281c4bbe58584d6e621d91fa7ae172de3cec44c336596847e73a573fb6e5efdfbdb8e12d4682adf4318f817b6dcd5834e53d41c5a99f67@172.23.105.120:30303"]],"id":1}' \
  http://172.23.105.82:8545

