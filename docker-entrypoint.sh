#!/usr/bin/env bash
set -Eeuo pipefail

echo "=========================================="
echo " R2R Marketing Digital • Deploy Agent"
echo "=========================================="
echo "Início: $(date -Iseconds)"

STATUS_N8N="skipped"
STATUS_EVOLUTION="skipped"
N8N_DETAIL=""
EVOLUTION_DETAIL=""

mkdir -p /app/public /app/logs

if [[ -n "${N8N_API_KEY:-}" ]]; then
  echo "[1/2] Publicando workflow no n8n..."
  set +e
  N8N_BASE_URL="${N8N_BASE_URL:-https://n8n-n8n.ke4n49.easypanel.host}"   N8N_API_KEY="$N8N_API_KEY"   bash /app/scripts/deploy-n8n.sh /app/n8n/R2R_MASTER.json 2>&1 | tee /app/logs/n8n.log
  RC_N8N=${PIPESTATUS[0]}
  set -e
  if [[ "$RC_N8N" -eq 0 ]]; then
    STATUS_N8N="ok"
  else
    STATUS_N8N="error"
    N8N_DETAIL="$(tail -n 8 /app/logs/n8n.log | tr '\n' ' ' | sed 's/"/\\\"/g')"
  fi
else
  STATUS_N8N="missing_secret"
  N8N_DETAIL="N8N_API_KEY ausente no Ambiente do operacao2r"
fi

if [[ -n "${EVOLUTION_API_KEY:-}" ]]; then
  echo "[2/2] Configurando Evolution API..."
  set +e
  EVOLUTION_BASE_URL="${EVOLUTION_BASE_URL:-https://evolution-evolution-api.ke4n49.easypanel.host}"   EVOLUTION_INSTANCE="${EVOLUTION_INSTANCE:-R2R Marketing Digital}"   N8N_WEBHOOK_URL="${N8N_WEBHOOK_URL:-https://n8n-n8n.ke4n49.easypanel.host/webhook/r2r/inbound-sales}"   EVOLUTION_API_KEY="$EVOLUTION_API_KEY"   bash /app/scripts/configure-evolution.sh 2>&1 | tee /app/logs/evolution.log
  RC_EVOLUTION=${PIPESTATUS[0]}
  set -e
  if [[ "$RC_EVOLUTION" -eq 0 ]]; then
    STATUS_EVOLUTION="ok"
  else
    STATUS_EVOLUTION="error"
    EVOLUTION_DETAIL="$(tail -n 8 /app/logs/evolution.log | tr '\n' ' ' | sed 's/"/\\\"/g')"
  fi
else
  STATUS_EVOLUTION="missing_secret"
  EVOLUTION_DETAIL="EVOLUTION_API_KEY ausente no Ambiente do operacao2r"
fi

cat > /app/public/status.json <<JSON
{
  "ok": true,
  "service": "R2R Marketing Digital Deploy Agent",
  "time": "$(date -Iseconds)",
  "n8n_deploy": "$STATUS_N8N",
  "n8n_detail": "$N8N_DETAIL",
  "evolution": "$STATUS_EVOLUTION",
  "evolution_detail": "$EVOLUTION_DETAIL"
}
JSON

cp /app/logs/n8n.log /app/public/n8n.log 2>/dev/null || true
cp /app/logs/evolution.log /app/public/evolution.log 2>/dev/null || true

AGENT_PORT="${R2R_AGENT_PORT:-3000}"
echo "Agente ativo na porta $AGENT_PORT"
exec python -m http.server "$AGENT_PORT" --directory /app/public
