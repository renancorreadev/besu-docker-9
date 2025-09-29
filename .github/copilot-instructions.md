# Copilot Instructions for This Codebase

## Project Overview
- **Purpose:** Deploys a 9-node Hyperledger Besu blockchain network (QBFT consensus) using Docker Compose.
- **Node Types:** 3 Bootnodes, 6 Validators. Each node is a separate container with its own config, keys, and permissions.
- **Key Files:**
  - `docker-compose.yml`: Main orchestration file for all nodes and network settings.
  - `setup/<node>/config/`: Contains `genesis.json`, keys, and `permissions_config.toml` for each node.
  - `setup/<node>/run/start_node.sh`: Entrypoint script for each node container.
  - `scripts/`: Utility scripts for network management and diagnostics.

## Architecture & Data Flow
- **Network:** All nodes are on a custom Docker bridge network (`besu_network`) with static IPs.
- **Consensus:** QBFT, with block period, epoch, and timeouts set in `genesis.json` and node configs.
- **Permissions:** Node and account allowlists enforced via TOML files per node.
- **RPC:** Each node exposes HTTP RPC on a unique host port (see `docker-compose.yml` and README).

## Developer Workflows
- **Start Network:** `./start_network.sh` or `docker-compose up -d`
- **Stop Network:** `./stop_network.sh` or `docker-compose down`
- **Check Status:** `./check_network.sh` or `docker-compose ps`
- **Logs:** `docker-compose logs -f [container]`
- **Access Container:** `docker-compose exec [container] bash`
- **Test Connectivity:** Use scripts like `test_connectivity.sh` or JSON-RPC curl commands (see README).

## Project-Specific Conventions
- **Node Naming:** All nodes use the `vmazupra*` prefix; match config, container, and hostname.
- **Static IPs:** All nodes have fixed IPs in `docker-compose.yml` and config files. Keep these in sync.
- **Entrypoint:** All containers start with `start_node.sh` in their respective `run/` directories.
- **Permissions:** Always update `permissions_config.toml` and key files when adding/removing nodes.
- **Scripts:** Use scripts in `scripts/` for common admin tasks; avoid manual Docker commands when possible.

## Integration & Extensibility
- **Adding Nodes:** Duplicate a node directory in `setup/`, update keys/configs, and add a service in `docker-compose.yml`.
- **External Access:** Expose RPC ports as needed; restrict with firewall or Docker network settings for security.
- **Monitoring:** Use provided curl commands or scripts to check peer count, block height, and connectivity.

## Troubleshooting
- **Logs:** Always check container logs first.
- **Config Sync:** Ensure all config files and static IPs are consistent across `docker-compose.yml` and node configs.
- **Permissions:** Validate key files and TOML permissions for each node.

## References
- See `README.md` for architecture, workflow, and troubleshooting details.
- Example: To add a validator, copy an existing validator setup, generate new keys, update configs, and register in `docker-compose.yml`.
