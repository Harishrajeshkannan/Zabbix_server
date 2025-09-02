#!/usr/bin/env bash
set -euo pipefail

LOAD_BALANCER_URL="${1:-}"
if [[ -z "$LOAD_BALANCER_URL" ]]; then
  echo "Usage: $0 <load-balancer-url>"
  exit 1
fi

MAX_ATTEMPTS=20
SLEEP_SECS=20
ATTEMPT=0

echo "🔍 Validating Zabbix at: $LOAD_BALANCER_URL"

check_http () {
  local url="$1"
  local status
  status=$(curl -s -o /dev/null -w "%{http_code}" "$url" || echo "000")
  [[ "$status" == "200" || "$status" == "301" || "$status" == "302" ]]
}

echo "⏳ Waiting for ALB to respond..."
until check_http "$LOAD_BALANCER_URL"; do
  ATTEMPT=$((ATTEMPT+1))
  if (( ATTEMPT > MAX_ATTEMPTS )); then
    echo "❌ ALB not healthy after $MAX_ATTEMPTS attempts"
    exit 1
  fi
  echo "Attempt $ATTEMPT/$MAX_ATTEMPTS — sleeping ${SLEEP_SECS}s"
  sleep "$SLEEP_SECS"
done

echo "✅ ALB responds. Checking for Zabbix markers..."
if curl -s "$LOAD_BALANCER_URL" | grep -qi "Zabbix"; then
  echo "🎉 Zabbix web interface is accessible."
else
  echo "⚠️ Page loaded but 'Zabbix' marker not found yet. It may still be initializing."
fi

echo "🔑 Default credentials: Admin / zabbix"
