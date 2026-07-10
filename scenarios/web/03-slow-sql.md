# 🧩 Escenario: API lenta por query SQL pesada — correlacionar nginx + app + DB

**Dominio:** web
**Nivel:** 🔴 Avanzado
**Herramientas:** `curl`, `nginx`, `journalctl`, `tcpdump`, `strace`
**Archivos:** Sistema en vivo

---

## 🎯 Problema

Los usuarios reportan que la API responde muy lento (3–10 segundos por request) pero el servidor no tiene CPU alta ni memoria agotada. Los logs de nginx muestran tiempos de respuesta altos. El problema parece estar en la aplicación o en la base de datos, no en el servidor web. Es necesario correlacionar los tiempos entre nginx, la aplicación y la base de datos para encontrar el cuello de botella real.

---

## ⚡ Quick command (SRE)

```bash
curl -s -o /dev/null -w "HTTP %{http_code} — %{time_total}s\n" http://localhost/api/endpoint
```

---

## ✅ Salida esperada

- `curl` muestra tiempos de respuesta > 3 segundos
- nginx access log muestra request_time alto pero upstream_response_time aún más alto
- la aplicación tiene queries SQL que tardan > 1 segundo
- la base de datos muestra queries en estado "Sending data" o "Copying to tmp table"

Interpretación:

- request_time alto en nginx + upstream_response_time alto → el problema está en el backend (app o DB)
- request_time bajo pero upstream_response_time alto → la app está esperando algo (DB, API externa)
- queries SQL con "Sending data" → la query está leyendo muchos datos (full table scan)
- queries con "Copying to tmp table" → la query necesita crear tabla temporal (JOIN pesado)

---

## 🧠 Diagnóstico

Cuando una API es lenta pero el servidor no está sobrecargado, el problema suele estar en queries SQL ineficientes. Una query sin índice, con JOIN múltiple, o que devuelve millones de filas puede bloquear toda la aplicación.

Patrones clave:

- tiempos de respuesta altos pero CPU baja → el cuello de botella es I/O (DB o disco)
- queries SQL con "Sending data" → full table scan, falta índice
- queries con "Copying to tmp table" → JOIN pesado, necesita optimización
- la lentitud ocurre solo en ciertos endpoints → la query problemática está en ese endpoint
- la lentitud es intermitente → posible lock de tabla o deadlock

👉 Si nginx responde rápido pero la app tarda, el problema está en la comunicación app-DB.

---

## 🛠️ Procedimiento (runbook)

### 1. Medir tiempo de respuesta desde nginx

```bash
curl -s -o /dev/null -w "time_connect: %{time_connect}\ntime_starttransfer: %{time_starttransfer}\ntime_total: %{time_total}\n" http://localhost/api/endpoint
```

### 2. Ver tiempos en el access log de nginx

```bash
tail -20 /var/log/nginx/access.log | awk '{print $NF, $7}'
```

### 3. Verificar si la app está esperando la DB

```bash
strace -p <PID_APP> -e trace=network -T 2>&1 | head -20
```

### 4. Ver queries lentas en la base de datos

```bash
# MySQL/MariaDB:
mysql -e "SHOW PROCESSLIST;"
mysql -e "SHOW ENGINE INNODB STATUS\G" | grep -A 5 "LATEST DETECTED DEADLOCK"

# PostgreSQL:
psql -c "SELECT pid, now() - pg_stat_activity.query_start AS duration, query FROM pg_stat_activity WHERE state = 'active' ORDER BY duration DESC;"
```

### 5. Verificar índices de la tabla problemática

```bash
# MySQL:
mysql -e "SHOW INDEX FROM <tabla>;"

# PostgreSQL:
psql -c "\d+ <tabla>"
```

---

## 🧯 Mitigación

Si se confirma que la query SQL es el problema:

Verificar:

```bash
mysql -e "SHOW PROCESSLIST;"
curl -s -o /dev/null -w "%{time_total}\n" http://localhost/api/endpoint
```

Acción:

```bash
# Agregar índice a la columna que falta
mysql -e "CREATE INDEX idx_columna ON tabla(columna);"

# O optimizar la query (si tenemos acceso al código)
# Ejemplo: agregar LIMIT, reducir columnas SELECT, evitar SELECT *
```

Mitigación adicional:

```bash
# Habilitar slow query log para detectar queries lentas
mysql -e "SET GLOBAL slow_query_log = 'ON';"
mysql -e "SET GLOBAL long_query_time = 1;"

# Verificar que el índice se aplicó
mysql -e "SHOW INDEX FROM tabla;"
```

Rollback:

```bash
# Si el índice causa problemas de rendimiento en escrituras
mysql -e "DROP INDEX idx_columna ON tabla;"
```

Casos comunes:

- query sin índice en columna filtrada → full table scan
- JOIN entre tablas grandes sin índice → la query tarda segundos
- SELECT * cuando solo se necesitan pocas columnas → lee datos innecesarios
- query con ORDER BY sin índice → filesort en disco
- subquery que se ejecuta por cada fila → reescribir como JOIN

---

## ✅ Interpretación

- la query tarda < 100ms tras agregar índice → el problema era la falta de índice
- la query sigue lenta → revisar el plan de ejecución con EXPLAIN
- la lentitud desaparece tras reiniciar la app → posible connection leak o pool agotado
- la lentitud es intermitente → posible lock de tabla o deadlock

---

## 🐧 Variante Alpine (OpenRC)

> Este escenario usa `systemctl` y `journalctl`.

### Variante B — systemctl + journalctl

```bash
# Debian:                          # Alpine:
systemctl restart nginx            rc-service nginx restart
journalctl -u nginx --since "1h"   logread | grep nginx | tail -20
```

---

## 🧑‍🏫 Modo docente

**Preguntas:** ¿Cómo correlacionás tiempos entre nginx y la base de datos? ¿Qué columnas del access.log de nginx analizás? ¿Qué herramienta de red usás para capturar queries lentas?

**Ejercicio:** Identificar una request lenta en nginx, correlacionar con query lenta en DB logs, proponer optimización.

**Evaluación:** identificación de la request problemática, correlación nginx-DB, propuesta de índice o refactor de query.

---

## 🔗 Referencias

- [`nginx`](../../guides/nginx.md) — configuración y logs de nginx
- [`curl`](../../guides/curl.md) — inspección de respuestas HTTP
- [`tcpdump`](../../guides/tcpdump.md) — captura de tráfico
- [`scenarios/web/01-performance-and-error-analysis.md`](01-performance-and-error-analysis.md) — análisis de rendimiento web
- [`scenarios/web/02-nginx-5xx-errors.md`](02-nginx-5xx-errors.md) — errores 5xx de nginx
