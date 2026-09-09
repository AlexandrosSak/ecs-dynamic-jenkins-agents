ARG JENKINS_IMAGE=jenkins-agent-base:latest
FROM ${JENKINS_IMAGE}

ARG AWS_REGION=eu-west-1
ARG GIT_IP=127.0.0.1

# Directory Structure & Permissions Setup
RUN mkdir -p /srv/app/public /srv/nfs/shared /var/log/app /etc/app /tmp/app /var/cache/app && \
    ln -sf /srv/app/public /app && \
    chown -R jenkins:jenkins /srv/nfs /srv/app /var/log/app /tmp/app /var/cache/app && \
    chmod -R 777 /srv/nfs /var/log/app /tmp/app /var/cache/app

# Sudo privileges
RUN echo "jenkins ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/jenkins && \
    chmod 0440 /etc/sudoers.d/jenkins

# Perlbrew Runtime Environment Config
ENV PERLBREW_ROOT=/opt/perlbrew
ENV PERLBREW_HOME=/opt/perlbrew
ENV PATH=/opt/perlbrew/perls/perl-5.26.1/bin:$PATH
ENV LD_LIBRARY_PATH=/opt/perlbrew/perls/perl-5.26.1/lib:$LD_LIBRARY_PATH

COPY docker/scripts/install-perl-tarball.sh /usr/local/bin/
COPY docker/scripts/jenkins-agent.sh /usr/local/bin/jenkins-agent
COPY docker/scripts/start-jenkins-agent.sh /usr/local/bin/start-jenkins-agent.sh

RUN chmod +x /usr/local/bin/install-perl-tarball.sh \
             /usr/local/bin/jenkins-agent \
             /usr/local/bin/start-jenkins-agent.sh

ENTRYPOINT ["/usr/local/bin/start-jenkins-agent.sh"]
USER jenkins
WORKDIR /home/jenkins/agent