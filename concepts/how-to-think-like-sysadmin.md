
# Cómo pensar como un sysadmin — Patrones de diagnóstico

## 🧠 ¿Qué es?

Pensar como un sysadmin implica identificar rápidamente qué comportamiento es normal y cuál es anómalo, y reducir el problema eliminando hipótesis incorrectas de forma sistemática.

La diferencia entre un principiante y un sysadmin experimentado no es el conocimiento de comandos, sino la capacidad de interpretar señales del sistema.

---

## 🎯 ¿Por qué importa?

- Reduce el tiempo de diagnóstico
- Evita cambios innecesarios o peligrosos
- Permite identificar patrones de fallo repetitivos
- Mejora la capacidad de respuesta ante incidentes

Un diagnóstico incorrecto genera más downtime que el problema original.

---

## 🧩 Conceptos clave

### Normal vs anómalo

Un sysadmin no mira valores absolutos, sino patrones:

- ¿Este comportamiento es esperado?
- ¿Cambió respecto a antes?
- ¿Es sostenido o puntual?

---

### Señales del sistema

El sistema siempre deja pistas:

- uso de CPU
- consumo de memoria
- I/O de disco
- latencia de red
- logs

Interpretar estas señales correctamente es la base del diagnóstico.

---

### Reducción del problema

Diagnosticar es descartar hipótesis:

- ¿es la red?
- ¿es la aplicación?
- ¿es el sistema?
- ¿es un cambio reciente?

Cada paso elimina una clase completa de causas.

---

## 🔄 Cómo encaja en el sistema

Este modelo mental se aplica en todas las capas:

- sistema operativo → procesos, memoria, disco
- red → conectividad, latencia, pérdida
- aplicaciones → errores, logs, comportamiento
- infraestructura → DNS, balanceadores, firewall

---

## ⚠️ Errores comunes

- Saltar directo a soluciones sin diagnosticar
- Cambiar múltiples variables al mismo tiempo
- Ignorar patrones históricos (baseline)
- Depender solo de comandos sin interpretar resultados
- Sobrecargar el diagnóstico con herramientas innecesarias

---

## 🧠 Modelo mental de diagnóstico

Un sysadmin trabaja así:

1. Observa el síntoma
2. Identifica qué capa podría estar fallando
3. Verifica lo más simple primero
4. Reduce el problema paso a paso
5. Confirma hipótesis con evidencia

El objetivo no es "probar cosas", sino **entender el sistema**.

---

## 📊 Patrones normales vs anómalos (referencia conceptual)

### CPU

| Señal | Normal | Anómalo |
|-------|--------|---------|
| `%us` (usuario) | < 70% sostenido | > 90% sostenido → proceso runaway o loop infinito |
| `%sy` (kernel) | < 20% | > 40% → driver bug, hardware o DDoS |
| `%wa` (iowait) | < 5% | > 30% → cuello de botella de disco |
| Load average | < núcleos × 1.0 | > núcleos × 2.0 → sobrecarga real o I/O |
| Context switches | < 10.000/s | > 50.000/s → contención de locks o threads excesivos |

### Memoria

| Señal | Normal | Anómalo |
|-------|--------|---------|
| RAM usada | 60–80% | > 95% sostenido → presión de memoria |
| Swap used | 0 MB (ideal) | > 0 MB creciendo → falta de RAM |
| OOM Killer | Nunca | Procesos terminados → memoria agotada |
| Cached | Alta (esperado) | Caída repentina → presión aguda de memoria |

### Disco

| Señal | Normal | Anómalo |
|-------|--------|---------|
| `%used` (`df -h`) | < 80% | > 90% → riesgo, > 95% → crítico |
| Inode usage (`df -i`) | < 70% | > 90% → demasiados archivos pequeños |
| I/O wait (`iostat`) | < 5% | > 30% → disco es cuello de botella |
| Disk latency | < 5ms (SSD), < 15ms (HDD) | > 50ms → disco degradado o sobresaturado |

### Red

| Señal | Normal | Anómalo |
|-------|--------|---------|
| Latencia ping | < 1ms (LAN), < 50ms (WAN) | > 100ms sostenido → congestión o ruta larga |
| Packet loss | 0% | > 1% → problema de red serio |
| TIME_WAIT acumuladas | < 10.000 | > 30.000 → agotamiento de puertos efímeros |
| Backlog de conexiones | < 100 | > 1.000 → servidor no da abasto |

### Procesos

| Señal | Normal | Anómalo |
|-------|--------|---------|
| Zombies (`Z`) | 0 | > 0 → padre no reaprovisiona |
| Estado `D` (uninterruptible) | < 5 | > 20 → I/O bloqueada severa |
| Procesos en `S` (sleeping) | Mayoría | Minoría → sistema idle anómalo |
| Fork rate | < 100/s | > 1.000/s → fork bomb o app mal escrita |

---

## 🔍 Embudo de diagnóstico (capas OSI)

Cuando enfrentás un síntoma, reducí el problema identificando qué capa del stack está fallando:

| Síntoma | Capa probable | Comando inicial |
|---------|--------------|-----------------|
| No se carga una página | Aplicación (capa 7) | `curl -I <url>` |
| Timeout de conexión | Transporte (capa 4) | `ss -tlnp`, `nc -zv <host> <port>` |
| Sin conectividad | Red (capa 3) | `ping <gateway>`, `ip route` |
| Pérdida de paquetes | Red (capa 3) | `mtr <host>` |
| ARP resolution falla | Enlace (capa 2) | `ip neigh` |
| Servidor lento | Sistema operativo | `top`, `vmstat 1`, `iostat -x 1` |
| Disco lento | Almacenamiento | `iostat -x 1`, `iotop` |
| App devuelve 5xx | Aplicación | `journalctl -u <svc>`, logs de app |

El embudo funciona de afuera hacia adentro:

1. verificá conectividad básica (¿responde el host?)
2. verificá el servicio (¿el puerto está abierto?)
3. verificá la aplicación (¿responde correctamente?)
4. verificá los recursos (¿CPU, memoria, disco, red?)

Cada capa que descartás reduce el espacio de búsqueda a la mitad.

---

## 🔄 Proceso iterativo de troubleshooting

El diagnóstico no es lineal. Es un ciclo que se repite hasta encontrar la causa raíz:

1. **Observar** — ¿Qué está pasando? ¿Cuál es el síntoma exacto?
2. **Formular hipótesis** — ¿Qué podría causar esto? (priorizar lo más simple y probable)
3. **Elegir prueba** — ¿Qué comando o verificación descarta esta hipótesis?
4. **Ejecutar** — Correr el comando y capturar la salida
5. **Analizar** — ¿La salida confirma o descarta la hipótesis?
6. **Decidir** — Si se descarta, volver al paso 2. Si se confirma, pasar a mitigar.
7. **Mitigar** — Aplicar la solución más segura primero
8. **Verificar** — ¿El síntoma desapareció? ¿Hay efectos secundarios?

Reglas del proceso:

- una hipótesis por vez — cambiar una sola variable entre pruebas
- la prueba más rápida primero — `ping` antes que `tcpdump`, `free` antes que `perf`
- si no entendés la salida, no la inventes — buscá ayuda o documentación
- documentá lo que hiciste — el próximo incidente puede ser idéntico

---

## 📜 Lectura de logs (conceptual)

Los logs no se leen línea por línea, se interpretan por patrones:

- repetición
- frecuencia
- correlación temporal
- origen (IP, servicio, usuario)

Un solo error no es problema. Un patrón repetido sí.

---

## 🔗 Ver también

- [`systemd_journalctl`](../guides/systemd_journalctl.md) — logs del sistema con systemd
- [`ip_ss`](../guides/ip_ss.md) — redes y sockets
- [`ping_traceroute`](../guides/ping_traceroute.md) — conectividad y latencia
- [`tcpdump`](../guides/tcpdump.md) — captura de tráfico de red
- [`scenarios/system/01-top-processes-and-resources.md`](../scenarios/system/01-top-processes-and-resources.md) — diagnóstico inicial de procesos y recursos
