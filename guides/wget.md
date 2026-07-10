# wget — Guía completa de descarga y mirroring

**Nivel:** 🟢 Básico
**Archivos de práctica:** `labs/docker-compose.yml`
**Ver escenarios relacionados:** [`web/01-performance`](../scenarios/web/01-performance-and-error-analysis.md)

---

## ⚡ Quick command

`wget https://ejemplo.com/archivo.tar.gz`

> ⚠️ No incluido en Alpine/BusyBox base. Instalar con `apk add wget`. En algunas distros minimal, usar `wget --no-check-certificate` para URLs HTTPS sin CA válida.

---

## ⚡ Quick run

```bash
wget -qO- http://localhost:80 | head -10
```

---

## 📑 Índice

1. [¿Qué es wget?](#qué-es-wget)
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

## 🧠 ¿Qué es wget?

wget es un descargador de archivos por HTTP, HTTPS y FTP. A diferencia de `curl`, está diseñado para descargas robustas: reintentos automáticos, mirroring recursivo, descarga en background, y reanudación de descargas interrumpidas.

Para un sysadmin, wget es la herramienta para:

- Bajar paquetes, scripts, ISOs
- Hacer mirror de sitios para backup
- Verificar que un servicio web responde (health check)
- Descargar en entornos donde `curl` no está instalado (aunque `wget` también debe instalarse en minimal)

---

## 🧠 Modelo mental

Pensá en wget como **un camión de carga** para internet. Es robusto, no se rinde si la conexión es mala (reintenta), puede seguir rutas recursivas (mirror) y trabaja en background sin supervisión.

`curl` es un auto deportivo: rápido, flexible, ideal para APIs y debugging. `wget` es un camión: lento pero confiable para descargas grandes y recursivas.

---

## 📝 Sintaxis básica

```text
wget [opciones] URL
```

| Uso | Comando |
|-----|---------|
| Descargar archivo | `wget URL` |
| Mostrar en stdout | `wget -qO- URL` |
| Continuar descarga | `wget -c URL` |
| Background | `wget -b URL` |
| Mirror recursivo | `wget -m URL` |

---

## 🔑 Salida clave

```text
--2026-07-10 18:30:00--  https://ejemplo.com/archivo.tar.gz
Resolving ejemplo.com (ejemplo.com)... 93.184.216.34
Connecting to ejemplo.com (ejemplo.com)|93.184.216.34|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 1048576 (1.0M) [application/gzip]
Saving to: 'archivo.tar.gz'

archivo.tar.gz       100%[===================>]   1.00M  2.50MB/s    in 0.4s
```

| Elemento | Significado |
|----------|-------------|
| `Resolving` | Resolución DNS exitosa |
| `connected` | Conexión TCP establecida |
| `200 OK` | Respuesta HTTP exitosa |
| `Length` | Tamaño del archivo (Content-Length) |
| `Saving to` | Archivo de destino |

---

## 🎛️ Opciones principales

### Descarga básica

| Flag | Significado |
|------|-------------|
| `-O archivo` | Output a archivo específico |
| `-O-` | Output a stdout (como `curl`) |
| `-q` | Quiet (sin output en pantalla) |
| `-c` | Continue (reanudar descarga parcial) |
| `-b` | Background (descarga desatendida, log en wget-log) |
| `-t N` | N intentos máximos (0 = infinito) |

### Mirroring y recursividad

| Flag | Significado |
|------|-------------|
| `-m` | Mirror (equivalente a `-r -N -l inf --no-remove-listing`) |
| `-r` | Recursivo |
| `-l N` | Niveles de profundidad máximos |
| `-np` | No parent (no subir de directorio) |
| `-k` | Convertir links a locales |
| `-p` | Page requisites (bajar CSS, JS, imágenes) |

### Red y seguridad

| Flag | Significado |
|------|-------------|
| `--no-check-certificate` | Ignorar errores de certificado TLS |
| `--timeout=N` | Timeout en segundos |
| `--tries=N` | Intentos máximos |
| `--limit-rate=N` | Limitar velocidad (ej: 100k, 1m) |
| `--header="Clave: Valor"` | Agregar header HTTP |
| `--user=USER --password=PASS` | Autenticación HTTP Basic |

---

## 📋 Patrones de uso

### Descargar y mostrar en console (sin guardar)

```bash
wget -qO- http://localhost/
```

### Descargar archivo con reintentos

```bash
wget -t 5 https://ejemplo.com/archivo_grande.iso
```

### Continuar descarga interrumpida

```bash
wget -c https://ejemplo.com/archivo_grande.iso
```

### Descargar sitio completo en mirror

```bash
wget -m -k -p -np https://docs.ejemplo.com/
```

### Descargar solo un tipo de archivo

```bash
wget -r -l 1 -A "*.pdf" https://ejemplo.com/docs/
```

### Health check silencioso

```bash
wget -q --spider http://localhost:8080/health && echo "OK" || echo "FAIL"
```

---

## 🔍 Uso en troubleshooting

### "¿El servidor web responde?"

```bash
wget -q --spider http://localhost:80 && echo "UP" || echo "DOWN"
```

### "¿La descarga anterior quedó incompleta?"

```bash
wget -c https://ejemplo.com/archivo.iso
```

Si el archivo parcial existe, wget lo continúa desde donde quedó.

### "¿El problema es DNS o HTTP?"

```bash
wget -O /dev/null http://dominio.com 2>&1 | head -5
```

Output incluye: nombre → IP (DNS OK), connected (TCP OK), HTTP response (servicio OK).

### "Ver respuesta HTTP sin descargar el contenido"

```bash
wget --spider -S http://dominio.com 2>&1 | grep "HTTP/"
```

---

## 🛠️ Combinación con otras herramientas

### wget + grep

```bash
wget -qO- http://localhost/status | grep -o "OK\|ERROR"
```

### wget + sh

```bash
# Descargar y ejecutar script (con cuidado)
wget -qO- https://ejemplo.com/script.sh | sh
```

### wget + tar

```bash
wget -qO- https://ejemplo.com/app.tar.gz | tar xz -C /opt/
```

### wget + cron

```bash
0 3 * * * wget -q -O /backups/daily.tar.gz https://api.ejemplo.com/export/daily
```

---

## 💡 Uno-liners imprescindibles

```bash
# Descargar archivo
wget https://ejemplo.com/archivo.tar.gz

# Descargar como si fuera curl (a stdout)
wget -qO- http://localhost:80

# Health check
wget -q --spider http://localhost:8080 && echo "OK" || echo "FAIL"

# Continuar descarga
wget -c https://ejemplo.com/iso_grande.iso

# Mirror de un sitio (solo ese directorio)
wget -m -np -k https://docs.ejemplo.com/manual/

# Limitar velocidad de descarga
wget --limit-rate=500k https://ejemplo.com/video.mp4

# Ver solo headers de respuesta
wget -S --spider https://ejemplo.com 2>&1 | grep -E "HTTP|Content"

# Descargar solo PDFs de un sitio
wget -r -l 2 -A "*.pdf" -np https://ejemplo.com/docs/

# Descarga desatendida en background
wget -b -o download.log https://ejemplo.com/grande.iso

# Bajar y descomprimir en un paso
wget -qO- https://ejemplo.com/app.tar.gz | tar xz
```

---

## ⚠️ Errores comunes

| Error | Causa | Solución |
|-------|-------|----------|
| `Unable to resolve host address` | DNS no resuelve | `dig`, `nslookup`, `/etc/hosts` |
| `Connection refused` | Servicio no corriendo | `systemctl status`, `ss -tlnp` |
| `404 Not Found` | URL incorrecta o recurso eliminado | Verificar path en el servidor |
| `403 Forbidden` | Sin permisos o requiere auth | `--user` / `--password` |
| `Certificate verification error` | Cert TLS inválido | Solo en dev: `--no-check-certificate` |
| `File name too long` | URL con parámetros muy largos | Usar `-O nombre_corto` |
| `wget: command not found` | No instalado | `apt install wget` o `apk add wget` |
| `Connection timed out` | Firewall DROP o host caído | `ping`, verificar conectividad de red |

---

## ✅ Buenas prácticas

1. **Usar `--spider` para health checks**: no descarga el contenido, solo verifica respuesta
2. **Usar `-c` para continuar descargas**: evita re-descargar lo que ya bajaste
3. **Limitar velocidad con `--limit-rate`** si no querés saturar la red
4. **Nunca usar `--no-check-certificate` en producción** — solo para testing local
5. **Usar `-np` en mirroring** para no descargar servidores enteros accidentalmente
6. **Loggear las descargas programadas** con `-o archivo.log`
7. **Para APIs REST, preferir `curl`**: wget está pensado para archivos, curl para APIs
8. **Usar `-nv`** (non-verbose) para output intermedio entre `-q` y el default

---

## 🔗 Referencias internas

- [`curl`](curl.md) — alternativa más flexible para APIs y debugging HTTP
- [`cron`](cron.md) — descargas programadas
- [`scenario`](../scenarios/web/01-performance-and-error-analysis.md) — diagnóstico HTTP
- [`scenario`](../scenarios/networking/04-dns-resolution-failure.md) — falla de DNS con wget
