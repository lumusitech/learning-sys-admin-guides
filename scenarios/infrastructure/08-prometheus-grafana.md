# 🧩 Escenario: Implementar monitoreo con Prometheus, node_exporter y Grafana

**Dominio:** infrastructure
**Nivel:** 🟡 Intermedio
**Herramientas:** `prometheus`, `node_exporter`, `grafana`, `curl`, `docker`
**Archivos:** `labs/docker-compose.monitoring.yml`

---

## 🎯 Problema

Tienes un servidor en producción y necesitas establecer monitoreo para detectar anomalías antes de que causen incidentes. Necesitas métricas de CPU, memoria, disco y red, visualizarlas en un dashboard, y definir SLIs que se alineen con los SLOs del servicio.

No tienes acceso a soluciones SaaS ni presupuesto para herramientas comerciales. Debes implementar un stack open source con Prometheus, node_exporter y Grafana.

---

## ⚡ Quick command (SRE)

```bash
curl -s http://localhost:9090/api/v1/query?query=up | jq '.data.result[] | {job: .metric.job, instance: .metric.instance, status: .value[1]}'
```

---

## ✅ Salida esperada

```json
{
  "data": {
    "result": [
      {"job": "prometheus", "instance": "localhost:9090", "status": "1"},
      {"job": "node", "instance": "node_exporter:9100", "status": "1"}
    ]
  }
}
```

Interpretación:

- `status: "1"` → el target está siendo scrapeado correctamente
- `status: "0"` → el target no responde (caído o inaccesible)
- Si falta un target, revisar configuración de `prometheus.yml` y conectividad de red

---

## 🧠 Diagnóstico

El monitoreo no es solo instalar herramientas: es definir **qué medir** antes de **cómo medirlo**.

Patrones clave:

- Sin métricas no hay baseline → sin baseline no hay detección de anomalías
- node_exporter expone métricas del sistema operativo (CPU, memoria, disco, red, load)
- Prometheus scrapea métricas cada `scrape_interval` (por defecto 15s)
- Grafana consulta Prometheus y las visualiza
- Un SLI bien definido es una consulta PromQL, no una corazonada

Relación con SRE:

| Concepto | En este escenario |
|----------|------------------|
| SLI | `(1 - avg by(job) (rate(node_cpu_seconds_total{mode="idle"}[5m])))` → uso de CPU |
| SLO | CPU < 80% sostenido, memoria < 85%, disco < 90% |
| Error budget | Tiempo permitido por fuera del SLO antes de intervenir |

---

## 🛠️ Procedimiento (runbook)

### 1. Iniciar el stack de monitoreo

```bash
cd labs
docker compose -f docker-compose.monitoring.yml up -d
docker compose -f docker-compose.monitoring.yml ps
```

Verificar que los 3 servicios estén `Up`:

```text
NAME            STATUS
prometheus      Up
node_exporter   Up
grafana         Up
```

### 2. Verificar que Prometheus scrapea correctamente

```bash
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, health: .health}'
```

Salida esperada:

```json
{"job": "prometheus", "health": "up"}
{"job": "node", "health": "up"}
```

Si algún target está `down`:

- Revisar que el contenedor destino esté corriendo
- Verificar conectividad de red entre contenedores
- Revisar `prometheus.yml` — el hostname debe coincidir con el nombre del servicio

### 3. Explorar métricas de node_exporter

```bash
# Listar todas las métricas disponibles
curl -s http://localhost:9100/metrics | head -30

# CPU usage rate (5 minutos)
curl -s 'http://localhost:9090/api/v1/query?query=100%20-%20avg(rate(node_cpu_seconds_total{mode="idle"}[5m]))%20*%20100'

# Memoria usada (%)
curl -s 'http://localhost:9090/api/v1/query?query=(1%20-%20node_memory_MemAvailable_bytes%20/%20node_memory_MemTotal_bytes)%20*%20100'

# Disco usado (%)
curl -s 'http://localhost:9090/api/v1/query?query=(1%20-%20node_filesystem_avail_bytes{mountpoint="/"}%20/%20node_filesystem_size_bytes{mountpoint="/"})%20*%20100'

# Load average (1 min)
curl -s 'http://localhost:9090/api/v1/query?query=node_load1'
```

Interpretar:

- CPU > 80% sostenido → posible bottleneck, revisar procesos
- Memoria > 90% → riesgo de OOM o swapping
- Disco > 85% → planificar limpieza o expansión
- Load average > núcleos × 2 → sobrecarga de CPU o I/O

### 4. Consultas PromQL para SLIs

```bash
# SLI: Disponibilidad de node_exporter (up / scrape total)
curl -s 'http://localhost:9090/api/v1/query?query=avg(up{job="node"})'

# SLI: Tasa de error de I/O de disco
curl -s 'http://localhost:9090/api/v1/query?query=rate(node_disk_io_time_seconds_total[5m])'

# SLI: Latencia de disco (avg I/O time)
curl -s 'http://localhost:9090/api/v1/query?query=rate(node_disk_read_time_seconds_total[5m])%20/%20rate(node_disk_reads_completed_total[5m])'
```

### 5. Configurar Grafana

Abrir http://localhost:3000 en el navegador:

- Usuario: `admin`
- Contraseña: `admin`

Grafana ya tiene el datasource de Prometheus preconfigurado (verificar en Configuration → Data Sources). Si no aparece, agregarlo manualmente:

1. Configuration → Data Sources → Add data source
2. Seleccionar Prometheus
3. URL: `http://prometheus:9090`
4. Save & Test

### 6. Importar dashboard de node_exporter

Opción A — Desde la interfaz web:

1. Crear → Dashboard → Add a new panel
2. Query: `100 - avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100`
3. Título: "CPU Usage %"
4. Agregar más paneles para memoria, disco, load, red

Opción B — API (para automatización):

```bash
# Obtener API key de Grafana
curl -s -X POST http://localhost:3000/api/auth/keys \
  -H "Content-Type: application/json" \
  -d '{"name":"automation","role":"Admin"}' \
  -u admin:admin

# Crear dashboard vía API (con la API key)
curl -s -X POST http://localhost:3000/api/dashboards/db \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <API_KEY>" \
  -d '{
    "dashboard": {
      "title": "Server Overview",
      "panels": [
        {"title": "CPU", "type": "graph", "targets": [{"expr": "100 - avg(rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100"}]},
        {"title": "Memory", "type": "graph", "targets": [{"expr": "(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100"}]},
        {"title": "Disk", "type": "graph", "targets": [{"expr": "(1 - node_filesystem_avail_bytes{mountpoint=\"/\"} / node_filesystem_size_bytes{mountpoint=\"/\"}) * 100"}]}
      ]
    },
    "overwrite": true
  }'
```

### 7. Simular carga y ver métricas en tiempo real

```bash
# Generar carga de CPU
docker exec node_exporter sh -c "cat /dev/urandom | gzip > /dev/null &"

# Ver el impacto en Prometheus
curl -s 'http://localhost:9090/api/v1/query?query=100%20-%20avg(rate(node_cpu_seconds_total{mode="idle"}[30s]))%20*%20100'

# Ver el dashboard de Grafana actualizar (F5 en el navegador)
```

---

## 🧯 Mitigación

### Prometheus no arranca

Verificar:

```bash
docker logs prometheus
docker compose -f docker-compose.monitoring.yml exec prometheus promtool check config /etc/prometheus/prometheus.yml
```

Acción:

- Revisar sintaxis de `prometheus.yml`
- Verificar que los puertos no estén ocupados
- Revisar permisos de volúmenes

Rollback:

```bash
docker compose -f docker-compose.monitoring.yml down -v
```

### Grafana no conecta con Prometheus

Verificar:

```bash
docker exec grafana curl -s http://prometheus:9090/api/v1/query?query=up
```

Acción:

- Verificar que prometheus sea reachable desde el contenedor grafana
- Revisar URL del datasource en Grafana: debe ser `http://prometheus:9090`
- Revisar `datasource.yml` si se usa provisioning

### node_exporter no reporta métricas

Verificar:

```bash
docker logs node_exporter
curl -s http://localhost:9100/metrics | head -5
```

Acción:

- Verificar que el contenedor esté en la red `monitoring`
- Revisar que `prometheus.yml` tenga el target correcto: `node_exporter:9100`
- Verificar permisos de montaje de `/proc`, `/sys`

---

## ✅ Interpretación

El monitoreo con Prometheus + node_exporter + Grafana te da visibilidad del estado del servidor en tiempo real. Pero el verdadero valor no está en los dashboards bonitos: está en poder responder preguntas concretas.

| Pregunta | Cómo responderla |
|----------|-----------------|
| ¿El servidor está sano? | `up` de todos los targets, CPU < 80%, memoria < 85% |
| ¿Está empeorando? | Tendencias en 1h vs 24h, rate de crecimiento |
| ¿Cuándo debo intervenir? | Cuando se acerca al SLO definido |
| ¿Qué cambió? | Correlacionar picos con deploys o cambios de config |

El stack es reproducible, open source, y escala de 1 server a un cluster completo. La misma lógica de scraping, alertas y dashboards aplica en cualquier escala.

---

## 🔗 Referencias

- [`concept`](../../concepts/sre-fundamentals.md) — SLI, SLO, error budget, modelos USE/RED
- [`concept`](../../concepts/baseline-and-anomalies.md) — establecimiento de baseline con métricas
- [`docker`](../../guides/docker.md) — contenedores para el stack de monitoreo
- [`curl`](../../guides/curl.md) — consultas HTTP a APIs de Prometheus y Grafana
- [`awk`](../../guides/awk.md) — procesamiento de métricas en terminal
- [`watch`](../../guides/watch.md) — monitoreo periódico de consultas
- [`scenario`](../system/01-top-processes-and-resources.md) — diagnóstico inicial de procesos y recursos
- [`scenario`](../system/05-system-memory-issues-oom.md) — troubleshooting de memoria
- [`scenario`](../system/07-high-io-wait.md) — troubleshooting de I/O de disco
