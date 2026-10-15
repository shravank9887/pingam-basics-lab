ARG JRE_IMAGE=eclipse-temurin:21.0.8_9-jre-jammy
FROM ${JRE_IMAGE}
ARG DS_VERSION

LABEL description="PingDS 8 for PingAM Basics lab (single AM profile per container)"
LABEL version="${DS_VERSION}"

ENV PINGDS_HOME=/opt/opendj \
    PINGDS_INSTANCE=/opt/opendj \
    JAVA_HOME=/opt/java/openjdk \
    PATH="${PATH}:/opt/opendj/bin" \
    DEBIAN_FRONTEND=noninteractive \
    OPENDJ_JAVA_ARGS="-server -Xmx512m -XX:+UseG1GC -XX:MaxGCPauseMillis=200"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl wget unzip openssl ca-certificates \
        dnsutils iputils-ping netcat-openbsd \
        procps ldap-utils gosu && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p ${PINGDS_HOME} /opt/pingds-data /opt/certs /opt/scripts /opt/backups /opt/logs

WORKDIR /opt

ARG DS_VERSION
COPY artifacts/DS-${DS_VERSION}.zip /tmp/

RUN cd /tmp && \
    unzip -q DS-*.zip -d /tmp/pingds && \
    if [ ! -d "/tmp/pingds/opendj" ]; then \
        echo "ERROR: PingDS extraction failed - opendj directory not found"; \
        exit 1; \
    fi && \
    mv /tmp/pingds/opendj/* ${PINGDS_HOME}/ && \
    if [ ! -f "${PINGDS_HOME}/setup" ]; then \
        echo "ERROR: PingDS setup file not found"; \
        exit 1; \
    fi && \
    chmod -R +x ${PINGDS_HOME}/bin && \
    chmod +x ${PINGDS_HOME}/setup && \
    rm -rf /tmp/DS-*.zip /tmp/pingds

COPY pingds/scripts/*.sh /opt/scripts/
RUN chmod +x /opt/scripts/*.sh

RUN groupadd -r pingds -g 1000 && \
    useradd -r -u 1000 -g pingds -d ${PINGDS_HOME} -s /bin/bash -c "PingDS Service Account" pingds

RUN chown -R pingds:pingds ${PINGDS_HOME} \
                            /opt/pingds-data \
                            /opt/certs \
                            /opt/backups \
                            /opt/scripts \
                            /opt/logs

EXPOSE 1389 1636 4444 8080 8443

# Default healthcheck; compose overrides per service (truststore only for ds-config).
HEALTHCHECK --interval=10s --timeout=10s --start-period=90s --retries=30 \
    CMD nc -z localhost 1389 || exit 1

VOLUME ["/opt/pingds-data", "/opt/certs", "/opt/backups", "/opt/logs"]

USER root
ENTRYPOINT ["/opt/scripts/docker-entrypoint.sh"]
CMD ["start-server"]
