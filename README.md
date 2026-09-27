# Empresa-R2R — Automation OS v4

Automação operacional da **R2R Marketing Digital**.

## Arquitetura atual

O workflow principal foi refatorado para remover dependências fictícias externas.

### Removidos
- `R2R_AI_ENDPOINT`
- `R2R_DATA_API`
- `R2R_NOTIFY_WEBHOOK`
- `R2R_CALENDAR_WEBHOOK`

### Agora usa diretamente
- **n8n**
- **Evolution API**
- **OpenAI**
- **Google Calendar nativo do n8n**
- **CRM/fila/KPIs internos do workflow**
- **PostgreSQL preparado em `database/schema.sql`**

## Workflow principal

`n8n/R2R_MASTER.json`

Nome:
`R2R MARKETING DIGITAL • MASTER OS • AUTOSSUFICIENTE v4`

## Variáveis privadas no EasyPanel / n8n

```
N8N_BLOCK_ENV_ACCESS_IN_NODE=false
EVOLUTION_API_KEY=
R2R_AI_API_KEY=
R2R_AI_MODEL=gpt-5.6
R2R_ADMIN_PHONE=
```

O agente de deploy `operacao2r` também usa:

```
N8N_API_KEY=
```

## Credenciais nativas do n8n

### Google Calendar
Crie uma credencial OAuth2 no n8n com o nome:

`R2R Google Calendar`

O nó **Agenda • Integrar Calendar** utiliza essa credencial e cria eventos no calendário `primary`.

### PostgreSQL
O schema completo está em:

`database/schema.sql`

Crie uma credencial Postgres no n8n com o nome:

`R2R Postgres`

A operação atual usa memória persistente do workflow para não quebrar antes da conexão do banco. O schema Postgres está pronto para migração/backup.

## Evolution API

Servidor:
`https://evolution-evolution-api.ke4n49.easypanel.host`

Instância:
`R2R Marketing Digital`

Webhook principal:
`POST https://n8n-n8n.ke4n49.easypanel.host/webhook/r2r/inbound-sales`

O fluxo:
- ignora `fromMe`;
- ignora grupos;
- bloqueia repetição por messageId;
- respeita opt-out;
- qualifica por IA;
- responde pela Evolution;
- mantém histórico do contato.

## Agente EasyPanel

O repositório contém um `Dockerfile` na raiz.

No EasyPanel, o serviço `operacao2r` deve usar:
- Fonte: GitHub
- Repositório: `RuanMarcos38/Empresa-R2R`
- Branch: `main`
- Build Path: `/`
- Builder: Dockerfile

Quando `N8N_API_KEY` e `EVOLUTION_API_KEY` estiverem no Ambiente do `operacao2r`, o container tenta:
1. publicar o workflow no n8n;
2. ativar o workflow;
3. configurar a Evolution API;
4. manter um endpoint simples de status na porta 3000.

## Segurança

O repositório é público. Nunca grave tokens ou senhas nos arquivos.
Use apenas:
- EasyPanel Environment;
- n8n Credentials;
- GitHub Actions Secrets.

## PostgreSQL

Não use diretamente as tabelas internas do n8n para dados da agência.

O ideal é criar um banco ou schema separado para a R2R. O arquivo `database/schema.sql` cria o schema `r2r` e tabelas para:
- leads;
- conversas;
- outreach;
- reuniões;
- propostas;
- clientes;
- métricas;
- vendas;
- incidentes.
