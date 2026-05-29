⬅️ [Volver al README principal](../README.md)

---

## 🧭 Navegación

- 🧠 [concepts/](../concepts/) — pensar como sysadmin
- 🛠️ [guides/](../guides/) — herramientas
- 🚨 [scenarios/](../scenarios/) — casos reales

---

# Laboratorio Docker — Prácticas de administración de servidores

Múltiples entornos Docker para practicar **desde cero** la administración de servidores Linux y redes. Cada `docker-compose.*.yml` se enfoca en un tipo de práctica distinto.

---

## 🎯 Cuándo usar esta sección
Usá labs/ cuando:

- necesitás datos reales para probar comandos
- querés practicar sin romper un sistema real
- necesitás validar un pipeline antes de usarlo en producción

👉 Esto es tu entorno seguro de práctica

## 🔄 Flujo recomendado
concepts → guides → labs → scenarios
👉 pensar → aprender → practicar → aplicar

---

## Requisitos

```bash
docker --version
docker compose version  # o docker-compose
```

---

## Escenarios disponibles

| Comando | Práctica |
|---------|----------|
| `docker compose up -d` | Servidores funcionando (SSH, web, DB, monitoreo) |
| `docker compose -f docker-compose.broken.yml up -d` | Servicios rotos para diagnosticar |
| `docker compose -f docker-compose.from-scratch.yml up -d` | Servidores desde cero (instalar todo) |
| `docker compose -f docker-compose.network.yml up -d` | Problemas de red (latencia, pérdida, DNS) |
| `docker compose -f docker-compose.security.yml up -d` | Servicios vulnerables para hardening |
| `docker compose -f docker-compose.performance.yml up -d` | Stress de CPU, memoria, I/O, swap |
| `docker compose -f docker-compose.cron.yml up -d` | Cron jobs con fallos para diagnóstico |
| `docker compose -f docker-compose.tls.yml up -d` | TLS expirado y renovación manual |

> **Importante**: Usa `-f` para elegir el archivo. Si no pones `-f`, usa el `docker-compose.yml` por defecto (el original).

---

## 1. Laboratorio base (`docker-compose.yml`)

8 servicios pre-configurados para practicar conectividad, escaneo y ataques controlados.

```bash
docker compose up -d
```

### Servicios

| Servicio | Puerto | Credenciales |
|----------|--------|--------------|
| `ssh-hardened` | 2222 | `admin` + clave pública |
| `ssh-weak` | 2223 | `admin` / `admin123` |
| `ssh-internal` | — | Solo vía bastion |
| `web-nginx` | 8080 | HTTP |
| `web-apache` | 8081 | HTTP |
| `db-mysql` | 3306 | `admin` / `secret` |
| `db-postgres` | 5432 | `admin` / `postgrespass` |
| `monitoring` | — | `admin` + clave pública |

### Conexión rápida

```bash
# SSH
ssh -p 2222 admin@localhost

# Web
curl localhost:8080

# MySQL
mysql -h localhost -P 3306 -u admin -psecret

# Contenedor de monitoreo (tiene tcpdump, nmap, curl)
docker exec -it monitoring bash
```

### Prácticas con este lab

| Práctica | Comando |
|----------|---------|
| Fuerza bruta SSH | `for i in $(seq 1 50); do sshpass -p "wrong$i" ssh admin@localhost -p 2223; done` |
| Port scan | `docker exec monitoring nmap -sS 172.17.0.0/24` |
| Capturar MySQL | `docker exec monitoring tcpdump -i any port 3306 -A` |
| Túnel SSH | `ssh -p 2222 -L 3307:db-mysql:3306 admin@localhost` |

---



## 2. Servicios rotos (`docker-compose.broken.yml`)

Cada contenedor tiene un **problema intencional** que debes diagnosticar y resolver. Ideal para aprender a leer logs, usar herramientas de diagnóstico y arreglar configuraciones.

```bash
docker compose -f docker-compose.broken.yml up -d
```

### Problemas incluidos

| Servicio | Problema | Síntoma | Herramientas de diagnóstico |
|----------|----------|---------|-----------------------------|
| `nginx-broken` | Config con error de sintaxis | nginx no arranca | `docker logs`, `nginx -t` |
| `ssh-bad-perms` | SSH permite root, sin límite de intentos | Inseguro pero funcional | `ssh -v`, revisar `/etc/ssh/` |
| `mysql-bad-grants` | Usuarios sin permisos, root sin password | `Access denied` al conectar | `mysql -u root`, `SHOW GRANTS` |
| `port-conflict-a/b` | Dos servicios en el mismo puerto host | `docker compose` falla al levantar | Mensaje de error de Docker |
| `dns-broken` | DNS apunta a IP inexistente | No resuelve nombres | `cat /etc/resolv.conf`, `dig` |
| `disk-full` | Disco ocupado con archivo basura | `No space left on device` | `df -h`, `du -sh /*` |
| `zombie` | Proceso zombie | `ps aux` muestra proceso `Z` | `ps aux \| grep Z` |
| `cpu-hog` | Bucle infinito consumiendo CPU | Servidor lento, CPU al 100% | `top`, `ps aux --sort=-%cpu` |
| `loopback-down` | Interfaz loopback caída | `ping 127.0.0.1` falla | `ip link show lo`, `ip link set lo up` |
| `cron-down` | crond no está ejecutándose | Tareas programadas no corren | `ps aux \| grep cron`, `crond -b` |

### Ejemplo práctico

```bash
# 1. Iniciar el lab de servicios rotos
docker compose -f docker-compose.broken.yml up -d

# 2. Verificar que servicios fallaron
docker compose -f docker-compose.broken.yml ps

# 3. Diagnosticar nginx
docker logs nginx-broken
# Deberías ver: "emerg" "invalid directive" o "syntax error"

# 4. Arreglar (desde dentro del contenedor)
docker exec -it nginx-broken sh
# Editar /etc/nginx/conf.d/default.conf y corregir la sintaxis
# Luego: nginx -s reload

# 5. Cuando arregles todo, resetear
docker compose -f docker-compose.broken.yml down -v
```

### Comandos de diagnóstico útiles

```bash
# Ver logs de un contenedor
docker logs <container>

# Ver qué procesos están corriendo
docker top <container>

# Entrar al contenedor
docker exec -it <container> sh

# Ver detalles (IP, mounts, etc.)
docker inspect <container>

# Ver uso de recursos
docker stats --no-stream
```

---

## 3. From scratch (`docker-compose.from-scratch.yml`)

Contenedores **mínimos** que simulan servidores recién instalados. Solo tienen SSH. Tú instalas todo lo demás.

```bash
docker compose -f docker-compose.from-scratch.yml up -d --build
```

### Servidores disponibles

| Servidor | Distro | Puerto SSH | Puerto HTTP |
|----------|--------|------------|-------------|
| `ubuntu-bare` | Ubuntu 22.04 | 2201 | 8001 |
| `debian-bare` | Debian Bookworm | 2202 | 8002 |
| `rocky-bare` | Rocky Linux 9 | 2203 | 8003 |
| `alpine-bare` | Alpine Linux | 2204 | — |
| `dind` | Docker-in-Docker | — (API 2375) | — |
| `no-ssh` | Alpine (sin SSH) | — (solo `docker exec`) | — |

### Ejemplo: aprovisionar servidor web desde cero

```bash
# 1. Conectar al servidor Ubuntu
ssh practica@localhost -p 2201
# Password: practica123

# 2. Instalar nginx (como si fuera un server recién comprado)
sudo apt update
sudo apt install -y nginx
sudo systemctl start nginx  # En Docker no funciona systemctl
# Alternativa:
sudo nginx

# 3. Crear página
echo "<h1>Mi primer servidor</h1>" | sudo tee /var/www/html/index.html

# 4. Probar (desde tu máquina)
curl localhost:8001

# 5. Configurar firewall
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw --force enable
sudo ufw status verbose
```

### Ejemplo: practicar Docker-in-Docker

```bash
# Conectar al cliente Docker remoto
docker -H localhost:2375 info

# O desde dentro del contenedor
docker exec -it dind sh
docker run -d nginx:alpine
docker ps
```

### Ejemplo: recuperar servidor sin SSH

```bash
# El contenedor no-ssh no tiene SSH corriendo
# Solo puedes acceder así:
docker exec -it no-ssh sh

# Tu tarea: instalar y configurar SSH para acceso remoto
apk add openssh-server
ssh-keygen -A
echo "root:admin123" | chpasswd
/usr/sbin/sshd
# Ahora deberías poder hacer ssh root@localhost -p ??? (mapear puerto)
```

---

## 4. Escenarios de red (`docker-compose.network.yml`)

Simulación de problemas de red: latencia, pérdida de paquetes, DNS roto, routing.

```bash
docker compose -f docker-compose.network.yml up -d
```

### Escenarios

| Servicio | Problema simulado | Síntoma |
|----------|-------------------|---------|
| `latency-client` | 200ms de latencia | `ping server-web` muestra RTT alto |
| `packet-loss-client` | 20% pérdida de paquetes | `ping` muestra pérdida, conexiones lentas |
| `choppy-client` | 300ms + 15% pérdida + 1% corruptos | Conexión casi inusable |
| `dns-broken-client` | DNS apunta a 192.0.2.1 | `ping google.com` falla por resolución |
| `router` | Router Linux entre subredes | NAT y forwarding |
| `internal-server` | Servidor en red interna | Solo accesible vía router |
| `closed-ports` | Sin servicios escuchando | Todos los puertos cerrados |
| `server-web` | Servidor web normal (referencia) | Responde en puerto 80 |
| `server-dns` | DNS interno autoritativo | Resuelve `*.lab.test` |

### Ejemplo: diagnosticar latencia

```bash
# 1. Entrar al cliente con latencia
docker exec -it latency-client sh

# 2. Hacer ping al servidor web
ping -c 10 server-web
# Deberías ver RTT de ~200ms

# 3. Usar mtr para ver el path
mtr server-web

# 4. Ver la regla tc que causa la latencia
tc qdisc show dev eth0

# 5. Eliminar la latencia (solucionar)
tc qdisc del dev eth0 root
```

### Ejemplo: resolver DNS roto

```bash
# 1. Entrar al cliente con DNS roto
docker exec -it dns-broken-client sh

# 2. Verificar que no resuelve
ping google.com  # Debería fallar

# 3. Ver config DNS
cat /etc/resolv.conf  # Muestra 192.0.2.1

# 4. Arreglar
echo "nameserver 1.1.1.1" > /etc/resolv.conf

# 5. Verificar
ping google.com  # Ahora funciona
```

### Probar el DNS interno

```bash
# Desde cualquier contenedor del lab
docker exec -it <container> sh
apk add --no-cache bind-tools  # si no tiene dig

# Consultar el DNS interno
dig @server-dns server-web.lab.test
dig @server-dns internal-server.lab.test
```

---

## 5. Seguridad (`docker-compose.security.yml`)

Servicios intencionalmente vulnerables para practicar hardening y detectar ataques.

> **ATENCIÓN**: NO expongas estos puertos a internet. Son solo para learning en localhost.

```bash
docker compose -f docker-compose.security.yml up -d
```

### Servicios vulnerables

| Servicio | Vulnerabilidad | Puerto |
|----------|---------------|--------|
| `sec-ssh-weak` | Password débil, root login | 2225 |
| `sec-ssh-weak-keys` | Algoritmos SSH débiles | 2226 |
| `sec-web-outdated` | Apache 2.2 EOL (sin parches) | 8083 |
| `sec-web-info-leak` | Directory listing, backups expuestos | 8084 |
| `sec-mysql-no-auth` | MySQL sin password | 3308 |
| `sec-ftp-anonymous` | FTP anónimo con escritura | 21 |
| `sec-snmp-public` | SNMP community "public" | 161 |
| `sec-telnet` | Telnet (tráfico sin cifrar) | 2323 |
| `sec-attacker` | Contenedor con herramientas de ataque | — |

### Ejemplo: detectar y explotar

```bash
# 1. Escanear servicios vulnerables desde el contenedor attacker
docker exec -it sec-attacker sh

# 2. Escanear puertos
nmap -sV sec-ssh-weak sec-web-outdated sec-mysql-no-auth

# 3. Fuerza bruta SSH
apk add --no-cache hydra
hydra -l root -P /tmp/wordlist.txt ssh://sec-ssh-weak

# 4. Conectar a MySQL sin password
mysql -h sec-mysql-no-auth -u root

# 5. Ver información expuesta en web-info-leak
curl sec-web-info-leak/
curl sec-web-info-leak/db_config.php.bak
curl sec-web-info-leak/backup.sql
```

### Ejemplo: capturar tráfico Telnet (sin cifrar)

```bash
# 1. En un terminal, capturar tráfico
docker exec -it sec-attacker sh
tcpdump -i any port 23 -X

# 2. En otro terminal, conectar al telnet
telnet localhost 2323
# Login: root
# Password: telnet123

# 3. Ver en tcpdump que usuario y password viajan en texto plano
```

### Prácticas de hardening con este lab

| Objetivo | Qué hacer |
|----------|-----------|
| Hardening SSH | Configurar `PermitRootLogin no`, `PasswordAuthentication no`, cambiar puerto |
| Hardening web | Deshabilitar `server_tokens`, `autoindex`, proteger backups |
| Hardening MySQL | Poner password a root, eliminar usuarios anónimos |
| Hardening FTP | Deshabilitar anónimo, restringir a usuarios locales |
| Hardening SNMP | Cambiar community string, restringir acceso |
| Detectar ataques | Configurar fail2ban, monitorear logs |

---

## 6. Performance (`docker-compose.performance.yml`)

Contenedores con `stress-ng` para simular problemas de rendimiento: CPU alta, memory leak, I/O saturado, swap pressure y context switches.

```bash
docker compose -f docker-compose.performance.yml up -d
```

### Servicios

| Servicio | Problema simulado | Escenario relacionado |
|----------|-------------------|----------------------|
| `cpu-stress` | 2 workers consumiendo 100% CPU | 04-high-cpu-runaway-process |
| `mem-stress` | 512MB de memoria asignada | 05-memory-issues-oom, 12-python-memory-leak |
| `io-stress` | 4 workers saturando I/O | 07-high-io-wait |
| `swap-stress` | Contenedor con 128MB RAM + 128MB swap, forzando swap | 10-swap-exhaustion |
| `ctx-stress` | 512 workers causando context switches | 13-high-context-switches |
| `perf-diagnostics` | Contenedor con herramientas de diagnóstico | — |

### Ejemplo: diagnosticar CPU alta

```bash
# 1. Ver qué contenedor consume más CPU
docker stats --no-stream

# 2. Entrar al contenedor de diagnóstico
docker exec -it perf-diagnostics sh

# 3. Ver procesos dentro del contenedor problemático
docker exec cpu-stress top -b -n 1

# 4. Matar el stress
docker exec cpu-stress pkill stress-ng
```

### Ejemplo: simular OOM killer

```bash
# 1. Verificar que mem-stress está consumiendo memoria
docker stats --no-stream mem-stress

# 2. Ver logs de OOM
docker logs mem-stress 2>&1 | grep -i oom

# 3. Si el contenedor tiene límite de memoria, Docker lo matará
docker inspect mem-stress | grep -i mem
```

---

## 7. Cron (`docker-compose.cron.yml`)

Servicio Alpine con múltiples cron jobs que fallan de diferentes formas: script inexistente, permisos incorrectos, PATH roto, MAILTO no configurado.

```bash
docker compose -f docker-compose.cron.yml up -d
```

### Jobs configurados

| Job | Hora | Problema |
|-----|------|----------|
| `backup` | 02:00 | Ninguno (funciona OK) |
| `reporte-roto` | 03:00 | Script no existe |
| `limpieza-sin-permisos` | 04:00 | Sin permisos para borrar |
| `no-existe.sh` | 05:00 | Ruta inexistente |
| `notificacion` | 06:00 | Sin MTA configurado |

### Ejemplo: diagnosticar fallos de cron

```bash
# 1. Ver los jobs configurados
docker exec cron-lab cat /etc/crontabs/root

# 2. Ver logs de cron
docker exec cron-lab cat /var/log/messages | grep CRON

# 3. Ver si crond está corriendo
docker exec cron-lab ps aux | grep crond

# 4. Ver logs de los jobs que fallaron
docker exec cron-lab cat /var/log/cron-jobs.log
```

---

## 8. TLS (`docker-compose.tls.yml`)

Nginx con certificado TLS que expiró hace 30 días. Incluye cliente con `curl` y `openssl` para diagnosticar.

```bash
docker compose -f docker-compose.tls.yml up -d
```

### Servicios

| Servicio | Puerto | Descripción |
|----------|--------|-------------|
| `nginx-tls-expired` | 8443 (HTTPS), 8085 (HTTP) | Nginx con TLS expirado |
| `tls-client` | — | Cliente con curl + openssl |

### Ejemplo: detectar certificado expirado

```bash
# 1. Intentar conectar (fallará por certificado expirado)
docker exec tls-client curl https://nginx-tls-expired

# 2. Ver fechas del certificado
docker exec tls-client sh -c 'echo | openssl s_client -connect nginx-tls-expired:443 2>/dev/null | openssl x509 -noout -dates'

# 3. Verificar el certificado
docker exec tls-client openssl s_client -connect nginx-tls-expired:443

# 4. Renovar el certificado
docker exec nginx-tls-expired sh -c '
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/server.key \
    -out /etc/nginx/ssl/server.crt \
    -subj "/CN=nginx-tls-expired" &&
  nginx -s reload
'

# 5. Verificar que ahora funciona
docker exec tls-client curl -k https://nginx-tls-expired
```

---

## Logs de práctica

Archivos de log incluidos para practicar pattern matching con `grep`, `awk`, `sort`:

| Archivo | Contenido | Patrón clave |
|---------|-----------|--------------|
| `fork-bomb.log` | Logs de detección de fork bomb | `fork: retry: Resource temporarily unavailable` |
| `cron.log` | Entradas de cron con fallos variados | `exit 127`, `exit 126`, `exit 1`, `Connection refused` |
| `auth.log` | Intentos de login SSH | `Failed password`, `Accepted publickey` |
| `nginx_access.log` | Accesos web con errores | `4xx`, `5xx` |
| `syslog.log` | Logs del sistema | `error`, `warning`, `kernel` |

### Ejemplo: practicar con fork-bomb.log

```bash
# Contar errores de fork
grep -c "fork: retry" labs/fork-bomb.log

# Ver solo las líneas de OOM
grep "Out of memory" labs/fork-bomb.log

# Extraer PIDs de procesos matados
grep "Killed process" labs/fork-bomb.log | awk '{print $4, $5}'
```

### Ejemplo: practicar con cron.log

```bash
# Ver solo los fallos (exit != 0)
grep "exit [^0]" labs/cron.log

# Contar fallos por tipo de error
grep "exit" labs/cron.log | awk '{print $NF}' | sort | uniq -c | sort -rn

# Ver solo los errores de PATH (script no encontrado)
grep "No such file" labs/cron.log
```

---

## Comandos transversales

### Iniciar terminal interactiva en un contenedor

```bash
# Si el contenedor tiene shell (sh, bash)
docker exec -it <container> sh
docker exec -it <container> bash

# Si el contenedor usa distro diferente (ubuntu, debian)
docker exec -it <container> bash    # Ubuntu/Debian/Rocky
docker exec -it <container> sh      # Alpine
```

### Ver logs de un servicio

```bash
docker logs <container>
docker logs -f <container>  # Follow (en tiempo real)
docker logs --tail 50 <container>  # Últimas 50 líneas
```

### Ver IPs de los contenedores

```bash
docker inspect <container> | grep IPAddress
# O más directo:
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' <container>
```

### Detener y limpiar todo

```bash
# Detener un lab específico
docker compose -f docker-compose.broken.yml down

# Detener y borrar volúmenes (reset completo)
docker compose -f docker-compose.broken.yml down -v

# Detener todo (todos los labs)
docker compose down
docker compose -f docker-compose.broken.yml down -v
docker compose -f docker-compose.from-scratch.yml down -v
docker compose -f docker-compose.network.yml down -v
docker compose -f docker-compose.security.yml down -v
```

### Ver todos los contenedores activos

```bash
docker ps
docker stats  # Recursos en vivo
```

---

## Estructura de archivos

```
labs/
├── docker-compose.yml               # Lab base (8 servicios pre-configurados)
├── docker-compose.broken.yml        # Servicios rotos para diagnosticar
├── docker-compose.from-scratch.yml  # Servidores desde cero
├── docker-compose.network.yml       # Problemas de red
├── docker-compose.security.yml      # Servicios vulnerables
├── docker-compose.performance.yml   # Stress CPU, mem, I/O, swap
├── docker-compose.cron.yml          # Cron jobs con fallos
├── docker-compose.tls.yml           # TLS expirado y renovación
├── README.md                        # Este archivo
├── setup.sh                         # Setup inicial (genera clave SSH)
├── monitoring.Dockerfile            # Dockerfile para contenedor monitoring
├── monitoring-ssh-setup.sh          # Script de setup SSH para monitoring
├── www/                             # Archivos web de ejemplo
├── from-scratch/                    # Dockerfiles para builds custom
│   ├── ubuntu-bare.Dockerfile
│   ├── debian-bare.Dockerfile
│   └── rocky-bare.Dockerfile
├── broken/                          # Configuraciones rotas
│   ├── nginx-bad.conf
│   ├── nginx-info-leak.conf
│   ├── ssh-permissive-config
│   ├── mysql-bad-grants.sql
│   ├── network-broken.sh
│   ├── zombie-maker.sh
│   └── www-info-leak/               # Archivos con información expuesta
│       ├── index.html
│       ├── db_config.php.bak
│       └── backup.sql
├── tls-setup.sh                     # Script de setup TLS (expirado)
├── cron-jobs.sh                     # Scripts de cron para el lab
├── fork-bomb.log                    # Logs de fork bomb (práctica)
├── cron.log                         # Logs de cron con fallos (práctica)
├── auth.log                         # Logs de SSH
├── nginx_access.log                 # Logs de nginx
├── syslog.log                       # Logs del sistema
└── (otros archivos de práctica)
```

⬅️ [Volver al README principal](../README.md)