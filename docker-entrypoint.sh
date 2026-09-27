#!/usr/bin/env bash
set -u

echo "=========================================="
echo " R2R Marketing Digital • Deploy Agent"
echo "=========================================="
echo "Início: $(date -Iseconds)"

AGENT_PORT="${R2R_AGENT_PORT:-3000}"
mkdir -p /app/public /app/logs

write_status() {
  local n8n_status="${1:-starting}"
  local n8n_detail="${2:-Inicializando}"
  local evo_status="${3:-starting}"
  local evo_detail="${4:-Inicializando}"

  python3 - "$n8n_status" "$n8n_detail" "$evo_status" "$evo_detail" <<'PY'
import json, sys, datetime, pathlib
out={
  "ok": True,
  "service": "R2R Marketing Digital Deploy Agent",
  "time": datetime.datetime.now(datetime.timezone.utc).isoformat(),
  "n8n_deploy": sys.argv[1],
  "n8n_detail": sys.argv[2],
  "evolution": sys.argv[3],
  "evolution_detail": sys.argv[4],
}
pathlib.Path("/app/public/status.json").write_text(
    json.dumps(out, ensure_ascii=False, indent=2),
    encoding="utf-8"
)
PY
}

write_status "starting" "Agente iniciado; validando n8n" "starting" "Agente iniciado; validando Evolution"

echo "Servidor de status ativo imediatamente na porta $AGENT_PORT"
python3 -m http.server "$AGENT_PORT" --bind 0.0.0.0 --directory /app/public &
SERVER_PID=$!

cleanup() {
  kill "$SERVER_PID" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

STATUS_N8N="skipped"
STATUS_EVOLUTION="skipped"
N8N_DETAIL=""
EVOLUTION_DETAIL=""

if [[ -n "${N8N_API_KEY:-}" ]]; then
  echo "[1/2] Publicando workflow no n8n..."
  N8N_BASE_URL="${N8N_BASE_URL:-https://n8n-n8n.ke4n49.easypanel.host}" \
  N8N_API_KEY="$N8N_API_KEY" \
  bash /app/scripts/deploy-n8n.sh /app/n8n/R2R_MASTER.json > /app/logs/n8n.log 2>&1
  RC_N8N=$?
  cat /app/logs/n8n.log
  if [[ "$RC_N8N" -eq 0 ]]; then
    STATUS_N8N="ok"
    N8N_DETAIL="Workflow publicado e validado"
  else
    STATUS_N8N="error"
    N8N_DETAIL="$(tail -n 8 /app/logs/n8n.log | tr '\n' ' ')"
  fi
else
  STATUS_N8N="missing_secret"
  N8N_DETAIL="N8N_API_KEY ausente no Ambiente do operacao2r"
fi

write_status "$STATUS_N8N" "$N8N_DETAIL" "starting" "Validando Evolution"

if [[ -n "${EVOLUTION_API_KEY:-}" ]]; then
  echo "[2/2] Configurando Evolution API..."
  EVOLUTION_BASE_URL="${EVOLUTION_BASE_URL:-https://evolution-evolution-api.ke4n49.easypanel.host}" \
  EVOLUTION_INSTANCE="${EVOLUTION_INSTANCE:-R2R Marketing Digital}" \
  N8N_WEBHOOK_URL="${N8N_WEBHOOK_URL:-https://n8n-n8n.ke4n49.easypanel.host/webhook/r2r/inbound-sales}" \
  EVOLUTION_API_KEY="$EVOLUTION_API_KEY" \
  bash /app/scripts/configure-evolution.sh > /app/logs/evolution.log 2>&1
  RC_EVOLUTION=$?
  cat /app/logs/evolution.log
  if [[ "$RC_EVOLUTION" -eq 0 ]]; then
    STATUS_EVOLUTION="ok"
    EVOLUTION_DETAIL="Evolution configurada corretamente"
  else
    STATUS_EVOLUTION="error"
    EVOLUTION_DETAIL="$(tail -n 8 /app/logs/evolution.log | tr '\n' ' ')"
  fi
else
  STATUS_EVOLUTION="missing_secret"
  EVOLUTION_DETAIL="EVOLUTION_API_KEY ausente no Ambiente do operacao2r"
fi

cp /app/logs/n8n.log /app/public/n8n.log 2>/dev/null || true
cp /app/logs/evolution.log /app/public/evolution.log 2>/dev/null || true
write_status "$STATUS_N8N" "$N8N_DETAIL" "$STATUS_EVOLUTION" "$EVOLUTION_DETAIL"

echo "Agente pronto. Status: http://0.0.0.0:$AGENT_PORT/status.json"
wait "$SERVER_PID"
