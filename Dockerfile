FROM python:3.12-alpine
RUN apk add --no-cache bash curl jq ca-certificates tzdata
WORKDIR /app
COPY n8n/R2R_MASTER.json /app/n8n/R2R_MASTER.json
COPY scripts/deploy-n8n.sh /app/scripts/deploy-n8n.sh
COPY scripts/configure-evolution.sh /app/scripts/configure-evolution.sh
COPY docker-entrypoint.sh /app/docker-entrypoint.sh
COPY health_server.py /app/health_server.py
RUN chmod +x /app/docker-entrypoint.sh /app/scripts/*.sh
ENV PORT=3000
ENV TZ=America/Sao_Paulo
EXPOSE 3000
CMD ["/app/docker-entrypoint.sh"]
