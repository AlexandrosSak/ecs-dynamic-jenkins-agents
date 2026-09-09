FROM ubuntu:22.04

RUN echo 'Acquire::Queue-Mode "access";' > /etc/apt/apt.conf.d/99parallel && \
    echo 'Acquire::http::Pipeline-Depth "10";' >> /etc/apt/apt.conf.d/99parallel && \
    echo 'Acquire::Retries "3";' >> /etc/apt/apt.conf.d/99parallel && \
    echo 'Acquire::http::Timeout "30";' >> /etc/apt/apt.conf.d/99parallel

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Tooling suite: OpenJDK, Perl, Ruby, Python, Docker CLI, System Libraries
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    openjdk-17-jre-headless ca-certificates curl wget git unzip \
    fontconfig less netbase openssh-client patch tzdata jq tree vim sudo gosu \
    python3 python3-pip python3-venv python3-dev build-essential \
    perl perl-doc cpanminus libssl-dev default-mysql-client libmysqlclient-dev \
    libxml2-dev libxml2 libexpat1 libexpat1-dev zlib1g-dev libbz2-dev liblzma-dev \
    ruby ruby-dev docker.io shellcheck ansible make gcc g++ libc6-dev \
    memcached libcache-memcached-perl netcat-openbsd telnet \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# System Users
ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000

RUN groupadd -g "${gid}" "${group}" \
  && useradd -l -c "Jenkins user" -d /home/"${user}" -u "${uid}" -g "${gid}" -m "${user}"

RUN groupadd -g 1001 worker \
  && useradd -l -c "Worker User" -d /home/worker -u 1001 -g 1001 -m worker \
  && usermod -aG docker worker

# Node.js 22 LTS
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && apt-get install -y nodejs && \
    npm install -g npm@latest serverless && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# AWS CLI v2 & HashiCorp Tooling
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && ./aws/install && rm -rf awscliv2.zip aws/ && \
    curl -LO https://releases.hashicorp.com/terraform/1.4.6/terraform_1.4.6_linux_amd64.zip && \
    unzip terraform_1.4.6_linux_amd64.zip && mv terraform /usr/local/bin/ && rm terraform*.zip && \
    curl -LO https://releases.hashicorp.com/packer/1.8.7/packer_1.8.7_linux_amd64.zip && \
    unzip packer_1.8.7_linux_amd64.zip && mv packer /usr/local/bin/ && rm packer*.zip

# Python & Ruby Build Dependencies
RUN pip3 install boto3 botocore pre-commit yamllint ansible-lint && \
    gem install minitar chef berkshelf --no-document

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="${JAVA_HOME}/bin:${PATH}"