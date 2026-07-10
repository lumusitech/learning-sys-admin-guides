# df — Guía completa

**Nivel:** 🟢 Básico
**Archivos de práctica:** Sistema en vivo
**Ver escenarios relacionados:** [`system/06-disk-full-inodes`](../scenarios/system/06-disk-full-inodes.md), [`system/01-top-processes`](../scenarios/system/01-top-processes-and-resources.md)

---

## ⚡ Quick command

`df -h`

---

## ⚡ Quick run

```bash
df -h && df -i | head -20
```

---

## 📑 Índice

1. [¿Qué es df?](#qué-es-df)
2. [Sintaxis básica](#sintaxis-básica)
3. [Salida clave](#salida-clave)
4. [Opciones principales](#opciones-principales)
5. [Inodes](#inodes)
6. [Sistemas de archivos especiales](#sistemas-de-archivos-especiales)
7. [Patrones de uso](#patrones-de-uso)
8. [Uso en troubleshooting](#uso-en-troubleshooting)
9. [Combinación con otras herramientas](#combinación-con-otras-herramientas)
10. [Uno-liners imprescindibles](#uno-liners-imprescindibles)
11. [Errores comunes](#errores-comunes)
12. [Buenas prácticas](#buenas-prácticas)

---

## 🧠 ¿Qué es df?

**df** (disk free) reporta el uso de espacio en sistemas de archivos montados. Muestra tamaño total, usado, disponible y porcentaje de ocupación de cada partición o volumen.

Se usa para:

- detectar discos llenos antes de que afecten servicios;
- identificar qué partición está saturada;
- verificar inodes agotados (demasiados archivos pequeños).

---

## 🧠 Modelo mental

`df` es el medidor de gasolina del servidor. Así como no dejás que el auto se quede sin combustible, no dejás que un disco se llene al 100% o los servicios empiezan a fallar.

Hay dos formas de "llenar" un disco:

1. **Espacio**: archivos grandes (logs, videos, backups). Se ve con `df -h`.
2. **Inodes**: millones de archivos pequeños (caché, colas, temporales). Se ve con `df -i`.

Un disco puede tener espacio libre pero inodes agotados. Cuando eso pasa, no se pueden crear archivos nuevos aunque haya espacio.

---

## 📝 Sintaxis básica

```bash
df [opciones] [ruta]
```

```bash
df -h            # Todos los sistemas de archivos, formato humano
df -h /var       # Solo el sistema que contiene /var
df -hT           # Con tipo de sistema de archivos (ext4, xfs, tmpfs)
df -i            # Uso de inodes
```

---

## 🔑 Salida clave

```text
Sist. archivos     Tipo  Tamaño  Usados  Disponible  Uso%  Montado en
/dev/sda1         ext4    98G     45G        48G    49%   /
/dev/sdb1         ext4   500G    452G        23G    96%   /var
tmpfs             tmpfs   16G     2.1G       14G    14%   /tmp
```

| Columna | Significado |
|---------|-------------|
| `Sist. archivos` | Dispositivo o volumen |
| `Tipo` | Sistema de archivos (ext4, xfs, tmpfs, nfs4) |
| `Tamaño` | Capacidad total |
| `Usados` | Espacio ocupado |
| `Disponible` | Espacio libre para el usuario (reserva del 5% para root) |
| `Uso%` | Porcentaje ocupado |
| `Montado en` | Punto de montaje |

### Regla de alarma

- `Uso%` > 80% → monitorear.
- `Uso%` > 90% → revisar, posible acción.
- `Uso%` > 95% → riesgo de fallo de servicio.
- `Uso%` = 100% → escrituras fallan inmediatamente.

---

## 🎛️ Opciones principales

| Opción | Efecto |
|--------|--------|
| `-h` | Formato humano (GB, MB) |
| `-H` | Base 1000 en vez de 1024 |
| `-T` | Mostrar tipo de sistema de archivos |
| `-i` | Mostrar uso de inodes en vez de espacio |
| `-x <tipo>` | Excluir tipo de fs (ej: `-x tmpfs`) |
| `-t <tipo>` | Solo mostrar un tipo (ej: `-t ext4`) |
| `--output` | Columnas específicas (moderno) |

---

## Inodes

Los inodes son la tabla de contenido del disco. Cada archivo o directorio consume un inode.

```bash
df -i
```

```text
Sist. archivos    Inodes  IUsados  ILibres  IUso%  Montado en
/dev/sda1         6.5M     1.2M     5.3M    19%    /
/dev/sdb1         32M      31.9M    0.1M    99%    /var/cache
```

Cuando los inodes se agotan al 100%, el sistema rechaza crear archivos nuevos incluso si `df -h` muestra espacio libre.

**Cómo liberar inodes:**

```bash
# Encontrar directorios con millones de archivos pequeños
find /var -xdev -type d | while read d; do
  count=$(ls -1 "$d" 2>/dev/null | wc -l)
  [ "$count" -gt 10000 ] && echo "$count $d"
done | sort -rn | head -10

# Eliminar archivos temporales viejos
find /var/cache -type f -atime +30 -delete
```

---

## Sistemas de archivos especiales

`df` sin filtros muestra también sistemas virtuales (tmpfs, devtmpfs, overlay). Para ignorarlos:

```bash
df -h -x tmpfs -x devtmpfs -x overlay
```

O más simple:

```bash
df -h | grep '^/dev/'
```

---

## 📋 Patrones de uso

### Discos físicos solamente

```bash
df -hT | grep '^/dev/'
```

### Partición más usada

```bash
df -h | awk 'NR>1 { print $5, $6 }' | sort -rn | head -5
```

### Espacio disponible en una ruta (útil para scripts de backup)

```bash
df -h /mnt/backups | awk 'NR==2 { print $4 }'
```

### Todos los discos con > 80% de uso

```bash
df -h | awk 'NR>1 && /^\// { gsub(/%/,"",$5); if ($5 > 80) print $6, $5"% usado" }'
```

### Porcentaje disponible en una partición

```bash
df -h /var | awk 'NR==2 { gsub(/%/,"",$5); print 100-$5 "% disponible" }'
```

---

## 🔍 Uso en troubleshooting

### Disco lleno — encontrar qué ocupa espacio

```bash
# 1. ¿Qué partición está llena?
df -h

# 2. ¿Qué directorio pesa más?
du -sh /var/* | sort -rh | head -10

# 3. ¿Qué archivos grandes hay?
find /var -type f -size +100M -exec ls -lh {} \; | sort -k5 -rh | head -10
```

### Inodes agotados

```bash
# 1. Verificar inodes
df -iT

# 2. Encontrar directorio con más archivos
ls -1 /var/spool | wc -l
find /var -xdev -type d -size +10M -exec sh -c 'echo "$(ls -1 "$1" | wc -l) $1"' _ {} \; | sort -rn | head -10
```

### Logrotate no funciona

```bash
# Si /var/log está lleno y hay logs enormes:
ls -lh /var/log/*.log | sort -k5 -rh | head -10

# Forzar rotación manual
sudo logrotate -f /etc/logrotate.conf
```

---

## 🛠️ Combinación con otras herramientas

### df + du: diagnóstico completo

```bash
df -h
du -sh /* | sort -rh | head -10
```

### df + awk: alerta por umbral

```bash
df -h | awk 'NR>1 && /^\// { gsub(/%/,"",$5); if ($5 > 85) printf "ALERTA: %s al %s%%\n", $6, $5 }'
```

### df + grep + mail: reporte periódico (cron)

```bash
df -h | mail -s "Reporte de disco" admin@empresa.com
```

---

## 💡 Uno-liners imprescindibles

```bash
df -h                                    # Resumen general
df -i                                    # Inodes
df -hT | grep '^/dev/'                   # Solo discos físicos
df -h /var /home /tmp                    # Particiones específicas
df -h | awk 'NR>1 { print $5, $6 }' | sort -rn | head -5   # Top ocupación
df -h / | awk 'NR==2 { print $4 }'      # GB disponibles en raíz
df -hT -x tmpfs -x devtmpfs             # Sin filesystems virtuales
```

---

## ⚠️ Errores comunes

- **No revisar inodes (`df -i`)**. Un disco con 40% de espacio usado puede tener inodes al 100%. Pasa en colas de correo, cachés de sesión, /var/spool.
- **Leer `Disponible` como espacio total libre**. El kernel reserva 5% para root (configurable con `tune2fs -m`). En discos de 1 TB, eso son 50 GB que `df` no muestra como disponibles.
- **Ignorar tmpfs en contenedores**. `df -h` dentro de un contenedor Docker puede mostrar el disco del host. Verificar con `df -h /` dentro y fuera.
- **Alarmarse por tmpfs montado en `/run` o `/tmp`**. Son en RAM. Si se llenan, se cae el servicio que los usa, pero no afectan al disco.

---

## ✅ Buenas prácticas

- Monitorear tanto `df -h` como `df -i`. Un cron diario que alerte si > 85% en cualquiera de los dos.
- Configurar `logrotate` antes de que los logs llene el disco.
- En servidores de producción, separar `/var`, `/home` y `/tmp` en particiones independientes. Un `/var` lleno no debería afectar al sistema.
- Dejar al menos 20% libre en particiones de bases de datos y logs.
- Usar `--direct` en `df` (cuando está disponible) para montajes NFS lentos: `df --direct -h /mnt/nfs`.

---

## 🔗 Referencias internas

- [`du`](du.md) — espacio usado por directorios específicos
- [`find`](find.md) — encontrar archivos grandes o viejos
- [`storage_backup`](storage_backup.md) — backup y rotación
