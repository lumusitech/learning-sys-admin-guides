#!/bin/sh
# ssh-setup.sh — Configura SSH en el contenedor monitoring
# Acepta clave pública por variable de entorno o por archivo montado

set -e

SSH_DIR="/home/admin/.ssh"

# Si se montó una clave pública, usarla (priorizar ed25519, luego rsa)
if [ -f /config/ssh-key.pub ]; then
    cp /config/ssh-key.pub "$SSH_DIR/authorized_keys"
elif [ -f /config/ssh-key-rsa.pub ]; then
    cp /config/ssh-key-rsa.pub "$SSH_DIR/authorized_keys"
elif [ -n "$PUBLIC_KEY" ]; then
    echo "$PUBLIC_KEY" > "$SSH_DIR/authorized_keys"
else
    # Generar una clave para el usuario admin si no hay clave externa
    ssh-keygen -t ed25519 -f "$SSH_DIR/id_ed25519" -N "" -q
    cp "$SSH_DIR/id_ed25519.pub" "$SSH_DIR/authorized_keys"
    echo ""
    echo "=== No se montó clave SSH. Se generó una interna. ==="
    echo "=== Para conectarse: docker exec -it monitoring bash ==="
    echo ""
fi

chmod 600 "$SSH_DIR/authorized_keys"
chown -R admin:admin "$SSH_DIR"

# Configurar password para admin
echo "admin:admin123" | chpasswd

echo ""
echo "=== Contenedor monitoring listo ==="
echo "=== SSH: ssh admin@localhost -p <puerto> ==="
echo "=== Tools: ps, top, vmstat, iostat, curl, tcpdump, dig, ss ==="
echo ""

exec /usr/sbin/sshd -D
