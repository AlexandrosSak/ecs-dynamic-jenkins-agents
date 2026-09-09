#!/bin/bash
set -ex

echo "=== STARTING JENKINS REMOTING AGENT ==="
java -version 2>&1 | head -1

if [ $# -gt 0 ]; then
    exec java -jar /usr/share/jenkins/agent.jar "$@"
else
    exec java -jar /usr/share/jenkins/agent.jar \
        -url "$JENKINS_URL" \
        -secret "$JENKINS_SECRET" \
        -name "$JENKINS_AGENT_NAME" \
        -workDir "${JENKINS_AGENT_WORKDIR:-/home/jenkins/agent}"
fi