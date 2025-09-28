# Makefile para gerenciar scripts da rede QBFT Hyperledger Besu
# Autor: Sistema de Rede Blockchain
# Data: $(shell date)

# Cores para output
GREEN = \033[0;32m
RED = \033[0;31m
YELLOW = \033[1;33m
BLUE = \033[0;34m
NC = \033[0m

# Diretório dos scripts
SCRIPTS_DIR = scripts

# Verificar se estamos no diretório correto
.PHONY: check-dir
check-dir:
	@if [ ! -f "docker-compose.yml" ]; then \
		echo "$(RED)❌ Erro: Execute este Makefile no diretório network/$(NC)"; \
		exit 1; \
	fi

# =============================================================================
# TARGETS PRINCIPAIS - GERENCIAMENTO DA REDE
# =============================================================================

.PHONY: start
start: check-dir
	@echo "$(BLUE)=== Iniciando Rede QBFT ===$(NC)"
	@chmod +x $(SCRIPTS_DIR)/start_network.sh
	@$(SCRIPTS_DIR)/start_network.sh

.PHONY: stop
stop: check-dir
	@echo "$(BLUE)=== Parando Rede QBFT ===$(NC)"
	@chmod +x $(SCRIPTS_DIR)/stop_network.sh
	@$(SCRIPTS_DIR)/stop_network.sh

.PHONY: restart
restart: stop start
	@echo "$(GREEN)✅ Rede reiniciada com sucesso!$(NC)"

.PHONY: status
status: check-dir
	@echo "$(BLUE)=== Status da Rede QBFT ===$(NC)"
	@chmod +x $(SCRIPTS_DIR)/check_network.sh
	@$(SCRIPTS_DIR)/check_network.sh

# =============================================================================
# TARGETS DE TESTE
# =============================================================================

.PHONY: test
test: check-dir
	@echo "$(BLUE)=== Executando Testes da Rede ===$(NC)"
	@chmod +x $(SCRIPTS_DIR)/test_network.sh
	@$(SCRIPTS_DIR)/test_network.sh

.PHONY: test-quick
test-quick: check-dir
	@echo "$(BLUE)=== Teste Rápido da Rede ===$(NC)"
	@chmod +x $(SCRIPTS_DIR)/quick_test.sh
	@$(SCRIPTS_DIR)/quick_test.sh

.PHONY: test-connectivity
test-connectivity: check-dir
	@echo "$(BLUE)=== Teste de Conectividade ===$(NC)"
	@chmod +x $(SCRIPTS_DIR)/test_connectivity.sh
	@$(SCRIPTS_DIR)/test_connectivity.sh

.PHONY: test-consensus
test-consensus: check-dir
	@echo "$(BLUE)=== Teste de Consenso ===$(NC)"
	@chmod +x $(SCRIPTS_DIR)/test_consensus.sh
	@$(SCRIPTS_DIR)/test_consensus.sh

# =============================================================================
# TARGETS DE REINICIALIZAÇÃO
# =============================================================================

.PHONY: restart-sequence
restart-sequence: check-dir
	@echo "$(BLUE)=== Reinicialização Sequencial ===$(NC)"
	@chmod +x $(SCRIPTS_DIR)/restart_sequence.sh
	@$(SCRIPTS_DIR)/restart_sequence.sh

.PHONY: restart-local
restart-local: check-dir
	@echo "$(BLUE)=== Reinicialização Local ===$(NC)"
	@chmod +x $(SCRIPTS_DIR)/restart_besu_local.sh
	@$(SCRIPTS_DIR)/restart_besu_local.sh

.PHONY: restart-coordinated
restart-coordinated: check-dir
	@echo "$(BLUE)=== Reinicialização Coordenada ===$(NC)"
	@chmod +x $(SCRIPTS_DIR)/restart_coordinated.sh
	@$(SCRIPTS_DIR)/restart_coordinated.sh

.PHONY: restart-production
restart-production: check-dir
	@echo "$(BLUE)=== Reinicialização de Produção ===$(NC)"
	@chmod +x $(SCRIPTS_DIR)/restart_production.sh
	@$(SCRIPTS_DIR)/restart_production.sh

# =============================================================================
# TARGETS DE MANUTENÇÃO
# =============================================================================

.PHONY: clear-peers
clear-peers: check-dir
	@echo "$(BLUE)=== Limpando Peers ===$(NC)"
	@chmod +x $(SCRIPTS_DIR)/clear_peers.sh
	@$(SCRIPTS_DIR)/clear_peers.sh

.PHONY: fix-quorum
fix-quorum: check-dir
	@echo "$(BLUE)=== Corrigindo Quorum Avançado ===$(NC)"
	@chmod +x $(SCRIPTS_DIR)/fix_quorum_advanced.sh
	@$(SCRIPTS_DIR)/fix_quorum_advanced.sh

# =============================================================================
# TARGETS DE DESENVOLVIMENTO E DEBUG
# =============================================================================

.PHONY: logs
logs: check-dir
	@echo "$(BLUE)=== Logs da Rede ===$(NC)"
	@docker-compose logs -f

.PHONY: logs-tail
logs-tail: check-dir
	@echo "$(BLUE)=== Últimos Logs ===$(NC)"
	@docker-compose logs --tail=50

.PHONY: ps
ps: check-dir
	@echo "$(BLUE)=== Status dos Containers ===$(NC)"
	@docker-compose ps

.PHONY: shell
shell: check-dir
	@echo "$(BLUE)=== Acessando Shell do Container ===$(NC)"
	@echo "Containers disponíveis:"
	@docker-compose ps --format "table {{.Name}}\t{{.Status}}"
	@echo ""
	@read -p "Digite o nome do container: " container; \
	docker-compose exec $$container bash

# =============================================================================
# TARGETS DE LIMPEZA
# =============================================================================

.PHONY: clean
clean: stop
	@echo "$(BLUE)=== Limpeza Completa ===$(NC)"
	@docker-compose down -v
	@docker-compose rm -f
	@docker system prune -f
	@echo "$(GREEN)✅ Limpeza concluída!$(NC)"

.PHONY: clean-volumes
clean-volumes: stop
	@echo "$(BLUE)=== Limpando Volumes ===$(NC)"
	@docker-compose down -v
	@echo "$(GREEN)✅ Volumes removidos!$(NC)"

.PHONY: clean-images
clean-images: stop
	@echo "$(BLUE)=== Limpando Imagens ===$(NC)"
	@docker-compose down
	@docker rmi $$(docker images -q) 2>/dev/null || true
	@echo "$(GREEN)✅ Imagens removidas!$(NC)"

# =============================================================================
# TARGETS DE INFORMAÇÃO E AJUDA
# =============================================================================

.PHONY: info
info: check-dir
	@echo "$(BLUE)=== Informações da Rede QBFT ===$(NC)"
	@echo ""
	@echo "$(YELLOW)Bootnodes:$(NC)"
	@echo "  - vmazupraplx7962: 172.23.105.82:30303"
	@echo "  - vmazupraplx9278: 172.23.105.99:30303"
	@echo "  - vmazuprapix4156: 172.23.105.105:30303"
	@echo ""
	@echo "$(YELLOW)Validadores:$(NC)"
	@echo "  - vmazupraplx2694: 172.23.105.98:30303"
	@echo "  - vmazupraplx9942: 172.23.105.101:30303"
	@echo "  - vmazupraplx4002: 172.23.105.104:30303"
	@echo "  - vmazupraplx8934: 172.25.206.4:30303"
	@echo "  - vmazupraplx6452: 172.23.105.108:30303"
	@echo "  - vmazupraplx8278: 172.23.105.107:30303"
	@echo ""
	@echo "$(YELLOW)RPC Endpoints:$(NC)"
	@echo "  - Bootnode 1: http://localhost:8545"
	@echo "  - Validador 1: http://localhost:8546"
	@echo "  - Validador 2: http://localhost:8547"
	@echo "  - Bootnode 2: http://localhost:8548"
	@echo "  - Validador 3: http://localhost:8549"
	@echo "  - Validador 4: http://localhost:8550"
	@echo "  - Bootnode 3: http://localhost:8551"
	@echo "  - Validador 5: http://localhost:8552"
	@echo "  - Validador 6: http://localhost:8553"

.PHONY: help
help:
	@echo "$(BLUE)=== Makefile - Rede QBFT Hyperledger Besu ===$(NC)"
	@echo ""
	@echo "$(YELLOW)GERENCIAMENTO DA REDE:$(NC)"
	@echo "  make start              - Iniciar a rede QBFT"
	@echo "  make stop               - Parar a rede QBFT"
	@echo "  make restart            - Reiniciar a rede QBFT"
	@echo "  make status             - Verificar status da rede"
	@echo ""
	@echo "$(YELLOW)TESTES:$(NC)"
	@echo "  make test               - Executar testes completos da rede"
	@echo "  make test-quick         - Teste rápido de conectividade"
	@echo "  make test-connectivity  - Teste detalhado de conectividade"
	@echo "  make test-consensus     - Teste de consenso QBFT"
	@echo ""
	@echo "$(YELLOW)REINICIALIZAÇÃO:$(NC)"
	@echo "  make restart-sequence   - Reinicialização sequencial coordenada"
	@echo "  make restart-local      - Reinicialização local do Besu"
	@echo "  make restart-coordinated - Reinicialização coordenada"
	@echo "  make restart-production  - Reinicialização de produção"
	@echo ""
	@echo "$(YELLOW)MANUTENÇÃO:$(NC)"
	@echo "  make clear-peers        - Limpar peers da rede"
	@echo "  make fix-quorum         - Corrigir problemas de quorum"
	@echo ""
	@echo "$(YELLOW)DESENVOLVIMENTO E DEBUG:$(NC)"
	@echo "  make logs               - Ver logs em tempo real"
	@echo "  make logs-tail          - Ver últimos 50 logs"
	@echo "  make ps                 - Status dos containers"
	@echo "  make shell              - Acessar shell de um container"
	@echo ""
	@echo "$(YELLOW)LIMPEZA:$(NC)"
	@echo "  make clean              - Limpeza completa (containers + volumes + imagens)"
	@echo "  make clean-volumes      - Limpar apenas volumes"
	@echo "  make clean-images       - Limpar apenas imagens"
	@echo ""
	@echo "$(YELLOW)INFORMAÇÕES:$(NC)"
	@echo "  make info               - Mostrar informações da rede"
	@echo "  make help               - Mostrar esta ajuda"
	@echo ""
	@echo "$(GREEN)Exemplo de uso: make start && make test-quick$(NC)"

# =============================================================================
# TARGETS DE VERIFICAÇÃO E DEPENDÊNCIAS
# =============================================================================

.PHONY: check-deps
check-deps: check-dir
	@echo "$(BLUE)=== Verificando Dependências ===$(NC)"
	@echo -n "Docker: "
	@if command -v docker > /dev/null 2>&1; then \
		echo "$(GREEN)✅ Instalado$(NC)"; \
	else \
		echo "$(RED)❌ Não instalado$(NC)"; \
		exit 1; \
	fi
	@echo -n "Docker Compose: "
	@if command -v docker-compose > /dev/null 2>&1; then \
		echo "$(GREEN)✅ Instalado$(NC)"; \
	else \
		echo "$(RED)❌ Não instalado$(NC)"; \
		exit 1; \
	fi
	@echo -n "Curl: "
	@if command -v curl > /dev/null 2>&1; then \
		echo "$(GREEN)✅ Instalado$(NC)"; \
	else \
		echo "$(RED)❌ Não instalado$(NC)"; \
		exit 1; \
	fi
	@echo -n "JQ: "
	@if command -v jq > /dev/null 2>&1; then \
		echo "$(GREEN)✅ Instalado$(NC)"; \
	else \
		echo "$(YELLOW)⚠️  Não instalado (recomendado para formatação JSON)$(NC)"; \
	fi
	@echo "$(GREEN)✅ Verificação de dependências concluída!$(NC)"

.PHONY: install-deps
install-deps: check-dir
	@echo "$(BLUE)=== Instalando Dependências ===$(NC)"
	@if command -v apt-get > /dev/null 2>&1; then \
		sudo apt-get update && sudo apt-get install -y docker.io docker-compose curl jq; \
	elif command -v yum > /dev/null 2>&1; then \
		sudo yum install -y docker docker-compose curl jq; \
	else \
		echo "$(RED)❌ Sistema não suportado para instalação automática$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)✅ Dependências instaladas!$(NC)"

# =============================================================================
# TARGET PADRÃO
# =============================================================================

.DEFAULT_GOAL := help
