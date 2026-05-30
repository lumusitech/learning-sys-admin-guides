# Redirección de Flujos y Descriptores de Archivo — Guía completa

**Nivel:** 🟢 Básico
**Archivos de práctica:** `labs/auth.log`, `labs/nginx_access.log`
**Ver escenarios relacionados:** [`system/11-cron-failure`](../scenarios/system/11-cron-failure.md), [`networking/01-detect-ssh-brute-force`](../scenarios/networking/01-detect-ssh-brute-force.md)

---

## ⚡ Quick command

`comando > archivo.log 2>&1`

> ⚠️ **Nota de compatibilidad:** El operador abreviado `&>` es nativo de Bash y Zsh. Si trabajás en entornos minimalistas como Alpine Linux con BusyBox (`/bin/sh`), debés usar obligatoriamente la sintaxis clásica estándar POSIX: `> archivo 2>&1`.

---

## ⚡ Quick run

```bash
# Ejecutar un comando que genera salida y error, separando los flujos
ls -la /root /tmp > /tmp/stdout.log 2> /tmp/stderr.log
cat /tmp/stdout.log
cat /tmp/stderr.log
```

---

## 📑 Índice

1. [¿Qué es la redirección?](#qué-es-la-redirección)
2. [Modelo mental](#modelo-mental)
3. [Descriptores de archivo](#descriptores-de-archivo)
4. [Sintaxis básica](#sintaxis-básica)
5. [Redirección de stdout](#redirección-de-stdout)
6. [Redirección de stderr](#redirección-de-stderr)
7. [Combinación de flujos (2>&1)](#combinación-de-flujos-21)
8. [Redirección de stdin](#redirección-de-stdin)
9. [Redirección a /dev/null](#redirección-a-devnull)
10. [Pipes vs redirecciones](#pipes-vs-redirecciones)
11. [Patrones de uso](#patrones-de-uso)
12. [Uso en troubleshooting](#uso-en-troubleshooting)
13. [Combinación con otras herramientas](#combinación-con-otras-herramientas)
14. [Uno-liners imprescindibles](#uno-liners-imprescindibles)
15. [Errores comunes](#errores-comunes)
16. [Buenas prácticas](#buenas-prácticas)

---

## 🧠 ¿Qué es la redirección?

**Redirección** es el mecanismo del shell para cambiar la fuente de entrada o el destino de salida de un comando. En lugar de leer del teclado y escribir en la pantalla, un comando puede leer de un archivo y escribir a otro.

Se usa para:

- guardar la salida de comandos en archivos de log;
- separar la salida normal (`stdout`) de los errores (`stderr`);
- ocultar salida innecesaria en scripts automatizados;
- capturar ambos flujos en una sola operación;
- encadenar comandos mediante pipes.

No se usa para:

- procesar texto entre comandos (eso es trabajo de **pipes** `|`);
- buscar patrones en la salida (eso es `grep`, `awk`, `sed`).

---

## 🧠 Modelo mental

Los flujos de E/S son **tuberías** conectadas a cada proceso:

- **stdin (0):** tubo de entrada — de dónde lee el comando (teclado, archivo, otro comando).
- **stdout (1):** tubo de salida normal — dónde escribe el resultado exitoso.
- **stderr (2):** tubo de errores — dónde escribe los mensajes de error.

Los operadores de redirección son **llaves de paso** que conectan estas tuberías a archivos o dispositivos:

- `>` → abrir la llave de stdout hacia un archivo (sobrescribir).
- `>>` → abrir la llave de stdout hacia un archivo (agregar).
- `2>` → abrir la llave de stderr hacia un archivo.
- `2>&1` → conectar la tubería de stderr a donde ya va stdout.
- `<` → cambiar la fuente de stdin a un archivo.

El orden de los operadores importa. El shell procesa de izquierda a derecha.

---

## 📝 Descriptores de archivo

Cada proceso tiene una tabla de **descriptores de archivo** (file descriptors). Los tres primeros están reservados:

| Descriptor | Nombre | Descripción | Ejemplo |
|------------|--------|-------------|---------|
| `0` | stdin | Entrada estándar | Teclado, archivo, pipe |
| `1` | stdout | Salida estándar | Pantalla, archivo, pipe |
| `2` | stderr | Salida de error | Pantalla, archivo, pipe |
| `3+` | — | Descriptores adicionales | Archivos abiertos por el proceso |

```bash
# Ver los descriptores abiertos de un proceso
ls -la /proc/$$/fd
```

---

## 📝 Sintaxis básica

```bash
# Redirección de stdout a archivo (sobrescribe)
comando > archivo

# Redirección de stdout a archivo (agrega)
comando >> archivo

# Redirección de stderr a archivo
comando 2> archivo

# Redirección de stderr a archivo (agrega)
comando 2>> archivo

# Redirección de stdout y stderr a archivo (Bash/Zsh)
comando &> archivo

# Redirección de stdout y stderr a archivo (POSIX)
comando > archivo 2>&1

# Redirección de stdin desde archivo
comando < archivo
```

---

## 🎛️ Redirección de stdout

### `>` — Sobrescribir

Crea el archivo si no existe. Si existe, **borra el contenido** y escribe el nuevo.

```bash
# Guardar la lista de archivos
ls -la /tmp > /tmp/lista.txt

# Sobrescribe el contenido anterior
echo "nueva línea" > /tmp/lista.txt
```

### `>>` — Agregar

Crea el archivo si no existe. Si existe, **agrega al final** sin borrar.

```bash
# Agregar una línea al log
echo "$(date) - inicio de tarea" >> /var/log/tareas.log

# Agregar más líneas
echo "$(date) - fin de tarea" >> /var/log/tareas.log
```

### Ejemplo práctico con labs

```bash
# Buscar intentos fallidos de SSH y guardarlos
grep "Failed password" labs/auth.log > /tmp/fallos_ssh.txt

# Agregar más resultados al mismo archivo
grep "Invalid user" labs/auth.log >> /tmp/fallos_ssh.txt
```

---

## 🎛️ Redirección de stderr

### `2>` — Sobrescribir errores

```bash
# Guardar solo los errores
ls -la /root 2> /tmp/errores.log

# Intentar acceder a directorio restringido
cat /etc/shadow 2> /tmp/errores_permiso.log
```

### `2>>` — Agregar errores

```bash
# Acumular errores en un log
comando1 2>> /tmp/errores.log
comando2 2>> /tmp/errores.log
comando3 2>> /tmp/errores.log
```

### Separar stdout y stderr

```bash
# Guardar salida normal y errores en archivos distintos
ls -la /root /tmp > /tmp/salida.txt 2> /tmp/errores.txt
cat /tmp/salida.txt
cat /tmp/errores.txt
```

---

## 🔑 Combinación de flujos (2>&1)

### ¿Qué hace `2>&1`?

Redirige el descriptor `2` (stderr) al descriptor `1` (stdout). Esto significa: "los errores van a donde ya va la salida normal".

### Orden correcto

```bash
# ✅ Correcto: stdout va al archivo, luego stderr va a donde va stdout (al archivo)
comando > archivo.log 2>&1

# ❌ Incorrecto: stderr va a donde va stdout (pantalla), luego stdout va al archivo
comando 2>&1 > archivo.log
```

Explicación del orden:

1. `> archivo.log` → stdout ahora apunta al archivo.
2. `2>&1` → stderr ahora apunta a donde va stdout (el archivo).

En el caso incorrecto:

1. `2>&1` → stderr apunta a donde va stdout (pantalla, aún no se redirigió).
2. `> archivo.log` → stdout apunta al archivo, pero stderr sigue apuntando a la pantalla.

### Sintaxis abreviada (Bash/Zsh)

```bash
# Equivalente a "> archivo 2>&1"
comando &> archivo.log

# Equivalente a ">> archivo 2>&1"
comando &>> archivo.log
```

> ⚠️ `&>` y `&>>` no son POSIX. En BusyBox/Alpine (`/bin/sh`) no funcionan. Usar siempre `> archivo 2>&1` para portabilidad.

---

## 🎛️ Redirección de stdin

### `<` — Leer de archivo

```bash
# Leer un archivo como entrada de un comando
wc -l < labs/auth.log

# Pasar contenido de archivo a otro comando
sort < labs/auth.log | head -20
```

### `<<` — Here document (heredoc)

```bash
# Pasar texto multilinea como stdin
cat <<EOF
Línea 1
Línea 2
Línea 3
EOF

# Escribir texto a un archivo
cat <<EOF > /tmp/config.txt
servidor=192.168.1.1
puerto=8080
EOF
```

### `<<<` — Here string (Bash/Zsh)

```bash
# Pasar una cadena como stdin
grep "error" <<< "esto tiene un error aquí"
```

---

## 🎛️ Redirección a /dev/null

`/dev/null` es un dispositivo especial que **descarta todo** lo que recibe. Se usa para ocultar salida innecesaria.

```bash
# Ocultar stdout
comando > /dev/null

# Ocultar stderr
comando 2> /dev/null

# Ocultar stdout y stderr
comando > /dev/null 2>&1

# Ocultar todo (Bash/Zsh)
comando &> /dev/null
```

### Ejemplos prácticos

```bash
# Verificar si un comando existe sin mostrar salida
command -v curl > /dev/null 2>&1 && echo "curl instalado" || echo "curl no encontrado"

# Ejecutar un cron job silenciosamente
0 2 * * * /opt/scripts/backup.sh > /dev/null 2>&1

# Ping silencioso para verificar conectividad
ping -c 1 8.8.8.8 > /dev/null 2>&1 && echo "online" || echo "offline"
```

---

## 📋 Pipes vs redirecciones

| Concepto | Pipe `|` | Redirección `>` `<` |
|----------|----------|---------------------|
| **Conecta** | stdout de un comando → stdin de otro | flujo de un comando → archivo |
| **Uso** | Encadenar comandos | Guardar o leer de archivos |
| **Resultado** | Procesamiento en cadena | Persistencia en disco |

```bash
# Pipe: grep filtra la salida de cat (sin archivo intermedio)
cat labs/auth.log | grep "Failed password"

# Redirección: grep guarda su salida en un archivo
grep "Failed password" labs/auth.log > /tmp/fallos.txt

# Combinados: pipe + redirección
cat labs/auth.log | grep "Failed password" > /tmp/fallos.txt

# Redirección + pipe: leer de archivo y pipear
grep "Failed password" < labs/auth.log | wc -l
```

---

## 📋 Patrones de uso

### Guardar logs de comandos

```bash
# Guardar salida de un comando con timestamp
echo "=== $(date) ===" >> /var/log/comando.log
mi_comando >> /var/log/comando.log 2>&1
```

### Separar flujos para análisis

```bash
# Ejecutar script y separar salida de errores
./script.sh > /tmp/salida.log 2> /tmp/errores.log

# Revisar si hubo errores
if [ -s /tmp/errores.log ]; then
    echo "Hubo errores:"
    cat /tmp/errores.log
fi
```

### Capturar salida de scripts cron

```bash
# En crontab, capturar toda la salida
0 3 * * * /opt/scripts/backup.sh >> /var/log/backup.log 2>&1
```

### Limpiar output en scripts automatizados

```bash
#!/bin/bash
# Solo mostrar errores importantes, ocultar el resto
apt-get update > /dev/null 2>&1
apt-get install -y nginx > /dev/null 2>&1
echo "Instalación completada"
```

---

## 🔍 Uso en troubleshooting

### Ejemplo 1: Diagnosticar fallos en cron

Conectar con scenario [`system/11-cron-failure`](../scenarios/system/11-cron-failure.md).

```bash
# Sin redirección, la salida de cron se pierde
0 2 * * * /opt/scripts/backup.py

# Con redirección, capturamos todo
0 2 * * * /opt/scripts/backup.py >> /var/log/backup.log 2>&1

# Revisar el log para diagnosticar
tail -50 /var/log/backup.log
```

### Ejemplo 2: Analizar logs de Docker

Conectar con scenario [`networking/01-detect-ssh-brute-force`](../scenarios/networking/01-detect-ssh-brute-force.md).

```bash
# docker logs envía stdout y stderr separados
# Con 2>&1 combinamos ambos flujos para filtrar
docker logs ssh-weak 2>&1 | grep "Failed password"

# Contar intentos fallidos
docker logs ssh-weak 2>&1 | grep -c "Failed password"
```

### Ejemplo 3: Capturar errores de comandos complejos

```bash
# Ejecutar pipeline y capturar todo
{
    echo "=== Inicio: $(date) ==="
    grep "error" labs/auth.log
    echo "=== Fin: $(date) ==="
} > /tmp/diagnostico.log 2>&1
```

---

## 🛠️ Combinación con otras herramientas

### Con `grep`

```bash
# Filtrar errores de un comando
comando 2>&1 | grep -i "error"

# Buscar en logs guardados
grep "Failed password" < labs/auth.log
```

### Con `tee`

```bash
# Guardar y ver en pantalla simultáneamente
comando 2>&1 | tee /tmp/salida.log

# Agregar a archivo y ver
comando 2>&1 | tee -a /tmp/salida.log
```

### Con `awk`

```bash
# Procesar campos de la salida
comando 2>&1 | awk '{print $1, $3}'
```

### Con `sort` y `uniq`

```bash
# Contar errores únicos
comando 2>&1 | sort | uniq -c | sort -rn
```

### Con `tail` en tiempo real

```bash
# Seguir un log en tiempo real
tail -f /var/log/app.log 2>&1 | grep --line-buffered "error"
```

---

## 💡 Uno-liners imprescindibles

```bash
# 1. Guardar toda la salida (stdout + stderr) en un archivo
comando > archivo.log 2>&1

# 2. Agregar toda la salida a un archivo existente
comando >> archivo.log 2>&1

# 3. Buscar errores en la salida de un comando
comando 2>&1 | grep -i "error"

# 4. Ejecutar silenciosamente (descartar todo)
comando > /dev/null 2>&1

# 5. Separar stdout y stderr en archivos distintos
comando > salida.log 2> errores.log

# 6. Guardar y ver en pantalla
comando 2>&1 | tee archivo.log

# 7. Contar líneas de un archivo sin mostrar el nombre
wc -l < archivo.txt

# 8. Leer de archivo y pipear
grep "patrón" < archivo.log | sort

# 9. Verificar si un comando existe silenciosamente
command -v cmd > /dev/null 2>&1 && echo "existe" || echo "no existe"

# 10. Ping silencioso para verificar conectividad
ping -c 1 host > /dev/null 2>&1 && echo "online" || echo "offline"

# 11. Guardar stderr y stdout en el mismo archivo (POSIX)
comando > /tmp/todo.log 2>&1

# 12. Redirigir a un archivo con permisos restringidos
comando > /tmp/seguro.log 2>&1 && chmod 600 /tmp/seguro.log
```

---

## ⚠️ Errores comunes

### Olvidar `2>&1` para capturar errores

```bash
# ❌ Solo captura stdout, los errores van a la pantalla
comando > archivo.log

# ✅ Captura stdout y stderr
comando > archivo.log 2>&1
```

### Orden incorrecto de operadores

```bash
# ❌ stderr va a pantalla, stdout va al archivo
comando 2>&1 > archivo.log

# ✅ Ambos van al archivo
comando > archivo.log 2>&1
```

### Usar `&>` en shells que no lo soportan

```bash
# ❌ Falla en BusyBox/Alpine
comando &> archivo.log

# ✅ Funciona en todos los shells
comando > archivo.log 2>&1
```

### Sobrescribir archivos importantes con `>`

```bash
# ❌ Borra el contenido anterior
echo "nueva línea" > /var/log/app.log

# ✅ Agrega al final
echo "nueva línea" >> /var/log/app.log
```

### No cerrar descriptores abiertos

```bash
# ❌ Descriptor queda abierto
exec 3> /tmp/miarchivo.txt
echo "texto" >&3

# ✅ Cerrar cuando se termina
exec 3> /tmp/miarchivo.txt
echo "texto" >&3
exec 3>&-
```

### Confundir pipe con redirección

```bash
# ❌ Intentar guardar stdin de un archivo con pipe
cat archivo.txt | grep "error" > resultado.txt  # funciona pero es innecesario

# ✅ Usar redirección de stdin
grep "error" < archivo.txt > resultado.txt
```

---

## ✅ Buenas prácticas

- Usar `>>` para logs, nunca `>` (evita borrar datos por error).
- Siempre capturar stderr en scripts y cron jobs.
- Preferir `> archivo 2>&1` sobre `&>` para portabilidad POSIX.
- Usar `/dev/null` para descartar salida innecesaria en scripts.
- En scripts, redirigir al inicio del bloque para no olvidar.
- Cerrar descriptores abiertos con `exec N>&-`.
- Usar `tee` cuando necesités ver y guardar simultáneamente.
- Documentar en los scripts qué flujos se redirigen y por qué.
- En crontab, siempre redirigir a un log para poder diagnosticar fallos.
- Verificar que el directorio destino existe antes de redirigir a un archivo.

---

## 🔗 Referencias internas

- [`system/11-cron-failure`](../scenarios/system/11-cron-failure.md) — fallos en cron por falta de redirección
- [`networking/01-detect-ssh-brute-force`](../scenarios/networking/01-detect-ssh-brute-force.md) — uso de `docker logs 2>&1`
- [`grep`](./grep.md) — filtrado de patrones en texto
- [`awk`](./awk.md) — procesamiento de campos y texto
- [`xargs`](./xargs.md) — ejecución de comandos con argumentos desde stdin
