#!/bin/sh
set -eu

CONFIG_PATH="${CONFIG_PATH:-/CLIProxyAPI/config.yaml}"
AUTH_DIR="${AUTH_DIR:-/root/.cli-proxy-api}"
LISTEN_HOST="${LISTEN_HOST:-}"
LISTEN_PORT="${PORT:-${LISTEN_PORT:-8317}}"

if [ -z "${PROXY_API_KEY:-}" ]; then
  echo "FATAL: PROXY_API_KEY env var must be set" >&2
  exit 1
fi

mkdir -p "$AUTH_DIR"

PERSISTED_CONFIG="${AUTH_DIR}/config.yaml"

if [ -f "$PERSISTED_CONFIG" ]; then
  echo "[entrypoint] using persisted config from $PERSISTED_CONFIG"
  cp "$PERSISTED_CONFIG" "$CONFIG_PATH"
  exec /CLIProxyAPI/CLIProxyAPI --config "$CONFIG_PATH"
fi

echo "[entrypoint] no persisted config; rendering bootstrap config from env"

cat > "$CONFIG_PATH" <<YAML
host: "${LISTEN_HOST}"
port: ${LISTEN_PORT}

tls:
  enable: false
  cert: ""
  key: ""

remote-management:
  allow-remote: true
  secret-key: ""
  disable-control-panel: false
  panel-github-repository: "https://github.com/router-for-me/Cli-Proxy-API-Management-Center"

auth-dir: "${AUTH_DIR}"

api-keys:
  - "${PROXY_API_KEY}"

debug: false

pprof:
  enable: false
  addr: "127.0.0.1:8316"

plugins:
  enabled: false
  dir: "plugins"

commercial-mode: false
logging-to-file: false
logs-max-total-size-mb: 0
error-logs-max-files: 10
usage-statistics-enabled: true
redis-usage-queue-retention-seconds: 60
proxy-url: ""
force-model-prefix: false
request-retry: 3
max-retry-interval: 30
max-retry-credentials: 5
disable-cooling: false
ws-auth: false
YAML

echo "[entrypoint] bootstrap config rendered at $CONFIG_PATH (auth-dir=$AUTH_DIR, port=$LISTEN_PORT)"
echo "[entrypoint] copying bootstrap to persistent volume so future edits survive restarts"
cp "$CONFIG_PATH" "$PERSISTED_CONFIG"
exec /CLIProxyAPI/CLIProxyAPI --config "$PERSISTED_CONFIG"
