#!/bin/bash
# Instalador automático InterProxy Panel desde GitHub
# Ejecuta todo: Node.js, PM2, dependencias, Prisma, firewall y levanta el panel

set -e

# --- CONFIGURACIÓN ---
GITHUB_REPO="https://github.com/interkingvpn/InterProxy.git"
PANEL_DIR="$HOME/InterProxy"
PORT=3000

# --- FUNCIONES ---
check_command() {
    command -v "$1" >/dev/null 2>&1
}

# --- CLONAR O ACTUALIZAR REPO ---
if [ ! -d "$PANEL_DIR" ]; then
    echo ">>> Clonando InterProxy desde GitHub..."
    git clone "$GITHUB_REPO" "$PANEL_DIR"
else
    echo ">>> Actualizando proyecto existente..."
    cd "$PANEL_DIR"
    git pull
fi

cd "$PANEL_DIR"

# --- INSTALAR NODE.JS 18 ---
if ! check_command node; then
    echo ">>> Instalando Node.js 18..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs build-essential
fi

# --- INSTALAR PM2 ---
if ! check_command pm2; then
    echo ">>> Instalando PM2..."
    npm install -g pm2
fi

# --- INSTALAR DEPENDENCIAS ---
echo ">>> Instalando dependencias del panel..."
npm install

# --- BORRAR DB ANTIGUA (SQLite) ---
echo ">>> Eliminando base de datos antigua..."
rm -f database.db

# --- CONFIGURAR PRISMA ---
if [ -f "./prisma/schema.prisma" ]; then
    echo ">>> Generando cliente Prisma y aplicando migraciones..."
    npx prisma generate
    npx prisma migrate deploy
fi

# --- LEVANTAR PANEL ---
if [ -f "ecosystem.config.js" ]; then
    echo ">>> Levantando el panel con PM2..."
    pm2 start ecosystem.config.js --name "InterProxy" || pm2 restart InterProxy
    pm2 save
    pm2 startup -y
fi

# --- ABRIR PUERTO EN FIREWALL ---
ufw allow "$PORT"/tcp || true

# --- MOSTRAR INFO FINAL ---
PUBLIC_IP=$(curl -s ifconfig.me || echo "localhost")
echo "✅ Instalación completa!"
echo "Accede al panel en: http://$PUBLIC_IP:$PORT"