# syntax=docker/dockerfile:1
# PingAM on Tomcat. Build context = repository root.
# Needs: artifacts/AM-${AM_VERSION}.war

ARG TOMCAT_IMAGE=tomcat:10.1.49-jdk21-temurin-jammy

FROM ${TOMCAT_IMAGE} AS war
ARG AM_VERSION
COPY artifacts/AM-${AM_VERSION}.war /tmp/am.war
RUN mkdir -p /am && cd /am && jar -xf /tmp/am.war && rm /tmp/am.war

FROM ${TOMCAT_IMAGE}
ARG AM_VERSION
LABEL org.opencontainers.image.title="pingam-basics-lab" \
      org.opencontainers.image.version="${AM_VERSION}"

ENV CATALINA_HOME=/usr/local/tomcat \
    CATALINA_BASE=/usr/local/tomcat \
    AM_CONFIG_DIR=/opt/am-config \
    CERTS_DIR=/opt/certs

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN groupadd -r tomcat -g 1001 && \
    useradd -r -u 1001 -g tomcat -d "${CATALINA_HOME}" -s /bin/bash tomcat && \
    rm -rf "${CATALINA_HOME}"/webapps/* && \
    mkdir -p "${AM_CONFIG_DIR}" "${CATALINA_HOME}/conf/keystores" "${CERTS_DIR}" /opt/scripts && \
    printf '%s\n' 'export CATALINA_OPTS="$CATALINA_OPTS -server -Xms512m -Xmx1536m -XX:MaxMetaspaceSize=256m -XX:+UseG1GC"' \
        > "${CATALINA_HOME}/bin/setenv.sh"

COPY --from=war /am ${CATALINA_HOME}/webapps/am
COPY --chmod=755 pingam/scripts/docker-entrypoint.sh /opt/scripts/docker-entrypoint.sh

RUN chown -R tomcat:tomcat "${CATALINA_HOME}" "${AM_CONFIG_DIR}" "${CERTS_DIR}" /opt/scripts
USER tomcat
EXPOSE 8080
HEALTHCHECK --interval=15s --timeout=10s --retries=20 --start-period=60s \
    CMD curl -fsS -o /dev/null http://localhost:8080/am/isAlive.jsp || exit 1
ENTRYPOINT ["/opt/scripts/docker-entrypoint.sh"]
CMD ["catalina.sh", "run"]
