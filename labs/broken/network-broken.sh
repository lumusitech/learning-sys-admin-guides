# Configuración de red rota para contenedor target
# Este script se ejecuta dentro del contenedor para romper la red

# 1. DNS apunta a un servidor inexistente
echo "nameserver 192.0.2.1" > /etc/resolv.conf

# 2. Ruta por defecto eliminada
ip route del default

# 3. Tabla ARP corrupta (entrada falsa)
arp -s 10.0.0.1 00:00:00:00:00:01

# 4. MTU reducido a 500 (causa fragmentación)
ip link set eth0 mtu 500

# 5. Loopback caído (rompe servicios que usan 127.0.0.1)
ip link set lo down
