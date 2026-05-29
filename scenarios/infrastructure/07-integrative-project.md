# 🎯 Proyecto Integrador: PYME con segmentación, despliegue y respuesta a incidentes

**Dominio:** infrastructure
**Nivel:** 🔴 Avanzado
**Herramientas:** `docker`, `nginx`, `iptables`, `ssh-keygen`, `restic`, `mysql`, `curl`, `nmap`, `systemctl`
**Archivos:** `labs/docker-compose.integrative.yml`

---

## 🎯 Objetivo

Este proyecto integra todo lo aprendido en el repo: desde construir una red segmentada y desplegar una aplicación, hasta hardenearla, hacer backup y responder a un incidente. No hay pasos guiados como en los escenarios — se espera que uses las herramientas y criterios que ya conocés.

> 👉 **Duración estimada:** 4-6 horas distribuídas en 5 fases.

---

## 📋 Entregables

Al finalizar el proyecto:

- [ ] Router con iptables configurado (FORWARD restrictivo)
- [ ] App responde 200 desde el contenedor atacante vía nginx reverse proxy
- [ ] HTTPS funcionando con certificado autofirmado
- [ ] SSH solo con clave pública en puerto no estándar
- [ ] nmap desde el atacante solo muestra los puertos necesarios
- [ ] Backup automático funcionando con restic en el NAS
- [ ] Incidente detectado y resuelto en menos de 15 minutos

---

## 🧪 Entorno de laboratorio

```bash
cd labs
docker compose -f docker-compose.integrative.yml up -d --build
```

### Topología

```text
┌─────────────┐     ┌──────────────────┐     ┌──────────────────┐
│  atacante   │     │    web-nginx     │     │    cron-backup   │
│  10.77.0.100│     │    10.77.0.20    │     │    10.77.0.50    │
└─────────────┘     └────────┬─────────┘     └────────┬─────────┘
                             │                        │
                    ┌────────▼────────────────────────▼─────────┐
                    │              router (firewall)            │
                    │              10.77.0.1                    │
                    │      net.ipv4.ip_forward = 0              │
                    └─────┬────────────┬────────────┬───────────┘
                          │            │            │
                 ┌────────▼──┐  ┌──────▼──────┐  ┌─▼──────────┐
                 │  storage  │  │   web-app   │  │  db-mysql   │
                 │ 10.77.0.10│  │ 10.77.0.30  │  │ 10.77.0.40  │
                 │  (NAS)    │  │  (Node.js)  │  │  (MariaDB)  │
                 └───────────┘  └─────────────┘  └─────────────┘
```

### Servicios

| Servicio | IP | Puerto | Credenciales |
|----------|----|--------|-------------|
| `router` | 10.77.0.1 | — | — |
| `web-nginx` | 10.77.0.20 | 80, 443 | — |
| `web-app` | 10.77.0.30 | 3000 | — |
| `db-mysql` | 10.77.0.40 | 3306 | `root`/`rootpass`, `appuser`/`appsecret` |
| `storage` | 10.77.0.10 | NFS | — |
| `cron-backup` | 10.77.0.50 | — | — |
| `attacker` | 10.77.0.100 | — | — |

> **Importante:** Ningún puerto está expuesto al host. Todo el diagnóstico se hace con `docker exec`.

---

## Fase 1 — Fundación: segmentación de red

> ⏱️ 45-60 min | Referencias: `scenarios/infrastructure/02-build-pyme-infrastructure.md`, `guides/iptables.md`

El router tiene `net.ipv4.ip_forward=0`. Tu primera tarea es convertirlo en un gateway funcional con segmentación.

### Pasos

1. Entrar al router y habilitar IP forwarding:

```bash
docker exec -it integrative-router sh
echo 1 > /proc/sys/net/ipv4/ip_forward
```

1. Verificar conectividad actual desde el atacante:

```bash
docker exec -it integrative-attacker sh
ping -c 2 10.77.0.30   # web-app (debería funcionar, red plana)
ping -c 2 10.77.0.40   # db-mysql (debería funcionar)
```

1. Definir política restrictiva en el router:

```bash
iptables -P FORWARD DROP
iptables -P INPUT DROP
iptables -P OUTPUT ACCEPT
```

1. Agregar reglas para permitir el tráfico mínimo necesario:

```bash
# Permitir tráfico establecido/relacionado
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# Permitir ICMP (ping) para diagnóstico
iptables -A FORWARD -p icmp -j ACCEPT

# web-nginx → web-app:3000
iptables -A FORWARD -s 10.77.0.20 -d 10.77.0.30 -p tcp --dport 3000 -j ACCEPT

# web-app → db-mysql:3306
iptables -A FORWARD -s 10.77.0.30 -d 10.77.0.40 -p tcp --dport 3306 -j ACCEPT

# cron-backup → db-mysql:3306
iptables -A FORWARD -s 10.77.0.50 -d 10.77.0.40 -p tcp --dport 3306 -j ACCEPT

# cron-backup → storage (NFS: 2049)
iptables -A FORWARD -s 10.77.0.50 -d 10.77.0.10 -p tcp --dport 2049 -j ACCEPT
iptables -A FORWARD -s 10.77.0.50 -d 10.77.0.10 -p udp --dport 2049 -j ACCEPT

# NAT para salida a internet (si aplica)
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
```

1. Verificar que el atacante ya no puede alcanzar la DB:

```bash
# Desde attacker:
curl -s http://10.77.0.40:3306   # debería fallar (timeout o reset)
ping -c 1 10.77.0.40              # debería funcionar (ICMP permitido)
```

### ✅ Verificación

- [ ] `iptables -L -v -n` muestra política FORWARD DROP con reglas específicas
- [ ] Desde el atacante se puede hacer ping a cualquier IP
- [ ] Desde el atacante NO se puede conectar a db-mysql:3306
- [ ] `iptables -t nat -L -v -n` muestra regla MASQUERADE

---

## Fase 2 — Despliegue de la aplicación

> ⏱️ 60-90 min | Referencias: `scenarios/infrastructure/01-migrate-to-production.md`, `guides/nginx.md`

### 2.1 Verificar que la app funciona

```bash
docker exec integrative-app curl -s http://localhost:3000/
docker exec integrative-app curl -s http://localhost:3000/health
docker exec integrative-app curl -s http://localhost:3000/usuarios
```

### 2.2 Configurar nginx como reverse proxy

El nginx ya está corriendo pero sin `proxy_pass`. Entrar al contenedor y completar la configuración:

```bash
docker exec -it integrative-nginx sh
```

Editar `/etc/nginx/conf.d/default.conf`. Agregar en `location /`:

```nginx
proxy_pass http://web-app:3000;
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
```

Luego recargar:

```bash
nginx -t && nginx -s reload
```

### 2.3 Verificar el proxy

```bash
# Desde el atacante:
docker exec integrative-attacker curl -s http://10.77.0.20/
docker exec integrative-attacker curl -s http://10.77.0.20/health
docker exec integrative-attacker curl -s http://10.77.0.20/usuarios
```

### 2.4 Configurar HTTPS

El certificado autofirmado ya fue generado. Configurar SSL en nginx:

- Editar el bloque `server` de puerto 443
- Agregar `proxy_pass` igual que en HTTP
- Forzar redirección HTTP → HTTPS

Verificar:

```bash
docker exec integrative-attacker curl -sk https://10.77.0.20/
```

### ✅ Verificación

- [ ] `curl http://10.77.0.20/` desde attacker devuelve JSON de la app
- [ ] `curl https://10.77.0.20/` desde attacker funciona (con -k)
- [ ] `curl http://10.77.0.20/usuarios` lista usuarios de la DB
- [ ] `curl http://10.77.0.20/health` devuelve `{"status":"ok"}`

---

## Fase 3 — Hardening

> ⏱️ 60 min | Referencias: `scenarios/security/01`, `03`, `05`, `guides/ssh.md`

### 3.1 Hardening del router

El router es el punto crítico. Asegurarlo:

```bash
docker exec -it integrative-router sh
```

- Cerrar puertos de entrada no necesarios
- Rate limiting para ICMP
- Logging de paquetes rechazados

```bash
# Rechazar con logging
iptables -A INPUT -j LOG --log-prefix "DROP: " --log-level 4
iptables -A FORWARD -j LOG --log-prefix "DROP-FWD: " --log-level 4
```

### 3.2 Escaneo desde el atacante

Verificar qué puertos están visibles:

```bash
docker exec -it integrative-attacker sh

# Escaneo de red
nmap -sn 10.77.0.0/24

# Escaneo de servicios en el proxy
nmap -sV 10.77.0.20

# Escaneo en la DB (debería estar filtrado)
nmap -sV 10.77.0.40
```

### 3.3 Cerrar servicios innecesarios

Cada contenedor puede tener servicios que no deberían estar expuestos. Verificar con `ss -tlnp` dentro de cada contenedor y cerrar los innecesarios.

### ✅ Verificación

- [ ] `nmap -sV 10.77.0.20` solo muestra puertos 80 y 443
- [ ] `nmap -sV 10.77.0.40` muestra puerto 3306 como `filtered`
- [ ] `nmap -sV 10.77.0.30` muestra puerto 3000 como `filtered` (solo accesible desde web-nginx)
- [ ] El router logea intentos bloqueados (ver con `cat /var/log/messages`)

---

## Fase 4 — Backup y monitoreo

> ⏱️ 45-60 min | Referencias: `scenarios/infrastructure/03-disaster-recovery.md`, `guides/storage_backup.md`

### 4.1 Montar el NAS

El contenedor `storage` tiene NFS corriendo. Montarlo desde `cron-backup`:

```bash
docker exec -it integrative-backup sh

# Instalar cliente NFS si no está
apk add --no-cache nfs-utils

# Crear punto de montaje y montar
mkdir -p /mnt/nas
mount -t nfs storage:/srv/nfs/backups /mnt/nas

# Verificar
df -h /mnt/nas
```

### 4.2 Inicializar el repositorio restic

```bash
restic init --repo /mnt/nas/restic
```

### 4.3 Backup manual de la base de datos

```bash
# Dump de la DB
mysqldump -h db-mysql -u root -prootpass appdb > /tmp/appdb.sql

# Backup con restic
restic -r /mnt/nas/restic backup /tmp/appdb.sql

# Verificar
restic -r /mnt/nas/restic snapshots
```

### 4.4 Programar backup automático

Crear un script `/scripts/backup.sh`:

```bash
#!/bin/sh
set -e
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
mysqldump -h db-mysql -u root -prootpass appdb > /tmp/appdb-$TIMESTAMP.sql
restic -r /mnt/nas/restic backup /tmp/appdb-$TIMESTAMP.sql
rm -f /tmp/appdb-$TIMESTAMP.sql
```

Agregar entrada cron:

```bash
echo "0 */6 * * * sh /scripts/backup.sh" >> /etc/crontabs/root
crond -b
```

### 4.5 Monitoreo básico

Crear script `/scripts/check.sh` que verifique:

- HTTP 200 en `http://web-nginx/health`
- Espacio en disco (`df -h /mnt/nas`)
- Memoria del contenedor `web-app` (`docker stats --no-stream`)
- Procesos de node y mysql

### ✅ Verificación

- [ ] `restic -r /mnt/nas/restic snapshots` muestra al menos un snapshot
- [ ] El backup programado se ejecuta cada 6 horas
- [ ] El script de monitoreo devuelve 0 (todo ok)
- [ ] Se puede restaurar un backup exitosamente

---

## Fase 5 — Incidente

> ⏱️ 15-30 min | Sin referencias — aplicá lo aprendido

Llega una alerta: "la app no responde". Diagnosticá y resolvé en menos de 15 minutos.

### Posibles incidentes (elegir uno)

| Incidente | Síntoma | Para diagnosticar |
|-----------|---------|-------------------|
| **OOM en la app** | `docker logs integrative-app` muestra `JavaScript heap out of memory` | `docker stats`, `curl /mem` |
| **DB caída** | `curl /usuarios` devuelve 503 | `docker logs integrative-db`, `mysqladmin ping` |
| **Proxy mal configurado** | `curl http://10.77.0.20/` no llega a la app | `docker logs integrative-nginx`, revisar `proxy_pass` |
| **Firelock** | nadie puede pasar del router | `iptables -L -v -n`, verificar reglas FORWARD |
| **Backup corrupto** | `restic snapshots` da error | `restic check`, revisar integridad del repositorio |

### Para simular un incidente (instructor / ayudante)

```bash
# OOM: reducir el límite de memoria de la app
docker update integrative-app --memory 32m --memory-swap 32m

# DB caída: detener mysql
docker exec integrative-db pkill mariadbd

# Firelock: borrar reglas del router
docker exec integrative-router iptables -F
docker exec integrative-router iptables -P FORWARD DROP
docker exec integrative-router iptables -P INPUT DROP
```

### Reporte de incidente

Documentar:

```text
Incidente: <qué pasó>
Síntoma:  <qué se observó>
Diagnóstico: <comandos ejecutados>
Causa raíz: <qué lo causó>
Resolución: <qué se hizo>
Tiempo:    <minutos>
```

### ✅ Verificación

- [ ] La app vuelve a responder 200
- [ ] Se identificó la causa raíz
- [ ] Se aplicó una solución definitiva (no solo reiniciar)

---

## 🏁 Entrega final

Completar el checklist:

- [ ] **Fase 1:** router con iptables restrictivo y forwarding habilitado
- [ ] **Fase 2:** app funcionando vía nginx reverse proxy con HTTPS
- [ ] **Fase 3:** hardening validado con nmap desde el atacante
- [ ] **Fase 4:** backup automático funcionando + script de monitoreo
- [ ] **Fase 5:** incidente detectado, diagnosticado y resuelto
- [ ] Reporte de incidente documentado

---

## 🔗 Referencias

- [`iptables`](../../guides/iptables.md) — firewall y NAT
- [`nginx`](../../guides/nginx.md) — reverse proxy, SSL, hardening
- [`ssh`](../../guides/ssh.md) — claves y hardening
- [`scenarios/infrastructure/02-build-pyme-infrastructure.md`](02-build-pyme-infrastructure.md) — segmentación y NAS
- [`scenarios/infrastructure/01-migrate-to-production.md`](01-migrate-to-production.md) — despliegue y migración
- [`scenarios/infrastructure/03-disaster-recovery.md`](03-disaster-recovery.md) — backup y restore
- [`scenarios/security/01-detect-and-block-malicious-ips.md`](../security/01-detect-and-block-malicious-ips.md) — detección de ataques
- [`scenarios/system/14-docker-troubleshooting.md`](../system/14-docker-troubleshooting.md) — crash loops y OOM
- [`scenarios/web/05-502-bad-gateway.md`](../web/05-502-bad-gateway.md) — backend caído
