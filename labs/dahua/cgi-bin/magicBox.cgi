#!/bin/sh
# Simula magicBox.cgi de Dahua

echo "Content-type: text/xml"
echo ""

# Parsear action del query string
ACTION=$(echo "$QUERY_STRING" | grep -o 'action=[^&]*' | cut -d= -f2)

case "$ACTION" in
    getSystemInfo)
        cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<systemInfo>
  <deviceName>IPC-HDW5442T-ASE</deviceName>
  <serialNumber>4P0720GAMG00001</serialNumber>
  <deviceType>IPC-HDW5442T-ASE</deviceType>
  <softwareVersion>V2.820.0000000.0.R</softwareVersion>
  <hardwareVersion>1.00</hardwareVersion>
</systemInfo>
EOF
        ;;
    reboot)
        echo "Rebooting..."
        ;;
    reset)
        echo "Factory reset..."
        ;;
    *)
        echo "Unknown action"
        ;;
esac
