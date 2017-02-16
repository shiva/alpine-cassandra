FROM openjdk:8-jre-alpine
MAINTAINER Shiva Velmurugan <shiv@shiv.me>

# Important! Update this following env variables, to force 
# refresh of base images, to remove the effect of caches
ENV REFRESHED_AT=2017-02-14 \
    LANG=en_US.UTF-8 \
    TERM=xterm \
    HOME=/

ARG proxy

ENV http_proxy  $proxy
ENV HTTP_PROXY  $proxy
ENV https_proxy $proxy
ENV HTTPS_PROXY $proxy

# Install Cassandra
ENV CASSANDRA_VERSION=3.10 \
    CASSANDRA_HOME=/opt/cassandra \
    CASSANDRA_CONFIG=/etc/cassandra \
    CASSANDRA_PERSIST_DIR=/var/lib/cassandra \
    CASSANDRA_DATA=/var/lib/cassandra/data \
    CASSANDRA_COMMITLOG=/var/lib/cassandra/commitlog \
    CASSANDRA_LOG=/var/log/cassandra \
    CASSANDRA_USER=cassandra

## Create data directories that should be used by Cassandra
RUN mkdir -p ${CASSANDRA_HOME} \
             ${CASSANDRA_DATA} \
             ${CASSANDRA_CONFIG} \
             ${CASSANDRA_LOG} \
             ${CASSANDRA_COMMITLOG}

## Install it and reduce container size
### Apache Cassandra
RUN apk --update --no-cache add wget ca-certificates tar \
    && wget http://apache.cs.utah.edu/cassandra/${CASSANDRA_VERSION}/apache-cassandra-${CASSANDRA_VERSION}-bin.tar.gz -P /tmp \
    && tar -xvzf /tmp/apache-cassandra-${CASSANDRA_VERSION}-bin.tar.gz -C /tmp/ \
    && mv /tmp/apache-cassandra-${CASSANDRA_VERSION}/* ${CASSANDRA_HOME}/  \
    && apk --purge del wget ca-certificates tar  \
    && rm -r /tmp/apache-cassandra-${CASSANDRA_VERSION} \
             /tmp/apache-cassandra-${CASSANDRA_VERSION}-bin.tar.gz \
             /var/cache/apk/*

# Setup entrypoint and bash to execute it
COPY ./docker-entrypoint.sh /docker-entrypoint.sh
RUN echo "proxy=$HTTP_PROXY"
RUN apk add --update --no-cache bash \
    && chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/bin/bash", "/docker-entrypoint.sh"]

# Add default config
RUN ls -l /opt/cassandra \
    && mv ${CASSANDRA_HOME}/conf/* ${CASSANDRA_CONFIG}
#COPY ./conf/* ${CASSANDRA_CONFIG}/
RUN chmod +x ${CASSANDRA_CONFIG}/*.sh

# https://issues.apache.org/jira/browse/CASSANDRA-11661
RUN sed -ri 's/^(JVM_PATCH_VERSION)=.*/\1=25/' /etc/cassandra/cassandra-env.sh

# Add cassandra bin to PATH
ENV PATH=$PATH:${CASSANDRA_HOME}/bin \
    CASSANDRA_CONF=${CASSANDRA_CONFIG}

# Change directories ownership and access rights
RUN adduser -D -s /bin/sh ${CASSANDRA_USER} && \
    chown -R ${CASSANDRA_USER}:${CASSANDRA_USER} ${CASSANDRA_HOME} \
                                                 ${CASSANDRA_PERSIST_DIR} \
                                                 ${CASSANDRA_DATA} \
                                                 ${CASSANDRA_CONFIG} \
                                                 ${CASSANDRA_LOG} \
                                                 ${CASSANDRA_COMMITLOG} && \
    chmod 777 ${CASSANDRA_HOME} \
              ${CASSANDRA_PERSIST_DIR} \
              ${CASSANDRA_DATA} \
              ${CASSANDRA_CONFIG} \
              ${CASSANDRA_LOG} \
              ${CASSANDRA_COMMITLOG}

USER ${CASSANDRA_USER}
WORKDIR ${CASSANDRA_HOME}

# Expose data volume
VOLUME ${CASSANDRA_PERSIST_DIR}

# 7000: intra-node communication
# 7001: TLS intra-node communication
# 7199: JMX
# 9042: CQL
# 9160: thrift service
EXPOSE 7000 7001 7199 9042 9160

CMD ["cassandra", "-f"]
