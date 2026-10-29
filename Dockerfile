FROM python:3.11-slim

# Deplexo runs containers with a read-only root filesystem, so never write .pyc files at runtime.
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    DATA_DIR=/data \
    PORT=8000

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Precompile bytecode at build time (runtime filesystem is read-only),
# create an unprivileged user and give it ownership of the persistent data mount.
RUN python -m compileall -q /app \
 && groupadd --system --gid 10001 app \
 && useradd --system --uid 10001 --gid app --no-create-home --shell /usr/sbin/nologin app \
 && mkdir -p /data \
 && chown -R app:app /data \
 && chmod 0755 /app/docker-entrypoint.sh

USER app

EXPOSE 8000

CMD ["sh", "/app/docker-entrypoint.sh"]
