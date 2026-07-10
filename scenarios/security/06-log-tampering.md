# 🧩 Escenario: Manipulación de logs — ocultación de evidencia

**Dominio:** security
**Nivel:** 🔴 Avanzado
**Herramientas:** `lsattr`, `chattr`, `stat`, `journalctl`, `find`, `grep`
**Archivos:** Sistema en vivo

---

## 🎯 Problema

Durante una respuesta a incidentes o auditoría de seguridad, se descubre que los archivos de log del sistema han sido manipulados: logs truncados, entradas eliminadas, timestamps alterados, o archivos borrados. Esto indica que alguien intentó cubrir rastros de actividad maliciosa. La integridad de los logs es fundamental para forense y cumplimiento normativo, por lo que cualquier alteración debe investigarse de inmediato.

---

## ⚡ Quick command (SRE)

```bash
stat /var/log/auth.log /var/log/syslog /var/log/nginx/access.log 2>/dev/null | grep -E "File:|Modify:|Change:"
```

---

## ✅ Salida esperada

- fechas de modificación (Modify) que no coinciden con la rotación esperada
- fechas de cambio de metadatos (Change) posteriores a la última escritura legítima
- archivos de log con tamaño 0 o muy pequeño para el período esperado
- gaps temporales en los logs (períodos sin registros)
- atributos inusuales en archivos de log (`i` immutable, `a` append-only)

Interpretación:

- `Modify` reciente pero log vacío → alguien borró el contenido
- `Change` posterior a `Modify` → metadatos alterados (ej: `touch` para falsificar fecha)
- log con tamaño 0 → contenido eliminado intencionalmente
- gap temporal de horas sin registros → entradas eliminadas entre fechas
- atributo `i` (immutable) → alguien protegió el archivo contra modificaciones

---

## 🧠 Diagnóstico

Los atacantes manipulan logs para dificultar la investigación. Las técnicas comunes incluyen: truncar archivos (`> /var/log/auth.log`), eliminar archivos, usar `touch` para alterar timestamps, y establecer atributos de protección. Los gaps temporales en logs son la señal más reveladora: un sistema activo siempre genera logs.

Patrones clave:

- log vacío o truncado en fecha reciente → alguien borró evidencia
- gap temporal en syslog/auth.log → entradas eliminadas
- timestamp de modificación anterior al de cambio de inode → `touch -t` usado para falsificar fecha
- atributo `i` (immutable) en log → protegido contra escritura (posible defensa o evidencia)
- log eliminado y recreado → evidencia de intento de ocultación
- `journalctl` vacío o con rango temporal incompleto → journal manipulado

👉 Un log que debería existir y no existe, o que tiene un gap temporal inexplicable, es evidencia de manipulación hasta que se demuestre lo contrario.

---

## 🛠️ Procedimiento (runbook)

### 1. Verificar la existencia y tamaño de logs críticos

```bash
ls -lh /var/log/auth.log /var/log/syslog /var/log/kern.log /var/log/nginx/access.log 2>/dev/null
wc -l /var/log/auth.log /var/log/syslog 2>/dev/null
```

### 2. Verificar metadatos y timestamps de los archivos de log

```bash
stat /var/log/auth.log /var/log/syslog 2>/dev/null
```

### 3. Buscar gaps temporales en los logs

```bash
# Verificar continuidad en auth.log
grep -E "^[A-Z][a-z]{2} [0-9]{2}" /var/log/auth.log | awk '{print $1, $2}' | sort -u

# Comparar con el rango esperado (últimos 7 días)
find /var/log -name "*.log" -mtime -7 -exec ls -lh {} \;
```

### 4. Verificar atributos de protección en los logs

```bash
lsattr /var/log/auth.log /var/log/syslog 2>/dev/null
```

### 5. Verificar si el journal de systemd está intacto

```bash
journalctl --disk-usage
journalctl --since "7 days ago" | wc -l
journalctl -b -1 2>/dev/null | tail -5  # último boot anterior
```

### 6. Buscar evidencia de manipulación en los logs

```bash
# Buscar comandos de manipulación de logs en los logs que sobrevivieron
grep -rE "> /var/log|rm.*log|truncate|chattr|touch.*log" /var/log/syslog /var/log/auth.log 2>/dev/null
```

---

## 🧯 Mitigación

Si se confirma manipulación de logs:

Verificar:

```bash
stat /var/log/auth.log /var/log/syslog
lsattr /var/log/auth.log /var/log/syslog
journalctl --since "1 hour ago" | tail -20
```

Acción:

```bash
# Proteger logs con atributo append-only (solo escritura al final)
chattr +a /var/log/auth.log /var/log/syslog

# Verificar que el atributo se aplicó
lsattr /var/log/auth.log
```

Mitigación adicional:

```bash
# Configurar envío de logs a servidor remoto (inalterable localmente)
# En /etc/rsyslog.conf:
# *.* @@logserver:514

# Si se detectó manipulación, restaurar logs desde backup
cp /backup/logs/auth.log.1 /var/log/auth.log

# Verificar si hay más archivos comprometidos
find /var/log -empty -name "*.log"
find /var/log -name "*.log" -mtime -1 -exec ls -lh {} \;
```

Rollback:

```bash
# Si se aplicó chattr +a por error, remover con:
chattr -a /var/log/auth.log /var/log/syslog
```

Casos comunes:

- atacante ejecuta `> /var/log/auth.log` → log truncado, evidencia eliminada
- atacante ejecuta `rm /var/log/syslog && touch /var/log/syslog` → log recreado vacío
- atacante usa `touch -t` para falsificar fecha → timestamp de modificación anterior a la intrusión
- usuario ejecuta `chattr +i /var/log/auth.log` → log protegido contra escritura (puede ser defensa legítima o bloqueo intencional)

---

## ✅ Interpretación

- log vacío con fecha de modificación reciente → contenido eliminado, investigar quién tuvo acceso
- gap temporal en auth.log → entradas eliminadas, comparar con journal
- atributo `i` o `a` en log → alguien protegió el archivo, verificar intención
- journal vacío pero syslog intacto → journal manipulado, syslog como fuente alternativa
- logs enviados a servidor remoto → verificar integridad en el servidor central
- todos los logs intactos sin manipulación → incidente descartado o atacante más sofisticado

---

## 🐧 Variante Alpine (OpenRC)

> Este escenario usa `journalctl` en la verificación del journal. Si el sistema usa OpenRC con `syslog-ng`, sustituir por `logread`.

### Variante B — systemctl + journalctl

```bash
# Debian:                                    # Alpine:
journalctl --disk-usage                       logread | wc -l
journalctl --since "7 days ago" | wc -l       logread | tail -20
journalctl -b -1                              logread | grep -c "last"
```

---

## 🧑‍🏫 Modo docente

**Preguntas:** ¿Cómo detectás que un archivo de log fue truncado o modificado? ¿Qué diferencia hay entre Modify time y Change time en stat? ¿Cómo protegés logs contra manipulación?

**Ejercicio:** Inspeccionar logs con stat para detectar manipulación, aplicar chattr +a a logs críticos, configurar rotación segura.

**Evaluación:** detección de manipulación por timestamps, protección con atributos extendidos, propuesta de logging remoto.

---

## 🔗 Referencias

- [`grep`](../../guides/grep.md) — filtrado de logs
- [`find`](../../guides/find.md) — búsqueda de archivos
- [`systemd_journalctl`](../../guides/systemd_journalctl.md) — journal de systemd
- [`scenarios/security/03-unauthorized-ssh-keys.md`](03-unauthorized-ssh-keys.md) — auditoría de accesos SSH
- [`scenarios/security/04-suspicious-cron.md`](04-suspicious-cron.md) — persistencia vía cron
