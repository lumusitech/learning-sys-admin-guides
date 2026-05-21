# Escenario: Recuperación ante desastres (disaster recovery)

## Problema

El servidor de producción ha sufrido un fallo de disco. Tienes backups almacenados en un NAS local y en la nube (Backblaze B2). Necesitas restaurar todo el stack en un servidor nuevo: sistema operativo, configuraciones, archivos web, base de datos, y verificar que la aplicación funciona correctamente. El tiempo de recuperación objetivo (RTO) es de 4 horas.

## Datos de entrada

- Nuevo servidor: `10.0.40.100` (recién instalado con Ubuntu Server)
- NAS de backups: `10.0.10.10:/srv/nas/backups`
- Backup externo: `b2:my-bucket/prod-backups/`
- Repositorio restic: `/srv/nas/backups/restic`
- Último snapshot conocido: `abc123def`

## Pipeline 1: Preparar servidor de recuperación

```bash
# Hardening rápido
apt update && apt upgrade -y
adduser --disabled-password --gecos "" admin
usermod -aG sudo admin

# SSH (usar la clave del backup)
mkdir -p /home/admin/.ssh
# La clave autorizada debería estar en el backup de /etc
# Mientras tanto, copiar manualmente
chmod 700 /home/admin/.ssh && chmod 600 /home/admin/.ssh/authorized_keys

# Firewall mínimo
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp && ufw allow 80/tcp && ufw allow 443/tcp
ufw --force enable

# Montar NAS de backups
apt install -y nfs-common
mkdir -p /mnt/nas-backups
mount -t nfs 10.0.10.10:/srv/nas/backups /mnt/nas-backups

# Verificar que los backups están accesibles
ls -la /mnt/nas-backups/
restic snapshots --repo /mnt/nas-backups/restic 2>/dev/null || echo "ERROR: Backup no accesible"
```

### Explicación paso a paso

1. **Preparación mínima** — Usuario, SSH, firewall
2. **Montar NAS** — El backup local debe estar accesible primero
3. **Verificar** — Si el backup no está accesible, pasar al backup externo

## Pipeline 2: Restaurar configuración del sistema

```bash
# Restaurar /etc desde backup rsync
FECHA_BACKUP=$(ls /mnt/nas-backups/servidor1/ | sort -r | head -1)
echo "Restaurando backup del: $FECHA_BACKUP"

# Restaurar configuraciones del sistema
rsync -avz /mnt/nas-backups/servidor1/$FECHA_BACKUP/etc/ /etc/

# Restaurar sysctl
sysctl --system

# Restaurar reglas de firewall
iptables-restore < /mnt/nas-backups/servidor1/$FECHA_BACKUP/iptables.rules 2>/dev/null || \
  echo "WARN: No se encontraron reglas de firewall"

# Verificar integridad de configs restauradas
diff -r /etc/ssh/sshd_config /mnt/nas-backups/servidor1/$FECHA_BACKUP/etc/ssh/sshd_config && \
  echo "OK: SSH config íntegra" || echo "ERROR: SSH config corrupta"
```

### Explicación paso a paso

1. **rsync inverso** — Restaura desde el NAS al nuevo servidor
2. **sysctl** — Aplica parámetros de kernel del backup
3. **iptables-restore** — Recupera las reglas de firewall exactas
4. **diff** — Verifica que la restauración fue correcta

## Pipeline 3: Restaurar aplicación web con restic

```bash
# Listar snapshots disponibles
restic snapshots --repo /mnt/nas-backups/restic | tail -20

# Restaurar el snapshot más reciente
restic restore latest \
  --repo /mnt/nas-backups/restic \
  --target /tmp/restore-restic \
  --verbose

# Mover a la ubicación correcta
cp -a /tmp/restore-restic/var/www/* /var/www/
cp -a /tmp/restore-restic/home/* /home/

# Si el backup local está corrupto, restaurar desde la nube
rclone sync b2:my-bucket/prod-backups/restic/ /mnt/nas-backups/restic/ \
  --progress --verbose

restic restore latest \
  --repo /mnt/nas-backups/restic \
  --target /tmp/restore-cloud \
  --verbose
```

### Explicación paso a paso

1. **restic snapshots** — Identifica el snapshot a restaurar
2. **restic restore** — Restaura archivos completos con permisos
3. **Fallback a nube** — Si el backup local falla, se descarga de B2

## Pipeline 4: Restaurar base de datos

```bash
# Buscar backup de MySQL en el backup restaurado
ls -lh /tmp/restore-restic/var/backups/mysql/

# Restaurar MySQL (si se restauró mysqldump)
apt install -y mysql-server
mysql -u root -p < /tmp/restore-restic/var/backups/mysql/midb_$(date +%Y%m%d).sql 2>/dev/null

# Si no hay dump, verificar si hay datos de MySQL en /var/lib/mysql
if [ -d /tmp/restore-restic/var/lib/mysql ]; then
  systemctl stop mysql
  rm -rf /var/lib/mysql/*
  cp -a /tmp/restore-restic/var/lib/mysql/* /var/lib/mysql/
  chown -R mysql:mysql /var/lib/mysql
  systemctl start mysql
fi

# Verificar base de datos restaurada
mysql -u root -e "SHOW DATABASES;" 2>/dev/null
mysql -u root -e "SELECT COUNT(*) FROM information_schema.tables;" 2>/dev/null
```

### Explicación paso a paso

1. **Dump SQL** — Si existe mysqldump, es la opción más segura
2. **Copia directa** — Si no hay dump, restaurar `/var/lib/mysql` directamente
3. **Verificación** — Comprueba que la BD se restauró correctamente

## Pipeline 5: Restaurar nginx y sitio web

```bash
# Restaurar configuración de nginx
cp -a /tmp/restore-restic/etc/nginx/* /etc/nginx/

# Restaurar certificados SSL (si existen)
if [ -d /tmp/restore-restic/etc/nginx/ssl ]; then
  cp -a /tmp/restore-restic/etc/nginx/ssl /etc/nginx/ssl
fi

# Verificar sintaxis
nginx -t && systemctl restart nginx

# Restaurar contenido web
cp -a /tmp/restore-restic/var/www/* /var/www/

# Probar que sirve contenido
curl -s -o /dev/null -w "%{http_code} %{content_type}" http://localhost
curl -s http://localhost | head -5
```

### Explicación paso a paso

1. **Configuración** — Se restaura completa incluyendo SSL
2. **`nginx -t`** — Verifica que la sintaxis sea correcta
3. **Contenido web** — Archivos estáticos y aplicaciones
4. **Curl test** — Verifica que nginx responde

## Pipeline 6: Verificación post-recuperación

```bash
# 1. Verificar servicios críticos
for svc in nginx mysql sshd systemd-journald; do
  systemctl is-active $svc >/dev/null && echo "OK: $svc" || echo "FALLO: $svc"
done

# 2. Probar integridad de archivos
find /var/www -type f -name "*.md5" -exec md5sum -c {} \; | grep -v "OK$"
echo "Archivos verificados: $(find /var/www -type f | wc -l)"

# 3. Verificar conectividad
for host in 10.0.10.10 10.0.40.11 8.8.8.8; do
  ping -c 1 -W 2 $host >/dev/null && echo "OK: $host" || echo "FALLO: $host"
done

# 4. Verificar DNS
nslookup portal.empresa.com 127.0.0.1 2>/dev/null && \
  echo "OK: DNS local" || echo "FALLO: DNS local"

# 5. Verificar logs de errores
journalctl -p err -b --no-pager | grep -v "startup" | head -10

# 6. Reporte final
echo "=== REPORTE DE RECUPERACIÓN ==="
echo "Fecha: $(date)"
echo "Host: $(hostname)"
echo "Servicios activos: $(systemctl list-units --state=running --type=service --no-legend | wc -l)"
echo "Archivos restaurados: $(find /var/www /etc/nginx -type f | wc -l)"
echo "Tamaño restaurado: $(du -sh /var/www/ /etc/nginx/ | tail -1)"
df -h / | tail -1
free -h | grep Mem
```

### Explicación paso a paso

1. **Servicios** — Verifica que los servicios críticos están activos
2. **Integridad** — Checksums de archivos restaurados
3. **Conectividad** — Ping a NAS, DB interna y DNS externo
4. **Logs** — Busca errores en el nuevo arranque

## Pipeline 7: Documentar lecciones aprendidas

```bash
# Generar reporte de lo que faltó en el backup
echo "=== LECCIONES APRENDIDAS ==="
echo ""
echo "Archivos que deberían estar en backup pero no:"
# Comparar /etc actual vs backup
diff -rq /etc/ /mnt/nas-backups/servidor1/latest/etc/ 2>/dev/null \
  | grep "Only in /etc/" | head -10

echo ""
echo "Tiempo de recuperación:"
RTO_START="2024-01-15 10:00:00"
RTO_END=$(date +"%Y-%m-%d %H:%M:%S")
echo "Inicio: $RTO_START"
echo "Fin:    $RTO_END"
echo "Duración estimada: $(echo $(($(date +%s) - $(date -d "$RTO_START" +%s)))) segundos"

echo ""
echo "Recomendaciones:"
echo "- Automatizar backup de /etc/ con rsync diario" | tee -a /tmp/recomendaciones.txt
echo "- Incluir mysqldump en el backup pre-restic" | tee -a /tmp/recomendaciones.txt
echo "- Documentar RPO (pérdida máxima aceptable)" | tee -a /tmp/recomendaciones.txt
echo "- Probar restauración completa cada 3 meses" | tee -a /tmp/recomendaciones.txt
```

### Explicación paso a paso

1. **diff** — Identifica configuraciones que no estaban en backup
2. **Cálculo RTO** — Mide el tiempo real de recuperación
3. **Recomendaciones** — Documenta mejoras para el próximo DR

## Variantes

### Recuperación desde la nube (sin NAS local)

```bash
# Si el NAS también falló, restaurar directamente desde B2
rclone sync b2:my-bucket/prod-backups/ /tmp/cloud-restore/ --progress

# restic desde repositorio en la nube
restic -r rclone:b2:my-bucket/prod-backups/restic restore latest --target /tmp/restore
```

### Recuperación parcial (solo un archivo)

```bash
# Restaurar un solo archivo de configuración
restic restore latest \
  --repo /mnt/nas-backups/restic \
  --target /tmp/restore-single \
  --include /etc/nginx/sites-available/miapp

# Restaurar un directorio específico
rsync -avz /mnt/nas-backups/servidor1/20240115/var/www/miapp/ /var/www/miapp/
```

### Simulacro de DR

```bash
# Crear script de simulación que prueba que los backups son válidos
# sin necesidad de restaurar realmente
#!/bin/bash
echo "=== SIMULACRO DR $(date) ==="
restic check --repo /mnt/nas-backups/restic && echo "OK: repositorio íntegro" || echo "FALLO: repositorio corrupto"
rsync -avn --delete /etc/ /mnt/nas-backups/servidor1/latest/etc/ | wc -l | xargs echo "Archivos diferentes en /etc:"
echo "Último backup de BD: $(ls -lt /mnt/nas-backups/mysql/*.sql.gz | head -1 | awk '{print $6, $7, $8}')"
echo "=== SIMULACRO COMPLETADO ==="
```

## Interpretación

| Indicador | Significado |
|-----------|-------------|
| `nginx -t` OK | Configuración de nginx restaurada correctamente |
| `mysql SHOW DATABASES` con datos | Base de datos íntegra |
| `curl` devuelve 200 | Aplicación funcionando |
| `restic check` OK | Backup no corrupto |
| `diff` sin diferencias en /etc | Restauración completa de configs |
| Tiempo total < 4 horas | RTO cumplido |
| Datos perdidos > RPO esperado | Ajustar frecuencia de backups |

## Comandos relacionados

- [storage_backup.md](../../guides/storage_backup.md)
- [production_server.md](../../guides/production_server.md)
- [nginx.md](../../guides/nginx.md)
- [restic backup](../..//guides/storage_backup.md#restic)
- [systemd_journalctl.md](../../guides/systemd_journalctl.md)
- [ssh.md](../../guides/ssh.md)
