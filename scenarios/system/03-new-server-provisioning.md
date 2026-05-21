# Escenario: Provisionamiento inicial de servidor

## Problema

Acabas de recibir un servidor nuevo (VPS, dedicado, o instancia cloud) con acceso root por contraseña. Necesitas asegurarlo, configurarlo y dejarlo listo para producción siguiendo las mejores prácticas.

Este es el **workflow inicial de todo sysadmin**. Cada paso está explicado con su propósito.

## Pipeline completo (paso a paso)

### Paso 1: Primer acceso como root

```bash
# Conectar por SSH con contraseña (la que te dio el proveedor)
ssh root@IP_DEL_SERVIDOR
```

### Paso 2: Actualizar el sistema

```bash
# Debian/Ubuntu
apt update && apt upgrade -y

# RHEL/CentOS/AlmaLinux/Rocky
dnf update -y
```

**¿Por qué?** El sistema recién instalado puede tener vulnerabilidades conocidas (CVEs) que ya están parcheadas en versiones más recientes.

### Paso 3: Crear usuario administrador

```bash
# Crear usuario con sudo y bash
useradd -m -s /bin/bash admin
passwd admin

# Agregar al grupo sudo (Debian/Ubuntu)
usermod -aG sudo admin

# RHEL/CentOS
usermod -aG wheel admin

# Verificar
sudo -l -U admin
```

**¿Por qué no usar root directamente?**
- root tiene acceso total: cualquier error es catastrófico
- Los logs distinguen entre `admin` y `root`
- Las auditorías de seguridad penalizan el login root directo

### Paso 4: Configurar clave pública SSH

```bash
# Desde tu máquina local (NO desde el servidor)
cat ~/.ssh/id_ed25519.pub | ssh root@IP_DEL_SERVIDOR "mkdir -p ~admin/.ssh && tee -a ~admin/.ssh/authorized_keys"

# En el servidor, corregir permisos
ssh root@IP_DEL_SERVIDOR "chown -R admin:admin ~admin/.ssh && chmod 700 ~admin/.ssh && chmod 600 ~admin/.ssh/authorized_keys"
```

### Paso 5: Probar acceso por clave

```bash
# Desde tu máquina local, en OTRA terminal (no cierres la sesión root)
ssh admin@IP_DEL_SERVIDOR
```

> Deja la sesión root abierta hasta confirmar que admin funciona con clave.

### Paso 6: Hardening SSH

```bash
# Editar /etc/ssh/sshd_config
# (hacer backup primero)
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#\?MaxAuthTries.*/MaxAuthTries 3/' /etc/ssh/sshd_config
sed -i 's/^#\?ClientAliveInterval.*/ClientAliveInterval 300/' /etc/ssh/sshd_config
sed -i 's/^#\?ClientAliveCountMax.*/ClientAliveCountMax 2/' /etc/ssh/sshd_config

# Añadir whitelist de usuarios
echo "AllowUsers admin" >> /etc/ssh/sshd_config

# Verificar sintaxis
sshd -t

# Si dice OK, recargar
systemctl reload sshd
```

**¿Qué hace cada cambio?**

| Directiva | Efecto |
|-----------|--------|
| `PermitRootLogin no` | Nadie puede loguearse como root por SSH |
| `PasswordAuthentication no` | Solo se aceptan claves, no contraseñas |
| `PubkeyAuthentication yes` | Activar autenticación por clave pública |
| `MaxAuthTries 3` | Máximo 3 intentos de autenticación |
| `ClientAliveInterval 300` | Desconectar sesiones inactivas tras 5min sin respuesta |
| `AllowUsers admin` | Solo admin puede hacer SSH (los demás usuarios no) |

### Paso 7: Configurar firewall

```bash
# Con ufw (Uncomplicated Firewall) — Ubuntu/Debian
ufw default deny incoming
ufw default allow outgoing

# Permitir SSH desde TU IP
ufw allow from TU_IP_PUBLICA to any port 22 proto tcp

# Permitir servicios web (si aplica)
ufw allow 80/tcp
ufw allow 443/tcp

# Activar
ufw enable

# Ver estado
ufw status verbose
```

```bash
# Con iptables
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Loopback
iptables -A INPUT -i lo -j ACCEPT

# Conexiones establecidas
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# SSH solo desde tu IP
iptables -A INPUT -p tcp --dport 22 -s TU_IP_PUBLICA -j ACCEPT

# HTTP/HTTPS (si aplica)
iptables -A INPUT -p tcp -m multiport --dports 80,443 -j ACCEPT

# Guardar reglas
apt install iptables-persistent
netfilter-persistent save
```

### Paso 8: Fail2ban (protección contra fuerza bruta)

```bash
apt install fail2ban -y

# Configuración
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh
logpath = %(sshd_log)s
EOF

systemctl restart fail2ban
fail2ban-client status sshd
```

### Paso 9: Instalar herramientas esenciales

```bash
# Esenciales para cualquier servidor
apt install -y \
  htop iotop iftop \
  net-tools dnsutils traceroute mtr \
  curl wget git \
  vim \
  tcpdump nmap \
  unattended-upgrades \
  logwatch

# Configurar actualizaciones automáticas de seguridad
dpkg-reconfigure --priority=low unattended-upgrades
```

### Paso 10: Configurar NTP (hora exacta)

```bash
# Verificar zona horaria
timedatectl set-timezone Europe/Madrid
timedatectl set-ntp true
timedatectl status
```

### Paso 11: Verificar y reiniciar

```bash
# Verificar que todo está bien
echo "=== USUARIOS CON SUDO ==="
getent group sudo

echo ""
echo "=== SSH CONFIG ==="
sshd -T | grep -E "permitrootlogin|passwordauthentication|pubkeyauthentication|maxauthtries|allowusers"

echo ""
echo "=== PUERTOS ABIERTOS ==="
ss -tuln

echo ""
echo "=== FIREWALL ==="
ufw status verbose 2>/dev/null || iptables -L -n

echo ""
echo "=== FAIL2BAN ==="
fail2ban-client status sshd 2>/dev/null

echo ""
echo "=== ACTUALIZACIONES PENDIENTES =="
apt list --upgradable 2>/dev/null
```

### Paso 12: Probar desde tu máquina

```bash
# Desde tu máquina local (WSL2/Linux/Mac)
ssh admin@IP_DEL_SERVIDOR

# Verificar que root está bloqueado
ssh root@IP_DEL_SERVIDOR
# Permission denied (publickey). ← Correcto

# Probar comando remoto
ssh admin@IP_DEL_SERVIDOR "uptime && free -h && df -h"
```

## Script completo de provisionamiento

```bash
#!/bin/bash
# provision.sh — Ejecutar en el servidor como root
# Uso: curl -sL https://raw.githubusercontent.com/.../provision.sh | bash

set -e

echo "=== Provisionando servidor ==="

# 1. Variables
ADMIN_USER="admin"
SSH_PORT="22"
SSH_KEY_URL="https://github.com/TU_USUARIO.keys"  # Tus claves públicas en GitHub

# 2. Actualizar
apt update && apt upgrade -y

# 3. Crear usuario
useradd -m -s /bin/bash "$ADMIN_USER"
usermod -aG sudo "$ADMIN_USER"
passwd -l "$ADMIN_USER"  # Bloquear contraseña (solo clave)

# 4. Configurar clave SSH
mkdir -p /home/$ADMIN_USER/.ssh
curl -sL "$SSH_KEY_URL" >> /home/$ADMIN_USER/.ssh/authorized_keys
chown -R $ADMIN_USER:$ADMIN_USER /home/$ADMIN_USER/.ssh
chmod 700 /home/$ADMIN_USER/.ssh
chmod 600 /home/$ADMIN_USER/.ssh/authorized_keys

# 5. Hardening SSH
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
echo "AllowUsers $ADMIN_USER" >> /etc/ssh/sshd_config
sshd -t && systemctl reload sshd

# 6. Firewall
ufw default deny incoming
ufw default allow outgoing
ufw allow from any to any port $SSH_PORT proto tcp
ufw --force enable

# 7. Fail2ban
apt install -y fail2ban
systemctl start fail2ban

# 8. Herramientas
apt install -y htop curl wget git vim net-tools dnsutils traceroute mtr tcpdump unattended-upgrades

# 9. NTP
timedatectl set-ntp true

echo ""
echo "=== PROVISIONAMIENTO COMPLETO ==="
echo "Usuario: $ADMIN_USER"
echo "Root login: deshabilitado"
echo "SSH contraseña: deshabilitada"
echo "Firewall: activo"
echo ""
echo "Cerrar sesión root y probar:"
echo "  ssh $ADMIN_USER@IP_DEL_SERVIDOR"
```

## Verificación post-provisionamiento

```bash
# Test rápido de seguridad
ssh admin@IP_DEL_SERVIDOR "
  echo '→ Puerto SSH:'; ss -tlnp | grep :22
  echo '→ Root login:'; grep PermitRootLogin /etc/ssh/sshd_config
  echo '→ Clave pública:'; wc -l ~/.ssh/authorized_keys
  echo '→ Fail2ban:'; fail2ban-client status sshd | grep -c 'Total banned'
  echo '→ Actualizaciones:'; apt list --upgradable 2>/dev/null | wc -l
"
```

## Checkpoint: servidor listo

Después de este proceso tienes un servidor:
- Sin acceso root por SSH
- Solo autenticación por clave pública
- Firewall bloqueando todo excepto SSH (desde cualquier IP o la tuya)
- Fail2ban protegiendo contra fuerza bruta
- Actualizaciones de seguridad automáticas
- Hora sincronizada vía NTP
- Herramientas de diagnóstico instaladas

Ahora puedes usar el resto de guías y escenarios del repo para administrarlo.

## Comandos relacionados

- [`ssh.md`](../../guides/ssh.md) — configuración detallada de SSH
- [`iptables.md`](../../guides/iptables.md) — firewall
- [`systemd_journalctl.md`](../../guides/systemd_journalctl.md) — gestión de servicios
