
# Race conditions — Cuando dos procesos chocan en el tiempo

## 🧠 ¿Qué es?

Una **race condition** ocurre cuando dos o más procesos acceden a un recurso compartido al mismo tiempo y el resultado depende del orden exacto en que se ejecutan. Como el orden no está garantizado, el resultado es impredecible.

Las race conditions son **bugs intermitentes**: el sistema funciona 999 veces de 1000, pero en esa milésima vez los procesos se cruzan en el momento exacto y los datos se corrompen, el archivo queda inconsistente o el script falla de forma misteriosa.

El **locking** (bloqueo) es el mecanismo para prevenirlas: garantiza que solo un proceso a la vez acceda al recurso compartido.

---

## 🎯 ¿Por qué importa?

Una race condition en un script de backup puede corromper el backup sin que nadie lo note hasta que necesiten restaurarlo. En ese momento, el backup es inservible.

- Dos procesos escribiendo al mismo archivo de log → líneas mezcladas, ilegibles
- Dos `cron` jobs compitiendo por el mismo lockfile → uno falla silenciosamente
- Dos instancias de un script creando el mismo directorio temporal → una borra lo que la otra acaba de crear
- `mv` y `cp` al mismo archivo destino desde dos procesos → archivo truncado

Las race conditions son especialmente peligrosas porque **pasan las pruebas manuales**. Solo aparecen bajo carga o concurrencia real.

---

## 🔑 Patrones comunes en sysadmin

### Archivos temporales

```text
Peligroso:
  echo "data" > /tmp/reporte.txt     # Dos procesos pisan el mismo archivo
  cat /tmp/*.tmp > final.txt          # Incluye archivos temporales de otros procesos

Seguro:
  tmp=$(mktemp /tmp/reporte.XXXXXX)
  echo "data" > "$tmp"
  mv "$tmp" final.txt                 # mv es atómico en el mismo filesystem
```

### Lockfiles

```text
if [ -f /var/lock/mi_script.lock ]; then
  echo "Ya se está ejecutando"
  exit 1
fi
touch /var/lock/mi_script.lock
# ... trabajo crítico ...
rm /var/lock/mi_script.lock
```

Esto tiene una race condition: entre el `if` y el `touch`, otro proceso puede crear el lockfile. La solución es usar `mkdir` (que falla si ya existe) o `flock`:

```text
exec 200>/var/lock/mi_script.lock
flock -n 200 || { echo "Ya se está ejecutando"; exit 1; }
# ... trabajo crítico ...
flock -u 200
```

### Escritura concurrente a archivos

`echo "linea" >> archivo` desde múltiples procesos puede entremezclar líneas si la escritura no es atómica. La solución es usar un mecanismo de locking:

```text
(
  flock -x 200
  echo "linea" >> archivo
) 200>/var/lock/archivo.lock
```

---

## 🛡️ Técnicas de locking

### PID files

```text
echo $$ > /var/run/mi_servicio.pid
```

Simple pero no atómico. Dos procesos pueden escribir el PID file casi al mismo tiempo.

### `mkdir` como lock

```text
mkdir /var/lock/mi_lock 2>/dev/null || exit 1
```

`mkdir` falla si el directorio ya existe → es atómico. Usado en scripts de init clásicos.

### `flock` (file lock)

```text
flock -x /var/lock/mi_lock -c "comando_critico"
```

Bloqueo exclusivo a nivel de kernel, garantizado atómico. Funciona en NFS.

### Bases de datos: transacciones

```text
BEGIN;
UPDATE contador SET valor = valor + 1 WHERE id = 1;
COMMIT;
```

La base de datos maneja el locking internamente. Si dos transacciones compiten, una espera a la otra.

---

## ⚠️ Dónde son más comunes

- Scripts ejecutados por `cron` (si tardan más que el intervalo)
- Scripts de deploy concurrentes
- Escritura a archivos compartidos en NFS
- Operaciones sobre `/tmp` compartido
- Procesamiento paralelo con `xargs -P` o `parallel`
- Contenedores que comparten volúmenes

---

## 🧠 Modelo mental

Pensá en las race conditions como **dos personas queriendo pasar por la misma puerta al mismo tiempo**. Si no hay un acuerdo (lock), chocan, se empujan, y alguno pasa incompleto o ninguno pasa.

El locking es poner un **cartel de "ocupado"** en la puerta. Quien lo ve, espera. Quien lo pone, lo saca al salir. El problema es asegurarse de que poner y ver el cartel sea una operación atómica — si dos personas llegan a la puerta exactamente al mismo tiempo y ambas leen "libre" antes de que la otra ponga el cartel, el mecanismo falla.

Por eso `flock` y `mkdir` existen: son operaciones atómicas que el kernel garantiza.

---

## 🔗 Ver también

- [`concept`](idempotency.md) — operaciones que no empeoran con reintentos
- [`concept`](blast-radius.md) — limitar el daño de una race condition
- [`cron`](../guides/cron.md) — tareas programadas, riesgo de solapamiento
- [`xargs`](../guides/xargs.md) — procesamiento paralelo con -P
- [`scenario`](../scenarios/system/11-cron-failure.md) — fallos por cron jobs solapados
