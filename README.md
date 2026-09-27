# Empresa-R2R — Automação R2R Marketing Digital

Repositório oficial do workflow mestre da R2R.

## Produção

n8n:
`https://n8n-n8n.ke4n49.easypanel.host`

Evolution API:
`https://evolution-evolution-api.ke4n49.easypanel.host`

Instância:
`R2R Marketing Digital`

Webhook principal da Evolution:
`POST https://n8n-n8n.ke4n49.easypanel.host/webhook/r2r/inbound-sales`

Healthcheck:
`GET https://n8n-n8n.ke4n49.easypanel.host/webhook/r2r/health`

## Integração Evolution incluída

O workflow mestre contém:
- recebimento de `MESSAGES_UPSERT`;
- filtro de mensagens `fromMe`;
- bloqueio de grupos;
- anti-loop e anti-duplicidade por messageId;
- opt-out;
- SDR com IA;
- memória de conversa;
- resposta automática via `/message/sendText/{instance}`;
- envio outbound pela Evolution com gate de compliance;
- delays de envio;
- logs e healthcheck.

## Automação do webhook Evolution

O arquivo `scripts/configure-evolution.sh`:
1. valida o estado da instância;
2. exige estado `open`;
3. configura `MESSAGES_UPSERT`;
4. aponta para o webhook do n8n;
5. consulta a configuração gravada;
6. testa o healthcheck da R2R.

## GitHub Secrets obrigatórios

Em **Settings → Secrets and variables → Actions** crie:

### N8N_API_KEY
API key da instância n8n. Usada apenas para publicar/atualizar o workflow.

### EVOLUTION_API_KEY
Token/API key privado da instância Evolution. Usado para configurar o webhook e autenticar as chamadas.

Não grave esses valores em arquivos: este repositório é público.

## GitHub Actions

- `Deploy R2R Master no n8n`: valida, cria/atualiza, ativa e testa o workflow.
- `Configurar Evolution API`: verifica a conexão, grava o webhook e confirma a configuração.

Depois de criar os dois Secrets, abra **Actions** e execute novamente os dois workflows. A partir daí, alterações futuras no workflow são publicadas automaticamente.
