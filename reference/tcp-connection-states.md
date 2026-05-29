# Estados de conexión TCP — Referencia rápida

Interpretación de los estados TCP vistos con `ss`, `netstat` o `tcpdump` para troubleshooting de red.

---

## 🔍 Cómo ver estados de conexión

```bash
# Ver todas las conexiones con estado
ss -tlnp      # solo LISTEN (puertos en escucha)
ss -tan       # todas las conexiones TCP establecidas y en transición
ss -tan | awk '{print $1}' | sort | uniq -c | sort -rn   # resumen por estado
```

---

## 📊 Tabla de estados

| Estado | Significado | Lo que indica en troubleshooting |
|--------|-------------|----------------------------------|
| **LISTEN** | El socket espera conexiones entrantes | Normal para servicios servidores. Si falta → el servicio no está escuchando |
| **SYN_SENT** | Se envió SYN, esperando SYN+ACK del otro lado | Conexión en curso. Si persiste → firewall DROP, host caído, ruta rota |
| **SYN_RECV** | Se recibió SYN, se respondió SYN+ACK, esperando ACK final | Handshake en progreso. Muchas → flood SYN (DDoS) o backlog lleno |
| **ESTABLISHED** | Conexión activa, datos fluyen en ambos sentidos | Normal. El número esperado depende del servicio y carga |
| **FIN_WAIT1** | Se envió FIN, esperando ACK de ese FIN | Cierre iniciado localmente. Normal en transición |
| **FIN_WAIT2** | Se recibió ACK del FIN, esperando FIN del otro lado | Cierre parcial. Si persiste → peer no cierra la conexión |
| **CLOSE_WAIT** | Se recibió FIN, se respondió ACK, esperando que la app local cierre | La app no está llamando `close()`. Fuga de conexiones, bug clásico |
| **TIME_WAIT** | Espera 2*MSL (~60s) antes de cerrar definitivamente | Normal después de cerrar. Muchas en servidores con alta rotación de conexiones |
| **LAST_ACK** | Se envió FIN, esperando el último ACK | Cierre iniciado por el peer. Si persiste → ACK no llega (red/perdida) |
| **CLOSING** | Ambas partes enviaron FIN simultáneamente, esperando ACK | Raro. Ocurre en cierres simultáneos |
| **CLOSED** | Socket cerrado | Estado final. No debería aparecer en `ss` activo |

---

## 🚨 Estados problema

| Estado | ¿Es problema? | Acción |
|--------|--------------|--------|
| LISTEN | Normal (es lo esperado) | Si falta un servicio, revisar si corrió y si escucha en la IP/interfaz correcta |
| SYN_SENT persistente | Sí | Firewall DROP, host caído, ruta incorrecta. Probar con `ping`, `tcptraceroute` |
| SYN_RECV excesivo | Sí (flood) | Backlog de escucha saturado o ataque SYN. Revisar `netstat -s \| grep LISTEN`, `tcp_syncookies` |
| ESTABLISHED | Normal | Monitorear cantidad esperada por servicio |
| FIN_WAIT2 persistente | Posible | Peer no cierra. Timeout de ~60s aplica, pero si hay muchas, revisar app remota |
| CLOSE_WAIT | **Sí** | Bug en la aplicación local: no cierra sockets. Revisar fuga de file descriptors |
| TIME_WAIT | Normal pero controlar | Muy alta (>30.000) puede agotar puertos efímeros. Ajustar `net.ipv4.tcp_tw_reuse` |
| LAST_ACK persistente | Sí | ACK final no llega. Posible pérdida de paquetes o peer caído |

---

## 📈 Cuándo preocuparse

```bash
# Resumen rápido de estado de conexiones
ss -tan | awk '{print $1}' | sort | uniq -c | sort -rn

# Interpretación:
# - CLOSE_WAIT > 100 → la app no cierra conexiones, revisar fuga de FDs
# - TIME_WAIT > 30.000 → presión sobre puertos efímeros
# - SYN_RECV > 1.000 → posible SYN flood
# - ESTABLISHED bajo de repente → servicio dejó de recibir tráfico o hubo reinicio
```

---

## 🔍 Cómo usarlo en diagnóstico

```bash
# Resumen rápido por estado
ss -tan | awk '{print $1}' | sort | uniq -c | sort -rn

# Ver solo conexiones problemáticas
ss -tan | awk '$1 ~ /CLOSE_WAIT|TIME_WAIT|SYN_RECV/'

# Contar conexiones por estado
ss -tan | grep -c CLOSE_WAIT
ss -tan | grep -c TIME_WAIT
ss -tan | grep -c SYN_RECV
```

---

## 🔗 Ver también

- [`ip_ss`](../guides/ip_ss.md) — opciones de ss para filtrar por estado
- [`tcpdump`](../guides/tcpdump.md) — captura de paquetes TCP a nivel wire
- [`scenarios/networking/01-detect-ssh-brute-force.md`](../scenarios/networking/01-detect-ssh-brute-force.md) — detección de fuerza bruta por conexiones
