#!/bin/sh
# Simula configManager.cgi de Dahua

echo "Content-type: text/xml"
echo ""

# Parsear action del query string
ACTION=$(echo "$QUERY_STRING" | grep -o 'action=[^&]*' | cut -d= -f2)
NAME=$(echo "$QUERY_STRING" | grep -o 'name=[^&]*' | cut -d= -f2)

case "$ACTION" in
    getConfig)
        case "$NAME" in
            NTP)
                cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<NTP>
  <Enable>true</Enable>
  <Server>192.168.1.1</Server>
  <Port>123</Port>
  <TimeZone>ART</TimeZone>
</NTP>
EOF
                ;;
            IVS)
                cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<IVS>
  <Rule>
    <Enable>true</Enable>
    <Type>Tripwire</Type>
    <DetectHuman>true</DetectHuman>
    <DetectVehicle>true</DetectVehicle>
  </Rule>
</IVS>
EOF
                ;;
            *)
                cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<config>
  <status>OK</status>
</config>
EOF
                ;;
        esac
        ;;
    setConfig)
        echo "Config updated"
        ;;
    *)
        echo "Unknown action"
        ;;
esac
