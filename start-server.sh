#!/bin/bash

echo "🚀 Iniciando entorno de desarrollo..."

# 1. Iniciar Backend en segundo plano
echo "-> Iniciando Backend (Django en puerto 8010)..."
cd ~/Documentos/github/predictive-back
./.venv/bin/python manage.py runserver 127.0.0.1:8010 &
BACK_PID=$!

# 2. Iniciar Frontend en segundo plano
echo "-> Iniciando Frontend (Vite en puerto 5174)..."
cd ~/Documentos/github/predictive-front
VITE_PORT=5174 VITE_API_PROXY=http://127.0.0.1:8010 npx vite --host 127.0.0.1 &
FRONT_PID=$!

# Esperar un par de segundos para asegurar que el puerto del front esté listo
sleep 2

# 3. Iniciar Cloudflared en segundo plano
echo "-> Iniciando túnel de Cloudflared..."
cloudflared tunnel --url http://127.0.0.1:5174 &
CLOUD_PID=$!

# Función para detener los servicios en el orden solicitado
cleanup() {
    echo -e "\n🛑 Apagando servicios..."

    echo "(1/3) Deteniendo Cloudflared (PID: $CLOUD_PID)..."
    kill $CLOUD_PID 2>/dev/null
    
    echo "(2/3) Deteniendo Frontend (PID: $FRONT_PID)..."
    kill $FRONT_PID 2>/dev/null
    
    echo "(3/3) Deteniendo Backend (PID: $BACK_PID)..."
    kill $BACK_PID 2>/dev/null

    echo "✅ Todos los servicios se cerraron correctamente."
    exit 0
}

# Capturar también Ctrl+C por si decides cerrarlo con el teclado en lugar de escribir 'exit'
trap cleanup SIGINT SIGTERM

echo "==============================================================="
echo "✅ Todos los procesos están corriendo en esta terminal."
echo "⌨️  Escribe 'exit' y presiona Enter para detener todo en orden."
echo "==============================================================="

# Bucle infinito leyendo la entrada del usuario en la terminal
while read -r input; do
    if [[ "$input" == "exit" ]]; then
        cleanup
    fi
done
