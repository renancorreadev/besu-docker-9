# Dockerfile para Hyperledger Besu QBFT Network
FROM hyperledger/besu:24.9.1

# Criar diretórios necessários como root
USER root
RUN mkdir -p /var/lib/besu/tmp \
    && mkdir -p /opt/besu/config/data \
    && chown -R besu:besu /var/lib/besu \
    && chown -R besu:besu /opt/besu/config \
    && chmod -R 777 /var/lib/besu \
    && chmod -R 777 /opt/besu/config

# Configurar JAVA_OPTS para RocksDB
ENV JAVA_OPTS="-Djava.io.tmpdir=/var/lib/besu/tmp -Djna.tmpdir=/var/lib/besu/tmp -Dorg.rocksdb.tmpdir=/var/lib/besu/tmp -Djava.library.tmpdir=/var/lib/besu/tmp -Drocksdb.native.library.path=/var/lib/besu/tmp -Djava.library.path=/var/lib/besu/tmp -XX:+UseG1GC -Djava.util.logging.manager=org.apache.logging.log4j.jul.LogManager"

# Copiar arquivos de configuração
COPY config/ /opt/besu/config/
COPY run/ /opt/besu/run/

# Configurar permissões dos scripts
RUN chmod +x /opt/besu/run/*.sh

# Mudar para usuário besu
USER besu

# Expor portas
EXPOSE 8545 30303

# Comando padrão
CMD ["/opt/besu/run/start_node.sh"]
