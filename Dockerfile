FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    APP_DIR=/app \
    DOC_ROOT=/app \
    HOST=0.0.0.0 \
    PORT=8443 \
    INDEX_FILE=noise_monitor.html \
    CERT_FILE=/app/cert.pem \
    KEY_FILE=/app/key.pem

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends openssl \
    && rm -rf /var/lib/apt/lists/*

COPY server_noise_monitor.py noise_monitor.html docker-entrypoint.sh /app/

EXPOSE 8443

ENTRYPOINT ["sh", "/app/docker-entrypoint.sh"]

