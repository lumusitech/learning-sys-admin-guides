⬅️ [Volver a scenarios](../README.md)

# 🧩 Escenario: Migrar aplicación a servidor de producción

---

## 🎯 Problema

Tienes una aplicación web funcionando en un servidor de desarrollo y necesitas migrarla a un servidor de producción recién aprovisionado. El servidor de producción debe estar hardening, con Docker, nginx como proxy reverso, SSL, límites de recursos, y monitoreo básico. El proceso incluye sincronizar archivos, configurar el stack, y verificar que todo funciona correctamente.

---

## ⚡ Quick command (SRE)

`ssh -o BatchMode=yes -o ConnectTimeout=5 ADMIN@PROD 'systemctl is-active nginx 2>/dev/null || true; ss -tuln | awk "NR==1 || /:80|:443|:3306|:5432/"'`

---

## ✅ Salida esperada

- servicios críticos activos (nginx / app)
- puertos necesarios abiertos (80, 443, DB internos)
- sin servicios fallidos en systemctl
- acceso remoto funcional

Interpretación:

- servicios activos → sistema listo para recibir tráfico
- puertos correctos → exposición controlada
- sin errores en systemctl → provisión correcta

---

## 🧠 Diagnóstico

Una migración a producción implica riesgo alto si el servidor no está correctamente configurado.

Patrones clave:

- servicios no activos → despliegue incompleto
- puertos incorrectos → exposición o fallo de acceso
- errores en logs → problemas de arranque o configuración
- falta de hardening → riesgo de seguridad inmediato

👉 Un deploy exitoso no es solo copiar archivos: es validar estado, exposición y estabilidad.

---

## 🛠️ Procedimiento (runbook)

### Hardening inicial

```bash
ssh admin@prod.empresa.local 'bash -s' <<'REMOTE'
set -e
echo "=== Actualizar ===" && apt update && apt upgrade -y
echo "=== Crear usuario ===" && adduser --disabled-password --gecos "" deploy
usermod -aG sudo deploy
echo "=== SSH hardening ==="
sed -i 's/^#Port 22/Port 2222/' /etc/ssh/sshd_config
sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd
echo "=== Firewall ==="
ufw --force reset && ufw default deny incoming && ufw default allow outgoing
ufw allow 2222/tcp && ufw allow 80/tcp && ufw allow 443/tcp
ufw --force enable
echo "=== Swap ==="
fallocate -l 2G /swapfile && chmod 600 /swapfile
mkswap /swapfile && swapon /swapfile
echo "/swapfile none swap sw 0 0" >> /etc/fstab
echo "=== Sysctl ==="
cat >> /etc/sysctl.d/99-production.conf <<'EOF'
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_tw_reuse=1
net.core.somaxconn=1024
vm.swappiness=10
EOF
sysctl --system
echo "=== Fail2ban ==="
apt install -y fail2ban && systemctl enable --now fail2ban
echo "=== Chrony ==="
apt install -y chrony && systemctl enable --now chrony
echo "=== Listo ==="
REMOTE
```

### Instalación de stack

```bash
ssh deploy@prod.empresa.local -p 2222 'bash -s' <<'REMOTE'
# Docker
curl -fsSL https://get.docker.com | bash
sudo usermod -aG docker $USER
# Docker daemon config
sudo tee /etc/docker/daemon.json <<'JSON'
{
  "log-driver": "json-file",
  "log-opts": {"max-size": "10m", "max-file": "3"},
  "storage-driver": "overlay2",
  "live-restore": true
}
JSON
sudo systemctl restart docker
# nginx
sudo apt install -y nginx
sudo tee /etc/nginx/sites-available/miapp <<'NGINX'
server {
    listen 80;
    server_name miapp.empresa.local;
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
NGINX
sudo ln -sf /etc/nginx/sites-available/miapp /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
REMOTE
```

### Migración de datos

```bash
# Sincronizar archivos de la aplicación
rsync -avz --delete -e "ssh -p 2222" \
  --exclude 'node_modules' \
  --exclude '.git' \
  --exclude 'tmp/' \
  --exclude '*.log' \
  /var/www/miapp/ \
  deploy@prod.empresa.local:/home/deploy/miapp/

# Backup y migración de MySQL
mysqldump -u root miapp | gzip \
  | ssh deploy@prod.empresa.local -p 2222 \
  "gunzip | mysql -u root miapp_prod"

# Verificar integridad (comparar checksums)
find /var/www/miapp -type f -exec md5sum {} \; \
  | ssh deploy@prod.empresa.local -p 2222 \
  "cat > /tmp/checksums.txt && cd /home/deploy/miapp && md5sum -c /tmp/checksums.txt | grep -v 'OK$'"
```

### Deploy

```bash
# docker-compose.yml en servidor de producción
ssh deploy@prod.empresa.local -p 2222 'bash -s' <<'REMOTE'
cat > /home/deploy/miapp/docker-compose.yml <<'YAML'
version: '3.8'
services:
  app:
    build: .
    restart: unless-stopped
    environment:
      - DB_HOST=db
      - DB_USER=miapp
      - DB_PASSWORD=${DB_PASSWORD}
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 512M
    networks:
      - backend
  db:
    image: mysql:8
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: ${DB_PASSWORD}
      MYSQL_DATABASE: miapp_prod
    volumes:
      - dbdata:/var/lib/mysql
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 1G
    networks:
      - backend
networks:
  backend:
volumes:
  dbdata:
YAML

cd /home/deploy/miapp
docker compose up -d
REMOTE
```

### Verificación

```bash
# 1. Probar que nginx responde
curl -s -o /dev/null -w "%{http_code}" http://miapp.empresa.local

# 2. Probar que la app responde (a través de nginx)
curl -s http://miapp.empresa.local/health | jq .

# 3. Ver logs de nginx
ssh deploy@prod.empresa.local -p 2222 \
  "tail -20 /var/log/nginx/access.log /var/log/nginx/error.log"

# 4. Ver logs de la aplicación
ssh deploy@prod.empresa.local -p 2222 \
  "docker logs --tail 30 miapp-app-1 2>&1"

# 5. Estadísticas de recursos
ssh deploy@prod.empresa.local -p 2222 \
  "docker stats --no-stream && echo '---' && free -h && echo '---' && df -h /"
```

---

## 🧯 Mitigación

Si la migración falla:

```bash
docker compose down
```

Verificar:

```bash
docker logs <contenedor>
```

Rollback:

```bash
docker compose -f docker-compose.old.yml up -d
```

Casos comunes:

- app no responde → verificar logs y puertos
- 502/503 → revisar nginx y upstream
- base de datos inaccesible → validar credenciales y conexión

---

## Variantes

### Rollback rápido

```bash
# Si algo falla, revertir en segundos
ssh deploy@prod.empresa.local -p 2222 \
  "cd /home/deploy/miapp && docker compose down && docker compose -f docker-compose.old.yml up -d"

# Restaurar código anterior
rsync -avz -e "ssh -p 2222" \
  /mnt/backups/miapp/rollback-$(date -d yesterday +%Y%m%d)/ \
  deploy@prod.empresa.local:/home/deploy/miapp/
```

### Migración con blue-green

```bash
# Servidor green paralelo, luego swap nginx
ssh deploy@prod.empresa.local -p 2222 \
  "COMPOSE_PROJECT_NAME=green docker compose up -d && \
   sed -i 's/server green:3000/server blue:3000/' /etc/nginx/sites-available/miapp && \
   nginx -s reload"
```

---

## ✅ Interpretación

- `curl` devuelve 200 → aplicación funcionando correctamente
- `curl` devuelve 502/503 → nginx no puede contactar backend
- errores en `docker logs` → problema en aplicación o dependencias
- disco >80% → riesgo de saturación
- falta de memoria → posible degradación

---

## 🔗 Referencias

- [nginx.md](../../guides/nginx.md)
- [production_server.md](../../guides/production_server.md)
- [storage_backup.md](../../guides/storage_backup.md)
- [ssh.md](../../guides/ssh.md)
- [systemd_journalctl.md](../../guides/systemd_journalctl.md)
