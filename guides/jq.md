# jq — Guía completa de procesamiento JSON en shell

**Nivel:** 🟡 Intermedio
**Archivos de práctica:** `labs/docker-compose.monitoring.yml`, `labs/docker-compose.yml`
**Ver escenarios relacionados:** [`infrastructure/08-prometheus-grafana`](../scenarios/infrastructure/08-prometheus-grafana.md), [`web/01-performance`](../scenarios/web/01-performance-and-error-analysis.md)

---

## ⚡ Quick command

`jq '.'`

> ⚠️ No incluido en Alpine/BusyBox base. Instalar con `apk add jq`.

---

## ⚡ Quick run

```bash
echo '{"servers":[{"name":"web1","cpu":45},{"name":"web2","cpu":78}]}' | jq '.servers[] | select(.cpu > 50) | .name'
```

---

## 📑 Índice

1. [¿Qué es jq?](#qué-es-jq)
2. [Modelo mental](#modelo-mental)
3. [Sintaxis básica](#sintaxis-básica)
4. [Salida clave](#salida-clave)
5. [Opciones principales](#opciones-principales)
6. [Patrones de uso](#patrones-de-uso)
7. [Uso en troubleshooting](#uso-en-troubleshooting)
8. [Combinación con otras herramientas](#combinación-con-otras-herramientas)
9. [Uno-liners imprescindibles](#uno-liners-imprescindibles)
10. [Errores comunes](#errores-comunes)
11. [Buenas prácticas](#buenas-prácticas)
12. [Referencias internas](#referencias-internas)

---

## 🧠 ¿Qué es jq?

jq es un procesador JSON de línea de comandos. Es como `sed` para JSON: filtra, transforma, extrae y formatea datos estructurados sin necesidad de un lenguaje de programación.

En 2026, casi toda API, herramienta CLI (kubectl, aws, docker) y archivo de configuración usa JSON. Sin jq, estás haciendo `grep` sobre JSON — que es frágil, ilegible y propenso a errores.

---

## 🧠 Modelo mental

Pensá en jq como **`awk` para JSON**:

- `jq '.'` = `cat` (mostrar todo)
- `jq '.clave'` = `awk '{print $2}'` (extraer campo)
- `jq 'select(.cpu > 50)'` = `awk '$3 > 50'` (filtrar por condición)
- `jq '[.[] | .name]'` = `awk '{print $1}'` sobre cada objeto (transformar)

La diferencia es que jq entiende la estructura del JSON: objetos anidados, arrays, tipos (string, number, boolean, null).

---

## 📝 Sintaxis básica

### Navegación

| Filtro | Significado |
|--------|-------------|
| `.` | El objeto raíz |
| `.clave` | Campo `clave` del objeto |
| `.clave.subclave` | Campo anidado |
| `.[0]` | Primer elemento del array |
| `.[]` | Todos los elementos del array (iterar) |
| `[]` | Aplanar array |

### Filtros y transformaciones

| Filtro | Significado |
|--------|-------------|
| `select(condición)` | Filtrar elementos |
| `map(expresión)` | Transformar cada elemento |
| `{clave: .origen}` | Crear nuevo objeto |
| `[expresión]` | Construir array |
| `length` | Longitud de string o array |

---

## 🔑 Salida clave

### `jq '.'` (pretty-print)

```json
{
  "name": "web-server",
  "cpu": 45.2,
  "memory": {"used": 2048, "total": 8192},
  "disks": ["sda", "sdb"]
}
```

### `jq '.memory.used'`

```text
2048
```

### `jq '.servers[] | {name, cpu}'`

```json
{"name": "web1", "cpu": 45}
{"name": "web2", "cpu": 78}
```

---

## 🎛️ Opciones principales

| Flag | Descripción |
|------|-------------|
| `-r` | Raw output (sin comillas) |
| `-c` | Compact output (una línea por objeto) |
| `-s` | Slurp: leer todo como un array (varios JSON concatenados) |
| `-n` | Null input (no leer stdin) |
| `--arg name value` | Pasar variable de shell a jq |
| `--slurpfile name file` | Leer archivo y exponer como variable |
| `-f file.jq` | Ejecutar filtro desde archivo |
| `-M` | Salida monocromática (sin colores) |

---

## 📋 Patrones de uso

### Extraer campo de API

```bash
curl -s http://localhost:9090/api/v1/query?query=up | jq '.data.result[] | .metric.job'
```

### Filtrar por condición

```bash
kubectl get pods -o json | jq '.items[] | select(.status.phase != "Running") | .metadata.name'
```

### Contar

```bash
jq '[.items[] | select(.status.phase == "Running")] | length'
```

### Agrupar y ordenar

```bash
jq 'group_by(.status) | map({status: .[0].status, count: length}) | sort_by(-.count)'
```

### Transformar a texto plano

```bash
jq -r '.items[] | "\(.metadata.name) \(.status.phase)"'
```

### Top N por campo

```bash
jq '.items | sort_by(-.cpu) | .[0:5] | .[] | {name, cpu}'
```

---

## 🔍 Uso en troubleshooting

### API de Prometheus

```bash
# ¿Todos los targets up?
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, health: .health}'

# ¿Algún target caído?
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.health != "up")'
```

### kubectl

```bash
# Pods en CrashLoopBackOff
kubectl get pods -o json | jq '.items[] | select(.status.containerStatuses[]?.state.waiting.reason == "CrashLoopBackOff") | .metadata.name'

# Eventos warning recientes en el cluster
kubectl get events -o json | jq '.items[] | select(.type == "Warning") | {reason: .reason, message: .message, timestamp: .lastTimestamp}'
```

### Docker

```bash
# Contenedores sin health check
docker inspect $(docker ps -q) | jq '.[] | select(.State.Health == null) | .Name'

# Imágenes sin tag
docker images --format json | jq 'select(.Tag == "<none>") | .Repository'
```

### Logs en JSON

```bash
# Extraer errores de logs JSON
cat /var/log/app.json | jq 'select(.level == "error") | {timestamp: .ts, error: .msg}'

# Top 10 IPs en access log JSON
cat access.json | jq -r '.client_ip' | sort | uniq -c | sort -rn | head -10
```

---

## 🛠️ Combinación con otras herramientas

### jq + curl

```bash
curl -s https://api.example.com/status | jq '.healthy'
```

### jq + kubectl

```bash
kubectl get pods -o json | jq '.items | length'
```

### jq + awk

```bash
jq -r '.items[].name' | awk '{print NR, $0}'
```

### jq + watch

```bash
watch -n 5 "curl -s http://localhost:9090/api/v1/query?query=up | jq '.data.result[] | .value[1]'"
```

---

## 💡 Uno-liners imprescindibles

```bash
# Pretty-print JSON (siempre lo primero)
jq '.' archivo.json

# Extraer un campo específico
jq -r '.status' response.json

# Filtrar objetos por campo
jq '.[] | select(.active == true)'

# Contar elementos en un array
jq '.items | length'

# Extraer y formatear múltiples campos
jq -r '.items[] | "\(.name)\t\(.cpu)%\t\(.memory)MB"'

# Buscar en todos los niveles (recursivo)
jq '.. | .name? | select(. != null)'

# Top 5 por campo numérico
jq '.items | sort_by(-.value) | .[0:5]'

# Validar que un JSON es sintácticamente correcto
jq empty archivo.json && echo "OK" || echo "INVALID"

# Merge de dos archivos JSON
jq -s '.[0] * .[1]' a.json b.json
```

---

## ⚠️ Errores comunes

| Error | Causa | Solución |
|-------|-------|----------|
| `jq: error: Cannot index string with string "clave"` | Intentar acceder a campo de un string | Verificar tipo con `type` |
| `jq: error: Cannot iterate over null` | Array vacío o campo inexistente | Usar `// empty` o `select(. != null)` |
| Comillas en output no deseado | Modo default (JSON) | Usar `-r` (raw output) |
| `parse error: Invalid numeric literal` | JSON malformado | Validar con `python -m json.tool` o `jq empty` |
| `null` en vez de valor | Campo no existe | Usar `// "default"` para valor por defecto |
| Output con escapes | JSON dentro de JSON | `fromjson` para anidado |
| `jq: command not found` | No instalado | `apt install jq` o `apk add jq` |

---

## ✅ Buenas prácticas

1. **Siempre empezar con `jq '.'`** para ver la estructura antes de filtrar
2. **Usar `-r` para output a pipelines** (sin comillas extras)
3. **Usar `select(. != null)` o `// empty`** para evitar errores en campos opcionales
4. **Validar JSON antes de procesar** con `jq empty`
5. **Preferir `.[]` sobre `.[0]`** a menos que solo necesites el primer elemento
6. **Usar `join(", ")` para strings, no concatenar manualmente**
7. **Filtros complejos en archivo** con `jq -f filtro.jq` para mantener legibilidad
8. **Variables de shell con `--arg`**, nunca incrustar con string interpolation
9. **`type` para debuggear** cuando el output no es lo esperado
10. **`keys` para listar campos** de un objeto desconocido

---

## 🔗 Referencias internas

- [`curl`](curl.md) — consultas HTTP que generan JSON
- [`kubectl`](kubectl.md) — `-o json` para diagnostico de clusters
- [`awk`](awk.md) — procesamiento de texto en pipelines post-jq
- [`grep`](grep.md) — filtrado complementario
- [`watch`](watch.md) — consultas periódicas con jq
- [`scenario`](../scenarios/infrastructure/08-prometheus-grafana.md) — jq con Prometheus API
- [`scenario`](../scenarios/web/01-performance-and-error-analysis.md) — jq con logs JSON
