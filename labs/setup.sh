#!/bin/sh
# setup.sh — Prepara el entorno de labs
# Ejecutar una vez antes de levantar los labs

set -e

LABS_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Setup de labs ==="

# Generar clave SSH para los labs si no existe
if [ ! -f "$LABS_DIR/ssh-key.pub" ]; then
    echo "Generando clave SSH para los labs..."
    ssh-keygen -t ed25519 -f "$LABS_DIR/ssh-key" -N "" -q
    cp "$LABS_DIR/ssh-key.pub" "$LABS_DIR/ssh-key.pub"
    echo "Clave generada: $LABS_DIR/ssh-key.pub"
    echo ""
    echo "Para conectarte por SSH, usa:"
    echo "  ssh -i $LABS_DIR/ssh-key admin@localhost -p 2222"
    echo ""
else
    echo "Clave SSH ya existe: $LABS_DIR/ssh-key.pub"
fi

# Verificar que Docker está disponible
if ! command -v docker >/dev/null 2>&1; then
    echo "ERROR: Docker no está instalado"
    exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
    echo "ERROR: Docker Compose no está disponible"
    exit 1
fi

echo ""
echo "=== Setup completo ==="
echo ""
echo "Lab base:        docker compose up -d"
echo "Lab rotos:       docker compose -f docker-compose.broken.yml up -d"
echo "Lab red:         docker compose -f docker-compose.network.yml up -d"
echo "Lab seguridad:  docker compose -f docker-compose.security.yml up -d"
echo "Lab desde cero: docker compose -f docker-compose.from-scratch.yml up -d --build"
echo ""
echo "Ver README.md para más detalles"
