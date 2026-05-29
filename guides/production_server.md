# Servidor de producción — Guía completa

**Nivel:** 🔴 Avanzado
**Archivos de práctica:** `labs/docker-compose.from-scratch.yml`
**Ver escenarios relacionados:** [`system/03-provisioning`](../scenarios/system/03-new-server-provisioning.md), [`infrastructure/01-migrate`](../scenarios/infrastructure/01-migrate-to-production.md)

## ⚡ Quick command

`sysctl net.ipv4.tcp_syncookies=1`

## ⚡ Quick run

```bash
sysctl net.ipv4.tcp_syncookies=1 && ulimit -n 65536
```

---

## 📑 Índice

1. [Sysctl tuning del kernel](#sysctl)
2. [Límites de recursos (ulimits)](#ulimits)
3. [Swap: configuración y ajuste](#swap)
4. [Logrotate: rotación de logs](#logrotate)
5. [Systemd resource control](#systemd-resource)
6. [Monitoreo básico](#monitoreo)
7. [Docker en producción](#docker-prod)
8. [Hardening post-instalación](#hardening)
9. [Time sync (NTP)](#ntp)
10. [Fail2ban: protección contra fuerza bruta](#fail2ban)
11. [Escenarios reales](#escenarios)

---

## 🧠 ¿Qué es un servidor de producción?

Un servidor de producción es el entorno donde corren aplicaciones y servicios que usuarios reales consumen. A diferencia de un entorno de desarrollo, requiere hardening, monitoreo, límites de recursos, backups y tolerancia a fallos.

---

## Sysctl tuning del kernel

El kernel de Linux tiene cientos de parámetros ajustables. Aquí los más importantes para un servidor de producción.

### Parámetros de red

```bash
# /etc/sysctl.d/99-network.conf

# Buffer máximo de conexiones esperando aceptación
net.core.somaxconn = 1024

# Conexiones backlog para SYN (defensa contra SYN flood)
net.ipv4.tcp_max_syn_backlog = 4096

# Reutilizar TIME_WAIT sockets para nuevas conexiones
net.ipv4.tcp_tw_reuse = 1

# Rango de puertos efímeros (por defecto 32768-60999)
net.ipv4.ip_local_port_range = 1024 65535

# Buffer de socket (lectura/escritura) — aumentar para servidores web
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 131072 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216

# Habilitar TCP Fast Open (3-way handshake rápido)
net.ipv4.tcp_fastopen = 3

# Keepalive
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 5

# SYN cookies (protección contra SYN flood)
net.ipv4.tcp_syncookies = 1

# Timeout de FIN
net.ipv4.tcp_fin_timeout = 15
```

### Parámetros de seguridad de red

```bash
# /etc/sysctl.d/99-security.conf

# No reenviar tráfico (si no es router)
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0

# No responder a broadcasts
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Ignorar ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv6.conf.all.accept_redirects = 0

# Ignorar pings de router solicitation
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0

# Proteger contra IP spoofing
net.ipv4.conf.all.rp_filter = 1

# Log martian packets (paquetes con IPs imposibles)
net.ipv4.conf.all.log_martians = 1
```

### Parámetros de memoria

```bash
# /etc/sysctl.d/99-memory.conf

# VM swappiness (0-100, bajo = menos swap)
vm.swappiness = 10

# VFS cache pressure (a qué velocidad el kernel reclama cache)
vm.vfs_cache_pressure = 50

# Min free memory (en páginas)
vm.min_free_kbytes = 65536

# Ratio dirty pages antes de sincronizar
vm.dirty_ratio = 20
vm.dirty_background_ratio = 5
```

### Aplicar cambios

```bash
# Aplicar todos los sysctl
sudo sysctl --system

# Probar un parámetro sin reiniciar
sudo sysctl -w net.ipv4.tcp_syncookies=1

# Ver valor actual
sysctl net.ipv4.tcp_syncookies
```

---

## Límites de recursos (ulimits)

Los procesos del sistema tienen límites de recursos. Aumentarlos evita errores como "too many open files".

### Ver límites actuales

```bash
# Usuario actual
ulimit -a

# Proceso específico
cat /proc/PID/limits

# Límite del sistema
cat /proc/sys/fs/file-max
```

### Configuración global

```bash
# /etc/security/limits.conf
# formato: <dominio> <tipo> <item> <valor>

# Aumentar límite de archivos abiertos para todos los usuarios
*        soft    nofile    65536
*        hard    nofile    1048576

# Aumentar procesos máximos
*        soft    nproc     65536
*        hard    nproc     65536

# Stack size (útil para aplicaciones pesadas)
*        soft    stack     16384
*        hard    stack     16384
```

### Configuración por servicio (systemd)

```bash
# /etc/systemd/system.conf
DefaultLimitNOFILE=65536
DefaultLimitNPROC=65536

# Por servicio
# /etc/systemd/system/myapp.service.d/limits.conf
[Service]
LimitNOFILE=65536
LimitNPROC=65536
```

### Verificar límites en un proceso

```bash
# Nginx
cat /proc/$(pgrep -x nginx | head -1)/limits | grep "open files"

# PostgreSQL
cat /proc/$(pgrep -x postgres)/limits | grep "open files"
```

---

## Swap

### Ver uso de swap

```bash
swapon --show
free -h
```

### Crear archivo swap

```bash
# Crear archivo de 4 GB
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Permanente
echo "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab
```

### Swap recomendado por uso

| Rol del servidor | Swap recomendado |
|-----------------|-------------------|
| Escritorio/Dev | 2x RAM |
| Servidor web | 2 GB o 1x RAM (el menor) |
| Base de datos | 4 GB fijo (o swap solo para kernel crash dumps) |
| Servidor crítico | 4 GB fijo + vm.swappiness=1 |

### swapoff para liberar

```bash
# Migrar páginas swap de vuelta a RAM (requiere RAM libre)
sudo swapoff -a

# Reactivar
sudo swapon -a
```

---

## Logrotate

Los logs pueden llenar el disco si no se rotan.

### Configuración básica

```bash
# /etc/logrotate.conf
# Config global
weekly
rotate 4
create
compress
delaycompress
missingok
notifempty

# Incluir configs de aplicaciones
include /etc/logrotate.d
```

### Ejemplo por aplicación

```bash
# /etc/logrotate.d/nginx
/var/log/nginx/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 www-data adm
    sharedscripts
    postrotate
        [ -f /var/run/nginx.pid ] && kill -USR1 $(cat /var/run/nginx.pid)
    endscript
}
```

```bash
# /etc/logrotate.d/myapp
/var/log/myapp/*.log {
    daily
    rotate 30
    compress
    maxsize 100M
    missingok
    notifempty
    dateext
    dateformat -%Y%m%d-%s
    postrotate
        systemctl reload myapp || true
    endscript
}
```

### Forzar rotación

```bash
# Simular rotación (dry-run)
sudo logrotate -d /etc/logrotate.conf

# Forzar rotación ahora
sudo logrotate -f /etc/logrotate.conf

# Rotar un log específico
sudo logrotate -f /etc/logrotate.d/nginx
```

### Verificar estado

```bash
# Última rotación
cat /var/lib/logrotate/status | grep nginx

# Logs rotados
ls -lh /var/log/nginx/
```

---

## Systemd resource control

### Limitar CPU

```bash
# /etc/systemd/system/myapp.service
[Service]
# % de un core (200 = 2 cores)
CPUQuota=200%

# Peso relativo de CPU (100-10000, default 1000)
CPUShares=512
```

### Limitar memoria

```bash
# /etc/systemd/system/myapp.service
[Service]
# Memoria máxima (absoluta)
MemoryMax=1G

# Memoria alta (empieza a presionar antes de llegar al máximo)
MemoryHigh=768M

# Swap máximo
MemorySwapMax=512M
```

### Limitar disco (IO)

```bash
# /etc/systemd/system/myapp.service
[Service]
# Peso IO (100-10000, default 100)
IOWeight=200

# IO máximo (bytes por segundo)
IOReadBandwidthMax=/var/log 10M
IOWriteBandwidthMax=/var/log 10M

# IO máximo (operaciones por segundo)
IOReadIOPSMax=/var/data 1000
IOWriteIOPSMax=/var/data 500
```

### Tasks máximos

```bash
# /etc/systemd/system/myapp.service
[Service]
# Número máximo de tareas/threads (protege contra fork bomb de app)
TasksMax=500
```

### Aislar en su propio cgroup

```bash
# /etc/systemd/system/myapp.service
[Service]
# Asignar slice separado
Slice=myapp.slice
```

### Ver uso de recursos por servicio

```bash
# Vista general
systemd-cgtop

# Estadísticas de un servicio
systemd-cgls myapp
systemctl show myapp -p MemoryCurrent
systemctl show myapp -p CPUUsageNSec
```

---

## Monitoreo básico

### top/htop

```bash
# top — teclas útiles:
#   P: ordenar por CPU
#   M: ordenar por memoria
#   k: matar proceso
#   1: ver todos los cores
#   u: filtrar por usuario
#   H: ver threads individuales

# htop (más amigable)
sudo apt install -y htop
htop
```

### Ver procesos por consumo

```bash
# Top 10 procesos por CPU (formato amigable)
ps aux --sort=-%cpu | head -11

# Top 10 procesos por memoria
ps aux --sort=-%mem | head -11

# Procesos con más archivos abiertos
lsof | awk '{print $1}' | sort | uniq -c | sort -rn | head -10

# Procesos con más conexiones de red
ss -tunp | awk '{print $6}' | sort | uniq -c | sort -rn | head -10
```

### Monitoreo de disco

```bash
# IO por proceso
iotop -oP

# IO por dispositivo
iostat -x 2

# Latencia de disco (await, svctm)
iostat -x -d 1

# Espacio usado
df -h

# Inodos usados
df -i

# Directorios más grandes
du -sh /* 2>/dev/null | sort -rh | head -10
```

### Monitoreo de red

```bash
# Conexiones por estado
ss -tan | awk '{print $1}' | sort | uniq -c

# Conexiones por puerto
ss -tan | awk '{print $4}' | sort | uniq -c | sort -rn

# Tráfico por interfaz
vnstat -i eth0 -h

# Ancho de banda en tiempo real
bmon -p eth0
```

### Alertas básicas con scripts

```bash
#!/bin/bash
# check_load.sh

LOAD=$(uptime | awk -F'load average:' '{print $2}' | cut -d, -f1 | tr -d ' ')
CPUS=$(nproc)
THRESHOLD=$(echo "$CPUS * 0.8" | bc | cut -d. -f1)

if (( $(echo "$LOAD > $THRESHOLD" | bc -l) )); then
    echo "ALERTA: Load average $LOAD > $THRESHOLD en $(hostname)" | \
      mail -s "Load alta en $(hostname)" admin@empresa.com
    
    # También matar proceso más pesado (opcional)
    # ps aux --sort=-%cpu | sed -n '2p' | awk '{print $2}' | xargs kill -9
fi
```

### netdata (monitoreo en tiempo real)

```bash
# Instalación rápida
bash <(curl -Ss https://my-netdata.io/kickstart.sh)

# Acceder en http://servidor:19999
```

---

## Docker en producción

### Instalación

```bash
# Instalar Docker Engine
curl -fsSL https://get.docker.com | sudo bash

# Sin sudo
sudo usermod -aG docker $USER
newgrp docker
```

### Configuración para producción

```bash
# /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "live-restore": true,
  "iptables": false,
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 65536,
      "Soft": 65536
    }
  }
}
```

### Limitar recursos por contenedor

```bash
# Memoria
docker run -d --memory="512m" --memory-swap="1g" nginx

# CPU
docker run -d --cpus="1.5" --cpuset-cpus="0,1" nginx

# IO
docker run -d --device-read-bps=/dev/sda:10mb nginx

# Reinicio automático
docker run -d --restart unless-stopped nginx
```

### Docker compose para producción

```yaml
# docker-compose.yml
version: '3.8'

services:
  web:
    image: nginx:alpine
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./www:/var/www/html:ro
      - ./ssl:/etc/nginx/ssl:ro
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 256M
        reservations:
          cpus: '0.5'
          memory: 128M
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    networks:
      - frontend

  app:
    image: myapp:latest
    restart: unless-stopped
    depends_on:
      - db
    environment:
      - DB_HOST=db
      - DB_USER=myapp
      - DB_PASSWORD=${DB_PASSWORD}
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 512M
    networks:
      - frontend
      - backend

  db:
    image: postgres:15-alpine
    restart: unless-stopped
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - pgdata:/var/lib/postgresql/data
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 1G
    networks:
      - backend

networks:
  frontend:
  backend:

volumes:
  pgdata:
```

### Monitoreo Docker

```bash
# Estadísticas en vivo
docker stats

# Logs de un contenedor
docker logs --tail 50 -f contenedor

# Eventos del daemon
docker events --filter event=oom

# Espacio usado
docker system df

# Limpiar
docker system prune -f
docker image prune -a -f
```

---

## Hardening post-instalación

### SSH hardening

```bash
# /etc/ssh/sshd_config
Port 2222
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
MaxSessions 5
ClientAliveInterval 300
ClientAliveCountMax 2
AllowUsers carludev admin
```

### Firewall básico

```bash
# ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow 2222/tcp    # SSH
ufw allow 80/tcp      # HTTP
ufw allow 443/tcp     # HTTPS
ufw enable

# O iptables mínimas
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p tcp --dport 2222 -j ACCEPT
iptables -A INPUT -p tcp --dport 80,443 -j ACCEPT
```

### Kernel hardening

```bash
# Parámetros de seguridad adicionales
# /etc/sysctl.d/99-hardening.conf
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
kernel.printk = 3 3 3 3
kernel.unprivileged_bpf_disabled = 1
net.core.bpf_jit_harden = 2
```

### Actualizaciones automáticas

```bash
# Solo seguridad
sudo apt install -y unattended-upgrades

# /etc/apt/apt.conf.d/50unattended-upgrades
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
```

### AIDE (detección de intrusiones de archivos)

```bash
sudo apt install -y aide
sudo aideinit
mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db

# Chequear integridad
sudo aide --check

# Programar en cron
echo "0 5 * * * root /usr/bin/aide --check | mail -s 'AIDE report' admin@empresa.com" | sudo tee -a /etc/crontab
```

---

## Time sync (NTP)

### Instalar chrony

```bash
sudo apt install -y chrony

# /etc/chrony/chrony.conf
pool 0.ubuntu.pool.ntp.org iburst
pool 1.ubuntu.pool.ntp.org iburst
pool 2.ubuntu.pool.ntp.org iburst
pool 3.ubuntu.pool.ntp.org iburst

# Permitir que otros servers consulten (opcional)
allow 10.0.0.0/8

# Ver estado
chronyc sources -v
chronyc tracking

# Sincronizar ahora
sudo chronyc -a makestep
```

---

## Fail2ban

Protege contra fuerza bruta en SSH, web, etc.

### Instalación

```bash
sudo apt install -y fail2ban
```

### Configuración

```bash
# /etc/fail2ban/jail.local
[DEFAULT]
# Tiempo de prohibición (1 hora)
bantime = 3600
# Ventana de tiempo (10 min)
findtime = 600
# Intentos máximos antes de prohibir
maxretry = 5
# Ignorar IPs internas
ignoreip = 127.0.0.1/8 10.0.0.0/8 192.168.0.0/16

[sshd]
enabled = true
port = 2222
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 86400  # 1 día para SSH

[nginx-http-auth]
enabled = true
port = http,https
filter = nginx-http-auth
logpath = /var/log/nginx/error.log

[nginx-botsearch]
enabled = true
port = http,https
filter = nginx-botsearch
logpath = /var/log/nginx/access.log
maxretry = 10
```

### Comandos útiles

```bash
# Ver estado
sudo fail2ban-client status
sudo fail2ban-client status sshd

# Ver IPs baneadas
sudo fail2ban-client status sshd | grep "Banned IP list"

# Desbanear IP
sudo fail2ban-client set sshd unbanip 192.168.1.100

# Banear IP manualmente
sudo fail2ban-client set sshd banip 1.2.3.4

# Ver log
sudo tail -f /var/log/fail2ban.log
```

---

## Escenarios

### 1. Puesta a punto de servidor nuevo

```bash
#!/bin/bash
# provision_production.sh — Script completo de hardening inicial

set -e

echo "=== 1. Actualizar sistema ==="
apt update && apt upgrade -y
apt autoremove -y

echo "=== 2. Crear usuario administrador ==="
adduser carludev
usermod -aG sudo carludev

echo "=== 3. SSH hardening ==="
sed -i 's/^#Port 22/Port 2222/' /etc/ssh/sshd_config
sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd

echo "=== 4. Firewall ==="
ufw default deny incoming
ufw default allow outgoing
ufw allow 2222/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

echo "=== 5. Sysctl tuning ==="
cat >> /etc/sysctl.d/99-production.conf <<'EOF'
# Red
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_local_port_range = 1024 65535
net.core.somaxconn = 1024

# Seguridad
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Memoria
vm.swappiness = 10
EOF
sysctl --system

echo "=== 6. Límites ==="
cat >> /etc/security/limits.conf <<'EOF'
* soft nofile 65536
* hard nofile 1048576
EOF

echo "=== 7. Swap ==="
fallocate -l 4G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo "/swapfile none swap sw 0 0" >> /etc/fstab

echo "=== 8. Fail2ban ==="
apt install -y fail2ban
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sed -i 's/^bantime = 10m/bantime = 1h/' /etc/fail2ban/jail.local
systemctl enable --now fail2ban

echo "=== 9. NTP ==="
apt install -y chrony
systemctl enable --now chrony

echo "=== 10. Unattended upgrades (seguridad) ==="
apt install -y unattended-upgrades
dpkg-reconfigure --priority=low unattended-upgrades

echo "=== 11. Logrotate ==="
# Config ya viene con buen default, verificar
logrotate -d /etc/logrotate.conf

echo ""
echo "=== ¡Servidor listo! ==="
echo "SSH: ssh carludev@$(hostname -I | awk '{print $1}') -p 2222"
echo "Pasos siguientes: instalar Docker, desplegar apps, configurar backups"
```

### 2. Docker + app con límites de recursos

```bash
# 1. Limitar memoria del Docker daemon
# /etc/docker/daemon.json
{ "storage-driver": "overlay2", "live-restore": true }

# 2. Contenedores con límites
docker run -d --name web \
  --memory="256M" --cpus="0.5" \
  --restart unless-stopped \
  -p 80:80 \
  nginx:alpine

docker run -d --name app \
  --memory="512M" --cpus="1" \
  --restart unless-stopped \
  --link db:db \
  myapp:latest

docker run -d --name db \
  --memory="1G" --cpus="2" \
  --restart unless-stopped \
  -v pgdata:/var/lib/postgresql/data \
  postgres:15-alpine

# 3. Monitorear
docker stats --no-stream

# 4. Logs con rotación
docker run -d --log-opt max-size=10m --log-opt max-file=3 nginx
```

### 3. Diagnóstico de servidor lento

```bash
#!/bin/bash
# diagnose_slow.sh

echo "=== 1. Load average ==="
uptime

echo "=== 2. Memoria ==="
free -h

echo "=== 3. Swap ==="
swapon --show

echo "=== 4. Top 5 procesos por CPU ==="
ps aux --sort=-%cpu | head -6

echo "=== 5. Top 5 procesos por memoria ==="
ps aux --sort=-%mem | head -6

echo "=== 6. IO en disco ==="
iostat -x 2 3 | tail -20

echo "=== 7. Conexiones de red ==="
ss -tan | awk '{print $1}' | sort | uniq -c

echo "=== 8. Archivos abiertos ==="
cat /proc/sys/fs/file-nr

echo "=== 9. Errores en logs recientes ==="
journalctl -p err -b --no-pager | tail -20

echo "=== 10. Espacio en disco ==="
df -h
```

---

## Uno-liners

```bash
# Ver todos los sysctl activos
sysctl -a | grep -E "tcp|net.core"

# Ver límites de archivos abiertos
ulimit -n
cat /proc/sys/fs/file-max

# Ver carga promedio
uptime | awk -F'load average:' '{print $2}'

# Ver procesos por consumo de memoria
ps aux --sort=-%mem | head -5

# Ver swap usado
free -h | grep Swap

# Forzar logrotate
sudo logrotate -f /etc/logrotate.conf

# Ver uso de Docker
docker stats --no-stream

# Ver logs de errores del sistema
journalctl -p err -b

# Ver archivos abiertos totales
lsof | wc -l

# Ver sysctl de seguridad
sysctl net.ipv4.conf.all.accept_redirects

# Ver conexiones TIME_WAIT
ss -tan | grep TIME_WAIT | wc -l

# Ver si swap está activo
swapon --show

# Limpiar cache de memoria (¡cuidado!)
sync; echo 3 > /proc/sys/vm/drop_caches

# Ver tiempo de actividad del servidor
uptime -p

# Ver reinicios del sistema
last reboot | head -5
```
