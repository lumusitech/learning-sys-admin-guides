# 🔐 Dahua — Acceso SSH a NVR

**Nivel:** 🔴 Avanzado
**Herramientas:** `ssh`, `scp`, `rsync`

---

## ⚡ Quick command

```bash
ssh admin@192.168.100.100
```

---

## 🧠 ¿Por qué SSH a NVR?

Los NVR Dahua permiten acceso SSH para:

- Diagnóstico avanzado del sistema
- Ver logs del sistema operativo
- Gestionar discos (SMART, formateo)
- Backup de configuración
- Restaurar grabaciones
- Monitoreo de recursos (CPU, RAM, disco)

---

## 🔓 Habilitar SSH en NVR

### Método 1: Vía interfaz web

1. Acceder a `http://NVR_IP`
2. Ir a **Setup → Network → SSH**
3. Habilitar SSH Server
4. Configurar puerto (22 por defecto)
5. Guardar

### Método 2: Vía API

```bash
curl -s -u admin:contraseña \
  -d "SSHServer.Enable=true&SSHServer.Port=22" \
  "http://192.168.100.100/cgi-bin/configManager.cgi?action=setConfig"
```

---

## 🔑 Conectar por SSH

```bash
# Conexión básica
ssh admin@192.168.100.100

# Con puerto personalizado
ssh -p 2222 admin@192.168.100.100

# Con clave SSH (si está configurada)
ssh -i ~/.ssh/dahua_nvr admin@192.168.100.100
```

---

## 📋 Navegación del sistema de archivos

```bash
# Directorio raíz del NVR
ls -la /

# Configuración del sistema
ls -la /etc/

# Logs del sistema
ls -la /var/log/

# Grabaciones
ls -la /mnt/sda/  # Disco 1
ls -la /mnt/sdb/  # Disco 2

# Aplicación Dahua
ls -la /usr/local/bin/
```

---

## 📊 Ver procesos y consumo de recursos

```bash
# Top interactivo
top

# Procesos ordenados por CPU
ps aux --sort=-%cpu | head -20

# Procesos ordenados por memoria
ps aux --sort=-%mem | head -20

# Ver proceso específico
ps aux | grep dahua

# Uso de disco
df -h

# Uso de memoria
free -h

# Información del sistema
uname -a
cat /proc/version
```

---

## 💽 Diagnóstico de discos

### Ver información de discos

```bash
# Listar discos
lsblk

# Información detallada
fdisk -l

# SMART status (si está disponible)
smartctl -a /dev/sda

# Verificar errores de disco
dmesg | grep -i error | grep -i sda
```

### Formatear disco

```bash
# ⚠️ ADVERTENCIA: Esto borra todos los datos
# Desmontar disco primero
umount /mnt/sda

# Formatear (solo si es necesario)
mkfs.ext4 /dev/sda

# Montar
mount /dev/sda /mnt/sda
```

---

## 📜 Ver logs del sistema

```bash
# Logs del sistema
cat /var/log/messages

# Logs de Dahua
cat /var/log/dahua.log

# Logs de red
cat /var/log/network.log

# Logs de grabación
cat /var/log/record.log

# Buscar errores
grep -i "error\|fail\|critical" /var/log/messages | tail -50
```

---

## 💾 Backup de configuración

### Método 1: Copiar archivos de configuración

```bash
# Desde el NVR
tar -czf /tmp/backup_$(date +%Y%m%d).tar.gz /etc/ /usr/local/etc/

# Desde tu máquina
scp admin@192.168.100.100:/tmp/backup_*.tar.gz ./
```

### Método 2: Usar API

```bash
# Descargar configuración
curl -s -u admin:contraseña \
  "http://192.168.100.100/cgi-bin/configBackup.cgi?action=startBackup" \
  -o backup_$(date +%Y%m%d).bin
```

---

## 🔄 Restaurar grabaciones

```bash
# Ver grabaciones disponibles
ls -lh /mnt/sda/record/

# Copiar grabación a tu máquina
scp admin@192.168.100.100:/mnt/sda/record/2024/01/15/*.mp4 ./

# Sincronizar directorio completo
rsync -av admin@192.168.100.100:/mnt/sda/record/ ./backup_record/
```

---

## 🛠️ Comandos específicos Dahua

```bash
# Ver estado del servicio Dahua
/etc/init.d/dahua status

# Reiniciar servicio Dahua
/etc/init.d/dahua restart

# Ver configuración actual
cat /usr/local/etc/config.xml

# Ver licencia
cat /usr/local/etc/license.dat

# Ver información del dispositivo
cat /proc/dahua/info
```

---

## 🚨 Troubleshooting de SSH

### Problema 1: Connection refused

```bash
# Verificar que SSH está habilitado
curl -s -u admin:contraseña \
  "http://192.168.100.100/cgi-bin/configManager.cgi?action=getConfig&name=SSHServer"

# Verificar que el puerto está abierto
nmap -p 22 192.168.100.100
```

### Problema 2: Authentication failed

```bash
# Verificar credenciales
# Las credenciales SSH pueden ser diferentes a las de la web
# Intentar con usuario root
ssh root@192.168.100.100
```

### Problema 3: Connection timeout

```bash
# Verificar conectividad
ping 192.168.100.100

# Verificar ruta
traceroute 192.168.100.100

# Verificar firewall
# Si hay firewall entre tú y el NVR, abrir puerto 22
```

---

## 💡 Uno-liners

```bash
# Ver espacio en disco de todas las rutas de grabación
ssh admin@192.168.100.100 "df -h | grep /mnt"

# Ver últimas 50 líneas de log
ssh admin@192.168.100.100 "tail -50 /var/log/messages"

# Buscar errores en logs
ssh admin@192.168.100.100 "grep -i 'error\|fail' /var/log/messages | tail -20"

# Ver procesos Dahua
ssh admin@192.168.100.100 "ps aux | grep dahua"

# Reiniciar servicio Dahua remotamente
ssh admin@192.168.100.100 "/etc/init.d/dahua restart"

# Copiar todas las grabaciones de hoy
ssh admin@192.168.100.100 "find /mnt/sda/record -name '*.mp4' -mtime 0" | xargs -I {} scp admin@192.168.100.100:{} ./
```

---

## 🔗 Ver también

- [`dahua-camera-api.md`](dahua-camera-api.md) — API para configuración
- [`dahua-troubleshooting.md`](dahua-troubleshooting.md) — diagnóstico de fallas
- [`../../scenarios/dahua/02-nvr-sin-disco.md`](../../scenarios/dahua/02-nvr-sin-disco.md) — escenario práctico
- [`../../labs/docker-compose.dahua-broken.yml`](../../labs/docker-compose.dahua-broken.yml) — laboratorio NVR: `cd labs && docker compose -f docker-compose.dahua-broken.yml up -d && ssh root@10.0.200.100`
