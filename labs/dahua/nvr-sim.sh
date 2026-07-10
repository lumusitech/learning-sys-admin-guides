#!/bin/sh
# nvr-sim.sh - Inicializa NVR Dahua simulado
set -e

echo "🚀 Inicializando NVR Dahua simulado..."

# Configurar SSH
echo "Configurando SSH..."
mkdir -p /var/run/sshd
echo "root:admin123" | chpasswd

# Deshabilitar DNS del lado del servidor (evita timeouts)
sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config

# Configurar nginx para interfaz web
echo "Configurando interfaz web..."
mkdir -p /run/nginx
cat > /etc/nginx/http.d/default.conf << 'EOF'
server {
    listen 80 default_server;
    server_name _;
    root /var/www/html;
    index index.html;
    
    location / {
        return 200 'NVR Dahua Simulator\n';
    }
}
EOF

# Simular disco duro
echo "Simulando disco..."
mkdir -p /mnt/sda/record/2025/01/15
mkdir -p /mnt/sda/record/2025/01/14
mkdir -p /var/log

# Crear archivos de grabación simulados
dd if=/dev/zero of=/mnt/sda/record/2025/01/15/cam01_ch01_20250115_100000.mp4 bs=1M count=10 2>/dev/null
dd if=/dev/zero of=/mnt/sda/record/2025/01/15/cam02_ch02_20250115_100000.mp4 bs=1M count=10 2>/dev/null
dd if=/dev/zero of=/mnt/sda/record/2025/01/14/cam01_ch01_20250114_100000.mp4 bs=1M count=10 2>/dev/null

# Crear logs simulados
cat > /var/log/messages << 'EOF'
Jan 15 10:00:00 nvr dahua[1234]: System started
Jan 15 10:00:01 nvr dahua[1234]: Recording service started
Jan 15 10:00:02 nvr dahua[1234]: Connected camera 192.168.100.108
Jan 15 10:00:03 nvr dahua[1234]: HDD detected /dev/sda (2000GB)
Jan 15 10:00:04 nvr dahua[1234]: Camera channel 01 - recording started
Jan 15 10:00:05 nvr dahua[1234]: Camera channel 02 - recording started
EOF

cat > /var/log/record.log << 'EOF'
Jan 15 10:00:04 Channel 01 recording started (192.168.100.108)
Jan 15 10:00:05 Channel 02 recording started (192.168.100.109)
Jan 15 10:15:23 Channel 01 motion detected
Jan 15 10:15:24 Channel 01 recording saved
Jan 15 10:30:45 Channel 02 motion detected
Jan 15 10:30:46 Channel 02 recording saved
EOF

cat > /var/log/ntp.log << 'EOF'
NTP synchronizing with 192.168.1.1
Time synchronized successfully
EOF

# Iniciar servicios
echo "Iniciando SSH..."
/usr/sbin/sshd

echo "Iniciando nginx..."
nginx

echo ""
echo "✅ NVR Dahua simulado listo"
echo "   Credenciales SSH: root/admin123"
echo "   IP: 10.0.100.100"
echo "   SSH: ssh root@10.0.100.100"
echo "   Web: http://10.0.100.100:80"
echo ""

# Mantener contenedor vivo
tail -f /dev/null
