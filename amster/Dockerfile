# One-shot Amster: install AM against ds-config + ds-identities, then wire external CTS to ds-cts.
ARG JRE_IMAGE=eclipse-temurin:21.0.8_9-jre-jammy
FROM ${JRE_IMAGE}
ARG AM_VERSION
RUN apt-get update && \
    apt-get install -y --no-install-recommends unzip curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*
COPY artifacts/Amster-${AM_VERSION}.zip /tmp/amster.zip
RUN unzip -q /tmp/amster.zip -d /opt && rm /tmp/amster.zip && \
    test -x /opt/amster/amster && \
    groupadd -r tomcat -g 1001 && useradd -r -u 1001 -g tomcat -d /opt/lab tomcat && \
    mkdir -p /opt/lab && chown tomcat:tomcat /opt/lab
COPY --chmod=755 amster/run.sh /opt/lab/run.sh
COPY amster/install.amster amster/configure-cts.amster /opt/lab/
USER 1001
WORKDIR /opt/lab
ENTRYPOINT ["/opt/lab/run.sh"]
