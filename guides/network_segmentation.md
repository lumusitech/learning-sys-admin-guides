# Segmentación de red — Guía completa

**Nivel:** 🔴 Avanzado
**Archivos de práctica:** `labs/docker-compose.network.yml`
**Ver escenarios relacionados:** [`infrastructure/02-build-pyme`](../scenarios/infrastructure/02-build-pyme-infrastructure.md)

## ⚡ Quick command

`ip link add link eth0 name eth0.10 type vlan id 10`

## ⚡ Quick run

```bash
ip link add link eth0 name eth0.10 type vlan id 10
```

---

## 📑 Índice

1. [Conceptos clave](#conceptos)
2. [Subnetting por departamento](#subnetting)
3. [Linux como router](#linux-router)
4. [VLANs (802.1Q)](#vlans)
5. [DHCP por segmento](#dhcp)
6. [ACLs con iptables](#acls)
7. [NAT y forwarding](#nat)
8. [Bridge y virtualización](#bridge)
9. [DNS por segmento](#dns)
10. [Monitoreo de tráfico entre segmentos](#monitoreo)
11. [Escenarios reales](#escenarios)

---

## 🧠 ¿Qué es segmentación de red?

La segmentación de red divide una red física en subredes lógicas más pequeñas para controlar el tráfico, aislar departamentos y reducir la superficie de ataque. En Linux se implementa con VLANs (802.1Q), subinterfaces, iptables y bridges.

---

## Conceptos clave

Segmentar la red significa dividirla en subredes más pequeñas, normalmente por departamento, para:

- **Aislar tráfico**: los equipos de RRHH no ven el tráfico de Producción
- **Controlar acceso**: solo ciertos hosts pueden alcanzar ciertos segmentos
- **Reducir broadcast**: menos hosts por segmento = menos ruido
- **Mejorar seguridad**: si comprometen un segmento, los demás siguen protegidos

### Esquema típico de PYME

```text
  [Router/Firewall Linux]
         |
    ┌────┴────┐
    |         |
  DMZ       LAN
  (web)   ┌──┼──┐
          |  |   |
       Admin IT | RRHH
                |
             Producción
```

---

## Subnetting por departamento

| Departamento | Subred | Máscara | Hosts | Gateway |
|-------------|--------|---------|-------|---------|
| Administración | 10.0.10.0/24 | 255.255.255.0 | 254 | 10.0.10.1 |
| IT/Sistemas | 10.0.20.0/24 | 255.255.255.0 | 254 | 10.0.20.1 |
| RRHH | 10.0.30.0/24 | 255.255.255.0 | 254 | 10.0.30.1 |
| Producción | 10.0.40.0/24 | 255.255.255.0 | 254 | 10.0.40.1 |
| DMZ | 10.0.99.0/24 | 255.255.255.0 | 254 | 10.0.99.1 |
| Gerencia | 10.0.50.0/24 | 255.255.255.0 | 254 | 10.0.50.1 |
| Invitados (WiFi) | 10.0.200.0/24 | 255.255.255.0 | 254 | 10.0.200.1 |

### Cálculo rápido de subredes

```bash
# Con ipcalc o subnetcalc
sudo apt install -y ipcalc

# Ver info de una subred
ipcalc 10.0.10.0/24

# Salida:
# Address:   10.0.10.0
# Netmask:   255.255.255.0 = 24
# Wildcard:  0.0.0.255
# Network:   10.0.10.0/24
# HostMin:   10.0.10.1
# HostMax:   10.0.10.254
# Broadcast: 10.0.10.255
# Hosts/Net: 254

ipcalc 10.0.0.0/16 -s 10.0.0.0/24 10.0.10.0/24 10.0.20.0/24
```

---

## VLANs para cámaras IP por pisos

### Esquema típico de segmentación por pisos

| Ubicación | VLAN | Subred | Uso |
|-----------|------|--------|-----|
| Piso 1 | 100 | 10.0.100.0/24 | Cámaras internas |
| Piso 2 | 110 | 10.0.110.0/24 | Cámaras internas |
| Piso 3 | 120 | 10.0.120.0/24 | Cámaras internas |
| Exterior | 130 | 10.0.130.0/24 | Cámaras perimetrales |
| WiFi APs | 140 | 10.0.140.0/24 | Access Points |
| NVR | 150 | 10.0.150.0/24 | Grabadores |

### Crear VLANs para cámaras

```bash
# Crear subinterfaces VLAN
ip link add link eth0 name eth0.100 type vlan id 100
ip link add link eth0 name eth0.110 type vlan id 110
ip link add link eth0 name eth0.120 type vlan id 120
ip link add link eth0 name eth0.130 type vlan id 130
ip link add link eth0 name eth0.140 type vlan id 140
ip link add link eth0 name eth0.150 type vlan id 150

# Asignar IPs
ip addr add 10.0.100.1/24 dev eth0.100
ip addr add 10.0.110.1/24 dev eth0.110
ip addr add 10.0.120.1/24 dev eth0.120
ip addr add 10.0.130.1/24 dev eth0.130
ip addr add 10.0.140.1/24 dev eth0.140
ip addr add 10.0.150.1/24 dev eth0.150

# Activar interfaces
ip link set eth0.100 up
ip link set eth0.110 up
ip link set eth0.120 up
ip link set eth0.130 up
ip link set eth0.140 up
ip link set eth0.150 up
```

### ACLs para aislar tráfico de cámaras

```bash
# Permitir que NVR acceda a todas las VLANs de cámaras
iptables -A FORWARD -i eth0.150 -o eth0.100 -j ACCEPT
iptables -A FORWARD -i eth0.150 -o eth0.110 -j ACCEPT
iptables -A FORWARD -i eth0.150 -o eth0.120 -j ACCEPT
iptables -A FORWARD -i eth0.150 -o eth0.130 -j ACCEPT

# Bloquear acceso desde otras VLANs a las cámaras
iptables -A FORWARD -i eth0.10 -o eth0.100 -j DROP
iptables -A FORWARD -i eth0.20 -o eth0.100 -j DROP

# Permitir solo RTSP (554) y Dahua (37777) entre VLANs
iptables -A FORWARD -i eth0.150 -o eth0.100 -p tcp --dport 554 -j ACCEPT
iptables -A FORWARD -i eth0.150 -o eth0.100 -p tcp --dport 37777 -j ACCEPT
```

### Ver también

- [`guides/dahua/dahua-discovery.md`](dahua/dahua-discovery.md) — descubrir cámaras Dahua
- [`guides/dahua/dahua-troubleshooting.md`](dahua/dahua-troubleshooting.md) — troubleshooting de cámaras

---

### Crear interfaces virtuales por segmento

```bash
# En el router Linux, una interfaz por segmento
# Suponiendo interfaz física eth0

# Segmento Admin
ip addr add 10.0.10.1/24 dev eth0 label eth0:admin

# Segmento IT
ip addr add 10.0.20.1/24 dev eth0 label eth0:it

# Segmento RRHH
ip addr add 10.0.30.1/24 dev eth0 label eth0:rrhh

# Segmento Producción
ip addr add 10.0.40.1/24 dev eth0 label eth0:prod

# Para hacerlo permanente (netplan)
# /etc/netplan/01-netcfg.yaml
network:
  version: 2
  ethernets:
    eth0:
      addresses:
        - 10.0.10.1/24
        - 10.0.20.1/24
        - 10.0.30.1/24
        - 10.0.40.1/24
        - 10.0.99.1/24
```

---

## Linux como router

### Activar forwarding

```bash
# Temporal
sudo sysctl -w net.ipv4.ip_forward=1

# Permanente
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Verificar
cat /proc/sys/net/ipv4/ip_forward
```

### Tabla de rutas

```bash
# Ver tabla de rutas
ip route show

# Agregar ruta estática a segmento Admin
ip route add 10.0.10.0/24 dev eth0

# Agregar ruta hacia Internet (default gateway)
ip route add default via 192.168.1.1

# Ruta hacia otra subred a través de otro router
ip route add 10.0.50.0/24 via 10.0.20.2
```

### Política de reenvío por interfaz

```bash
# /etc/sysctl.d/99-forwarding.conf
# Reenviar solo entre interfaces internas
net.ipv4.conf.eth0.forwarding = 1
net.ipv4.conf.wlan0.forwarding = 1
net.ipv4.conf.tun0.forwarding = 1
```

---

## VLANs (802.1Q)

Las VLANs permiten segmentar sin cables adicionales. Múltiples subredes en un mismo switch.

### Configurar VLAN en Linux

```bash
# Instalar soporte 802.1q
sudo apt install -y vlan
sudo modprobe 8021q

# Crear VLAN 10 (Admin) sobre eth0
ip link add link eth0 name eth0.10 type vlan id 10
ip addr add 10.0.10.1/24 dev eth0.10
ip link set dev eth0.10 up

# VLAN 20 (IT)
ip link add link eth0 name eth0.20 type vlan id 20
ip addr add 10.0.20.1/24 dev eth0.20
ip link set dev eth0.20 up

# VLAN 30 (RRHH)
ip link add link eth0 name eth0.30 type vlan id 30
ip addr add 10.0.30.1/24 dev eth0.30
ip link set dev eth0.30 up

# Ver VLANs
ip -d link show | grep vlan
cat /proc/net/vlan/config
```

### Permanente con netplan

```yaml
# /etc/netplan/01-netcfg.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
  vlans:
    eth0.10:
      id: 10
      link: eth0
      addresses: [10.0.10.1/24]
    eth0.20:
      id: 20
      link: eth0
      addresses: [10.0.20.1/24]
    eth0.30:
      id: 30
      link: eth0
      addresses: [10.0.30.1/24]
```

### Switch gestionable (configuración típica)

```cisco
# Puerto 1: trunk al router Linux
interface gigabitethernet 1/0/1
 switchport mode trunk
 switchport trunk allowed vlan 10,20,30,40,99

# Puerto 2-5: Admin (VLAN 10)
interface gigabitethernet 1/0/2-5
 switchport mode access
 switchport access vlan 10

# Puerto 6-10: IT (VLAN 20)
interface gigabitethernet 1/0/6-10
 switchport mode access
 switchport access vlan 20

# Puerto 11-15: RRHH (VLAN 30)
interface gigabitethernet 1/0/11-15
 switchport mode access
 switchport access vlan 30
```

---

## DHCP por segmento

Un servidor DHCP puede servir múltiples segmentos, ya sea con interfaces separadas o con relay.

### Configuración con isc-dhcp-server

```bash
sudo apt install -y isc-dhcp-server

# /etc/default/isc-dhcp-server
INTERFACESv4="eth0.10 eth0.20 eth0.30 eth0.40 eth0.99"
```

```bash
# /etc/dhcp/dhcpd.conf — Segmentos
default-lease-time 600;
max-lease-time 7200;
ddns-update-style none;
authoritative;

# Administración
subnet 10.0.10.0 netmask 255.255.255.0 {
    range 10.0.10.100 10.0.10.200;
    option routers 10.0.10.1;
    option domain-name-servers 10.0.10.1, 1.1.1.1;
    option domain-name "admin.empresa.local";
}

# IT/Sistemas
subnet 10.0.20.0 netmask 255.255.255.0 {
    range 10.0.20.100 10.0.20.200;
    option routers 10.0.20.1;
    option domain-name-servers 10.0.20.1, 1.1.1.1;
    option domain-name "it.empresa.local";
}

# RRHH
subnet 10.0.30.0 netmask 255.255.255.0 {
    range 10.0.30.100 10.0.30.150;
    option routers 10.0.30.1;
    option domain-name-servers 10.0.30.1, 1.1.1.1;
    option domain-name "rrhh.empresa.local";
}

# Producción (IPs fijas para servidores, rango pequeño)
subnet 10.0.40.0 netmask 255.255.255.0 {
    range 10.0.40.200 10.0.40.220;
    option routers 10.0.40.1;
    option domain-name-servers 10.0.40.1, 1.1.1.1;
    option domain-name "prod.empresa.local";
}

# DMZ
subnet 10.0.99.0 netmask 255.255.255.0 {
    range 10.0.99.100 10.0.99.150;
    option routers 10.0.99.1;
    option domain-name-servers 10.0.99.1, 1.1.1.1;
    option domain-name "dmz.empresa.local";
}
```

### Reservas estáticas (servidores)

```bash
# /etc/dhcp/dhcpd.conf
host web-prod {
    hardware ethernet 00:11:22:aa:bb:01;
    fixed-address 10.0.40.10;
}

host db-prod {
    hardware ethernet 00:11:22:aa:bb:02;
    fixed-address 10.0.40.11;
}

host admin-pc {
    hardware ethernet 00:11:22:aa:bb:10;
    fixed-address 10.0.10.10;
}
```

### DHCP Relay (cuando el DHCP está en otro segmento)

```bash
# En el router del segmento remoto
sudo apt install -y dhcp-helper

# /etc/default/dhcp-helper
DHCPHELPER_OPTS="-s 10.0.20.10"

# Enviar solicitudes DHCP de la VLAN 50 al servidor central
# Requiere interfaz en cada segmento
```

### Ver leases activos

```bash
# Ver IPs asignadas
cat /var/lib/dhcp/dhcpd.leases | less

# Leases activos por segmento
dhcp-lease-list | grep 10.0.10.
dhcp-lease-list | grep 10.0.20.
```

---

## ACLs con iptables

Controlar qué tráfico puede cruzar entre segmentos.

### Política base: denegar todo, permitir lo necesario

```bash
#!/bin/bash
# firewall_segments.sh — Política de segmentación

# Limpiar reglas
iptables -F
iptables -X
iptables -t nat -F
iptables -t mangle -F

# Política por defecto
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Permitir tráfico establecido/relacionado
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# Permitir loopback
iptables -A INPUT -i lo -j ACCEPT

# --- ADMIN (10.0.10.0/24) ---
# Admin → Todo (departamento con más privilegios)
iptables -A FORWARD -s 10.0.10.0/24 -j ACCEPT

# --- IT (10.0.20.0/24) ---
# IT → Servidores prod (puertos específicos)
iptables -A FORWARD -s 10.0.20.0/24 -d 10.0.40.10 \
  -p tcp --dport 22 -j ACCEPT   # SSH a web
iptables -A FORWARD -s 10.0.20.0/24 -d 10.0.40.11 \
  -p tcp --dport 3306 -j ACCEPT  # MySQL
iptables -A FORWARD -s 10.0.20.0/24 -d 10.0.99.0/24 \
  -p tcp --dport 443 -j ACCEPT   # Admin DMZ

# --- RRHH (10.0.30.0/24) ---
# RRHH → solo Internet y servidor de archivos
iptables -A FORWARD -s 10.0.30.0/24 -d 10.0.40.20 \
  -p tcp --dport 445 -j ACCEPT   # Samba
iptables -A FORWARD -s 10.0.30.0/24 -o eth0 \
  -p tcp --dport 80,443 -j ACCEPT  # Internet

# --- PRODUCCIÓN (10.0.40.0/24) ---
# Servidores web → Internet
iptables -A FORWARD -s 10.0.40.10 -o eth0 \
  -p tcp --dport 80,443 -j ACCEPT

# Servidores DB → solo servidores web
iptables -A FORWARD -s 10.0.40.11 -d 10.0.40.10 \
  -p tcp --dport 3306 -j ACCEPT  # MySQL permitido

# --- DMZ (10.0.99.0/24) ---
# DMZ → Internet (web server público)
iptables -A FORWARD -s 10.0.99.0/24 -o eth0 \
  -p tcp --dport 80,443 -j ACCEPT

# DMZ → Producción (solo web → db)
iptables -A FORWARD -s 10.0.99.10 -d 10.0.40.11 \
  -p tcp --dport 3306 -j ACCEPT

# --- GERENCIA (10.0.50.0/24) ---
# Gerencia → Admin, Internet
iptables -A FORWARD -s 10.0.50.0/24 -d 10.0.10.0/24 -j ACCEPT
iptables -A FORWARD -s 10.0.50.0/24 -o eth0 \
  -p tcp --dport 80,443 -j ACCEPT

# --- INVITADOS (10.0.200.0/24) ---
# Solo Internet, nada interno
iptables -A FORWARD -s 10.0.200.0/24 -o eth0 \
  -p tcp --dport 80,443 -j ACCEPT
```

### Logging de tráfico denegado entre segmentos

```bash
# Log de tráfico denegado (útil para debugging)
iptables -A FORWARD -m limit --limit 5/min -j LOG \
  --log-prefix "DENIED: " --log-level 7

# Ver logs
journalctl -k | grep DENIED
dmesg -T | grep DENIED
```

### Guardar y restaurar

```bash
# Guardar reglas
sudo iptables-save > /etc/iptables/rules.v4

# Restaurar al boot
sudo systemctl enable netfilter-persistent
sudo netfilter-persistent save
sudo netfilter-persistent reload
```

---

## NAT y forwarding

Para que los segmentos internos accedan a Internet.

### Masquerade (SNAT)

```bash
# Traducir IPs internas a la IP pública del router
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
```

### DNAT (redirigir puertos a servidores internos)

```bash
# Web público → DMZ
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 \
  -j DNAT --to-destination 10.0.99.10:80

iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 443 \
  -j DNAT --to-destination 10.0.99.10:443

# SSH externo → servidor de administración
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 2222 \
  -j DNAT --to-destination 10.0.10.10:22
```

### Rutas NAT por segmento

```bash
# Permitir NAT solo para ciertos segmentos
iptables -t nat -A POSTROUTING -s 10.0.10.0/24 -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 10.0.30.0/24 -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 10.0.40.0/24 -o eth0 -j MASQUERADE

# DMZ con IP pública estática (1:1 NAT)
iptables -t nat -A PREROUTING -d 203.0.113.50 -j DNAT --to-destination 10.0.99.10
iptables -t nat -A POSTROUTING -s 10.0.99.10 -j SNAT --to-source 203.0.113.50
```

---

## Bridge y virtualización

Conectar máquinas virtuales o contenedores a la red física.

### Bridge Linux

```bash
# Instalar bridge utils
sudo apt install -y bridge-utils

# Crear bridge
ip link add name br0 type bridge
ip link set dev br0 up

# Agregar interfaces físicas al bridge
ip link set dev eth0 master br0

# Asignar IP al bridge (la interfaz física queda sin IP)
ip addr add 10.0.10.1/24 dev br0

# Ver bridges
brctl show
ip link show type bridge

# /etc/netplan/01-netcfg.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
  bridges:
    br0:
      interfaces: [eth0]
      addresses: [10.0.10.1/24]
      parameters:
        stp: true
```

### Bridge con VLANs

```bash
# Bridge que transporta VLANs trunk
ip link add link br0 name br0.10 type vlan id 10
ip addr add 10.0.10.1/24 dev br0.10

ip link add link br0 name br0.20 type vlan id 20
ip addr add 10.0.20.1/24 dev br0.20
```

### Bridge para LXC/Docker

```bash
# Docker ya crea docker0 bridge
# Para redes personalizadas por segmento
docker network create -d bridge \
  --subnet=10.0.40.0/24 \
  --gateway=10.0.40.1 \
  prod-network

docker network create -d bridge \
  --subnet=10.0.99.0/24 \
  --gateway=10.0.99.1 \
  dmz-network
```

---

## DNS por segmento

Un DNS interno puede resolver nombres por segmento.

### dnsmasq para DNS + DHCP

```bash
sudo apt install -y dnsmasq

# /etc/dnsmasq.conf
# Escuchar en interfaces de cada segmento
interface=eth0.10
interface=eth0.20
interface=eth0.30
interface=eth0.40
interface=eth0.99
bind-interfaces

# No reenviar consultas locales
domain=empresa.local
local=/empresa.local/

# Servidores DNS upstream
server=1.1.1.1
server=8.8.8.8

# Resoluciones estáticas por segmento
# Admin
address=/admin-web.empresa.local/10.0.10.10
address=/admin-db.empresa.local/10.0.10.11

# Producción
address=/web.prod.empresa.local/10.0.40.10
address=/db.prod.empresa.local/10.0.40.11

# DMZ
address=/www.empresa.com/10.0.99.10

# DHCP
dhcp-range=eth0.10,10.0.10.100,10.0.10.200,12h
dhcp-range=eth0.20,10.0.20.100,10.0.20.200,12h
dhcp-range=eth0.30,10.0.30.100,10.0.30.150,12h
dhcp-range=eth0.99,10.0.99.100,10.0.99.150,12h

# Reservas
dhcp-host=00:11:22:aa:bb:01,10.0.40.10,web-prod
dhcp-host=00:11:22:aa:bb:02,10.0.40.11,db-prod
```

---

## Monitoreo de tráfico entre segmentos

### nftables/iptables con contadores

```bash
# Contar tráfico entre segmentos
iptables -A FORWARD -s 10.0.10.0/24 -d 10.0.40.0/24 -j ACCEPT
iptables -A FORWARD -s 10.0.30.0/24 -d 10.0.40.0/24 -j ACCEPT

# Ver contadores
iptables -L FORWARD -v -n | column -t

# Contador por protocolo
iptables -A FORWARD -s 10.0.10.0/24 -d 10.0.40.0/24 \
  -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -s 10.0.10.0/24 -d 10.0.40.0/24 \
  -p tcp --dport 443 -j ACCEPT
```

### iptstate (conexiones activas)

```bash
sudo apt install -y iptstate

# Ver conexiones activas entre segmentos
iptstate | grep 10.0.
iptstate | grep 10.0.10.
```

### nethogs por interfaz VLAN

```bash
sudo nethogs eth0.10
sudo nethogs eth0.40
```

### vnstat por segmento

```bash
# Monitoreo continuo de tráfico por interfaz VLAN
vnstat -i eth0.10
vnstat -i eth0.40 -h   # por hora
vnstat -i eth0.40 -d   # por día
```

---

## Escenarios

### 1. PYME con 3 departamentos + DMZ

```bash
# Objetivo: aislar RRHH de Producción, DMZ pública
#
# Internet ←→ [Router Linux] ←→ Switch gestionable
#                    |
#         ┌────┬────┼────┬────┐
#        DMZ  Admin IT  RRHH  Prod
#        VLAN99 /24 VLAN10/24 20/24 30/24 40/24

# Router
ip link add link eth0 name eth0.10 type vlan id 10
ip addr add 10.0.10.1/24 dev eth0.10
ip link set dev eth0.10 up

ip link add link eth0 name eth0.20 type vlan id 20
ip addr add 10.0.20.1/24 dev eth0.20
ip link set dev eth0.20 up

ip link add link eth0 name eth0.30 type vlan id 30
ip addr add 10.0.30.1/24 dev eth0.30
ip link set dev eth0.30 up

ip link add link eth0 name eth0.40 type vlan id 40
ip addr add 10.0.40.1/24 dev eth0.40
ip link set dev eth0.40 up

ip link add link eth0 name eth0.99 type vlan id 99
ip addr add 10.0.99.1/24 dev eth0.99
ip link set dev eth0.99 up

# Firewall
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80,443 \
  -j DNAT --to-destination 10.0.99.10

# DHCP + DNS (dnsmasq)
sudo systemctl enable --now dnsmasq
```

### 2. Segmento invitados aislado

```bash
# Crear VLAN 200 para invitados
ip link add link eth0 name eth0.200 type vlan id 200
ip addr add 10.0.200.1/24 dev eth0.200
ip link set dev eth0.200 up

# Firewall: solo Internet
iptables -A FORWARD -s 10.0.200.0/24 -o eth0 \
  -p tcp --dport 80,443 -j ACCEPT
iptables -A FORWARD -s 10.0.200.0/24 -d 10.0.0.0/8 -j DROP

# DHCP
iptables -A INPUT -i eth0.200 -p udp --dport 67 -j ACCEPT

# Rate limiting (evitar abuso)
iptables -A FORWARD -s 10.0.200.0/24 -m limit --limit 100/sec -j ACCEPT
```

### 3. Aislar servidor de base de datos

```bash
# DB puede:
# - Hablar con servidores web (puerto 3306)
# - Hablar con admin/IT (puerto 22)
# - Hablar con Internet NO

iptables -A FORWARD -d 10.0.40.11 \
  -p tcp --dport 3306 \
  -s 10.0.40.10 -j ACCEPT

iptables -A FORWARD -d 10.0.40.11 \
  -p tcp --dport 22 \
  -s 10.0.20.0/24 -j ACCEPT

iptables -A FORWARD -d 10.0.40.11 -j DROP

# No tiene salida a Internet (si necesita updates, usar proxy/cache)
iptables -A FORWARD -s 10.0.40.11 -o eth0 -j DROP
```

### 4. Acceso remoto por VPN segmentado

```bash
# VPN termina en tun0, asignar IP de segmento Admin
iptables -A FORWARD -i tun0 -s 10.0.10.50 -d 10.0.10.0/24 -j ACCEPT
iptables -A FORWARD -i tun0 -s 10.0.10.50 -d 10.0.20.0/24 -j ACCEPT
iptables -A FORWARD -i tun0 -s 10.0.10.50 -d 10.0.40.0/24 \
  -p tcp --dport 22,443 -j ACCEPT
iptables -A FORWARD -i tun0 -s 10.0.10.50 -d 10.0.30.0/24 -j DROP
```

---

## Uno-liners

```bash
# Ver todas las interfaces y sus IPs
ip addr show | grep -E "^[0-9]|inet "

# Ver tabla de rutas por interfaz
ip route show table all

# Ver VLANs activas
cat /proc/net/vlan/config

# Contar tráfico entre dos segmentos
iptables -L FORWARD -v -n | grep 10.0.10. | grep 10.0.40.

# Habilitar forwarding
sysctl net.ipv4.ip_forward=1

# Crear VLAN rápida
ip link add link eth0 name eth0.100 type vlan id 100 && ip addr add 10.0.100.1/24 dev eth0.100 && ip link set dev eth0.100 up

# Masquerade para un segmento
iptables -t nat -A POSTROUTING -s 10.0.10.0/24 -o eth0 -j MASQUERADE

# Redirigir puerto a host interno
iptables -t nat -A PREROUTING -p tcp --dport 8080 -j DNAT --to-destination 10.0.40.10:80

# Ver conexiones activas entre segmentos
ss -tun | grep 10.0.40.

# Bridge rápido
ip link add br0 type bridge && ip link set eth0 master br0 && ip addr add 10.0.10.1/24 dev br0

# Escanear hosts activos en un segmento
nmap -sn 10.0.40.0/24

# Verificar que dos hosts en distintos segmentos se ven
ping -c 2 10.0.40.10
traceroute 10.0.40.10
```
