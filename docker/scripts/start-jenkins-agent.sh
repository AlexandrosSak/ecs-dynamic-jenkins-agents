#!/bin/bash
set -ex

echo "=== AGENT INITIALIZATION & SERVICE DISCOVERY ==="

# Dynamic Service Discovery (e.g. Solr via ECS Task Inspection)
SOLR_IP="10.50.13.33"
TASK_ARN=$(aws ecs list-tasks --cluster dev-cluster --service-name app-solr --region eu-west-1 --query "taskArns[0]" --output text 2>/dev/null || echo "none")

if [ "$TASK_ARN" != "none" ] && [ -n "$TASK_ARN" ]; then
    DISCOVERED_IP=$(aws ecs describe-tasks --cluster dev-cluster --tasks "$TASK_ARN" --region eu-west-1 --query "tasks[0].containers[0].networkInterfaces[0].privateIpv4Address" --output text 2>/dev/null || echo "none")
    if [ "$DISCOVERED_IP" != "none" ] && [ -n "$DISCOVERED_IP" ]; then
        SOLR_IP="$DISCOVERED_IP"
    fi
fi

echo "Connecting to Solr endpoint: ${SOLR_IP}:8983"

# Delegate execution to main agent connection process
exec /usr/local/bin/jenkins-agent "$@"