#!/usr/bin/env bash
set -Eeuo pipefail

echo "=========================================="
echo " R2R Marketing Digital • Deploy Agent"
echo "=========================================="
echo "Início: $(date -Iseconds)"

STATUS_N8N="skipped"
STATUS_EVOLUTION="skipped"

if [[ -n "${N8N_API_KEY:-}" ]]; then
  echo "[1/2] Publicando workflow no n8n..."
  if N8N_BASE_URL="${N8N_BASE_URL:-https://n8n-n8n.ke4n49.easypanel.host}"      N8N_API_KEY="$N8N_API_KEY"      bash /app/scripts/deploy-n8n.sh /app/n8n/R2R_MASTER.json; then
    STATUS_N8N="ok"
  else
    STATUS_N8N="error"
    echo "Deploy do n8n falhou; mantendo agente ativo para inspeção."
  fi
else
  echo "[1/2] N8N_API_KEY ausente."
  STATUS_N8N="missing_secret"
fi

if [[ -n "${EVOLUTION_API_KEY:-}" ]]; then
  echo "[2/2] Configurando Evolution API..."
  if EVOLUTION_BASE_URL="${EVOLUTION_BASE_URL:-https://evolution-evolution-api.ke4n49.easypanel.host}"      EVOLUTION_INSTANCE="${EVOLUTION_INSTANCE:-R2R Marketing Digital}"      N8N_WEBHOOK_URL="${N8N_WEBHOOK_URL:-https://n8n-n8n.ke4n49.easypanel.host/webhook/r2r/inbound-sales}"      EVOLUTION_API_KEY="$EVOLUTION_API_KEY"      bash /app/scripts/configure-evolution.sh; then
    STATUS_EVOLUTION="ok"
  else
    STATUS_EVOLUTION="error"
    echo "Configuração da Evolution falhou; mantendo agente ativo para inspeção."
  fi
else
  echo "[2/2] EVOLUTION_API_KEY ausente."
  STATUS_EVOLUTION="missing_secret"
fi

mkdir -p /app/public
cat > /app/public/status.json <<JSON
{
  "ok": true,
  "service": "R2R Marketing Digital Deploy Agent",
  "n8n_deploy": "$STATUS_N8N",
  "evolution": "$STATUS_EVOLUTION"
}
JSON

echo "Agente ativo na porta ${PORT:-3000}"
exec python -m http.server "${PORT:-3000}" --directory /app/public
