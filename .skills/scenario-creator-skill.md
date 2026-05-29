# Skill: Scenario Creator

## Rol

Creás escenarios SRE para el repo `learning-sys-admin-guides` siguiendo el estándar del proyecto. Cada escenario debe pasar `pnpm lint:md` sin errores.

---

## Plantilla completa

`````md
# 🧩 Escenario: <título claro y accionable>

**Dominio:** networking / system / security / web / infrastructure
**Nivel:** 🟢 Básico | 🟡 Intermedio | 🔴 Avanzado
**Herramientas:** `<tool1>`, `<tool2>`, `<tool3>`
**Archivos:** `labs/<archivo1>`, `labs/<archivo2>`

---

## 🎯 Problema

Descripción breve del incidente real.

Debe responder:

- qué está pasando;
- qué impacto tiene;
- qué hay que diagnosticar o resolver.

---

## ⚡ Quick command (SRE)

```bash
<comando rápido, robusto y representativo>
```

---

## ✅ Salida esperada

- señal observable 1
- señal observable 2
- señal observable 3

Interpretación:

- patrón → significado operativo
- patrón → significado operativo

---

## 🧠 Diagnóstico

Explicar el modelo mental del problema.

Patrones clave:

- patrón → causa probable
- patrón → causa probable

👉 Frase final que resuma el criterio SRE.

---

## 🛠️ Procedimiento (runbook)

### 1. Primer chequeo

```bash
comando
```

### 2. Segundo chequeo

```bash
comando
```

### 3. Confirmar hipótesis

```bash
comando
```

---

## 🧯 Mitigación

Si se confirma el problema:

Verificar:

```bash
comando seguro de verificación
```

Acción:

```bash
comando de mitigación preferido
```

Rollback:

```bash
comando para volver atrás
```

Casos comunes:

- caso → causa

---

## ✅ Interpretación

- resultado → conclusión
- resultado → conclusión

---

## 🐧 Variante Alpine (OpenRC)

> Incluir solo si el escenario usa `systemctl`, `journalctl`, `apt`, `ufw`, `fallocate`, `bc`, `watch` o `column`.

### Variante A — solo systemctl

```bash
# Debian:                          # Alpine:
systemctl restart <svc>             rc-service <svc> restart
```

### Variante B — systemctl + journalctl

```bash
# Debian:                          # Alpine:
systemctl restart <svc>             rc-service <svc> restart
journalctl -u <svc> -n 20           logread | grep <svc>
```

### Variante C — provisionamiento (apt + ufw + systemctl)

```bash
# Debian:                     # Alpine:
apt update                     apk update
apt install -y <pkg>           apk add <pkg>
ufw default deny incoming       iptables -P INPUT DROP
systemctl restart <svc>         rc-service <svc> restart
```

### Variante D — herramientas extra

```bash
apk add procps     # watch
apk add util-linux # column
apk add bc         # bc
```

---

## 🔗 Referencias

- [`awk`](../../guides/awk.md) — arrays asociativos y formateo
- [`sort`](../../guides/sort.md) + [`uniq`](../../guides/uniq.md) — frecuencias
- [`apk`](../../guides/apk.md) — Alpine Linux: gestor de paquetes (si usaste Variante C)
- [`openrc`](../../guides/openrc.md) — Alpine Linux: servicios (si usaste Variante A/B/C)
- [`busybox`](../../guides/busybox.md) — Alpine Linux: toolchain mínima (si usaste Variante B)

`````

---

## Naming

```txt
scenarios/<dominio>/NN-short-kebab-name.md
```

Ejemplos:

```txt
scenarios/system/09-cve-kernel-panic.md
scenarios/networking/09-arp-spoofing.md
scenarios/web/03-rate-limit-bypass.md
```

Usar el siguiente número disponible en el dominio.

---

## Checklist antes de commit

```txt
[ ] título con emoji 🧩
[ ] headers con emoji estándar: 🎯, ⚡, ✅, 🧠, 🛠️, 🧯, 🐧, 🔗
[ ] metadata: Dominio, Nivel, Herramientas, Archivos
[ ] quick command robusto (inline code o ```bash, útil en incidente)
[ ] salida esperada con interpretación
[ ] diagnóstico con patrones clave
[ ] procedimiento con pasos numerados
[ ] mitigación con verificar / acción / rollback
[ ] interpretación final
[ ] 🐧 Variante Alpine si el escenario usa systemctl/journalctl/apt/ufw/bc/watch/column
[ ] referencias en formato: [`name`](../../path/name.md) — descripción
[ ] sin bloques "Explicación paso a paso"
[ ] sin links vacíos
[ ] sin comandos peligrosos como primera acción
[ ] pnpm lint:md → 0 errores
```

---

## Cuándo agregar bloque Alpine

| ¿Usa alguno de estos? | ¿Bloque Alpine? | Variante |
|-----------------------|-----------------|----------|
| `systemctl` (solo en mitigación) | Sí | A |
| `systemctl` + `journalctl` | Sí | B |
| `apt` + `ufw` + `systemctl` | Sí | C |
| `watch`, `column`, `bc` | Sí | D (combinar con A/B/C) |
| Solo `grep`, `awk`, `sort`, `ps`, `ss`, `df`... | **No** | — |
