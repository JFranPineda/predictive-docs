#!/usr/bin/env bash
# Entorno local completo: backend (Django) + front (Vite) + túnel cloudflared.
#
#   ./start-server.sh               migra, levanta los tres y espera 'exit'
#   ./start-server.sh --no-tunnel   sin cloudflared
#   ./start-server.sh --no-migrate  sin migrar al arrancar
#   BACK_PORT=8020 FRONT_PORT=5184 ./start-server.sh   otros puertos
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACK="$ROOT/predictive-back"
FRONT="$ROOT/predictive-front"
PY="$BACK/.venv/bin/python"
BACK_PORT="${BACK_PORT:-8010}"
FRONT_PORT="${FRONT_PORT:-5174}"
LOGS="${TMPDIR:-/tmp}/predictive-dev"
TUNNEL=1
MIGRATE=1
BACK_PID=""
FRONT_PID=""
CLOUD_PID=""

for arg in "$@"; do
  case "$arg" in
    --no-tunnel) TUNNEL=0 ;;
    --no-migrate) MIGRATE=0 ;;
    -h | --help) sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Opción desconocida: $arg (usa --help)"; exit 2 ;;
  esac
done

mkdir -p "$LOGS"

# --- Comprobaciones previas ----------------------------------------------------

[ -x "$PY" ] || { echo "❌ Falta el entorno de Python: cd $BACK && python3 -m venv .venv && .venv/bin/pip install -e '.[dev]'"; exit 1; }
[ -x "$FRONT/node_modules/.bin/vite" ] || { echo "❌ Faltan las dependencias del front: cd $FRONT && npm install"; exit 1; }
if [ "$TUNNEL" = 1 ] && ! command -v cloudflared > /dev/null; then
  echo "⚠️  cloudflared no está instalado: sigo sin túnel."
  TUNNEL=0
fi

listeners() { ss -ltnpH "( sport = :$1 )" 2> /dev/null | grep -o 'pid=[0-9]*' | cut -d= -f2 | sort -u; }
port_busy() { ss -ltnH "( sport = :$1 )" 2> /dev/null | grep -q .; }

# "That port is already in use" casi siempre es una ejecución anterior que no se
# cerró (o un runserver huérfano: el autorecargador deja un hijo escuchando).
free_port() {
  local port=$1 pids answer
  port_busy "$port" || return 0
  pids=$(listeners "$port")
  echo "⚠️  El puerto $port ya está en uso:"
  if [ -z "$pids" ]; then
    echo "    lo tiene un proceso de otro usuario; ciérralo a mano o usa otro puerto."
    return 1
  fi
  for pid in $pids; do ps -o pid=,args= -p "$pid" | cut -c1-150 | sed 's/^/    /'; done
  read -r -p "   ¿Lo detengo? [s/N] " answer
  [[ "$answer" =~ ^[sS]$ ]] || return 1
  kill $pids 2> /dev/null
  for _ in $(seq 1 20); do port_busy "$port" || return 0; sleep 0.25; done
  kill -9 $pids 2> /dev/null
  sleep 0.5
  ! port_busy "$port"
}

free_port "$BACK_PORT" || exit 1
free_port "$FRONT_PORT" || exit 1

# --- Migraciones ---------------------------------------------------------------

# Control y cada empresa son bases distintas: `migrate` solo toca la de
# control, y runserver avisa de "unapplied migrations" mirando solo esa.
migrate_one() {
  local label=$1 log="$LOGS/migrate-$1.log" applied
  shift
  if ! (cd "$BACK" && "$PY" manage.py "$@") > "$log" 2>&1; then
    echo "   ❌ $label: falló la migración. Últimas líneas ($log):"
    tail -15 "$log" | sed 's/^/      /'
    return 1
  fi
  applied=$(grep -c "Applying" "$log")
  if [ "$applied" -gt 0 ]; then echo "   ✓ $label: $applied migraciones aplicadas"; else echo "   ✓ $label: al día"; fi
}

if [ "$MIGRATE" = 1 ]; then
  echo "-> Migraciones"
  migrate_one control migrate --noinput || exit 1
  for code in $(cd "$BACK" && "$PY" manage.py tenants list 2> /dev/null | awk '{print $2}'); do
    migrate_one "$code" tenants migrate "$code" || exit 1
  done
fi

# --- Arranque -----------------------------------------------------------------

# Cada servicio va en su propio grupo de procesos (setsid): al apagar se mata el
# grupo entero, hijos incluidos, y no quedan procesos huérfanos con el puerto.
stop() {
  local name=$1 pid=$2 _
  [ -n "$pid" ] && kill -0 -- "-$pid" 2> /dev/null || return 0
  echo "   deteniendo $name..."
  kill -TERM -- "-$pid" 2> /dev/null
  for _ in $(seq 1 20); do kill -0 -- "-$pid" 2> /dev/null || return 0; sleep 0.25; done
  kill -KILL -- "-$pid" 2> /dev/null
}

cleanup() {
  local status=${1:-0}
  trap - EXIT INT TERM HUP
  echo
  echo "🛑 Apagando servicios..."
  stop Cloudflared "$CLOUD_PID"
  stop Frontend "$FRONT_PID"
  stop Backend "$BACK_PID"
  echo "✅ Todo detenido."
  exit "$status"
}
trap 'cleanup 0' INT TERM HUP
trap 'cleanup $?' EXIT

# Espera a que el servicio responda; si su proceso muere antes, lo dice.
wait_http() {
  local name=$1 pid=$2 url=$3
  for _ in $(seq 1 60); do
    curl -s -o /dev/null --max-time 1 "$url" && return 0
    kill -0 -- "-$pid" 2> /dev/null || { echo "❌ $name se cerró al arrancar (mira el error arriba)."; return 1; }
    sleep 0.5
  done
  echo "❌ $name no respondió en 30 s (mira el error arriba)."
  return 1
}

echo "-> Backend: Django en 127.0.0.1:$BACK_PORT"
cd "$BACK"
setsid "$PY" manage.py runserver "127.0.0.1:$BACK_PORT" &
BACK_PID=$!
wait_http Backend "$BACK_PID" "http://127.0.0.1:$BACK_PORT/" || exit 1

echo "-> Frontend: Vite en 127.0.0.1:$FRONT_PORT → API en :$BACK_PORT"
cd "$FRONT"
# --strictPort: si el puerto se ocupa, Vite falla en vez de saltar al siguiente
# y dejar el túnel apuntando a otro servidor.
VITE_API_PROXY="http://127.0.0.1:$BACK_PORT" setsid ./node_modules/.bin/vite \
  --host 127.0.0.1 --port "$FRONT_PORT" --strictPort &
FRONT_PID=$!
wait_http Frontend "$FRONT_PID" "http://127.0.0.1:$FRONT_PORT/" || exit 1

TUNNEL_URL=""
if [ "$TUNNEL" = 1 ]; then
  echo "-> Túnel cloudflared (registro en $LOGS/cloudflared.log)"
  setsid cloudflared tunnel --url "http://127.0.0.1:$FRONT_PORT" --http-host-header 127.0.0.1 \
    > "$LOGS/cloudflared.log" 2>&1 &
  CLOUD_PID=$!
  for _ in $(seq 1 60); do
    # api.trycloudflare.com sale en los errores; no es la URL del túnel.
    TUNNEL_URL=$(grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' "$LOGS/cloudflared.log" | grep -v '//api\.' | head -1)
    [ -n "$TUNNEL_URL" ] && break
    kill -0 -- "-$CLOUD_PID" 2> /dev/null || break
    sleep 0.5
  done
  [ -n "$TUNNEL_URL" ] || echo "⚠️  El túnel no dio URL; revisa $LOGS/cloudflared.log"
fi

echo "==============================================================="
echo "✅ Todo corriendo."
echo "   App:      http://127.0.0.1:$FRONT_PORT"
echo "   IPSA:     http://ipsa.localhost:$FRONT_PORT"
[ -n "$TUNNEL_URL" ] && echo "   Público:  $TUNNEL_URL"
echo "   API:      http://127.0.0.1:$BACK_PORT/api/"
echo "⌨️  Escribe 'exit' y Enter (o Ctrl+C) para detener todo en orden."
echo "==============================================================="

if [ -t 0 ]; then
  while read -r input; do
    [ "$input" = "exit" ] && break
  done
else
  # Sin terminal (p. ej. lanzado con nohup): sigue hasta recibir una señal.
  wait
fi
