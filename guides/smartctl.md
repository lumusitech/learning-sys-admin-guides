# smartctl — Guía completa

**Nivel:** 🟡 Intermedio
**Archivos de práctica:** N/A — requiere un disco real o una VM con disco virtual. El lab Dahua simula el NVR pero no expone SMART
**Ver escenarios relacionados:** [`raid-degradation`](../scenarios/infrastructure/06-raid-degradation.md), [`nvr-sin-disco`](../scenarios/dahua/02-nvr-sin-disco.md)

---

## ⚡ Quick command

`smartctl -H /dev/sda`

> ⚠️ Detrás de un RAID por hardware o un puente USB el disco no responde directo: hace falta `-d` (`sat`, `megaraid,N`, `nvme`). Ver [Opciones principales](#️-opciones-principales).

---

## ⚡ Quick run

```bash
# Salud general + atributos + errores en una sola pasada
smartctl -a /dev/sda

# Solo el veredicto (para scripts)
smartctl -H /dev/sda | grep -i "result"
```

---

## 📑 Índice

1. [¿Qué es smartctl?](#qué-es-smartctl)
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

## 🧠 ¿Qué es smartctl?

`smartctl` es la herramienta de línea de comandos de **smartmontools**. Consulta el sistema **SMART** (Self-Monitoring, Analysis and Reporting Technology) que traen casi todos los discos ATA/SATA, SCSI/SAS y NVMe.

SMART es un conjunto de contadores y auto-tests que el propio disco mantiene: sectores reasignados, errores de lectura, temperatura, horas encendidas, desgaste de una SSD. `smartctl` los lee y los interpreta.

Lo que responde:

- ¿El disco dice que está sano o fallando?
- ¿Hay sectores reasignados o pendientes de reasignar?
- ¿El enlace SATA está tirando errores (cable, backplane)?
- ¿Cuánto desgaste tiene una SSD?
- ¿Pasó el último self-test?

Lo que **no** responde:

- ¿El disco va a fallar mañana? SMART predice tendencias, no garantiza nada.
- ¿El sistema de archivos está corrupto? Eso lo dice `fsck`, no SMART.
- ¿El RAID está degradado? Eso lo dice `mdadm` o el controlador.

---

## 🧠 Modelo mental

El disco es un dispositivo que lleva su propia **libreta de salud**. Cada vez que lee un sector y falla, lo anota; cuando reasigna un sector, lo cuenta; cuando sube la temperatura, la registra. `smartctl` es el lector de esa libreta.

Tres capas de información:

| Capa | Qué te dice | Comando |
|------|-------------|---------|
| Veredicto | PASSED / FAILED | `smartctl -H` |
| Atributos | Contadores que explican el veredicto | `smartctl -A` |
| Historial | Self-tests y errores registrados | `smartctl -l selftest`, `smartctl -l error` |

La regla: **el veredicto PASSED no alcanza**. Un disco puede decir PASSED y tener `Reallocated_Sector_Ct` subiendo. Los atributos son la señal temprana; el veredicto es la confirmación tardía.

---

## 📝 Sintaxis básica

```bash
smartctl [opciones] dispositivo
```

| Forma | Significado |
|-------|-------------|
| `smartctl -a /dev/sda` | Toda la información disponible |
| `smartctl -H /dev/sda` | Solo el veredicto de salud |
| `smartctl -A /dev/sda` | Solo la tabla de atributos |
| `smartctl -i /dev/sda` | Modelo, serie, firmware, capacidad |
| `smartctl -l error /dev/sda` | Log de errores del dispositivo |
| `smartctl -l selftest /dev/sda` | Historial de self-tests |
| `smartctl -t short /dev/sda` | Lanzar un test corto (~2 min) |
| `smartctl -t long /dev/sda` | Lanzar un test largo (horas) |
| `smartctl -X /dev/sda` | Abortar el test en curso |

> `smartctl` necesita permisos de root para abrir el dispositivo. En Alpine se instala con `apk add smartmontools`; en Debian/Ubuntu `apt install smartmontools`; en RHEL/Fedora `dnf install smartmontools`.

---

## 🔑 Salida clave

### Veredicto (ATA)

```text
=== START OF READ SMART DATA SECTION ===
SMART overall-health self-assessment test result: PASSED
```

```text
SMART overall-health self-assessment test result: FAILED!
Drive failure expected in less than 24 hours. SAVE ALL DATA.
Failed Attributes:
ID# ATTRIBUTE_NAME          FLAG     VALUE WORST THRESH TYPE      UPDATED  WHEN_FAILED RAW_VALUE
  5 Reallocated_Sector_Ct   0x0033   001   001   010    Pre-fail  Always   FAILING_NOW 2048
```

Interpretación:

- `PASSED` → el disco no se considera en fallo inminente.
- `FAILED!` → respaldar ya. El disco está en fallo declarado.
- `FAILING_NOW` en `WHEN_FAILED` → el atributo cruzó su umbral ahora.

### Atributos ATA (fragmento)

```text
ID# ATTRIBUTE_NAME          FLAG     VALUE WORST THRESH TYPE      UPDATED  WHEN_FAILED RAW_VALUE
  5 Reallocated_Sector_Ct   0x0033   100   100   010    Pre-fail  Always       -       0
  9 Power_On_Hours          0x0032   095   095   000    Old_age   Always       -       40123
187 Reported_Uncorrect      0x0032   100   100   000    Old_age   Always       -       0
188 Command_Timeout         0x0032   100   100   000    Old_age   Always       -       0
197 Current_Pending_Sector  0x0012   100   100   000    Old_age   Always       -       0
198 Offline_Uncorrectable   0x0010   100   100   000    Old_age   Offline      -       0
199 UDMA_CRC_Error_Count    0x003e   200   200   000    Old_age   Always       -       0
```

| Columna | Qué significa |
|---------|---------------|
| `VALUE` | Valor normalizado actual (100 = mejor). Baja cuando el atributo empeora |
| `WORST` | El peor valor histórico registrado |
| `THRESH` | Umbral: si `VALUE` lo cruza, el atributo queda en fallo |
| `TYPE` | `Pre-fail` (crítico) u `Old_age` (desgaste normal) |
| `RAW_VALUE` | El contador crudo del fabricante |

### Atributos que importan

| ID | Atributo | Señal |
|----|----------|-------|
| 5 | `Reallocated_Sector_Ct` | Sectores reasignados. **Cualquier valor > 0 es sospechoso** |
| 9 | `Power_On_Hours` | Horas encendido. Contexto de vida del disco |
| 187 | `Reported_Uncorrect` | Errores no corregidos reportados al host |
| 188 | `Command_Timeout` | Timeouts de comandos (cable, controlador, disco) |
| 197 | `Current_Pending_Sector` | Sectores pendientes de reasignar. **> 0 es señal fuerte** |
| 198 | `Offline_Uncorrectable` | Sectores ilegibles detectados en tests offline |
| 199 | `UDMA_CRC_Error_Count` | Errores de CRC en el enlace. **Casi siempre cable/backplane** |
| 194 | `Temperature_Celsius` | Temperatura actual y máxima |

### NVMe

```text
=== START OF SMART DATA SECTION ===
SMART overall-health self-assessment test result: PASSED

SMART/Health Information (NVMe Log 0x02)
Critical Warning:                   0x00
Temperature:                        38 Celsius
Available Spare:                    100%
Available Spare Threshold:          10%
Percentage Used:                    3%
Data Units Read:                    41,203,911 [21.0 TB]
Data Units Written:                 22,884,102 [11.7 TB]
Media and Data Integrity Errors:    0
Error Information Log Entries:      0
```

| Campo | Señal |
|-------|-------|
| `Critical Warning` | `0x00` = sin alertas. Cualquier otro valor requiere atención |
| `Available Spare` | Bloques de reserva disponibles. Bajo el umbral = desgaste avanzado |
| `Percentage Used` | Desgaste estimado de la SSD. 100% = fin de vida útil estimada |
| `Media and Data Integrity Errors` | Errores de integridad. **> 0 es grave** |

### Self-test

```text
SMART Self-test log structure revision number 1
Num  Test_Description    Status                  Remaining  LifeTime(hours)  LBA_of_first_error
# 1  Short offline       Completed without error       00%     40120         -
# 2  Extended offline    Completed: read failure       90%     39980         123456789
```

`Completed: read failure` con `LBA_of_first_error` identifica el sector problemático. Es evidencia directa de fallo.

---

## 🎛️ Opciones principales

| Opción | Qué hace | Cuándo usarla |
|--------|----------|---------------|
| `-a` | Toda la información | Primer diagnóstico |
| `-x` | Información extendida | Casos raros, logs adicionales |
| `-H` | Veredicto de salud | Chequeo rápido y scripts |
| `-A` | Tabla de atributos | Seguimiento de tendencias |
| `-i` | Identificación del disco | Inventario |
| `-l error` | Log de errores | Confirmar errores de lectura |
| `-l selftest` | Historial de tests | Ver si el disco falló un test |
| `-t short` | Test corto | Chequeo rápido (2 min) |
| `-t long` | Test largo | Diagnóstico profundo (horas) |
| `-t offline` | Test offline | Similar a short, sin intervención |
| `-X` | Abortar test | El test afecta producción |
| `-s on` | Activar SMART | Disco con SMART deshabilitado |
| `-o on` | Activar recolección offline | Mejorar atributos offline |
| `-n standby` | No despertar discos dormidos | NAS con discos en reposo |
| `-j` | Salida JSON | Scripts con `jq` |
| `-d TIPO` | Forzar tipo de dispositivo | RAID, USB, NVMe |
| `--scan` | Descubrir dispositivos | Inventario inicial |
| `--scan-open` | Descubrir y abrir | Verificar acceso real |

### Tipos de dispositivo (`-d`)

| Tipo | Uso |
|------|-----|
| `auto` | Detección automática (default) |
| `sat` | Disco ATA detrás de un puente USB/SATA |
| `sat,12` / `sat,16` | Ajustar el tamaño de los comandos ATA |
| `scsi` | Disco SCSI/SAS |
| `nvme` | Disco NVMe |
| `megaraid,N` | Disco N detrás de un controlador MegaRAID |
| `3ware,N` | Disco N detrás de un controlador 3ware |
| `areca,N` | Disco N detrás de un controlador Areca |
| `hpt,...` | HighPoint RocketRAID |

### Códigos de salida (bitmask)

`smartctl` no devuelve solo 0/1: devuelve una máscara de bits. Un `0` significa "todo bien"; cada bit encendido indica un problema distinto.

| Bit | Valor | Significado |
|-----|-------|-------------|
| 0 | 1 | La línea de comandos no se pudo interpretar |
| 1 | 2 | No se pudo abrir el dispositivo (o está en bajo consumo) |
| 2 | 4 | Falló algún comando SMART o hay checksum inválido |
| 3 | 8 | El veredicto fue `DISK FAILING` |
| 4 | 16 | Hay atributos `Pre-fail` en o bajo el umbral |
| 5 | 32 | Hubo atributos en el umbral en el pasado |
| 6 | 64 | El log de errores tiene registros |
| 7 | 128 | El log de self-tests tiene errores |

Para leer un bit concreto en POSIX sh:

```bash
smartctl -H /dev/sda >/dev/null 2>&1
status=$?
if [ $((status & 8)) -ne 0 ]; then
  echo "El disco se declara en fallo"
fi
```

> ⚠️ Un `smartctl -H` que devuelve `0` no garantiza que el disco esté sano: los bits 4 a 7 pueden estar encendidos con veredicto `PASSED`. Revisar la máscara completa.

---

## 📋 Patrones de uso

### 1. Chequeo rápido de un disco

```bash
smartctl -H /dev/sda
```

Salida esperada: `PASSED`. Si dice `FAILED!`, no seguir diagnosticando: respaldar.

### 2. Diagnóstico completo

```bash
smartctl -a /dev/sda
```

Ordenar la lectura: primero el veredicto, después los atributos 5, 197, 198, 199, y al final los logs.

### 3. Inventario de discos

```bash
smartctl --scan
smartctl --scan-open
```

`--scan` lista los dispositivos que smartmontools detecta; `--scan-open` confirma cuáles puede abrir realmente. Útil para saber qué discos quedan fuera por un controlador.

### 4. Revisar todos los discos de un servidor

```bash
for disk in /dev/sd?; do
  echo "== $disk"
  smartctl -H "$disk" 2>/dev/null | grep -i "result"
done
```

Para NVMe:

```bash
for disk in /dev/nvme?n1; do
  echo "== $disk"
  smartctl -H "$disk" 2>/dev/null | grep -i "result"
done
```

### 5. Disco detrás de un RAID por hardware

```bash
# Ver qué discos expone el controlador
smartctl --scan

# Primer disco del controlador MegaRAID
smartctl -a -d megaraid,0 /dev/sda

# Segundo disco
smartctl -a -d megaraid,1 /dev/sda
```

> En un RAID por software (`mdadm`), los miembros se ven como `/dev/sdX` y `smartctl` funciona directo. En RAID por hardware, el sistema solo ve el volumen lógico: hay que usar `-d`.

### 6. Disco USB

```bash
smartctl -a -d sat /dev/sdb
```

Si `sat` falla, probar `-d sat,12` o `-d sat,16`. Muchos puentes USB no pasan comandos SMART y el disco queda inaccesible por esta vía.

### 7. SSD NVMe: desgaste

```bash
smartctl -a /dev/nvme0n1
```

Mirar `Percentage Used`, `Available Spare` y `Media and Data Integrity Errors`. Un `Percentage Used` alto con `Available Spare` bajo indica fin de vida cercano.

### 8. Lanzar un self-test y consultarlo después

```bash
# Test corto (unos minutos)
smartctl -t short /dev/sda

# Test largo (puede tardar horas)
smartctl -t long /dev/sda

# Consultar el resultado cuando termine
smartctl -l selftest /dev/sda
```

> `-t long` somete al disco a lectura completa: en producción, programarlo en ventana de mantenimiento. Se puede abortar con `-X`.

### 9. Monitoreo continuo con smartd

```bash
# /etc/smartd.conf
DEVICESCAN -H -m root -M exec /usr/share/smartmontools/smartd-runner
```

`smartd` vigila los discos y envía alertas cuando un atributo cruza el umbral. En Alpine se instala con `apk add smartmontools` y se inicia con `rc-service smartd start`.

### 10. Salida JSON para automatizar

```bash
smartctl -j -H /dev/sda | jq '.smart_status.passed'
```

Devuelve `true` o `false`. Ideal para checks de monitoreo sin parsear texto.

---

## 🔍 Uso en troubleshooting

### "El RAID está degradado"

```bash
cat /proc/mdstat
mdadm --detail /dev/md0
```

Después, identificar el disco expulsado y confirmar con SMART:

```bash
smartctl -a /dev/sdX
```

Si el disco dice `FAILED!` o tiene `Reallocated_Sector_Ct` alto → reemplazo físico. Si dice `PASSED` y no hay errores → puede ser cable, backplane o un falso positivo del controlador.

### "El disco desapareció del sistema"

```bash
lsblk
dmesg | grep -i "ata\|sata\|error" | tail -20
smartctl --scan-open
```

Si `smartctl` no puede abrir el dispositivo, el problema es anterior a SMART: alimentación, cable o controlador.

### "Hay errores de I/O en el kernel"

```bash
dmesg | grep -i "I/O error\|medium error\|UNC" | tail -20
smartctl -l error /dev/sda
```

Si el log de errores tiene registros con LBA, el disco ya leyó mal esos sectores. Comparar con `Current_Pending_Sector`.

### "El enlace SATA tira errores"

```bash
smartctl -A /dev/sda | grep -i "CRC"
```

`UDMA_CRC_Error_Count` alto apunta a cable, conector o backplane, no al disco. Reemplazar el cable antes de condenar el disco.

### "El NVR no graba / no ve el disco"

```bash
lsblk
smartctl -H /dev/sda
smartctl -l error /dev/sda
dmesg | grep -i "ata\|link"
```

Si el disco no aparece en `lsblk`, SMART no va a responder. Primero resolver la detección física.

### "La SSD está lenta"

```bash
smartctl -a /dev/nvme0n1
```

Revisar `Percentage Used`, `Available Spare` y `Critical Warning`. Una SSD con desgaste alto puede seguir funcionando pero con rendimiento degradado.

---

## 🛠️ Combinación con otras herramientas

| Combinación | Para qué |
|-------------|----------|
| `smartctl` + `lsblk` | Ver qué discos existen y cuáles responden a SMART |
| `smartctl` + `dmesg` | Cruzar errores del kernel con el log del disco |
| `smartctl` + `mdadm` | Confirmar si el disco expulsado del RAID está fallando |
| `smartctl` + `df` | Relacionar el disco con el filesystem montado |
| `smartctl` + `jq` | Automatizar checks con salida JSON |
| `smartctl` + `diff` | Comparar atributos entre chequeos (tendencia) |
| `smartctl` + `cron` | Revisión periódica y alerta |

Ejemplo de tendencia: guardar los atributos de cada semana y comparar.

```bash
smartctl -A /dev/sda > /var/log/smart/sda-$(date +%Y%m%d).txt
diff /var/log/smart/sda-20260101.txt /var/log/smart/sda-20260201.txt
```

---

## 💡 Uno-liners imprescindibles

```bash
# Veredicto de todos los discos
for d in /dev/sd? /dev/nvme?n1; do smartctl -H "$d" 2>/dev/null | grep -i result; done

# Solo discos que NO están PASSED
for d in /dev/sd?; do smartctl -H "$d" 2>/dev/null | grep -qi "PASSED" || echo "REVISAR: $d"; done

# Atributos críticos de un disco
smartctl -A /dev/sda | grep -E "Reallocated|Pending|Uncorrectable|CRC"

# ¿Hay errores en el log del disco?
smartctl -l error /dev/sda | tail -5

# ¿Pasó el último test?
smartctl -l selftest /dev/sda | tail -3

# Desgaste de una SSD NVMe
smartctl -a /dev/nvme0n1 | grep -Ei "Percentage Used|Available Spare|Critical Warning"

# JSON: ¿el disco está sano?
smartctl -j -H /dev/sda | jq -r '.smart_status.passed'

# Disco detrás de MegaRAID
smartctl -a -d megaraid,0 /dev/sda
```

---

## ⚠️ Errores comunes

### 1. Interpretar PASSED como "disco nuevo"

`PASSED` solo significa que no cruzó el umbral de fallo. Un disco con 40 sectores reasignados puede seguir en `PASSED`. Revisar los atributos 5, 197, 198 y 199.

### 2. Ignorar `UDMA_CRC_Error_Count`

Un valor alto de CRC casi nunca es el disco: es el cable, el conector o el backplane. Reemplazar el disco no arregla un cable defectuoso.

### 3. Usar `smartctl` sobre el volumen de RAID

En RAID por hardware, `/dev/sda` es el volumen lógico, no el disco físico. Hace falta `-d megaraid,N`. Sin eso, el comando puede fallar o devolver datos del volumen.

### 4. Confundir `VALUE` con `RAW_VALUE`

`VALUE` es el valor normalizado (100 = mejor); `RAW_VALUE` es el contador crudo. Un `VALUE` de 100 con `RAW_VALUE` de 2048 en el atributo 5 significa que el fabricante todavía no considera crítico el valor, pero ya hay 2048 sectores reasignados.

### 5. Lanzar `-t long` en producción sin ventana

El test largo lee todo el disco y agrega carga. Puede degradar el rendimiento de la aplicación y, en discos que ya fallan, precipitar el problema. Programarlo.

### 6. Despertar discos dormidos en un NAS

`smartctl -a` puede sacar un disco de standby. Usar `-n standby` para no interrumpir el reposo.

### 7. Confiar en el código de salida 0

`smartctl -H` devuelve 0 cuando el veredicto es PASSED, aunque los bits 4-7 estén encendidos. Revisar la máscara completa o usar `-j`.

### 8. Olvidar que el disco puede no exponer SMART

Puentes USB baratos, controladores RAID propietarios y algunas VM no pasan los comandos SMART. Si `smartctl` no ve el disco, no es un problema de SMART: es de acceso al dispositivo.

---

## ✅ Buenas prácticas

- **Chequeo periódico, no solo cuando falla**: guardar los atributos y comparar tendencia.
- **Automatizar con `smartd`**: alerta por mail o por el canal de monitoreo antes de que el disco muera.
- **Leer los atributos, no solo el veredicto**: 5, 187, 197, 198, 199 y, en SSD, `Percentage Used`.
- **Separar disco de enlace**: CRC alto = cable; sectores reasignados = disco.
- **No condenar un disco por un solo chequeo**: un valor aislado importa menos que la tendencia.
- **Programar los tests largos**: ventana de mantenimiento, nunca en pico.
- **Documentar el mapeo de discos**: qué `/dev/sdX` corresponde a qué bahía y a qué RAID.
- **Tener el reemplazo listo**: SMART avisa con tiempo; el repuesto no debería comprarse de urgencia.

---

## 🔗 Referencias internas

- [`df`](df.md) — espacio en disco y filesystems montados
- [`du`](du.md) — consumo por directorio
- [`dmesg`](dmesg.md) — errores de disco y enlace en el kernel
- [`jq`](jq.md) — procesar la salida JSON de `smartctl -j`
- [`diff`](diff.md) — comparar atributos entre chequeos
- [`cron`](cron.md) — programar la revisión periódica
- [`scenario`](../scenarios/infrastructure/06-raid-degradation.md) — RAID degradado y reemplazo de disco
- [`scenario`](../scenarios/dahua/02-nvr-sin-disco.md) — NVR sin disco: detección y SMART
- [`dahua-troubleshooting`](dahua/dahua-troubleshooting.md) — diagnóstico de NVR Dahua
- [`dahua-nvr-ssh`](dahua/dahua-nvr-ssh.md) — acceso SSH al NVR
