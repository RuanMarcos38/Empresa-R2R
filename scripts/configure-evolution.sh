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

echo "2/4 Configurando webhook MESSAGES_UPSERT (Evolution 2.3.7)..."
HTTP_CODE="$(curl -sS -o /tmp/evolution-webhook-set.json -w "%{http_code}" -X POST   -H "apikey: $EVOLUTION_API_KEY"   -H "Content-Type: application/json"   --data-binary @-   "$EVOLUTION_BASE_URL/webhook/set/$ENCODED_INSTANCE" <<JSON
{
  "webhook": {
    "enabled": true,
    "url": "$N8N_WEBHOOK_URL",
    "byEvents": false,
    "base64": false,
    "events": ["MESSAGES_UPSERT"]
  }
}
JSON
)"

cat /tmp/evolution-webhook-set.json || true
echo

if [[ "$HTTP_CODE" != "200" && "$HTTP_CODE" != "201" ]]; then
  echo "Falha ao configurar webhook da Evolution. HTTP $HTTP_CODE"
  exit 1
fi

echo "3/4 Conferindo webhook..."
curl -fsS   -H "apikey: $EVOLUTION_API_KEY"   "$EVOLUTION_BASE_URL/webhook/find/$ENCODED_INSTANCE"   | tee /tmp/evolution-webhook.json

CONFIG_URL="$(jq -r '.webhook.url // .url // empty' /tmp/evolution-webhook.json)"
if [[ "$CONFIG_URL" != "$N8N_WEBHOOK_URL" ]]; then
  echo "Webhook retornado diferente do esperado: $CONFIG_URL"
  exit 1
fi

echo "4/4 Testando healthcheck do n8n..."
set +e
curl -fsS --max-time 20   "https://n8n-n8n.ke4n49.easypanel.host/webhook/r2r/health"   | tee /tmp/r2r-health.json
RC_HEALTH=${PIPESTATUS[0]}
set -e

if [[ "$RC_HEALTH" -ne 0 ]]; then
  echo "AVISO: Evolution configurada corretamente, mas o n8n ainda não respondeu ao healthcheck."
  echo "Evolution API configurada com sucesso."
  exit 0
fi

if ! jq -e '.ok == true' /tmp/r2r-health.json >/dev/null 2>&1; then
  echo "AVISO: Evolution configurada corretamente; resposta do healthcheck do n8n não confirmou ok=true."
  echo "Evolution API configurada com sucesso."
  exit 0
fi

echo "Evolution API configurada com sucesso."
