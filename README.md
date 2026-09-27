# Empresa-R2R — Automation OS v5

A versão v5 foi preparada para usar **variáveis do EasyPanel** e evitar seleção manual de credenciais dentro do workflow.

## Workflow
`n8n/R2R_MASTER.json`

Nome:
`R2R MARKETING DIGITAL • MASTER OS • EASY PANEL v5`

## EasyPanel → serviço n8n → Ambiente

```
N8N_BLOCK_ENV_ACCESS_IN_NODE=false

EVOLUTION_API_KEY=...
R2R_AI_API_KEY=...
R2R_AI_MODEL=gpt-5.6
R2R_ADMIN_PHONE=55...

GOOGLE_CLIENT_ID=...
GOOGLE_CLIENT_SECRET=...
GOOGLE_REFRESH_TOKEN=...
GOOGLE_CALENDAR_ID=primary
```

Depois de salvar as variáveis, faça redeploy do serviço n8n.

## Google Calendar
O workflow não depende mais de uma credencial Google Calendar selecionada manualmente no nó.

Ele faz:
1. troca `GOOGLE_REFRESH_TOKEN` por access token;
2. cria o evento no Google Calendar;
3. cria link Google Meet;
4. adiciona o e-mail do lead como participante;
5. registra a reunião no CRM interno.

## Evolution
Webhook principal:
`POST https://n8n-n8n.ke4n49.easypanel.host/webhook/r2r/inbound-sales`

## OpenAI
O endpoint é direto:
`https://api.openai.com/v1/chat/completions`

## Segurança
Nunca grave API keys, client secrets ou refresh tokens no repositório público.
Use apenas as variáveis de ambiente do EasyPanel.
