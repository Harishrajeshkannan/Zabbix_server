#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${1:-dev}"
PROJECT_NAME="${PROJECT_NAME:-zabbix}"

echo "🧹 Cleanup for env: $ENVIRONMENT"

# Delete any leftover ECS services (if present)
CLUSTER="${PROJECT_NAME}-${ENVIRONMENT}-cluster"
if aws ecs describe-clusters --clusters "$CLUSTER" --query 'clusters[0].status' --output text 2>/dev/null | grep -q "ACTIVE"; then
  SERVICES=$(aws ecs list-services --cluster "$CLUSTER" --query 'serviceArns[]' --output text || true)
  for svc in $SERVICES; do
    echo "Forcing delete of service: $svc"
    aws ecs update-service --cluster "$CLUSTER" --service "$svc" --desired-count 0 || true
    aws ecs delete-service --cluster "$CLUSTER" --service "$svc" --force || true
  done
fi

# Delete log groups if left behind
aws logs delete-log-group --log-group-name "/ecs/${PROJECT_NAME}-${ENVIRONMENT}-server" || true
aws logs delete-log-group --log-group-name "/ecs/${PROJECT_NAME}-${ENVIRONMENT}-web" || true

echo "✅ Cleanup complete."
