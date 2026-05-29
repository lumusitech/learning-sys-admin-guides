# find — Guía completa

**Nivel:** 🟡 Intermedio
**Archivos de práctica:** Sistema de archivos (`/`)
**Ver escenarios relacionados:** [`security/02-suid-audit`](../scenarios/security/02-suid-audit-and-file-permissions.md)

## ⚡ Quick command

`find / -type f -perm -4000 2>/dev/null`

## ⚡ Quick run

```bash
find / -type f -name "*.log" -size +100M 2>/dev/null
```

---

## 📑 Índice

1. [¿Qué es find?](#qué-es-find)
2. [Sintaxis básica](#sintaxis-básica)
3. [Búsqueda por nombre](#búsqueda-por-nombre)
4. [Búsqueda por tipo](#búsqueda-por-tipo)
5. [Búsqueda por tamaño](#búsqueda-por-tamaño)
6. [Búsqueda por tiempo](#búsqueda-por-tiempo)
7. [Búsqueda por permisos](#búsqueda-por-permisos)
8. [Búsqueda por usuario/grupo](#búsqueda-por-usuariogrupo)
9. [Operadores lógicos](#operadores-lógicos)
10. [Acciones sobre resultados](#acciones-sobre-resultados)
11. [Ejecutar comandos: -exec, -ok, -delete](#ejecutar-comandos)
12. [Optimización y rendimiento](#optimización-y-rendimiento)
13. [Escenarios reales](#escenarios-reales)
14. [find en seguridad y auditoría](#find-en-seguridad-y-auditoría)
15. [Combinación con otras herramientas](#combinación-con-otras-herramientas)
16. [Uno-liners imprescindibles](#uno-liners-imprescindibles)

---

## 🧠 ¿Qué es find?

**find** busca archivos y directorios en una jerarquía de directorios según criterios como nombre, tipo, tamaño, fecha, permisos, etc. Es la herramienta más potente para localizar archivos en Linux.

A diferencia de `locate` (que usa una base de datos indexada), `find` busca en **tiempo real** recorriendo el sistema de archivos, lo que es más lento pero siempre refleja el estado actual.

---

## 📝 Sintaxis básica

```bash
find [directorio(s)] [expresiones]
```

```bash
# Encontrar todo en el directorio actual (recursivo)
find .

# Encontrar todo en /home
find /home

# Buscar archivos por nombre
find /etc -name "*.conf"
```

Si no se especifica directorio, find usa el **directorio actual** (`.`).

---

## Búsqueda por nombre

### -name (nombre exacto, sensible a mayúsculas)

```bash
# Archivos que terminan en .log
find /var/log -name "*.log"

# Archivos que empiezan con "access"
find . -name "access*"

# Exactamente "config.conf"
find /etc -name "config.conf"

# Con comodín en medio
find / -name "*error*"
```

### -iname (insensible a mayúsculas)

```bash
# Encontrar .txt, .TXT, .Txt, etc.
find . -iname "*.txt"

# Encontrar "readme" en cualquier combinación
find /doc -iname "*readme*"
```

### -lname (nombre del enlace simbólico)

Busca enlaces simbólicos por el nombre del archivo al que apuntan.

```bash
# Enlaces que apuntan a /bin/bash
find /usr -lname "/bin/bash"

# Enlaces rotos (apuntan a nada)
find . -type l ! -exec test -e {} \; -print
```

### Patrones con comodines

| Comodín | Significado |
|---------|-------------|
| `*` | Cualquier secuencia de caracteres |
| `?` | Un solo carácter cualquiera |
| `[abc]` | Un carácter del conjunto |
| `[a-z]` | Un carácter del rango |

```bash
# Archivos con exactamente 3 caracteres antes de .log
find . -name "???.log"

# Archivos que empiezan con a o b
find . -name "[ab]*"
```

> **Importante**: las comillas son necesarias. Sin comillas, el shell expande `*` antes de pasar el argumento a find.

---

## Búsqueda por tipo

| Opción | Qué busca |
|--------|-----------|
| `-type f` | Archivos regulares |
| `-type d` | Directorios |
| `-type l` | Enlaces simbólicos |
| `-type s` | Sockets |
| `-type p` | Named pipes (FIFO) |
| `-type b` | Dispositivos de bloque |
| `-type c` | Dispositivos de carácter |

```bash
# Solo archivos regulares
find . -type f -name "*.sh"

# Solo directorios
find / -type d -name "bin"

# Todos los enlaces simbólicos
find /usr -type l

# Solo sockets
find /var/run -type s
```

---

## Búsqueda por tamaño

| Opción | Significado |
|--------|-------------|
| `-size +100M` | Mayor que 100 megabytes |
| `-size -10k` | Menor que 10 kilobytes |
| `-size 1024` | Exactamente 1024 bloques de 512 bytes |
| `-size 100M` | Exactamente 100 megabytes |

### Sufijos de tamaño

| Sufijo | Unidad | Equivalencia |
|--------|--------|--------------|
| `b` | Bloques | 512 bytes (por defecto si no se usa sufijo) |
| `c` | Bytes | 1 byte |
| `w` | Words | 2 bytes |
| `k` | Kilobytes | 1024 bytes |
| `M` | Megabytes | 1048576 bytes |
| `G` | Gigabytes | 1073741824 bytes |

```bash
# Archivos mayores de 1GB
find / -type f -size +1G

# Archivos menores de 1KB
find . -type f -size -1k

# Archivos entre 10MB y 100MB
find /var -type f -size +10M -size -100M

# Archivos exactamente de 1000 bytes
find . -type f -size 1000c

# Archivos vacíos (0 bytes)
find . -type f -empty
# También: find . -type f -size 0
```

> **`-empty`**: selecciona archivos vacíos o directorios vacíos. No confundir con `-size 0`, que solo aplica a archivos regulares.

---

## Búsqueda por tiempo

### Tiempos de archivo

| Campo | Significado |
|-------|-------------|
| `atime` (acceso) | Última vez que se **leyó** el archivo |
| `mtime` (modificación) | Última vez que se **modificó** el contenido |
| `ctime` (cambio) | Última vez que **cambió** el inodo (permisos, nombre, contenido) |

### Formato: +N, -N, N

| Sintaxis | Significado |
|----------|-------------|
| `-mtime +30` | Más de 30 días (hace >30 días) |
| `-mtime -7` | Menos de 7 días (última semana) |
| `-mtime 1` | Exactamente hace 1 día (entre 24h y 48h) |
| `-mmin +60` | Más de 60 minutos |
| `-mmin -10` | Hace menos de 10 minutos |

```bash
# Modificados en las últimas 24 horas
find . -type f -mtime -1

# Modificados hace más de 30 días
find /var/log -type f -mtime +30

# Accedidos en los últimos 10 minutos
find . -type f -amin -10

# Cambiados de estado en la última hora
find . -type f -cmin -60

# Entre 7 y 30 días
find . -type f -mtime +7 -mtime -30
```

### -newer (comparar con otro archivo)

```bash
# Archivos modificados más recientemente que referencia.txt
find . -type f -newer referencia.txt

# Archivos más recientes que un archivo específico
find . -newer /etc/passwd
```

### -daystart (inicio del día como referencia)

Por defecto find cuenta desde hace 24 horas desde ahora. Con `-daystart`, cuenta desde el inicio del día actual.

```bash
# Archivos modificados hoy (desde medianoche)
find . -type f -daystart -mtime 0

# Archivos modificados ayer
find . -type f -daystart -mtime 1
```

---

## Búsqueda por permisos

### -perm (permisos exactos)

```bash
# Permisos exactamente 755
find . -type f -perm 755

# Cualquier archivo con permisos 777 (todos escribibles)
find . -type f -perm 777
```

### -perm -modo (todos los bits indicados deben estar presentes)

```bash
# Archivos ejecutables para cualquiera (el bit +x está en al menos un grupo)
find . -type f -perm -111

# Archivos escribibles por cualquiera (world-writable)
find . -type f -perm -o+w

# Directorios con sticky bit
find / -type d -perm -1000

# Archivos SUID (setuid activado)
find /usr -type f -perm -4000
```

### -perm /modo (cualquier bit indicado presente)

```bash
# Archivos con SUID o SGID
find /usr -type f -perm /6000

# Archivos con cualquier permiso especial
find / -type f -perm /7000
```

### Modos simbólicos

```bash
# Escribible por cualquiera (world-writable)
find / -type f -perm -o+w

# Legible por grupo
find . -type f -perm -g+r

# Ejecutable por owner
find . -type f -perm -u+x
```

---

## Búsqueda por usuario/grupo

```bash
# Archivos de un usuario específico
find / -type f -user carludev

# Archivos del grupo www-data
find /var/www -type f -group www-data

# Archivos que NO son del usuario root
find / -type f ! -user root

# Archivos sin usuario asignado (usuario eliminado)
find / -type f -nouser

# Archivos sin grupo asignado
find / -type f -nogroup

# Archivos de múltiples usuarios
find / -user carludev -o -user root
```

---

## Operadores lógicos

| Operador | Significado | Sintaxis |
|----------|-------------|----------|
| AND | Y lógico | `-a` o `-and` o simplemente juntar condiciones |
| OR | O lógico | `-o` o `-or` |
| NOT | Negación | `!` o `-not` |
| Paréntesis | Agrupación | `\(` `\)` (escapados) |

```bash
# AND implícito: archivos .conf que contienen "nginx"
find /etc -name "*.conf" -type f

# AND explícito
find /etc -name "*.conf" -a -type f

# OR: archivos .txt o .md
find . -name "*.txt" -o -name "*.md"

# NOT: archivos que no son .log
find /var/log -type f ! -name "*.log"

# Agrupación: ( .py o .js ) Y modificados hoy
find . \( -name "*.py" -o -name "*.js" \) -mtime -1

# NOT combinado: archivos que NO son .txt NI .md
find . -type f ! \( -name "*.txt" -o -name "*.md" \)
```

---

## Acciones sobre resultados

### -print (por defecto)

Imprime las rutas encontradas, una por línea.

```bash
find . -name "*.conf" -print
```

### -print0 (separador nulo)

Separa resultados con carácter nulo (`\0`). Esencial para pipear a `xargs -0` o manejar nombres con espacios.

```bash
find . -name "*.log" -print0 | xargs -0 grep "error"
```

### -printf (formato personalizado - GNU find)

Mucho más potente que `-print`. Permite elegir qué mostrar.

| Secuencia | Qué imprime |
|-----------|-------------|
| `%p` | Ruta del archivo |
| `%f` | Nombre del archivo (sin directorio) |
| `%h` | Directorio que lo contiene |
| `%s` | Tamaño en bytes |
| `%k` | Tamaño en KB |
| `%M` | Permisos en modo simbólico (rwxr-xr-x) |
| `%m` | Permisos en octal (755) |
| `%u` | Nombre del usuario propietario |
| `%g` | Nombre del grupo propietario |
| `%t` | Timestamp de última modificación |
| `%Tk` | Timestamp en formato `@seconds since epoch` |
| `%A@` | Timestamp de último acceso en epoch |
| `%C@` | Timestamp de cambio de inodo en epoch |
| `\n` | Nueva línea |
| `\t` | Tabulación |

```bash
# Lista tipo ls -la personalizada
find . -type f -printf "%M %u:%g %s %p\n"

# Solo nombres de archivo (sin ruta)
find /etc -name "*.conf" -printf "%f\n"

# Tamaño y nombre
find . -type f -printf "%8s %p\n" | sort -rn

# Directorios con fecha de modificación
find . -type d -printf "%T@ %p\n" | sort -rn

# Permisos en octal
find . -type f -printf "%m %p\n"
```

### -ls (listado detallado)

```bash
# Formato similar a ls -dils
find / -type f -name "*.log" -ls
```

---

## Ejecutar comandos

### -exec (ejecutar comando)

Ejecuta un comando para cada archivo encontrado. `{}` se reemplaza por la ruta del archivo. `\;` termina el comando.

```bash
# Mostrar permisos de cada archivo .conf
find /etc -name "*.conf" -exec ls -l {} \;

# Contar líneas de cada archivo .py
find . -name "*.py" -exec wc -l {} \;

# Cambiar permisos
find . -type f -name "*.sh" -exec chmod +x {} \;

# Mover archivos
find /tmp -name "*.log" -mtime +7 -exec mv {} /backup/ \;
```

### -exec {} + (ejecutar agrupado)

Agrupa archivos y los pasa como argumentos, como `xargs`. Mucho más eficiente que `-exec \;`.

```bash
# Un solo comando chmod para todos los archivos
find . -type f -name "*.sh" -exec chmod +x {} +

# grep en todos los .log de una sola invocación
find /var/log -name "*.log" -exec grep -l "error" {} +

# rm de una sola vez (más rápido que \;)
find /tmp -name "*.tmp" -mtime +1 -exec rm {} +
```

### -ok (preguntar antes de ejecutar)

Como `-exec` pero pregunta antes de cada acción.

```bash
# Preguntar antes de borrar
find . -name "*.tmp" -ok rm {} \;

# Preguntar antes de mover
find . -name "*.log" -ok mv {} /backup/ \;
```

### -delete (eliminar)

Elimina archivos o directorios vacíos. Más seguro que `-exec rm {} \;` porque find se queja si intenta borrar directorios no vacíos.

```bash
# Eliminar archivos .tmp
find /tmp -name "*.tmp" -type f -delete

# Eliminar directorios vacíos
find . -type d -empty -delete
```

> **Precaución**: siempre probar sin `-delete` primero para ver qué se va a borrar.

### Ejecutar con pipes

find no puede pipear directamente. Se combina con `-print0` y `xargs -0`:

```bash
# Para comandos que aceptan stdin
find . -name "*.txt" -print0 | xargs -0 -I {} cp {} /backup/

# Con filtros adicionales
find . -name "*.log" -print0 | xargs -0 grep -l "ERROR"
```

---

## Optimización y rendimiento

### Orden de evaluación (short-circuit)

find evalúa las condiciones de izquierda a derecha y cortocircuita (como `&&` en lógica). Pon primero lo más rápido/selectivo.

```bash
# Eficiente: primero filtra por nombre (más barato), luego por contenido (más caro)
find . -name "*.py" -exec grep -q "TODO" {} \; -print

# Ineficiente: exec grep en todo (lento)
find . -exec grep -q "TODO" {} \; -name "*.py" -print
```

### -maxdepth / -mindepth

Controlan la profundidad de la búsqueda. Esencial para rendimiento en directorios grandes.

```bash
# Solo el directorio actual (no recursivo)
find . -maxdepth 1 -name "*.py"

# Hasta 3 niveles de profundidad
find /var -maxdepth 3 -name "*.log"

# Ignorar primeros 2 niveles
find / -mindepth 3 -name "*.conf"

# Solo el nivel 2 (mindepth=2, maxdepth=2)
find /var -mindepth 2 -maxdepth 2 -type d
```

### -prune (podar)

Excluye directorios completos de la búsqueda. Muy útil para ignorar `.git`, `node_modules`, etc.

```bash
# Excluir directorio .git
find . -name .git -prune -o -type f -name "*.py" -print

# Excluir múltiples directorios
find . \( -name .git -o -name node_modules -o -name __pycache__ \) -prune -o -type f -print

# Excluir /proc y /sys en búsquedas de sistema
find / \( -path /proc -o -path /sys \) -prune -o -name "*.conf" -print
```

> **Explicación de `-prune`**: cuando `-prune` encuentra una coincidencia, no entra en ese directorio y, al ser una condición verdadera, el `-o` hace que se omita la segunda parte. Es decir: "si es .git, pódalo y no procese más; si no, busque archivos .py".

### -regex / -iregex (GNU find)

Usa regex en lugar de globs para el nombre completo de la ruta.

```bash
# Archivos que terminan en .py o .pyc
find . -regex ".*\.\(py\|pyc\)$"

# IPv4 en el nombre
find . -regex ".*[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}.*"

# Igual insensible a mayúsculas
find . -iregex ".*\.jpg$"
```

### -regextype (tipo de regex)

```bash
# Usar regex estilo emacs (por defecto), posix-egrep, posix-extended, etc.
find . -regextype posix-egrep -regex ".*\.(py|js|ts)$"
```

---

## Escenarios reales

### 1. Limpieza de logs y temporales

```bash
# Logs de hace más de 30 días (con simulación)
find /var/log -type f -name "*.log" -mtime +30 -ls

# Borrar logs rotados
find /var/log -type f -name "*.gz" -mtime +90 -delete

# Temporales de más de 7 días
find /tmp -type f -atime +7 -delete

# Archivos core dump
find / -type f -name "core" -size +1M -exec rm {} \;

# Cache de paquetes antiguos
find /var/cache/apt -type f -mtime +30 -delete
```

### 2. Auditoría de permisos

```bash
# Archivos SUID/SGID (potencial riesgo de seguridad)
find /usr -type f \( -perm -4000 -o -perm -2000 \) -ls

# Archivos world-writable en /etc
find /etc -type f -perm -o+w -ls

# Directorios world-writable con sticky bit faltante
find / -type d -perm -1000 ! -perm -1000 -ls

# Archivos sin dueño
find / -type f -nouser -o -type f -nogroup -ls

# Permisos inseguros en /home
find /home -type f -perm /o+w ! -type l -ls
```

### 3. Búsqueda de contenido en archivos

```bash
# Archivos .py con "TODO" (busca contenido en los encontrados)
find . -name "*.py" -exec grep -l "TODO" {} \;

# Archivos modificados hoy con "password"
find . -mtime -1 -exec grep -l "password" {} \;

# Archivos grandes (>10MB) que contienen "error"
find /var -type f -size +10M -exec grep -l "error" {} \;

# Buscar en archivos excluyendo binarios
find . -type f -exec grep -Iq . {} \; -exec grep -l "patron" {} \;
```

> **`grep -I`**: ignora archivos binarios. Útil para descartarlos en búsquedas.

### 4. Operaciones masivas con archivos

```bash
# Cambiar extensión de .txt a .md
find . -name "*.txt" -exec sh -c 'mv "$1" "${1%.txt}.md"' _ {} \;

# Comprimir todos los .log viejos
find /var/log -type f -name "*.log" -mtime +1 -exec gzip {} \;

# Normalizar permisos: directorios 755, archivos 644
find . -type d -exec chmod 755 {} \;
find . -type f -exec chmod 644 {} \;

# Cambiar propietario masivamente
find /var/www -type f -exec chown www-data:www-data {} \;

# Backup de archivos .conf a /backup preservando estructura
find /etc -name "*.conf" -exec cp --parents {} /backup/ \;
```

### 5. Encontrar archivos por contenido

```bash
# Archivos que contienen una palabra específica
find . -type f -exec grep -l "palabra" {} \;

# Archivos que contienen el patrón y mostrar el contexto
find . -type f -name "*.log" -exec grep -H "error" {} \;

# Archivos que NO contienen un patrón
find . -type f -exec grep -L "copyright" {} \;
```

### 6. Trabajar con fechas específicas

```bash
# Archivos creados/modificados en un rango de fechas
touch -t 202401010000 inicio
touch -t 202401312359 fin
find . -newer inicio ! -newer fin

# Archivos modificados durante el fin de semana
find . -type f -newer "$(date -d 'last saturday' +%s)" ! -newer "$(date -d 'last monday' +%s)"

# Archivos accedidos exactamente hoy
find . -type f -daystart -atime 0
```

---

## find en seguridad y auditoría

### Detectar amenazas comunes

```bash
# Archivos con SUID en directorios no habituales
find /usr /etc /home -type f -perm -4000 -ls

# Archivos con nombres sospechosos
find /tmp -type f \( -name "*.sh" -o -name "*.py" -o -name "*.pl" \) -ls

# Enlaces simbólicos en /tmp (potencial race condition)
find /tmp -type l -ls

# Archivos ocultos con ejecutables
find /home -type f -name ".*" -exec file {} \; | grep -i executable

# Backdoors: archivos modificados recientemente en /bin, /sbin
find /bin /sbin /usr/bin /usr/sbin -type f -mtime -1 -ls
```

### Rootkits y malware

```bash
# Permisos inusuales en binarios del sistema
find /bin /sbin /usr/bin /usr/sbin -type f ! -perm 755 -ls

# Archivos .so inusuales en LD_LIBRARY_PATH
find /lib /usr/lib -type f -name "*.so.*" -perm /o+w -ls

# Procesos ocultos (archivos en /proc con dueño inusual)
find /proc -maxdepth 2 -type d -user carludev 2>/dev/null
```

### Auditoría de sistemas

```bash
# Archivos grandes que crecen rápido (logs sin rotar)
find /var/log -type f -size +100M -ls

# Archivos duplicados por nombre
find . -type f -printf "%f\n" | sort | uniq -d

# Directorios sin recorrido (--x) para otros
find / -type d ! -perm -o+x -ls

# Archivos con permisos 777
find / -type f -perm 777 -ls
```

---

## 🛠️ Combinación con otras herramientas

### find + xargs (la combinación más potente)

```bash
# Buscar y procesar con xargs
find . -name "*.log" -print0 | xargs -0 grep "error"

# Con -I para reemplazar
find . -name "*.jpg" -print0 | xargs -0 -I {} convert {} -resize 50% {}

# Paralelo
find . -name "*.py" -print0 | xargs -0 -P4 -I {} python {} --test
```

> **Siempre usa `-print0` + `xargs -0`** cuando los nombres puedan tener espacios. NUNCA `find ... | xargs` sin `-0`.

### find + tar

```bash
# Empaquetar archivos encontrados
find . -name "*.log" -mtime +30 -print0 | xargs -0 tar czf old_logs.tar.gz

# O mejor: tar con -T
find . -name "*.log" -mtime +30 > lista.txt
tar czf old_logs.tar.gz -T lista.txt

# Sin archivo temporal (proceso substitución)
tar czf old_logs.tar.gz -T <(find . -name "*.log" -mtime +30)
```

### find + du

```bash
# Tamaño total de archivos .log
find . -name "*.log" -exec du -ch {} + | tail -1

# Top 10 archivos más grandes
find . -type f -printf "%s %p\n" | sort -rn | head -10

# Directorios con más archivos
find . -type d -exec sh -c 'echo "$1 $(find "$1" -type f | wc -l)"' _ {} \; | sort -rn -k2
```

### find + chmod/chown

```bash
# Corregir permisos en proyecto
find . -type d -exec chmod 755 {} \;
find . -type f -exec chmod 644 {} \;
find . -name "*.sh" -exec chmod 755 {} \;

# Cambiar propietario recursivo
find /var/www -user olduser -exec chown newuser:newgroup {} \;
```

### find + watch

```bash
# Monitorear creación de archivos
watch -n 5 'find /tmp -type f -mmin -5 -ls'

# Monitorear crecimiento de logs
watch -n 10 'find /var/log -type f -size +100M -ls'
```

---

## 💡 Uno-liners imprescindibles

```bash
# Buscar archivos por contenido (más rápido que grep -r en grandes árboles)
find . -type f -exec grep -l "busqueda" {} \;

# Contar archivos por tipo
find . -type f | wc -l

# Contar directorios
find . -type d | wc -l

# Archivos con tamaño exacto
find . -type f -size 1024c

# Archivos más grandes (top 5)
find . -type f -exec ls -s {} \; | sort -rn | head -5

# Archivos más recientes (top 5)
find . -type f -printf "%T@ %p\n" | sort -rn | head -5

# Archivos con extensión específica (múltiples)
find . -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" \)

# Eliminar archivos vacíos
find . -type f -empty -delete

# Encontrar y eliminar archivos con caracteres extraños
find . -name "*[!-a-zA-Z0-9._]*" -ls

# Archivos sin extension
find . -type f ! -name "*.*"

# Enlaces simbólicos rotos
find . -type l ! -exec test -e {} \; -print

# Archivos con múltiples hard links
find . -type f -links +1 -ls

# Directorios del home que no son del usuario
find /home -maxdepth 1 -type d ! -user root

# Últimos N archivos modificados recursivamente
find . -type f -printf "%T@ %p\n" | sort -rn | head -10 | cut -d' ' -f2-

# Archivos de más de 1 año
find . -type f -mtime +365

# Copiar estructura de directorios (sin archivos)
find . -type d -exec mkdir -p /destino/{} \;

# Diff de dos árboles
diff <(find dir1 -type f -printf "%P\n" | sort) <(find dir2 -type f -printf "%P\n" | sort)
```
