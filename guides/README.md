# 🐧 sys-admin-guides

Colección completa de guías de referencia para administración de servidores Linux y redes. Cada guía cubre una herramienta desde lo más básico hasta escenarios profesionales reales, explicando **cada opción** y la **interpretación de salidas** en contextos de éxito, falla y ataque.

```
../README.md   → índice raíz
labs/          → archivos de ejemplo para practicar
```

## 📚 Guías incluidas

### Procesamiento de texto y datos

| Guía                   | Descripción                                                                               |
| ---------------------- | ----------------------------------------------------------------------------------------- |
| [`awk.md`](awk.md)     | Lenguaje de procesamiento por campos. Patrones, arrays, funciones, getline, combinaciones |
| [`sed.md`](sed.md)     | Editor de flujo. Sustituciones, rangos, hold space, branching, edición in-place           |
| [`grep.md`](grep.md)   | Búsqueda con expresiones regulares. PCRE, contexto, recursividad, escenarios de seguridad |
| [`cut.md`](cut.md)     | Extracción de columnas por caracteres, campos y bytes                                     |
| [`sort.md`](sort.md)   | Ordenamiento alfabético, numérico, por campos, versiones, humano                          |
| [`uniq.md`](uniq.md)   | Filtrado y conteo de duplicados                                                           |
| [`wc.md`](wc.md)       | Conteo de líneas, palabras, caracteres y bytes                                            |
| [`find.md`](find.md)   | Búsqueda de archivos por nombre, tipo, tamaño, fecha, permisos, contenido                 |
| [`xargs.md`](xargs.md) | Construcción de comandos desde stdin. Paralelismo, seguridad con `-0`                     |

### Redes y conectividad

| Guía                                       | Descripción                                                                         |
| ------------------------------------------ | ----------------------------------------------------------------------------------- |
| [`ip_ss.md`](ip_ss.md)                     | Configuración de red (ip) y sockets (ss). Interfaces, rutas, ARP, estados TCP       |
| [`tcpdump.md`](tcpdump.md)                 | Captura de paquetes. Filtros BPF, análisis de ataques, resolución de problemas      |
| [`ping_traceroute.md`](ping_traceroute.md) | Diagnóstico ICMP. ping, traceroute, mtr, interpretación de TTL y latencia           |
| [`dig_curl.md`](dig_curl.md)               | DNS (dig) y transferencias HTTP/API (curl). Autenticación, SSL, medición de tiempos |
| [`nmap.md`](nmap.md)                       | Escaneo de puertos y servicios. NSE, detección de SO, evasión de firewalls          |
| [`iptables.md`](iptables.md)               | Firewall Netfilter. Reglas, NAT, mitigación de ataques, rate limiting               |

### Sistema

| Guía                                             | Descripción                                                                         |
| ------------------------------------------------ | ----------------------------------------------------------------------------------- |
| [`systemd_journalctl.md`](systemd_journalctl.md) | Gestión de servicios (systemctl) y logs (journalctl). Análisis de arranque, filtros |

## 🎯 Enfoque

Cada guía está estructurada para servir como **referencia rápida** y como **material de estudio**:

- **Cada opción explicada**: no solo se muestra `-d`, se explica que es el delimitador de campos
- **Salidas interpretadas**: qué significa cada columna, cada flag, cada código de error
- **Escenarios reales**: ejemplos de logs, configuraciones, monitoreo
- **Escenarios de ataque**: cómo detectar SYN flood, ARP spoofing, port scans, DDoS
- **Escenarios de falla**: qué significa un timeout, un RST, un CLOSE_WAIT, un NXDOMAIN
- **Combinaciones**: cómo se conectan las herramientas (awk+sort, find+xargs, grep+sed, etc.)
- **Uno-liners**: comandos listos para copiar y pegar

## 🚀 Cómo usar

Clonar el repo:

```bash
git clone git@github.com:lumusitech/learning-sys-admin-guides.git
cd learning-sys-admin-guides
```

## 📝 Licencia

MIT — libre de usar, compartir y modificar.
