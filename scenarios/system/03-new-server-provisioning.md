# 🧩 Escenario: Provisionamiento inicial de servidor

**Dominio:** system / infrastructure
**Nivel:** 🟡 Intermedio
**Herramientas:** `ssh`, `ufw`/`iptables`, `systemctl`, `sed`, `fail2ban`, `timedatectl`
**Archivos:** Servidor remoto (VPS/cloud)

**Quick command (SRE):** `ssh -o BatchMode=yes -o ConnectTimeout=5 ADMIN@HOST 'hostname; uptime; sudo systemctl --no-pager --failed || true; sudo ss -tuln | head -20'`

**Quick command (original):** `ssh root@IP && apt update && apt upgrade -y && useradd -m -s /bin/bash admin && usermod -aG sudo admin`

**Cuándo usar este escenario:**
- Acabas de recibir un servidor nuevo (VPS, cloud)
- Necesitas asegurarlo antes de ponerlo en producción
- Quieres automatizar el hardening inicial

**Archivo(s) de práctica:** no aplica (producción)

---

## 🎯 Objetivo

1. Asegurar un servidor nuevo desde el primer acceso root por contraseña.
2. Configurar SSH hardening, firewall, fail2ban y actualizaciones automáticas.
3. Dejar el servidor listo para producción en producción.

---

## 🧠 Contexto

Acabas de recibir un servidor nuevo (VPS, dedicado o instancia cloud) con acceso root por contraseña. Está en su estado más vulnerable. Hay que asegurarlo antes de desplegar cualquier aplicación.

---

## ✅ Datos de entrada

- **Producción:** Servidor remoto con IP pública y acceso root por SSH
- **Práctica:** Docker container `from-scratch/ubuntu-bare` (simula servidor nuevo)

---

## ⚡ Quick run (hardening automatizado)

```bash
# Descargar y ejecutar script de provisionamiento
curl -sL https://raw.githubusercontent.com/lumusitech/learning-sys-admin-guides/main/scenarios/system/provision.sh | bash
```

---

## 🔍 Paso a paso (Workflow completo)

### 1. Primer acceso

```bash
ssh root@IP_DEL_SERVIDOR
```

### 2. Actualizar sistema

```bash
apt update && apt upgrade -y
```

### 3. Crear usuario administrador

```bash
useradd -m -s /bin/bash admin
passwd admin
usermod -aG sudo admin  # Debian/Ubuntu
```

**¿Por qué no root?** Root tiene acceso total. Un error con root puede romper todo. Los logs de auditoría distinguen usuarios.

### 4. Configurar clave SSH

```bash
# Desde tu máquina local
cat ~/.ssh/id_ed25519.pub | ssh root@IP "mkdir -p ~admin/.ssh && tee -a ~admin/.ssh/authorized_keys"
ssh root@IP "chown -R admin:admin ~admin/.ssh && chmod 700 ~admin/.ssh && chmod 600 ~admin/.ssh/authorized_keys"
```

### 5. Probar acceso por clave (NO cerrar sesión root)

```bash
# Desde OTRA terminal
ssh admin@IP_DEL_SERVIDOR
```

### 6. Hardening SSH

```bash
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#\?MaxAuthTries.*/MaxAuthTries 3/' /etc/ssh/sshd_config
echo "AllowUsers admin" >> /etc/ssh/sshd_config
sshd -t && systemctl reload sshd
```

### 7. Firewall

```bash
ufw default deny incoming
ufw default allow outgoing
ufw allow from TU_IP to any port 22 proto tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable
```

### 8. Fail2ban

```bash
apt install -y fail2ban
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT] bantime=3600; findtime=600; maxretry=3
[sshd] enabled=true
EOF
systemctl restart fail2ban
```

### 9. NTP y zona horaria

```bash
timedatectl set-timezone Europe/Madrid
timedatectl set-ntp true
```

### 10. Verificación final

```bash
echo "=== USUARIOS CON SUDO ===" && getent group sudo
echo "=== SSH CONFIG ===" && sshd -T | grep -E "permitrootlogin|passwordauthentication"
echo "=== PUERTOS ===" && ss -tuln
echo "=== FIREWALL ===" && ufw status verbose
echo "=== FAIL2BAN ===" && fail2ban-client status sshd
```

---

## ✅ Salida esperada (servidor listo)

```
- Sin acceso root por SSH
- Solo claves públicas
- Firewall bloqueando todo excepto SSH (desde tu IP) + web
- Fail2ban activo
- Hora sincronizada
- Actualizaciones de seguridad automáticas
```

---

## Script completo

```bash
#!/bin/bash
# provision.sh — Ejecutar como root en servidor nuevo
set -e

ADMIN_USER="admin"
SSH_KEY_URL="https://github.com/TU_USUARIO.keys"

apt update && apt upgrade -y
useradd -m -s /bin/bash "$ADMIN_USER" && usermod -aG sudo "$ADMIN_USER" && passwd -l "$ADMIN_USER"
mkdir -p /home/$ADMIN_USER/.ssh && curl -sL "$SSH_KEY_URL" >> /home/$ADMIN_USER/.ssh/authorized_keys
chown -R $ADMIN_USER:$ADMIN_USER /home/$ADMIN_USER/.ssh && chmod 700 /home/$ADMIN_USER/.ssh && chmod 600 /home/$ADMIN_USER/.ssh/authorized_keys

sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
echo "AllowUsers $ADMIN_USER" >> /etc/ssh/sshd_config && sshd -t && systemctl reload sshd

ufw default deny incoming && ufw default allow outgoing
ufw allow 22/tcp && ufw --force enable
apt install -y fail2ban && systemctl enable --now fail2ban
apt install -y htop curl wget git vim net-tools dnsutils traceroute mtr tcpdump unattended-upgrades
timedatectl set-ntp true

echo "=== PROVISIONAMIENTO COMPLETO ==="
echo "Usuario: $ADMIN_USER | Root login: no | Firewall: activo"
```

---

## 🧯 Mitigación (si algo sale mal)

```bash
# Perdiste acceso?
# Usar consola del proveedor cloud (VNC/IPMI)
# O restaurar snapshot/backup
# Revisar: ¿cambiaste PermitRootLogin antes de probar admin?
# ¿Bloqueaste tu IP en ufw?
```

### Rollback rápido

```bash
# Restaurar backup de sshd_config
cp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config && systemctl reload sshd

# Resetear ufw
ufw --force reset && ufw enable
```

---

## 🛡️ Prevención

- [ ] Guardar el script de provisionamiento en Git
- [ ] Probar en Docker antes de aplicar en producción
- [ ] Tener consola de recovery del proveedor
- [ ] Documentar IPs permitidas en firewall
- [ ] Backup de sshd_config antes de cambiarlo

---

## 🧪 Cómo practicarlo en el lab

```bash
cd labs && docker compose -f docker-compose.from-scratch.yml up -d ubuntu-bare
# El contenedor simula un servidor nuevo con SSH por password
ssh practica@localhost -p 2201  # password: practica123
# Aplicar todos los pasos de hardening dentro del contenedor
```

[Ver laboratorio completo →](../../labs/README.md)

---

## 🔗 Referencias

- [`guides/ssh.md`](../../guides/ssh.md) — hardening SSH detallado
- [`guides/iptables.md`](../../guides/iptables.md) — firewall
- [`guides/systemd_journalctl.md`](../../guides/systemd_journalctl.md) — gestión de servicios
- [`guides/production_server.md`](../../guides/production_server.md) — servidor en producción
- [`concepts/how-to-think-like-sysadmin.md`](../../concepts/how-to-think-like-sysadmin.md) — checklist mental
