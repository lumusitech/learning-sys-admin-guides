# SSH — Guía completa de administración remota

**Nivel:** 🟡 Intermedio
**Archivos de práctica:** Contenedores Docker (`ssh-hardened`, `ssh-weak`)
**Ver escenarios relacionados:** [`networking/01-detect-ssh-brute-force`](../scenarios/networking/01-detect-ssh-brute-force.md), [`system/03-provisioning`](../scenarios/system/03-new-server-provisioning.md)

## ⚡ Quick command

`ssh user@host`

## ⚡ Quick run

```bash
ssh -p 2222 admin@localhost
```

---

## 📑 Índice

1. [¿Qué es SSH?](#qué-es-ssh)
2. [Conexión básica](#conexión-básica)
3. [Autenticación por clave pública](#autenticación-por-clave-pública)
4. [Configuración del servidor SSH (sshd)](#configuración-del-servidor-ssh-sshd)
5. [Hardening del servidor SSH](#hardening-del-servidor-ssh)
6. [Restricción por IP (AllowUsers + firewall)](#restricción-por-ip-allowusers--firewall)
7. [Configuración del cliente SSH](#configuración-del-cliente-ssh)
8. [Conexión desde WSL2](#conexión-desde-wsl2)
9. [Túneles SSH (port forwarding)](#túneles-ssh-port-forwarding)
10. [ProxyJump y bastion hosts](#proxyjump-y-bastion-hosts)
11. [Sesiones persistentes y multiplexado](#sesiones-persistentes-y-multiplexado)
12. [Transferencia de archivos (scp, rsync)](#transferencia-de-archivos)
13. [Automatización con scripts](#automatización-con-scripts)
14. [Auditoría y logs](#auditoría-y-logs)
15. [Recuperación de acceso perdido](#recuperación-de-acceso-perdido)
16. [Laboratorio Docker para practicar](#laboratorio-docker-para-practicar)
17. [Uno-liners imprescindibles](#uno-liners-imprescindibles)

---

## 🧠 ¿Qué es SSH?

**SSH** (Secure Shell) es el protocolo estándar para administración remota de servidores. Proporciona:

- **Cifrado** de extremo a extremo (no como telnet que manda texto plano)
- **Autenticación** por contraseña, clave pública, o certificados
- **Integridad** de datos (nadie puede modificar el tráfico)
- **Túneles** para redirigir puertos y servicios

### Por qué SSH es esencial para un sysadmin

- Es la puerta de entrada a cualquier servidor
- Una mala configuración expone el servidor a ataques (brute force, MITM)
- El hardening SSH es el primer paso al provisionar un servidor
- Permite ejecutar comandos, transferir archivos, y crear túneles seguros

---

## Conexión básica

```bash
ssh usuario@servidor
ssh usuario@192.168.1.100
ssh usuario@dominio.com -p 22
```

| Parámetro | Descripción |
|-----------|-------------|
| `usuario` | Usuario del sistema remoto |
| `servidor` | IP o nombre de host del servidor |
| `-p puerto` | Puerto SSH (por defecto 22) |
| `-v` | Verboso (para depurar conexión) |
| `-vvv` | Muy verboso |
| `-q` | Modo silencioso |

```bash
# Primer conexión (aceptar fingerprint del servidor)
ssh admin@192.168.1.100
# The authenticity of host '192.168.1.100 (192.168.1.100)' can't be established.
# ECDSA key fingerprint is SHA256:...
# Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

> **Fingerprint**: huella digital del servidor. Verifícala con el administrador del servidor antes de aceptar. Previene ataques MITM.

### Ejecutar comando remoto sin sesión interactiva

```bash
ssh admin@servidor "ls -la /var/log"
ssh admin@servidor "systemctl status nginx"
ssh admin@servidor "df -h && free -m && uptime"
```

---

## Autenticación por clave pública

Es más segura que contraseña porque:

- No se puede adivinar por fuerza bruta
- No viaja por la red (solo el challenge firmado)
- Se puede revocar sin cambiar la clave del servidor

### Generar par de claves

```bash
ssh-keygen -t ed25519 -C "mi-correo@ejemplo.com"
```

| Opción | Descripción |
|--------|-------------|
| `-t ed25519` | Tipo de clave: **ed25519** (recomendada, más segura y rápida) |
| `-t rsa -b 4096` | RSA de 4096 bits (alternativa, compatible con sistemas viejos) |
| `-C "comentario"` | Comentario para identificar la clave |
| `-f ~/.ssh/id_ed25519` | Ruta del archivo de clave (por defecto) |
| `-N "frase"` | Frase de paso (passphrase) para cifrar la clave privada |

```bash
# Sin passphrase (menos seguro, pero útil para automatización)
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519

# Con passphrase (recomendado)
ssh-keygen -t ed25519 -C "admin@empresa.com"
# Te pedirá una frase de paso
```

### Archivos generados

| Archivo | Descripción |
|---------|-------------|
| `~/.ssh/id_ed25519` | Clave **privada** — NUNCA compartir, permisos 600 |
| `~/.ssh/id_ed25519.pub` | Clave **pública** — se copia al servidor |

### Copiar clave pública al servidor

```bash
# Método recomendado (si tienes acceso por contraseña)
ssh-copy-id -i ~/.ssh/id_ed25519.pub admin@servidor

# Manual (si no tienes ssh-copy-id)
cat ~/.ssh/id_ed25519.pub | ssh admin@servidor "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

> **Explicación de `ssh-copy-id`**: copia tu clave pública al archivo `~/.ssh/authorized_keys` del servidor, y configura permisos correctos automáticamente.

### Verificar que funciona

```bash
ssh admin@servidor
# Si todo está bien, entra directamente (o pide passphrase de la clave)
```

### Frase de paso y ssh-agent

Para no escribir la frase cada vez que te conectas:

```bash
# Iniciar agente (se puede añadir al .bashrc)
eval "$(ssh-agent -s)"

# Agregar clave (pedirá la frase una vez)
ssh-add ~/.ssh/id_ed25519

# Listar claves cargadas
ssh-add -l

# Eliminar todas las claves
ssh-add -D
```

#### ssh-agent en WSL2

```powershell
# En Windows, configurar que WSL2 use el agente de Windows
# Instalar: https://github.com/rupor-github/wsl-ssh-agent
# O usar:
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

---

## Configuración del servidor SSH (sshd)

Archivo de configuración del servidor: **`/etc/ssh/sshd_config`**

> **No confundir** con `/etc/ssh/ssh_config` (configuración del cliente) vs `sshd_config` (configuración del servidor).

### Configuración segura mínima

```bash
# /etc/ssh/sshd_config — Configuración hardening

# Puerto (cambiarlo de 22 reduce ruido de bots)
Port 2222

# Solo SSH protocolo 2 (el 1 es inseguro)
Protocol 2

# Autenticación
PubkeyAuthentication yes           # Activar clave pública
PasswordAuthentication no          # DESACTIVAR contraseña (solo claves)
PermitEmptyPasswords no            # Nunca permitir contraseñas vacías
ChallengeResponseAuthentication no # Desactivar desafío respuesta
UsePAM yes                         # Mantener PAM para logeo

# Usuarios permitidos (whitelist)
AllowUsers admin carludev          # Solo estos usuarios pueden SSH
# DenyUsers root                   # Opcional: bloquear root por usuario
PermitRootLogin prohibit-password  # Root solo con clave (o 'no' para bloquear)

# Límites y seguridad
MaxAuthTries 3                     # Máximo 3 intentos de autenticación
MaxSessions 10                     # Máximo 10 sesiones simultáneas
MaxStartups 10:30:60               # 10 conexiones sin autenticar, luego 30% probabilidad de drop, luego 60 máximo
LoginGraceTime 30                  # 30 segundos para autenticarse

# Timeout de sesión inactiva
ClientAliveInterval 300            # Enviar keepalive cada 300s
ClientAliveCountMax 2              # Desconectar tras 2 keepalives sin respuesta

# Cifrado (rechazar algoritmos débiles)
KexAlgorithms curve25519-sha256,diffie-hellman-group16-sha512
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com

# Logging
LogLevel VERBOSE                   # Log detallado de autenticación
SyslogFacility AUTH

# Red
ListenAddress 0.0.0.0              # Escuchar en todas las interfaces
# ListenAddress 192.168.1.100      # O solo en una IP específica

# Desactivar forwarding innecesario
AllowTcpForwarding yes             # Mantener si usas túneles, si no: no
X11Forwarding no                   # Desactivar X11 (casi nunca necesario)
AllowAgentForwarding yes           # Útil para bastion hosts
PermitTunnel no                    # Desactivar túneles de capa 3
```

> La configuración `PasswordAuthentication no` requiere tener la clave pública configurada ANTES de aplicar, o te quedarás fuera.

### Después de modificar sshd_config

```bash
# Verificar sintaxis
sudo sshd -t

# Si dice "no errors", recargar
sudo systemctl reload sshd
# o
sudo systemctl restart sshd

# Dejar una segunda sesión SSH abierta mientras pruebas
# Por si la nueva configuración te bloquea
```

> **Siempre** mantener una sesión SSH activa mientras pruebas cambios de configuración. Si algo falla, usas esa sesión para revertir.

---

## Hardening del servidor SSH

### 1. Cambiar puerto

```bash
# En /etc/ssh/sshd_config
Port 2222

# En el firewall
sudo iptables -A INPUT -p tcp --dport 2222 -s TU_IP -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 2222 -j DROP

# Al conectarte
ssh -p 2222 admin@servidor
```

### 2. Bloquear root login

```bash
# En /etc/ssh/sshd_config
PermitRootLogin no
# O: PermitRootLogin prohibit-password  (solo con clave, sin contraseña)
```

Creas un usuario normal con sudo y te conectas con ese:

```bash
# En el servidor
sudo useradd -m -G sudo admin
sudo passwd admin
# Luego configuras tu clave pública para admin
```

### 3. AllowUsers (whitelist de usuarios)

```bash
AllowUsers admin carludev deploy
```

### 4. Fail2ban (protección contra fuerza bruta)

```bash
sudo apt install fail2ban

# /etc/fail2ban/jail.local
[sshd]
enabled = true
port    = ssh
logpath = %(sshd_log)s
maxretry = 3
bantime = 3600
findtime = 600
```

### 5. Autenticación de dos factores (2FA)

```bash
sudo apt install libpam-google-authenticator

# Configurar para el usuario
google-authenticator

# En /etc/pam.d/sshd
auth required pam_google_authenticator.so

# En /etc/ssh/sshd_config
ChallengeResponseAuthentication yes
AuthenticationMethods publickey,keyboard-interactive
```

### 6. Restricciones del sistema (limits)

```bash
# /etc/security/limits.conf
admin    hard    maxlogins    3
```

---

## Restricción por IP (AllowUsers + firewall)

### Opción 1: iptables (solo tu IP)

```bash
# Puerto SSH estándar
sudo iptables -A INPUT -p tcp --dport 22 -s TU_IP_PUBLICA -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 22 -j DROP

# Si cambiaste el puerto
sudo iptables -A INPUT -p tcp --dport 2222 -s TU_IP_PUBLICA -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 2222 -j DROP
```

### Opción 2: Match Address en sshd_config

```bash
# /etc/ssh/sshd_config
# Permitir SSH solo desde IPs específicas
Match Address 192.168.1.0/24,203.0.113.0/24
    PubkeyAuthentication yes
    PasswordAuthentication no

# Para el resto, ni siquiera responder
Match Address *
    PasswordAuthentication no
    AuthenticationMethods no
```

### Opción 3: nftables

```bash
sudo nft add rule inet filter input tcp dport 22 ip saddr TU_IP accept
sudo nft add rule inet filter input tcp dport 22 drop
```

### Opción 4: ufw (Uncomplicated Firewall)

```bash
# Permitir SSH solo desde tu IP
sudo ufw allow from TU_IP to any port 22 proto tcp
sudo ufw enable

# Para múltiples IPs
sudo ufw allow from 203.0.113.0/24 to any port 22 proto tcp
```

### Tu IP pública puede cambiar

Si tu IP es dinámica, usa Dynamic DNS + script:

```bash
#!/bin/bash
# Actualizar regla iptables con tu IP dinámica
MI_IP=$(dig +short midominio.ddns.net)
sudo iptables -F INPUT
sudo iptables -A INPUT -p tcp --dport 22 -s $MI_IP -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 22 -j DROP
```

---

## Configuración del cliente SSH

Archivo de configuración del cliente: **`~/.ssh/config`**

### Configuración por host

```bash
# ~/.ssh/config

# Servidor de producción
Host produccion
    HostName 203.0.113.10
    User admin
    Port 2222
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60
    ServerAliveCountMax 3

# Servidor de staging
Host staging
    HostName 192.168.1.50
    User deploy
    Port 22
    IdentityFile ~/.ssh/id_ed25519_staging

# Múltiples servidores con misma configuración
Host *.internal.empresa.com
    User admin
    Port 2222
    IdentityFile ~/.ssh/id_ed25519
    StrictHostKeyChecking yes

# Configuración global (para todos los hosts)
Host *
    ServerAliveInterval 300
    ServerAliveCountMax 2
    ExitOnForwardFailure yes
    ControlMaster auto
    ControlPath ~/.ssh/controlmasters/%r@%h:%p
    ControlPersist 10m
```

### Usar alias

```bash
# Conectar con alias definido en ~/.ssh/config
ssh produccion
ssh staging

# Copiar archivos usando alias
scp archivo.txt produccion:/home/admin/
rsync -av ./ proyecto/ produccion:/var/www/
```

### Opciones útiles del cliente

| Opción en config | Equivalente CLI | Descripción |
|------------------|-----------------|-------------|
| `ServerAliveInterval 60` | `-o ServerAliveInterval=60` | Enviar keepalive cada 60s |
| `ServerAliveCountMax 3` | `-o ServerAliveCountMax=3` | Desconectar tras 3 keepalives fallidos |
| `StrictHostKeyChecking no` | `-o StrictHostKeyChecking=no` | Aceptar cualquier fingerprint (inseguro, solo labs) |
| `UserKnownHostsFile /dev/null` | `-o UserKnownHostsFile=/dev/null` | No guardar fingerprints (solo labs) |
| `LogLevel DEBUG` | `-v` | Log detallado para depurar |

### Conexión directa desde terminal (sin config)

```bash
# Todas las opciones inline
ssh -p 2222 -i ~/.ssh/id_ed25519 -o ServerAliveInterval=60 admin@203.0.113.10
```

---

## Conexión desde WSL2

### Configuración inicial de WSL2

```bash
# Dentro de WSL2 (Ubuntu)
# Actualizar paquetes
sudo apt update && sudo apt upgrade -y

# Instalar herramientas esenciales
sudo apt install -y openssh-client openssh-server curl wget git vim \
  net-tools dnsutils traceroute mtr nmap tcpdump iptables \
  build-essential docker.io docker-compose
```

### Generar claves SSH desde WSL2

```bash
# Generar clave
ssh-keygen -t ed25519 -C "wsl2-$(hostname)"

# Iniciar agente automáticamente (añadir a ~/.bashrc)
cat >> ~/.bashrc << 'EOF'
# SSH agent
if [ -z "$SSH_AUTH_SOCK" ]; then
   eval "$(ssh-agent -s)" > /dev/null
   ssh-add ~/.ssh/id_ed25519 2>/dev/null
fi
EOF
```

### Conexión a servidores desde WSL2

```bash
# Directa
ssh admin@servidor

# Con proxy (si estás detrás de firewall corporativo)
ssh -J user@bastion.empresa.com admin@servidor-interno
```

### Compartir claves entre Windows y WSL2

```bash
# Copiar claves de Windows a WSL2
cp /mnt/c/Users/TU_USUARIO/.ssh/id_ed25519* ~/.ssh/
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub

# O mejor: usar el agente SSH de Windows
# En Windows (PowerShell como Admin):
# Set-Service ssh-agent -StartupType Automatic
# Start-Service ssh-agent
# ssh-add $env:USERPROFILE\.ssh\id_ed25519

# En WSL2, añadir a ~/.bashrc:
# export SSH_AUTH_SOCK=$HOME/.ssh/agent.sock
# ss -a | grep -q "$SSH_AUTH_SOCK" || \
#   rm -f "$SSH_AUTH_SOCK" && \
#   socat UNIX-LISTEN:$SSH_AUTH_SOCK,fork \
#         UNIX-CONNECT:$WSL2_AGENT_SOCK &
```

---

## Túneles SSH (port forwarding)

### Local port forwarding (traer puerto remoto a local)

```bash
# Puerto 3306 (MySQL) del servidor remoto → localhost:3306 local
ssh -L 3306:localhost:3306 admin@servidor

# Puerto 5432 (PostgreSQL) remoto → puerto local 5432
ssh -L 5432:localhost:5432 admin@servidor

# Con puerto local diferente al remoto
ssh -L 8080:localhost:80 admin@servidor

# Múltiples túneles
ssh -L 3306:localhost:3306 -L 8080:localhost:80 admin@servidor
```

Esto permite conectarte a servicios remotos como si estuvieran en tu máquina:

```bash
# Conectar a MySQL remoto vía túnel
mysql -h localhost -P 3306 -u admin -p

# Acceder a web app remota en navegador local
# http://localhost:8080
```

### Remote port forwarding (exponer puerto local)

```bash
# Exponer tu servidor web local (puerto 3000) en el servidor remoto (puerto 9000)
ssh -R 9000:localhost:3000 admin@servidor

# Útil para mostrar tu desarrollo local al exterior
# O para que un servicio remoto acceda a tu máquina local
```

### Dynamic port forwarding (SOCKS proxy)

```bash
# Crea un proxy SOCKS5 en tu máquina local
ssh -D 1080 admin@servidor

# Configura tu navegador para usar proxy SOCKS5 localhost:1080
# Todo el tráfico del navegador saldrá por el servidor remoto
```

### Túnel persistente con autossh

```bash
# autossh reconecta automáticamente si el túnel se cae
sudo apt install autossh

# Ejemplo: túnel MySQL persistente
autossh -M 0 -o "ServerAliveInterval 30" -o "ServerAliveCountMax 3" \
  -L 3306:localhost:3306 admin@servidor -N -f

# -N: no ejecutar comandos remotos
# -f: background
```

---

## ProxyJump y bastion hosts

### Bastion host (servidor puerta de enlace)

En muchas empresas, los servidores internos no tienen acceso directo desde internet. Se accede a través de un **bastion host** (también llamado jump box).

```text
Tu máquina → Bastion (público) → Servidor interno (privado)
```

### ProxyJump (-J)

```bash
# Un solo salto
ssh -J user@bastion.empresa.com admin@servidor-interno

# Múltiples saltos
ssh -J bastion1,bastion2 admin@servidor-interno
```

### Configuración en ~/.ssh/config

```bash
Host bastion
    HostName bastion.empresa.com
    User user
    Port 22
    IdentityFile ~/.ssh/id_ed25519

Host servidor-interno
    HostName 10.0.0.50
    User admin
    ProxyJump bastion
    IdentityFile ~/.ssh/id_ed25519

# Conectarse fácilmente
ssh servidor-interno
```

### ProxyJump con agent forwarding

Para que la clave privada no esté en el bastion:

```bash
# En ~/.ssh/config del bastion
Host bastion
    ForwardAgent yes

# O en línea de comandos
ssh -A -J user@bastion admin@servidor-interno
```

> **`-A`** (Agent Forwarding): reenvía tu agente SSH local al bastion, que lo usa para autenticarte en el servidor interno. Tu clave privada nunca sale de tu máquina.

### Túnel a través de bastion

```bash
# Puerto 3306 remoto → local, a través del bastion
ssh -J user@bastion -L 3306:localhost:3306 admin@servidor-interno
```

---

## Sesiones persistentes y multiplexado

### ControlMaster (reutilizar conexión)

Evita el handshake SSH en cada conexión después de la primera:

```bash
# ~/.ssh/config
Host *
    ControlMaster auto
    ControlPath ~/.ssh/controlmasters/%r@%h:%p
    ControlPersist 10m
```

```bash
# Crear directorio para sockets
mkdir -p ~/.ssh/controlmasters

# Primera conexión (crea el socket)
ssh servidor

# Segunda conexión (reutiliza, no pide autenticación)
ssh servidor

# Ver sockets activos
ls -la ~/.ssh/controlmasters/

# Cerrar todas las sesiones multiplexadas
ssh -O exit servidor
```

### tmux/screen en el servidor

Para mantener sesiones largas que no se caigan al cerrar SSH:

```bash
# En el servidor
tmux new -s trabajo     # Crear sesión
tmux detach             # Desconectar (Ctrl+b d)
tmux attach -t trabajo  # Reconectar
tmux ls                 # Listar sesiones

# Alternativa: screen
screen -S trabajo       # Crear
screen -r trabajo       # Reconectar
screen -ls              # Listar
```

### Conexión al servidor + tmux automático

```bash
ssh -t servidor "tmux attach -t trabajo || tmux new -s trabajo"
```

---

## Transferencia de archivos

### scp (Secure Copy)

```bash
# Subir archivo local al servidor
scp archivo.txt admin@servidor:/home/admin/

# Subir directorio
scp -r ./proyecto/ admin@servidor:/home/admin/proyecto/

# Bajar archivo del servidor
scp admin@servidor:/var/log/syslog ./

# Con puerto no estándar
scp -P 2222 archivo.txt admin@servidor:/home/admin/

# Con alias de ~/.ssh/config
scp archivo.txt produccion:/home/admin/
```

### rsync (sincronización eficiente)

rsync solo transfiere las diferencias, mucho más rápido que scp para actualizaciones.

```bash
# Subir directorio (eficiente)
rsync -avz ./proyecto/ admin@servidor:/home/admin/proyecto/

# Bajar archivos
rsync -avz admin@servidor:/var/log/ ./logs/

# Eliminar archivos en destino que no existen en origen
rsync -avz --delete ./proyecto/ admin@servidor:/home/admin/proyecto/

# Excluir directorios
rsync -avz --exclude 'node_modules' --exclude '.git' ./proyecto/ admin@servidor:

# Con puerto no estándar
rsync -avz -e "ssh -p 2222" ./ archivo admin@servidor:

# Simular (dry-run) antes de ejecutar
rsync -avz --dry-run ./proyecto/ admin@servidor:

# Mostrar progreso
rsync -avz --progress ./archivo-grande.zip admin@servidor:
```

### Comparación: scp vs rsync

| Aspecto | scp | rsync |
|---------|-----|-------|
| Velocidad inicial | Similar | Similar |
| Actualizaciones | Transfiere todo | Solo diferencias |
| Reanudar si se corta | No | Sí (parcial) |
| Compresión | No | Sí (`-z`) |
| Excluir archivos | No nativo | Sí (`--exclude`) |

---

## Automatización con scripts

### Script de backup básico

```bash
#!/bin/bash
# backup.sh — Backup de directorios remotos

SERVIDOR="produccion"
REMOTE_DIR="/var/www/html"
LOCAL_DIR="/backups/$(date +%Y%m%d)/"
LOG="/var/log/backup.log"

echo "[$(date)] Iniciando backup de $SERVIDOR:$REMOTE_DIR" >> "$LOG"

rsync -avz --delete -e "ssh" "$SERVIDOR:$REMOTE_DIR" "$LOCAL_DIR" >> "$LOG" 2>&1

if [ $? -eq 0 ]; then
    echo "[$(date)] Backup completado" >> "$LOG"
else
    echo "[$(date)] ERROR en backup" >> "$LOG"
fi
```

### Script de ejecución remota en múltiples servidores

```bash
#!/bin/bash
# run_on_all.sh — Ejecutar comando en varios servidores

SERVIDORES=("prod-web1" "prod-web2" "prod-db1")
COMANDO="$@"

for server in "${SERVIDORES[@]}"; do
    echo "=== $server ==="
    ssh "$server" "$COMANDO"
    echo ""
done
```

### Script de health check remoto

```bash
#!/bin/bash
# healthcheck.sh — Verificar estado de servidores

SERVIDORES=(
    "prod-web1:admin"
    "prod-web2:admin"
    "prod-db1:dbadmin"
)

for entrada in "${SERVIDORES[@]}"; do
    IFS=":" read -r server user <<< "$entrada"
    
    echo "=== $server ==="
    ssh "$user@$server" "
        echo 'Uptime:'; uptime
        echo ''
        echo 'Disco:'; df -h / | tail -1
        echo ''
        echo 'RAM:'; free -h | grep Mem
        echo ''
        echo 'Carga:'; cat /proc/loadavg
    "
    echo ""
done
```

### Ejecución remota con sshpass (solo scripts internos)

> **sshpass** no es recomendado por seguridad. Solo para entornos controlados o CI/CD:

```bash
sshpass -p 'contraseña' ssh admin@servidor "comando"
sshpass -p 'contraseña' ssh-copy-id admin@servidor
```

---

## Auditoría y logs

### Logs del servidor SSH

```bash
# Intentos de conexión (todos)
sudo journalctl -u sshd -b

# Logins exitosos
sudo journalctl -u sshd -b | grep "Accepted"

# Logins fallidos
sudo journalctl -u sshd -b | grep "Failed password"

# Conexiones de IPs específicas
sudo journalctl -u sshd -b | grep "192.168.1.100"

# Intentos de usuario inexistente
sudo journalctl -u sshd -b | grep "Invalid user"

# Logs de autenticación (tradicional)
sudo grep "sshd" /var/log/auth.log
```

### Auditoría de conexiones activas

```bash
# Conexiones SSH activas al servidor
ss -t state established '( dport = :22 or sport = :22 )'

# Usuarios conectados vía SSH
who | grep -v local

# Todas las sesiones SSH
ps aux | grep sshd | grep -v grep

# Detalles de sesiones SSH activas
sudo ss -tlnp | grep sshd
```

### Monitorear conexiones SSH en tiempo real

```bash
# Watch de conexiones
watch -n 2 'ss -t state established "( dport = :22 or sport = :22 )"'

# Tail de logs SSH
sudo journalctl -u sshd -f

# Detectar fuerza bruta en vivo
sudo journalctl -u sshd -f | grep --line-buffered "Failed password"
```

### Reporte de accesos SSH

```bash
#!/bin/bash
echo "=== REPORTE DE ACCESOS SSH ==="
echo ""

echo "→ Conexiones exitosas (últimas 20):"
sudo journalctl -u sshd -b --no-pager \
  | grep "Accepted" \
  | awk '{print $1, $2, $3, $9, $11}' \
  | tail -20

echo ""
echo "→ Intentos fallidos (top 10 IPs):"
sudo journalctl -u sshd -b --no-pager \
  | grep "Failed password" \
  | grep -oP 'from \K[0-9.]+' \
  | sort \
  | uniq -c \
  | sort -rn \
  | head -10

echo ""
echo "→ Conexiones actuales:"
ss -t state established '( dport = :22 or sport = :22 )'
```

---

## Recuperación de acceso perdido

### Me quedé fuera del servidor — ¿qué hago?

#### 1. Consola del proveedor de cloud

AWS, DigitalOcean, Linode, Vultr, etc. ofrecen **consola web** o **serial console** directamente desde su panel. Es el plan A.

```bash
# Desde la consola web
# 1. Entrar al panel de control
# 2. Seleccionar la instancia
# 3. Abrir "Serial Console" o "VNC Console"
# 4. Iniciar sesión con usuario y contraseña local
```

#### 2. Conexión por IPMI/iDRAC/iLO

Si es servidor físico o dedicado:

```bash
# Conectar a IPMI
ssh admin@IPMI_IP
# O abrir consola Java/KVM desde el panel
```

#### 3. Recovery mode (reboot)

Algunos proveedores permiten bootear en **modo recovery** que monta el disco en un sistema temporal:

```bash
# Entrar al servidor recovery
# Montar el disco del sistema
# Revisar /mnt/etc/ssh/sshd_config
# Revisar /mnt/home/admin/.ssh/authorized_keys
```

#### 4. Script de rescate (cloud-init)

Si el proveedor soporta **user-data** (cloud-init), puedes lanzar un script que se ejecute en el próximo reinicio:

```yaml
#cloud-config
runcmd:
  - echo "ssh-ed25519 AAAAC3... TU_CLAVE" >> /home/admin/.ssh/authorized_keys
  - chmod 600 /home/admin/.ssh/authorized_keys
  - chown admin:admin /home/admin/.ssh/authorized_keys
```

#### 5. Prevenir: tener un plan B

```bash
# 1. Tener clave pública en múltiples ubicaciones
# 2. Tener otro usuario alternativo con sudo
sudo useradd -m -G sudo admin-backup
sudo passwd admin-backup

# 3. Probar configuración con sshd -t
sudo sshd -t

# 4. Tener cron que revierta configuración si pierdes conexión
# /etc/cron.d/ssh-guard
# */5 * * * * root /usr/local/bin/ssh-guard.sh
```

---

## Laboratorio Docker para practicar

### Escenario 1: Servidor SSH básico

```bash
# Crear Dockerfile para servidor SSH
cat > Dockerfile.ssh << 'EOF'
FROM ubuntu:22.04

RUN apt update && apt install -y openssh-server sudo && \
    mkdir /var/run/sshd && \
    useradd -m -s /bin/bash admin && \
    echo "admin:admin123" | chpasswd && \
    usermod -aG sudo admin

COPY id_ed25519.pub /home/admin/.ssh/authorized_keys
RUN chown -R admin:admin /home/admin/.ssh && \
    chmod 700 /home/admin/.ssh && \
    chmod 600 /home/admin/.ssh/authorized_keys

# Configuración segura
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    echo "AllowUsers admin" >> /etc/ssh/sshd_config

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
EOF
```

### Construir y ejecutar

```bash
# Generar clave local si no tienes
ssh-keygen -t ed25519 -N "" -f ~/.ssh/lab-key

# Construir imagen
docker build -f Dockerfile.ssh -t ssh-lab .

# Ejecutar contenedor
docker run -d --name servidor-ssh -p 2222:22 ssh-lab

# Conectarse
ssh -p 2222 -i ~/.ssh/lab-key admin@localhost

# Ver logs
docker logs servidor-ssh
```

### Escenario 2: Bastion host + servidor interno

```bash
# Red docker
docker network create lab-net

# Servidor interno (sin puerto expuesto)
docker run -d --name servidor-interno --network lab-net ssh-lab

# Bastion host (puerto expuesto)
docker run -d --name bastion --network lab-net -p 2223:22 ssh-lab

# Conectar al interno vía bastion
ssh -J admin@localhost:2223 admin@servidor-interno
```

### Escenario 3: Múltiples servidores con docker-compose

```yaml
# docker-compose.yml
version: '3.8'

services:
  bastion:
    build: .
    ports:
      - "2222:22"
    networks:
      - lab

  web-server:
    build: .
    networks:
      - lab
    volumes:
      - ./www:/var/www/html
    command: >
      sh -c "apt install -y nginx && service nginx start && /usr/sbin/sshd -D"

  db-server:
    build: .
    networks:
      - lab
    command: >
      sh -c "apt install -y mariadb-server && service mariadb start && /usr/sbin/sshd -D"

networks:
  lab:
```

```bash
# Iniciar laboratorio
docker-compose up -d

# Probar conexiones
ssh -J admin@localhost:2222 admin@web-server
ssh -J admin@localhost:2222 admin@db-server

# Verificar conectividad desde el bastion
ssh admin@localhost:2222 "ssh web-server 'curl -s db-server:3306 | echo'"
```

### Escenario 4: SSH brute force lab

```bash
# Configurar servidor con contraseña débil (para practicar detección)

cat > Dockerfile.ssh-weak << 'EOF'
FROM ubuntu:22.04
RUN apt update && apt install -y openssh-server sudo && \
    mkdir /var/run/sshd && \
    useradd -m -s /bin/bash admin && \
    echo "admin:1234" | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
EOF

# Construir
docker build -f Dockerfile.ssh-weak -t ssh-weak-lab .

# Ejecutar
docker run -d --name ssh-weak -p 2224:22 ssh-weak-lab

# Practicar detección de fuerza bruta
sudo journalctl -u docker -f | grep ssh-weak

# Simular ataque (otro terminal)
for i in $(seq 1 100); do
  sshpass -p "wrong" ssh -o StrictHostKeyChecking=no admin@localhost -p 2224 "exit" 2>/dev/null
done

# Analizar logs
docker logs ssh-weak 2>&1 | grep "Failed password" | grep -oP 'from \K[0-9.]+' | sort | uniq -c
```

### Script para generar laboratorio completo

```bash
#!/bin/bash
# setup-lab.sh — Crea laboratorio Docker SSH completo

echo "Creando laboratorio SSH..."

# Red
docker network create ssh-lab 2>/dev/null

# Servidor con SSH seguro
docker run -d \
  --name ssh-hardened \
  --network ssh-lab \
  -p 2225:22 \
  -e SSH_PUBLIC_KEY="$(cat ~/.ssh/id_ed25519.pub)" \
  linuxserver/openssh-server

# Servidor con SSH débil (para pentesting)
docker run -d \
  --name ssh-weak \
  --network ssh-lab \
  -p 2226:22 \
  -e PASSWORD_ACCESS=true \
  -e USER_PASSWORD=admin123 \
  linuxserver/openssh-server

echo ""
echo "=== Laboratorio listo ==="
echo "SSH seguro:  ssh -p 2225 -o StrictHostKeyChecking=no admin@localhost"
echo "SSH débil:   sshpass -p admin123 ssh -p 2226 -o StrictHostKeyChecking=no admin@localhost"
echo ""
echo "Entre contenedores:"
echo "  docker exec -it ssh-hardened bash"
echo "  docker exec -it ssh-weak bash"
```

---

## 💡 Uno-liners imprescindibles

```bash
# Conectar
ssh admin@servidor

# Con puerto no estándar
ssh -p 2222 admin@servidor

# Ejecutar comando remoto
ssh admin@servidor "comando"

# Túnel local
ssh -L 8080:localhost:80 admin@servidor

# Túnel remoto
ssh -R 9000:localhost:3000 admin@servidor

# SOCKS proxy
ssh -D 1080 admin@servidor

# ProxyJump
ssh -J bastion admin@servidor-interno

# Copiar clave pública
ssh-copy-id admin@servidor

# Subir archivo
scp archivo.txt admin@servidor:/ruta/

# Sincronizar con rsync
rsync -avz ./dir/ admin@servidor:/ruta/

# Multiplexado (reutilizar conexión)
ssh -o ControlMaster=auto -o ControlPath=~/.ssh/socket-%r@%h:%p servidor

# Forward agent
ssh -A admin@servidor

# Mantener vivo
ssh -o ServerAliveInterval=60 admin@servidor

# Configuración temporal (sin ~/.ssh/config)
ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" admin@localhost

# Ver fingerprint del servidor
ssh-keyscan servidor

# Ver fingerprint de clave local
ssh-keygen -lf ~/.ssh/id_ed25519.pub

# Generar clave
ssh-keygen -t ed25519 -C "user@host"

# Iniciar agente
eval "$(ssh-agent -s)" && ssh-add

# Ver conexiones activas SSH
ss -t state established '( dport = :22 or sport = :22 )'

# Logs de SSH en vivo
sudo journalctl -u sshd -f

# Test de conexión (sin ejecutar comandos)
ssh -q admin@servidor exit && echo "OK" || echo "FALLO"
```
