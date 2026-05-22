⬅️ [Volver a scenarios](../README.md)

# Escenario: Construir infraestructura PYME desde cero

## ⚡ Quick command (SRE)

**Quick command (SRE):** `ip -br a; ip r; ss -tuln | head -30`

**Quick command (original):** `ip link add link eth1 name eth1.10 type vlan id 10 && ip addr add 10.0.10.1/24 dev eth1.10 && ip link set dev eth1.10 up`

**Cuándo usar este escenario:**
- Diseñar la red de una PYME desde cero
- Segmentar por departamentos con VLANs y firewall
- Montar NAS (Samba+NFS), DHCP, DNS y web server

**Archivo(s) de práctica:** Docker compose (`docker-compose.network.yml`)

---

## 🎯 Problema

Eres el primer administrador de sistemas de una PYME en crecimiento (~50 empleados). Te piden construir la infraestructura desde cero: segmentar la red por departamentos, montar un NAS para backups y archivos compartidos, servir páginas web con nginx, configurar DHCP/DNS interno, y aislar la red de invitados. Todo debe hacerse en un solo servidor Linux que oficia de router, NAS, web server y DNS/DHCP.

## Datos de entrada

- Servidor: Ubuntu Server 22.04, 3 interfaces de red
  - `eth0`: WAN (Internet, IP pública)
  - `eth1`: LAN interna (switch gestionable)
  - `eth2`: WiFi AP para invitados
- Departamentos: Admin, IT, RRHH, Producción, Gerencia
- Subredes: 10.0.10.0/24, 10.0.20.0/24, 10.0.30.0/24, 10.0.40.0/24, 10.0.50.0/24

## Pipeline 1: Crear VLANs y asignar IPs

```bash
# Crear interfaces VLAN sobre eth1
for vlan in 10 20 30 40 50; do
  ip link add link eth1 name eth1.$vlan type vlan id $vlan
  ip addr add 10.0.${vlan}.1/24 dev eth1.$vlan
  ip link set dev eth1.$vlan up
done

# IPs fijas para servicios del servidor
ip addr add 10.0.10.10/24 dev eth1.10   # NAS (Admin)
ip addr add 10.0.40.10/24 dev eth1.40   # Web server (Producción)

# VLAN 200 para invitados en eth2
ip link add link eth2 name eth2.200 type vlan id 200
ip addr add 10.0.200.1/24 dev eth2.200
ip link set dev eth2.200 up

# Verificar
ip -d link show | grep vlan | awk '{print $2, $3, $5}'
```

### Explicación paso a paso

1. **VLANs** — Cada departamento tiene su propia VLAN y subred
2. **IP fija NAS** — 10.0.10.10 para servicios de almacenamiento
3. **IP fija Web** — 10.0.40.10 para nginx
4. **VLAN invitados** — Red separada sin acceso a LAN

## Pipeline 2: Configurar routing y NAT

```bash
# Activar forwarding
sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

# NAT para todos los segmentos
for subnet in 10.0.10.0/24 10.0.20.0/24 10.0.30.0/24 10.0.40.0/24 10.0.50.0/24; do
  iptables -t nat -A POSTROUTING -s $subnet -o eth0 -j MASQUERADE
done

# NAT para invitados (solo HTTP/HTTPS)
iptables -t nat -A POSTROUTING -s 10.0.200.0/24 -o eth0 -j MASQUERADE

# Rutas estáticas hacia segmentos (opcional, ya están en eth1.VLAN)
ip route show | grep -E "10\.0\.[0-9]+\.0"
```

### Explicación paso a paso

1. **ip_forward** — Permite reenviar paquetes entre interfaces
2. **MASQUERADE** — Traduce IPs internas a la IP pública para salir a internet
3. **Invitados** — También con NAT para que tengan internet

## Pipeline 3: Firewall ACLs entre segmentos

```bash
# Política base
iptables -P FORWARD DROP
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# Admin → todo (confianza total)
iptables -A FORWARD -s 10.0.10.0/24 -j ACCEPT

# IT → servidores prod (SSH, MySQL)
iptables -A FORWARD -s 10.0.20.0/24 -d 10.0.40.10 -p tcp --dport 22,80,443 -j ACCEPT
iptables -A FORWARD -s 10.0.20.0/24 -d 10.0.40.11 -p tcp --dport 3306 -j ACCEPT

# IT → NAS (Samba, NFS)
iptables -A FORWARD -s 10.0.20.0/24 -d 10.0.10.10 -p tcp --dport 445,2049 -j ACCEPT

# RRHH → NAS (solo Samba)
iptables -A FORWARD -s 10.0.30.0/24 -d 10.0.10.10 -p tcp --dport 445 -j ACCEPT

# Producción → Internet (web server actualiza paquetes)
iptables -A FORWARD -s 10.0.40.10 -o eth0 -p tcp --dport 80,443 -j ACCEPT

# Gerencia → Admin e Internet
iptables -A FORWARD -s 10.0.50.0/24 -d 10.0.10.0/24 -j ACCEPT
iptables -A FORWARD -s 10.0.50.0/24 -o eth0 -p tcp --dport 80,443 -j ACCEPT

# Invitados → solo Internet
iptables -A FORWARD -s 10.0.200.0/24 -o eth0 -p tcp --dport 80,443 -j ACCEPT

# Bloquear invitados → LAN
iptables -A FORWARD -s 10.0.200.0/24 -d 10.0.0.0/8 -j DROP

# Ver reglas
iptables -L FORWARD -v -n | column -t | head -30
```

### Explicación paso a paso

1. **Política DROP** — Por defecto no se permite tráfico entre segmentos
2. **Admin → todo** — El departamento de administración tiene acceso completo (IT, gerencia)
3. **IT → servidores** — Solo puertos específicos a producción
4. **RRHH → NAS** — Solo archivos compartidos, no acceso a servidores
5. **Invitados** — Solo internet, completamente aislados de la LAN

## Pipeline 4: NAS con Samba + NFS

```bash
# Crear directorios del NAS
mkdir -p /srv/nas/{compartido,backups,multimedia,departamentos/{admin,it,rrhh,produccion,gerencia}}

# NFS para Linux
apt install -y nfs-kernel-server
cat >> /etc/exports <<'EOF'
/srv/nas/compartido   10.0.0.0/8(rw,sync,no_subtree_check)
/srv/nas/backups      10.0.10.0/24(rw,sync,no_subtree_check)
/srv/nas/departamentos 10.0.0.0/8(rw,sync,no_subtree_check,no_root_squash)
EOF
exportfs -ra && systemctl restart nfs-kernel-server

# Samba para Windows
apt install -y samba
cat >> /etc/samba/smb.conf <<'SAMBA'
[Compartido]
path = /srv/nas/compartido
browsable = yes
writable = yes
guest ok = no
valid users = @admin @it

[Departamento-RRHH]
path = /srv/nas/departamentos/rrhh
valid users = @rrhh @admin
read only = no

[Departamento-Gerencia]
path = /srv/nas/departamentos/gerencia
valid users = @gerencia @admin
read only = no

[Backups]
path = /srv/nas/backups
valid users = @admin @it
read only = no
SAMBA
systemctl restart smbd

# Ver recursos compartidos
smbclient -L localhost -U admin -N 2>/dev/null | grep -E "^\s+[A-Z]"
exportfs -v
```

### Explicación paso a paso

1. **Directorios** — Estructura clara por departamento y propósito
2. **NFS** — Para servidores Linux (rápido, montaje transparente)
3. **Samba** — Para clientes Windows, con autenticación por grupo
4. **Grupos** — Cada departamento solo ve su propio directorio

## Pipeline 5: DHCP + DNS interno (dnsmasq)

```bash
apt install -y dnsmasq

# Configurar por segmento
cat > /etc/dnsmasq.conf <<'DNSMASQ'
# Interfaces
interface=eth1.10
interface=eth1.20
interface=eth1.30
interface=eth1.40
interface=eth1.50
interface=eth2.200
bind-interfaces

# Dominio local
domain=empresa.local
local=/empresa.local/

# DNS upstream
server=1.1.1.1
server=8.8.8.8

# Resoluciones estáticas
address=/nas.empresa.local/10.0.10.10
address=/web.empresa.local/10.0.40.10
address=/mail.empresa.local/10.0.50.10
address=/portal.empresa.com/10.0.40.10

# DHCP por segmento
dhcp-range=eth1.10,10.0.10.100,10.0.10.200,12h
dhcp-range=eth1.20,10.0.20.100,10.0.20.200,12h
dhcp-range=eth1.30,10.0.30.100,10.0.30.150,12h
dhcp-range=eth1.40,10.0.40.100,10.0.40.120,12h
dhcp-range=eth1.50,10.0.50.100,10.0.50.150,12h
dhcp-range=eth2.200,10.0.200.100,10.0.200.200,1h

# Reservas estáticas
dhcp-host=AA:BB:CC:00:11:01,10.0.40.10,web-prod
dhcp-host=AA:BB:CC:00:11:02,10.0.40.11,db-prod
dhcp-host=AA:BB:CC:00:11:10,10.0.10.10,nas-server
DNSMASQ

systemctl restart dnsmasq

# Ver leases
cat /var/lib/misc/dnsmasq.leases | awk '{print $3, $4}'
```

### Explicación paso a paso

1. **dnsmasq** — Un solo servicio para DHCP + DNS en todos los segmentos
2. **Resoluciones estáticas** — Los servidores tienen nombres fáciles de recordar
3. **DHCP por interfaz** — Cada VLAN recibe IPs de su propio rango
4. **Reservas** — Servidores críticos con IP fija vía MAC

## Pipeline 6: nginx con hosts virtuales

```bash
apt install -y nginx

# Sitio público
cat > /etc/nginx/sites-available/portal <<'NGINX'
server {
    listen 80;
    server_name portal.empresa.com www.empresa.com;
    root /var/www/portal;
    index index.html;
    access_log /var/log/nginx/portal_access.log;
    error_log /var/log/nginx/portal_error.log;
    location / {
        try_files $uri $uri/ =404;
    }
}
NGINX

# Sitio interno (solo LAN)
cat > /etc/nginx/sites-available/intranet <<'NGINX'
server {
    listen 10.0.40.10:80;
    server_name intranet.empresa.local;
    root /var/www/intranet;
    index index.html;
    allow 10.0.10.0/24;
    allow 10.0.20.0/24;
    allow 10.0.50.0/24;
    deny all;
    access_log /var/log/nginx/intranet_access.log;
}
NGINX

ln -sf /etc/nginx/sites-available/portal /etc/nginx/sites-enabled/
ln -sf /etc/nginx/sites-available/intranet /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

# Verificar
curl -s -o /dev/null -w "%{http_code}" http://localhost
curl -s -o /dev/null -w "%{http_code}" http://10.0.40.10
```

### Explicación paso a paso

1. **Sitio público** — Portal corporativo accesible desde internet
2. **Sitio interno** — Intranet solo accesible desde Admin, IT y Gerencia
3. **`allow/deny`** — Control de acceso por IP

## Pipeline 7: Backup automático al NAS

```bash
# Backup de configuraciones del router
cat > /usr/local/bin/backup-router.sh <<'SCRIPT'
#!/bin/bash
FECHA=$(date +%Y%m%d)
DEST="/srv/nas/backups/router/$FECHA"
mkdir -p "$DEST"
# Configuraciones
cp /etc/dnsmasq.conf "$DEST/"
cp /etc/samba/smb.conf "$DEST/"
cp /etc/exports "$DEST/"
iptables-save > "$DEST/iptables.rules"
ip route show > "$DEST/routes.txt"
ip addr show > "$DEST/ips.txt"
# Respaldar bases de datos de servicios
tar czf "$DEST/var-etc.tar.gz" /etc/nginx/ /etc/dhcp/ /etc/dnsmasq.d/
echo "Backup completado: $FECHA" >> /var/log/backup-router.log
SCRIPT
chmod +x /usr/local/bin/backup-router.sh

# Programar en cron
echo "0 2 * * * root /usr/local/bin/backup-router.sh" > /etc/cron.d/backup-router

# Backup a NAS remoto (3-2-1)
apt install -y restic
restic init --repo /srv/nas/backups/restic
restic backup /etc/ /var/www/ /srv/nas/ \
  --repo /srv/nas/backups/restic \
  --exclude '*.log' --verbose

# Ver backups
restic snapshots --repo /srv/nas/backups/restic
ls -la /srv/nas/backups/router/
```

### Explicación paso a paso

1. **Backup de configs** — Todo lo que hace funcionar al router se respalda diario
2. **restic** — Backup deduplicado y cifrado de datos importantes
3. **Cron** — Automatización diaria

## Variantes

### Agregar un nuevo departamento

```bash
# VLAN 60 (Contabilidad)
ip link add link eth1 name eth1.60 type vlan id 60
ip addr add 10.0.60.1/24 dev eth1.60
ip link set dev eth1.60 up

# Firewall: solo NAS y Admin
iptables -A FORWARD -s 10.0.60.0/24 -d 10.0.10.10 -p tcp --dport 445 -j ACCEPT
iptables -A FORWARD -s 10.0.60.0/24 -d 10.0.10.0/24 -j ACCEPT
iptables -A FORWARD -s 10.0.60.0/24 -o eth0 -p tcp --dport 80,443 -j ACCEPT

# DHCP
echo "dhcp-range=eth1.60,10.0.60.100,10.0.60.200,12h" >> /etc/dnsmasq.conf
systemctl restart dnsmasq
```

### Reporte de conectividad entre segmentos

```bash
# Probar conectividad desde cada segmento a servidores
for ip in 10.0.10.10 10.0.40.10 10.0.40.11; do
  echo -n "$ip -> "
  ping -c 1 -W 2 $ip >/dev/null && echo "OK" || echo "FALLO"
done

# Ver estados de conexiones entre segmentos
ss -tun | grep -E "10\.0\." \
  | awk '{print $5, $6}' \
  | sed 's/:[0-9]*/ /g' \
  | sort | uniq -c | sort -rn \
  | head -10
```

## Interpretación

| Indicador | Significado |
|-----------|-------------|
| Todas las VLANs tienen IP | Segmentación configurada correctamente |
| `iptables -L FORWARD` con reglas | ACLs activas entre segmentos |
| `dnsmasq` leases activos | DHCP funcionando en todos los segmentos |
| `exportfs -v` muestra recursos | NFS exportando correctamente |
| `curl` desde LAN da 200, desde invitados no | Aislamiento de red de invitados OK |
| `restic snapshots` con snapshots recientes | Backups funcionando |
| `smbclient -L` lista recursos | Samba autenticando correctamente |

## Comandos relacionados

- [network_segmentation.md](../../guides/network_segmentation.md)
- [nginx.md](../../guides/nginx.md)
- [storage_backup.md](../../guides/storage_backup.md)
- [production_server.md](../../guides/production_server.md)
- [iptables.md](../../guides/iptables.md)
- [ip_ss.md](../../guides/ip_ss.md)
- [systemd_journalctl.md](../../guides/systemd_journalctl.md)
