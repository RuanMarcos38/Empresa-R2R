# Correção de compatibilidade n8n

Erro observado:
`Cannot assign to read only property 'name' of object 'Error: access to env vars denied'`

Causa:
o workflow COMPATIBILIDADE usa `$env` no nó `Validar Configuração`, enquanto a instância n8n 2.x está bloqueando acesso a variáveis de ambiente nos nodes.

Correção aplicada no arquivo de contingência gerado na conversa:
- nó `Validar Configuração` substituído por `Validar Inicialização`;
- validação não lê `$env`;
- health notification foi desativada nessa versão até o EasyPanel liberar acesso às variáveis.

Para o workflow de produção baseado em variáveis de ambiente, configure no serviço n8n e no runner/worker:
`N8N_BLOCK_ENV_ACCESS_IN_NODE=false`

Se a instância suportar allowlist de env vars em expressões, autorize apenas:
`R2R_AI_ENDPOINT,R2R_AI_API_KEY,R2R_AI_MODEL,R2R_DATA_API,R2R_NOTIFY_WEBHOOK,R2R_CALENDAR_WEBHOOK,EVOLUTION_API_KEY`

Reinicie todos os componentes n8n que executam workflows após alterar o ambiente.
