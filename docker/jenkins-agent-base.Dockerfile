ARG BASE_IMAGE=base-tools:latest
FROM ${BASE_IMAGE}

ARG VERSION=3355.v388858a_47b_33
RUN mkdir -p /usr/share/jenkins && \
    curl -L "https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${VERSION}/remoting-${VERSION}.jar" \
    -o /usr/share/jenkins/agent.jar && \
    chmod 0644 /usr/share/jenkins/agent.jar

# Embedded Memcached Cache Daemon
RUN sed -i 's/^-l.*/# -l 127.0.0.1/' /etc/memcached.conf && \
    sed -i 's/^-p.*/# -p 11211/' /etc/memcached.conf && \
    echo "-p 11211" >> /etc/memcached.conf && \
    echo "-l 0.0.0.0" >> /etc/memcached.conf && \
    echo "-m 64" >> /etc/memcached.conf