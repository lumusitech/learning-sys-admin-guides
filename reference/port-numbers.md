# Puertos TCP/UDP — Referencia rápida

Puertos comunes para troubleshooting de red y seguridad. Usar con `ss`, `netstat`, `lsof`, `nmap`.

---

## 🔴 Puertos de sistema (0-1023)

| Puerto | Protocolo | Servicio | Qué verificar |
|--------|----------|----------|-------------|
| 20, 21 | TCP | FTP (data, control) | `ftp` no responde: firewall bloqueando modo pasivo |
| 22 | TCP | SSH | Brute force: `grep "Failed password" /var/log/auth.log` |
| 23 | TCP | Telnet | NUNCA en producción. Si aparece → comprometido |
| 25 | TCP | SMTP | `telnet mail.example.com 25` para testear relay |
| 53 | UDP/TCP | DNS | `dig @127.0.0.1 example.com`, UDP para queries, TCP para zone transfers |
| 67, 68 | UDP | DHCP | `dhclient -v eth0`, `tcpdump -i eth0 port 67 or port 68` |
| 80 | TCP | HTTP | `curl -I http://localhost` |
| 110 | TCP | POP3 | Email entrante. Obsoleto frente a IMAP |
| 123 | UDP | NTP | `ntpq -p`, `chronyc sources` |
| 143 | TCP | IMAP | Email entrante (IMAP) |
| 161, 162 | UDP | SNMP | Monitoreo de red. `snmpwalk -v2c -c public localhost` |
| 389 | TCP | LDAP | Directorio. `ldapsearch -x -H ldap://localhost -b "dc=example,dc=com"` |
| 443 | TCP | HTTPS | `openssl s_client -connect localhost:443 -servername example.com` |
| 445 | TCP | SMB/CIFS | Compartición Windows/Samba. `smbclient -L //server` |
| 465 | TCP | SMTPS | SMTP sobre SSL (deprecado, usar 587) |
| 514 | UDP | Syslog | `logger -n localhost "test"`, `tcpdump -i lo port 514` |
| 587 | TCP | SMTP Submission | Envío de email autenticado (STARTTLS) |
| 636 | TCP | LDAPS | LDAP sobre SSL |
| 993 | TCP | IMAPS | IMAP sobre SSL |

---

## 🟡 Puertos de aplicación (1024-49151)

| Puerto | Servicio | Qué verificar |
|--------|----------|-------------|
| 1080 | SOCKS proxy | Proxy tunnel. `curl --socks5 localhost:1080 http://example.com` |
| 1433 | MSSQL | `nc -zv localhost 1433` |
| 1521 | Oracle DB | `tnsping <SID>` |
| 1723 | PPTP VPN | VPN insegura. Migrar a WireGuard/OpenVPN |
| 2049 | NFS | `showmount -e server`, `mount -t nfs server:/export /mnt` |
| 2181 | ZooKeeper | `nc localhost 2181` → `stat` para ver estado |
| 2375, 2376 | Docker API | Exponer sin TLS es un riesgo de seguridad |
| 3000 | Grafana, dev servers | Web UI de monitoreo |
| 3128 | Squid proxy | `curl -x http://localhost:3128 http://example.com` |
| 3306 | MySQL/MariaDB | `mysql -h localhost -P 3306 -u root -p` |
| 3389 | RDP | Escritorio remoto Windows |
| 4000 | Aplicaciones web dev | Muchos frameworks usan este puerto |
| 5000 | Flask dev, Docker registry | `curl localhost:5000/v2/_catalog` |
| 5432 | PostgreSQL | `psql -h localhost -p 5432 -U postgres` |
| 5672 | RabbitMQ (AMQP) | `rabbitmqctl status` |
| 5900+ | VNC | Escritorio remoto. `vncviewer host:0` (5900 + display) |
| 6379 | Redis | `redis-cli -h localhost -p 6379 ping` |
| 6443 | Kubernetes API | `kubectl cluster-info` |
| 8080 | HTTP alternativo | Proxy reverso, Tomcat, Jenkins |
| 8443 | HTTPS alternativo | Igual que 8080 pero con TLS |
| 9090 | Prometheus | `curl localhost:9090/api/v1/query?query=up` |
| 9092 | Kafka | `kafka-topics.sh --bootstrap-server localhost:9092 --list` |
| 9100 | node_exporter | `curl localhost:9100/metrics` |
| 9200 | Elasticsearch | `curl localhost:9200/_cluster/health` |
| 11211 | Memcached | `nc localhost 11211` y escribir `stats` |
| 27017 | MongoDB | `mongosh --host localhost --port 27017` |

---

## 🛠️ Comandos rápidos

```bash
# ¿Quién está escuchando?
ss -tlnp                    # TCP listening
ss -ulnp                    # UDP listening
ss -tlnp | grep ":80 "      # puerto específico

# ¿Quién está conectado?
ss -tn state established    # conexiones TCP establecidas
lsof -i :22                 # qué proceso usa el puerto 22
```

---

## 🔗 Ver también

- [`guides/ip_ss.md`](../guides/ip_ss.md) — socket statistics
- [`guides/nc.md`](../guides/nc.md) — netcat para testeo de puertos
- [`guides/curl.md`](../guides/curl.md) — HTTP client y testeo de endpoints
- [`guides/nmap.md`](../guides/nmap.md) — escaneo de puertos
- [`guides/lsof.md`](../guides/lsof.md) — listar archivos abiertos y puertos
- [`reference/tcp-connection-states.md`](tcp-connection-states.md) — estados de conexiones TCP
- [`scenarios/networking/01-detect-ssh-brute-force.md`](../scenarios/networking/01-detect-ssh-brute-force.md) — SSH brute force
- [`scenarios/security/01-detect-and-block-malicious-ips.md`](../scenarios/security/01-detect-and-block-malicious-ips.md) — bloqueo de IPs maliciosas
