# Empresa-R2R — Automação da R2R Marketing Digital

Este repositório mantém o workflow mestre da operação automatizada da R2R.

## Arquivos principais

- `n8n/R2R_MASTER.json` — workflow mestre do n8n.
- `.github/workflows/deploy-n8n.yml` — CI/CD que atualiza a instância n8n no EasyPanel após push em `main`.
- `scripts/deploy-n8n.sh` — upsert, ativação e healthcheck do workflow.
- `.env.example` — variáveis exigidas sem nenhum segredo.

## n8n em produção

Base URL:
`https://n8n-n8n.ke4n49.easypanel.host`

Webhook principal da Evolution API:
`POST https://n8n-n8n.ke4n49.easypanel.host/webhook/r2r/inbound-sales`

Healthcheck:
`GET https://n8n-n8n.ke4n49.easypanel.host/webhook/r2r/health`

## Atualização automática

O GitHub Actions faz:

1. validação do JSON;
2. busca do workflow por nome;
3. criação ou atualização via API do n8n;
4. reativação para registrar os webhooks;
5. healthcheck de produção.

### GitHub Secrets obrigatórios

- `N8N_BASE_URL` = `https://n8n-n8n.ke4n49.easypanel.host`
- `N8N_API_KEY` = API key criada na sua instância n8n.

## Variáveis no serviço n8n do EasyPanel

Configure as variáveis listadas em `.env.example` no serviço **n8n** do EasyPanel.

> Segurança: este repositório é público. Tokens, senhas e API keys nunca devem ser gravados em arquivos versionados.

## Regra de infraestrutura

Se houver mais de um componente n8n (main/runner/worker/webhook), todos devem usar a mesma versão do n8n. A documentação oficial recomenda atualizar os componentes conjuntamente para evitar incompatibilidades de protocolo.
