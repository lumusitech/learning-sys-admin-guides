# Almacenamiento y copias de seguridad — Guía completa

**Nivel:** 🟡 Intermedio
**Archivos de práctica:** `labs/docker-compose.yml` (volúmenes)
**Ver escenarios relacionados:** [`infrastructure/02-build-pyme`](../scenarios/infrastructure/02-build-pyme-infrastructure.md), [`infrastructure/03-disaster-recovery`](../scenarios/infrastructure/03-disaster-recovery.md)

## ⚡ Quick command

`rsync -av /src/ /dst/`

## ⚡ Quick run

```bash
rsync -avz --delete /etc/ /mnt/backups/etc/
```

---

## Índice

1. [NFS: Sistema de archivos en red](#nfs)
2. [Samba/CIFS: Compatibilidad con Windows](#samba)
3. [Estrategia de backups 3-2-1](#estrategia-backups)
4. [Backup local con rsync](#backup-local)
5. [Rotación de backups](#rotacion)
6. [Backup a la nube con rclone](#rclone)
7. [Backup con restic (deduplicación y cifrado)](#restic)
8. [Réplicas y sincronización](#replicas)
9. [Restauración: la prueba de fuego](#restauracion)
10. [Monitoreo de backups](#monitoreo)
11. [Escenarios reales](#escenarios)

---

## ¿Qué es almacenamiento y backups?

El almacenamiento en red (NFS, Samba) permite compartir archivos entre servidores. Los backups garantizan la recuperación de datos ante fallos, errores humanos o desastres. La estrategia recomendada es 3-2-1: 3 copias, 2 soportes distintos, 1 fuera del sitio.

---

## NFS: Sistema de archivos en red

NFS (Network File System) permite compartir directorios entre servidores Linux como si fueran locales.

### Servidor NFS

```bash
# Instalar
sudo apt install -y nfs-kernel-server

# /etc/exports — directorios a compartir
# formato: /ruta    cliente(opciones)

# Compartir a toda la subred
/srv/backups   10.0.0.0/24(rw,sync,no_subtree_check,no_root_squash)

# Compartir a una IP específica
/srv/datos     192.168.1.50(rw,sync,no_subtree_check)
```

| Opción | Descripción |
|--------|-------------|
| `rw` | Lectura y escritura |
| `ro` | Solo lectura |
| `sync` | Escribir en disco antes de responder (seguro) |
| `async` | Responder antes de escribir (más rápido, menos seguro) |
| `no_subtree_check` | No verificar que el archivo está dentro del export (más rápido) |
| `no_root_squash` | Permitir acceso root remoto (peligroso si no confías en los clientes) |
| `root_squash` | Root remoto se mapea a nobody/nogroup (por defecto, seguro) |

```bash
# Aplicar configuración
sudo exportfs -ra
sudo systemctl restart nfs-kernel-server

# Ver exports activos
sudo exportfs -v
```

### Cliente NFS

```bash
# Instalar
sudo apt install -y nfs-common

# Montar manual
sudo mount -t nfs SERVIDOR:/srv/backups /mnt/backups

# Montar automático (/etc/fstab)
echo "10.0.0.10:/srv/backups /mnt/backups nfs defaults,noatime 0 0" | sudo tee -a /etc/fstab

# Probar
df -h /mnt/backups
```

---

## Samba/CIFS: Compatibilidad con Windows

Comparte directorios con máquinas Windows.

### Servidor Samba

```bash
# Instalar
sudo apt install -y samba

# /etc/samba/smb.conf
[global]
workgroup = EMPRESA
server string = Servidor Linux
security = user
map to guest = Bad User

[Compartido]
path = /srv/compartido
browsable = yes
writable = yes
guest ok = no
create mask = 0644
directory mask = 0755
valid users = admin, carludev

[Publico]
path = /srv/publico
browsable = yes
writable = yes
guest ok = yes
force user = nobody
```

```bash
# Agregar usuario Samba (tiene que existir en el sistema)
sudo smbpasswd -a admin

# Ver usuarios Samba
sudo pdbedit -L

# Iniciar
sudo systemctl enable --now smbd

# Ver recursos compartidos
smbclient -L localhost -U admin
```

### Cliente Samba (Linux)

```bash
# Instalar
sudo apt install -y smbclient cifs-utils

# Montar manual
sudo mount -t cifs //SERVIDOR/Compartido /mnt/samba -o username=admin,uid=1000,gid=1000

# Montar automático (/etc/fstab)
//SERVIDOR/Compartido /mnt/samba cifs username=admin,password=XXXX,uid=1000,gid=1000,noatime 0 0

# Desde Windows
# \\SERVIDOR\Compartido
```

---

## Estrategia de backups 3-2-1

La regla de oro de las copias de seguridad:

- **3** copias de tus datos
- **2** soportes diferentes (ej: disco local + nube)
- **1** copia fuera del sitio (off-site)

```bash
# Ejemplo de implementación
# Copia 1: datos originales en el servidor
# Copia 2: backup local en NAS (NFS)
# Copia 3: backup externo en S3 (rclone)
```

### Qué backupear

```bash
# Configuraciones del sistema
/etc/
/var/lib/docker/volumes/

# Datos de aplicaciones
/var/www/
/var/lib/mysql/
/var/lib/postgresql/

# Home de usuarios
/home/

# Logs importantes (opcional)
/var/log/
```

### Qué NO backupear

```bash
# No tiene sentido:
/tmp/
/proc/
/sys/
/dev/
/run/
/var/cache/apt/
*.log (a menos que sean necesarios por compliance)
```

---

## Backup local con rsync

### Backup básico

```bash
#!/bin/bash
# backup_local.sh

ORIGEN="/var/www /etc /home"
DESTINO="/mnt/backups/servidor1"
FECHA=$(date +%Y%m%d_%H%M%S)
LOG="/var/log/backup.log"

echo "[$FECHA] Iniciando backup..." >> "$LOG"

rsync -avz --delete --partial \
  $ORIGEN \
  "$DESTINO/actual/" \
  >> "$LOG" 2>&1

echo "[$FECHA] Backup completado" >> "$LOG"
```

| Opción rsync | Descripción |
|--------------|-------------|
| `-a` | Modo archivo: preserva permisos, dueño, grupo, timestamps, enlaces |
| `-v` | Verboso |
| `-z` | Comprimir durante la transferencia |
| `--delete` | Eliminar en destino archivos que ya no existen en origen |
| `--partial` | Mantener archivos parciales si se corta la transferencia |

### Backup remoto vía SSH

```bash
#!/bin/bash
# backup_remoto.sh

rsync -avz --delete -e "ssh -p 22" \
  /var/www/ \
  admin@NAS:/backups/servidor1/www/ \
  2>&1 | logger -t backup
```

### Backup con exclusión

```bash
rsync -avz --delete \
  --exclude 'node_modules' \
  --exclude '.git' \
  --exclude 'tmp/' \
  --exclude 'vendor/' \
  --exclude '*.log' \
  /var/www/proyecto/ \
  /mnt/backups/proyecto/
```

---

## Rotación de backups

### Rotación simple con enlaces duros (rsnapshot)

```bash
# Estructura: backups/diario.0/ → backups/diario.1/ → etc.
# Los archivos no modificados comparten el mismo inodo (no ocupan espacio extra)
```

```bash
# /etc/rsnapshot.conf
config_version  1.2
snapshot_root   /mnt/backups/
cmd_cp          /bin/cp
cmd_rm          /bin/rm
cmd_rsync       /usr/bin/rsync
cmd_logger      /usr/bin/logger

retain  hourly  6     # 6 hourly snapshots
retain  daily   7     # 7 daily snapshots
retain  weekly  4     # 4 weekly snapshots
retain  monthly 3     # 3 monthly snapshots

backup  /var/www/     servidor1/www/
backup  /etc/         servidor1/etc/
backup  /home/        servidor1/home/
```

```bash
# Ejecutar
sudo rsnapshot hourly
sudo rsnapshot daily

# Ver backups disponibles
ls -la /mnt/backups/
```

### Rotación manual con scripts

```bash
#!/bin/bash
# backup_rotate.sh — Rotación simple semanal/mensual

BASE="/mnt/backups"
FECHA=$(date +%Y%m%d)
SEMANA=$(date +%V)
MES=$(date +%m)

# Backup diario
rsync -a --delete /var/www/ "$BASE/diario/" 2>&1

# Backup semanal (lunes)
if [ "$(date +%u)" = "1" ]; then
    cp -al "$BASE/diario" "$BASE/semanal_$SEMANA"
fi

# Backup mensual (día 1)
if [ "$(date +%d)" = "01" ]; then
    cp -al "$BASE/diario" "$BASE/mensual_$MES"
fi
```

> **`cp -al`**: crea enlaces duros. Los archivos no ocupan espacio extra hasta que cambian.

### Cron de backups

```bash
# /etc/crontab
# Backup diario a las 2am
0 2 * * * root /usr/local/bin/backup_local.sh

# Backup remoto a las 3am
0 3 * * * root /usr/local/bin/backup_remoto.sh

# Rotación semanal (domingo 4am)
0 4 * * 0 root /usr/local/bin/backup_rotate.sh

# Verificar backups (cada 6 horas)
0 */6 * * * root /usr/local/bin/check_backup.sh
```

---

## Backup a la nube con rclone

rclone sincroniza archivos con más de 40 proveedores cloud (S3, Backblaze B2, Google Drive, Dropbox, etc.).

### Instalación

```bash
sudo -v ; curl https://rclone.org/install.sh | sudo bash
```

### Configuración

```bash
rclone config
# Sigue las instrucciones interactivas para conectar con tu proveedor

# Configuración directa para S3 (ej: Backblaze B2)
rclone config create b2 b2 account $B2_KEY_ID key $B2_APP_KEY
```

### Backups con rclone

```bash
#!/bin/bash
# backup_cloud.sh

rclone sync /var/www/ b2:my-bucket/www/ \
  --progress \
  --verbose \
  --transfers 8 \
  --checkers 16 \
  --exclude 'node_modules/**' \
  --exclude '.git/**' \
  --b2-hard-delete \
  2>&1 | logger -t backup-cloud

# Encriptar antes de subir (cifrado del lado del cliente)
rclone sync /var/www/ crypt:backup-encrypted/www/ \
  --progress --verbose
```

| Comando | Descripción |
|---------|-------------|
| `sync` | Hace que el destino sea idéntico al origen |
| `copy` | Copia archivos nuevos/actualizados (no elimina en destino) |
| `move` | Mueve (copia + elimina origen) |
| `check` | Verifica que archivos en origen y destino son iguales |
| `crypt` | Sistema de archivos virtual que encripta antes de subir |

### Verificar backups en la nube

```bash
# Listar archivos en bucket
rclone ls b2:my-bucket/www/

# Verificar integridad
rclone check /var/www/ b2:my-bucket/www/ --download

# Obtener estadísticas
rclone size b2:my-bucket/
```

---

## Backup con restic (deduplicación y cifrado)

restic hace backups deduplicados, cifrados y eficientes. Ideal para backups frecuentes.

### Instalación

```bash
sudo apt install -y restic
```

### Inicializar repositorio

```bash
# Local
restic init --repo /mnt/backups/restic

# S3
export AWS_ACCESS_KEY_ID=xxx
export AWS_SECRET_ACCESS_KEY=yyy
restic init --repo s3:s3.us-east-1.amazonaws.com/mybucket/restic

# Con contraseña de cifrado
export RESTIC_PASSWORD="mi-frase-segura"
```

### Backup

```bash
restic backup /var/www/ /etc/ /home/ \
  --repo /mnt/backups/restic \
  --exclude '*.log' \
  --exclude 'node_modules' \
  --verbose

# Backup con etiqueta
restic backup /var/www/ --tag web --tag diario
```

### Restauración

```bash
# Listar snapshots
restic snapshots --repo /mnt/backups/restic

# Restaurar último snapshot
restic restore latest --target /tmp/restore

# Restaurar snapshot específico
restic restore SNAPSHOT_ID --target /tmp/restore

# Montar como sistema de archivos (explorar sin restaurar)
restic mount /mnt/restic --repo /mnt/backups/restic
```

### Limpieza automática

```bash
# Política de retención
restic forget \
  --keep-daily 7 \
  --keep-weekly 5 \
  --keep-monthly 6 \
  --keep-yearly 2 \
  --prune

# Automatizar
restic backup && restic forget --keep-daily 7 --keep-weekly 5 --prune
```

---

## Réplicas y sincronización

### Réplica de servidor completo

```bash
#!/bin/bash
# replica.sh — Sincronizar servidor A → servidor B (modo recuperación)

rsync -avz --delete --delayed-updates \
  -e "ssh -o ServerAliveInterval=30" \
  /var/www/ /etc/ /home/ \
  admin@SERVER_B:/backup-replica/

# Para bases de datos, usar sus propias herramientas de replicación
# MySQL: mysqldump + rsync, o replicación binlog
# PostgreSQL: pg_basebackup, o streaming replication
```

### Réplica con lsyncd (sincronización en tiempo real)

```bash
sudo apt install -y lsyncd

# /etc/lsyncd/lsyncd.conf.lua
settings {
    logfile = "/var/log/lsyncd/lsyncd.log",
    statusFile = "/var/log/lsyncd/lsyncd.status",
    insist = 1,
}

sync {
    default.rsyncssh,
    source = "/var/www/",
    host = "admin@SERVER_B",
    targetdir = "/var/www/replica/",
    rsync = {
        archive = true,
        compress = true,
        whole_file = false,
    },
    ssh = {
        port = 22,
    },
}
```

```bash
sudo systemctl enable --now lsyncd
```

### Réplica de base de datos (MySQL/MariaDB)

```bash
# En el servidor de base de datos
# /etc/mysql/mariadb.conf.d/replica.cnf
[mysqld]
server-id = 1
log_bin = /var/log/mysql/mysql-bin.log
binlog_do_db = midb

# En el servidor réplica
CHANGE MASTER TO
  MASTER_HOST='10.0.0.10',
  MASTER_USER='replica',
  MASTER_PASSWORD='password',
  MASTER_LOG_FILE='mysql-bin.000001',
  MASTER_LOG_POS=  0;

START SLAVE;
SHOW SLAVE STATUS\G
```

---

## Restauración: la prueba de fuego

Un backup que no se prueba no es un backup.

### Script de verificación

```bash
#!/bin/bash
# check_backup.sh — Verificar que los backups son válidos

echo "=== Verificación de backups: $(date) ==="

# 1. Verificar que el sistema de archivos de backup está montado
mountpoint -q /mnt/backups || {
    echo "ERROR: /mnt/backups no está montado"
    mount /mnt/backups
}

# 2. Verificar que hay backups recientes
RECIENTE=$(find /mnt/backups/ -maxdepth 1 -name "*.ok" -mtime -1)
if [ -z "$RECIENTE" ]; then
    echo "WARN: No hay backup de las últimas 24h"
fi

# 3. Verificar integridad de archivos de configuración (rsync diff)
rsync -avn --delete /etc/ /mnt/backups/etc/ | grep -q "^$" || {
    echo "CAMBIOS: /etc/ difiere del backup"
}

# 4. Probar restauración de un archivo de prueba
echo "test-$(date +%s)" > /tmp/test_restore.txt
cp /tmp/test_restore.txt /mnt/backups/test_restore.txt
diff /tmp/test_restore.txt /mnt/backups/test_restore.txt && {
    echo "OK: Restauración básica funciona"
}

# Ensure backup de BD accesible
if [ -d /mnt/backups/mysql/ ]; then
    echo "OK: Backup MySQL existe"
    ls -lh /mnt/backups/mysql/ | tail -5
fi

echo "=== Verificación completada ==="
```

### Prueba de restauración real

```bash
# 1. Restaurar archivos
rsync -avz /mnt/backups/servidor1/www/ /tmp/restore_test/www/

# 2. Verificar integridad (mysql)
gunzip -c /mnt/backups/mysql/midb_$(date +%Y%m%d).sql.gz | head -50

# 3. Probar en contenedor
docker run -d --name test-restore \
  -v /tmp/restore_test/www:/var/www/html \
  -p 8888:80 \
  nginx:alpine

curl -s http://localhost:8888 | head -5
```

---

## Monitoreo de backups

### Logging centralizado

```bash
# Usar logger para enviar a syslog/journald
rsync -avz /var/www/ /mnt/backups/ 2>&1 | logger -t backup-www

# Ver logs
journalctl -t backup-www -b

# Backups de bases de datos con logging
mysqldump -u root midb | gzip > /mnt/backups/mysql/midb_$(date +%Y%m%d).sql.gz 2>&1 \
  | logger -t backup-mysql
```

### Alertas de backup fallido

```bash
#!/bin/bash
# alert_backup.sh — Enviar alerta si backup falla

if [ $? -ne 0 ]; then
    echo "Backup fallido en $(hostname) a las $(date)" | \
      mail -s "ALERTA: Backup fallido" admin@empresa.com
    
    # O enviar a webhook de Slack/Telegram
    curl -s -X POST https://hooks.slack.com/services/TOKEN \
      -H "Content-Type: application/json" \
      -d '{"text":"Backup fallido en '"$(hostname)"'"}'
fi
```

### Dashboard de estado

```bash
#!/bin/bash
# status_backup.sh
echo "=== Estado de Backups ==="
echo ""
echo "Últimos backups:"
find /mnt/backups/ -name "*.ok" -mtime -7 -exec ls -lh {} \; | awk '{print $6, $7, $9}'
echo ""
echo "Tamaño total del repositorio:"
du -sh /mnt/backups/
echo ""
echo "Snapshots restic disponibles:"
restic snapshots --repo /mnt/backups/restic 2>/dev/null | tail -10
```

---

## Escenarios

### 1. NAS casero con NFS + Samba

```bash
# 1. Montar discos
sudo mkdir -p /srv/nas/{backups,datos,publico,multimedia}
sudo mount /dev/sdb1 /srv/nas/datos  # Disco dedicado

# 2. Compartir por NFS (Linux)
# /etc/exports
/srv/nas/backups    10.0.0.0/24(rw,sync,no_subtree_check)
/srv/nas/datos      10.0.0.0/24(rw,sync,no_subtree_check)
/srv/nas/publico    10.0.0.0/24(ro,sync,no_subtree_check)

# 3. Compartir por Samba (Windows)
# /etc/samba/smb.conf
[Backups]
path = /srv/nas/backups
valid users = admin
read only = no

[Publico]
path = /srv/nas/publico
guest ok = yes
read only = yes

# 4. Backup automático al NAS
echo "0 3 * * * root rsync -avz /var/www/ /srv/nas/backups/www/" >> /etc/crontab
```

### 2. Estrategia completa 3-2-1

```bash
#!/bin/bash
# backup_321.sh — Estrategia 3-2-1 completa

FECHA=$(date +%Y%m%d)
LOG="/var/log/backup_321.log"

echo "=== Backup 3-2-1: $FECHA ===" >> "$LOG"

# Copia 1: datos originales (existen ya en el servidor)

# Copia 2: backup local en NAS
echo "→ Backup a NAS local..." >> "$LOG"
rsync -avz --delete /var/www/ /etc/ /home/ \
  /mnt/nas/backups/$(hostname)/$FECHA/ \
  >> "$LOG" 2>&1

# Copia 3: backup externo (S3/Backblaze)
echo "→ Backup a S3..." >> "$LOG"
restic backup /var/www/ /etc/ \
  --repo s3:s3.us-east-1.amazonaws.com/mybucket/restic \
  --tag $FECHA \
  >> "$LOG" 2>&1

# Limpiar snapshots antiguos (S3)
restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune \
  --repo s3:s3.us-east-1.amazonaws.com/mybucket/restic \
  >> "$LOG" 2>&1

echo "=== Backup completado ===" >> "$LOG"
```

### 3. Backup de base de datos + archivos

```bash
#!/bin/bash
# backup_db_files.sh

FECHA=$(date +%Y%m%d)
DEST="/mnt/backups/$FECHA"
mkdir -p "$DEST"

# Backup MySQL
echo "Backup MySQL..."
mysqldump --all-databases -u root | gzip > "$DEST/mysql_all.sql.gz"

# Backup PostgreSQL
echo "Backup PostgreSQL..."
sudo -u postgres pg_dumpall | gzip > "$DEST/postgres_all.sql.gz"

# Backup archivos
echo "Backup archivos..."
rsync -a --delete /var/www/ "$DEST/www/"

# Backup configuraciones
tar czf "$DEST/etc.tar.gz" /etc/nginx/ /etc/ssh/ /etc/mysql/

# Verificar integridad
echo "Verificando..."
md5sum "$DEST"/*.sql.gz > "$DEST/checksums.md5"
md5sum -c "$DEST/checksums.md5"

echo "Backup completado en $DEST"
```

---

## Uno-liners

```bash
# Backup rápido de /etc
sudo tar czf /backups/etc-$(date +%Y%m%d).tar.gz /etc/

# Backup de MySQL
mysqldump -u root midb | gzip > /backups/midb-$(date +%Y%m%d).sql.gz

# Backup remoto
rsync -avz /var/www/ admin@NAS:/backups/www/

# Montar NFS
mount -t nfs NAS:/srv/backups /mnt/backups

# Verificar backup reciente
find /mnt/backups -name "*.tar.gz" -mtime -1

# Espacio usado por backups
du -sh /mnt/backups/

# Tamaño de cada directorio de backup
du -sh /mnt/backups/*/

# Último backup de cada directorio
ls -lt /mnt/backups/*/ | head -20

# Enviar backup a S3
rclone sync /mnt/backups s3:my-bucket/backups/ --progress

# Backup deduplicado con restic
restic backup /var/www/ --repo /mnt/backups/restic

# Restaurar último snapshot restic
restic restore latest --target /tmp/restore --repo /mnt/backups/restic
```
