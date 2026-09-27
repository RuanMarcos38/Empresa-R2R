#!/usr/bin/env bash
set -Eeuo pipefail

: "${EVOLUTION_API_KEY:?EVOLUTION_API_KEY não configurado}"

EVOLUTION_BASE_URL="${EVOLUTION_BASE_URL:-https://evolution-evolution-api.ke4n49.easypanel.host}"
EVOLUTION_INSTANCE="${EVOLUTION_INSTANCE:-R2R Marketing Digital}"
N8N_WEBHOOK_URL="${N8N_WEBHOOK_URL:-https://n8n-n8n.ke4n49.easypanel.host/webhook/r2r/inbound-sales}"

ENCODED_INSTANCE="$(python3 - <<'PY'
import urllib.parse, os
print(urllib.parse.quote(os.environ.get('EVOLUTION_INSTANCE','R2R Marketing Digital'), safe=''))
PY
)"

echo "1/4 Validando conexão da instância..."
curl -fsS   -H "apikey: $EVOLUTION_API_KEY"   "$EVOLUTION_BASE_URL/instance/connectionState/$ENCODED_INSTANCE"   | tee /tmp/evolution-state.json

STATE="$(jq -r '.instance.state // empty' /tmp/evolution-state.json)"
if [[ "$STATE" != "open" ]]; then
  echo "A instância não está em estado open. Estado atual: ${STATE:-desconhecido}"
  exit 1
fi

echo "2/4 Configurando webhook MESSAGES_UPSERT..."
curl -fsS -X POST   -H "apikey: $EVOLUTION_API_KEY"   -H "Content-Type: application/json"   --data-binary @-   "$EVOLUTION_BASE_URL/webhook/set/$ENCODED_INSTANCE" <<JSON
{
  "enabled": true,
  "url": "$N8N_WEBHOOK_URL",
  "webhookByEvents": false,
  "webhookBase64": false,
  "events": ["MESSAGES_UPSERT"]
}
JSON

echo "3/4 Conferindo webhook..."
curl -fsS   -H "apikey: $EVOLUTION_API_KEY"   "$EVOLUTION_BASE_URL/webhook/find/$ENCODED_INSTANCE"   | tee /tmp/evolution-webhook.json

CONFIG_URL="$(jq -r '.webhook.url // .url // empty' /tmp/evolution-webhook.json)"
if [[ "$CONFIG_URL" != "$N8N_WEBHOOK_URL" ]]; then
  echo "Webhook retornado diferente do esperado: $CONFIG_URL"
  exit 1
fi

echo "4/4 Testando healthcheck do n8n..."
curl -fsS "https://n8n-n8n.ke4n49.easypanel.host/webhook/r2r/health" | tee /tmp/r2r-health.json
jq -e '.ok == true' /tmp/r2r-health.json >/dev/null

echo "Evolution API configurada com sucesso."
