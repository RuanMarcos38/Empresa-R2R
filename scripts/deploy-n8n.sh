#!/usr/bin/env bash
set -Eeuo pipefail

: "${N8N_BASE_URL:?N8N_BASE_URL não configurado}"
: "${N8N_API_KEY:?N8N_API_KEY não configurado}"

FILE="${1:-n8n/R2R_MASTER.json}"
BASE="${N8N_BASE_URL%/}"

if ! jq -e '.name and (.nodes|type=="array") and (.connections|type=="object")' "$FILE" >/dev/null; then
  echo "Workflow JSON inválido: $FILE"
  exit 1
fi

NAME="$(jq -r '.name' "$FILE")"
PAYLOAD="$(mktemp)"
trap 'rm -f "$PAYLOAD" /tmp/n8n-workflows.json /tmp/n8n-response.json /tmp/n8n-activate.json' EXIT

# A API pública do n8n não aceita campos somente-leitura/extras em POST/PUT.
jq '{name,nodes,connections,settings,staticData}' "$FILE" > "$PAYLOAD"

echo "Buscando workflow: $NAME"
curl -fsS   -H "X-N8N-API-KEY: $N8N_API_KEY"   "$BASE/api/v1/workflows?limit=250" > /tmp/n8n-workflows.json

ID="$(jq -r --arg n "$NAME" '.data[]? | select(.name==$n) | .id' /tmp/n8n-workflows.json | head -n1)"

if [[ -n "$ID" && "$ID" != "null" ]]; then
  echo "Atualizando workflow existente: $ID"
  curl -fsS -X PUT     -H "X-N8N-API-KEY: $N8N_API_KEY"     -H "Content-Type: application/json"     --data-binary "@$PAYLOAD"     "$BASE/api/v1/workflows/$ID" > /tmp/n8n-response.json
else
  echo "Criando workflow"
  curl -fsS -X POST     -H "X-N8N-API-KEY: $N8N_API_KEY"     -H "Content-Type: application/json"     --data-binary "@$PAYLOAD"     "$BASE/api/v1/workflows" > /tmp/n8n-response.json
  ID="$(jq -r '.id' /tmp/n8n-response.json)"
fi

if [[ -z "$ID" || "$ID" == "null" ]]; then
  echo "Não foi possível obter o ID do workflow"
  cat /tmp/n8n-response.json
  exit 1
fi

echo "Workflow salvo: $ID"

# Reativa o workflow para garantir o registro dos webhooks após atualização.
curl -sS -X POST   -H "X-N8N-API-KEY: $N8N_API_KEY"   "$BASE/api/v1/workflows/$ID/deactivate" >/dev/null || true

sleep 2

if ! curl -fsS -X POST   -H "X-N8N-API-KEY: $N8N_API_KEY"   "$BASE/api/v1/workflows/$ID/activate" > /tmp/n8n-activate.json; then
  echo "Falha ao ativar workflow. Resposta:"
  cat /tmp/n8n-activate.json 2>/dev/null || true
  exit 1
fi

echo "Aguardando registro dos webhooks..."
sleep 5

HEALTH="$BASE/webhook/r2r/health"
echo "Healthcheck: $HEALTH"
for attempt in 1 2 3 4 5 6; do
  if response="$(curl -fsS --max-time 15 "$HEALTH" 2>/dev/null)"; then
    echo "$response" | jq . || echo "$response"
    echo "Deploy validado com sucesso."
    exit 0
  fi
  echo "Tentativa $attempt/6 ainda sem resposta; aguardando..."
  sleep 5
done

echo "Workflow atualizado, mas o webhook de healthcheck não respondeu."
echo "Verifique se main/runner/worker/webhook usam a mesma versão do n8n."
exit 1
