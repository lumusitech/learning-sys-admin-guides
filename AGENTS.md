# AGENTS.md — Sistema de aprendizaje sysadmin

## 🎯 Propósito del proyecto

Sistema de aprendizaje práctico para administración de servidores Linux y redes. No es una colección de cheatsheets: es un framework de entrenamiento con progresión didáctica, práctica real y un modelo mental consistente.

**Frase guía:**
> No estamos coleccionando comandos. Estamos construyendo un sistema de entrenamiento para pensar como sysadmin/SRE.

---

## 📁 Estructura del repositorio

```text
.
├── concepts/          # Modelos mentales y fundamentos (¿cómo pensar?)
├── guides/            # Herramientas explicadas en profundidad (¿cómo funciona?)
├── labs/              # Entornos Docker para práctica (¿dónde practicar?)
├── scenarios/         # Problemas reales resueltos paso a paso (¿cómo resolver?)
│   ├── system/        # Procesos, memoria, disco, I/O, logs, cron, Docker
│   ├── networking/    # SSH brute force, DNS, latencia, firewalls, ARP, DHCP, MTU
│   ├── security/      # IPs maliciosas, SUID, claves SSH, cron sospechoso, logs
│   ├── web/           # Rendimiento, 5xx, slow SQL, rate limit, CORS, WebSocket
│   └── infrastructure/# Migración, PYME, DR, TLS, NFS, RAID, proyecto integrador
├── reference/         # Tablas y mapas de consulta rápida (ayuda memoria)
├── scripts/           # Scripts de validación
├── .github/workflows/ # CI/CD
└── .skills/           # Skills para creación de contenido
```

**Flujo pedagógico:**

```text
concepts → guides → labs → scenarios
entender → aprender → practicar → aplicar
```

---

## 📊 Estado actual

| Categoría | Cantidad |
|-----------|:--------:|
| Guías | 50 |
| Escenarios | 48 |
| Entornos Docker (labs) | 12 |
| Conceptos | 5 |
| Referencias rápidas | 6 |
| Proyecto integrador | 1 |

## 🔄 Última sesión (jul-2026)

- PR #56: lychee en CI
- PR #57: 🧑‍🏫 Modo docente en todos los escenarios
- PR #58: `guides/cron.md` (nueva guía)
- PR #59: `.skills/` → `.opencode/skills/` (skills invocables con `skill()`)
- `.opencode/instructions.md` creado (init prompt de sesión)
- Contadores: 49 → 50 guías
- Pendientes bajos para próxima sesión (ver TODO.md)

---

## 🛠️ Comandos de desarrollo

```bash
pnpm lint:md           # Markdown lint
pnpm lint:md:fix       # Corregir automáticamente
pnpm lint:sh           # ShellCheck en scripts/*.sh
pnpm validate:sre      # Validación SRE (detecta grep -P, bashismos)
pnpm validate          # Todo lo anterior
```

---

## 🧩 Skills disponibles (invocables con `skill()`)

Los skills del proyecto están en `.opencode/skills/<nombre>/SKILL.md`. Opencode los carga automáticamente al invocar `skill("<nombre>")`.

| Skill | Descripción |
|-------|-------------|
| `sysadmin-guides` | Skill principal: mantiene y expande el repo entero (plantillas, convenciones, workflow Git) |
| `scenario-creator` | Crea escenarios SRE con plantilla estándar |
| `reference-creator` | Crea tablas de referencia rápida |
| `concepts-creator` | Crea documentos conceptuales (modelos mentales) |
| `web-labs-creator` | Crea entornos Docker para labs web (CORS, WebSocket) |

Además, `.opencode/instructions.md` se carga al inicio de cada sesión (resumen ejecutivo del proyecto).

**Regla:** Cargar el skill relevante con `skill("<nombre>")` antes de crear contenido nuevo.

---

## 📝 Convenciones de contenido

### Plantilla de guía (`guides/`)

```md
# <tool> — Guía completa

**Nivel:** 🟢 Básico | 🟡 Intermedio | 🔴 Avanzado
**Archivos de práctica:** `labs/...`
**Ver escenarios relacionados:** [`scenario`](../scenarios/dominio/NN-nombre.md)

---

## ⚡ Quick command

`comando mínimo representativo`

> ⚠️ Notas de compatibilidad si aplica (Alpine, BusyBox).

---

## ⚡ Quick run

```bash
comando práctico para probar rápido
```

---

## 📑 Índice (si 4+ secciones)

1. [¿Qué es <tool>?](#qué-es-tool)
2. [Modelo mental](#modelo-mental)
3. ...

---

## 🧠 ¿Qué es <tool>?

## 🧠 Modelo mental

## 📝 Sintaxis básica

## 🔑 Salida clave

## 🎛️ Opciones principales

## 📋 Patrones de uso

## 🔍 Uso en troubleshooting

## 🛠️ Combinación con otras herramientas

## 💡 Uno-liners imprescindibles

## ⚠️ Errores comunes

## ✅ Buenas prácticas

## 🔗 Referencias internas

```md

### Plantilla de escenario (`scenarios/`)

```md
# 🧩 Escenario: <título claro y accionable>

**Dominio:** networking / system / security / web / infrastructure
**Nivel:** 🟢 Básico | 🟡 Intermedio | 🔴 Avanzado
**Herramientas:** `<tool1>`, `<tool2>`
**Archivos:** `labs/<archivo1>`, `labs/<archivo2>`

---

## 🎯 Problema

## ⚡ Quick command (SRE)

## ✅ Salida esperada

Interpretación:

## 🧠 Diagnóstico

## 🛠️ Procedimiento (runbook)

### 1. ...

### 2. ...

### 3. ...

## 🧯 Mitigación

Verificar:

Acción:

Rollback:

## ✅ Interpretación

## 🐧 Variante Alpine (OpenRC) — solo si usa systemctl/journalctl/apt/ufw/bc

## 🔗 Referencias
```

Ver `scenarios/_TEMPLATE.md` para la plantilla exacta.

### Plantilla de concepto (`concepts/`)

```md
# <Título> — <subtítulo>

## 🧠 ¿Qué es?

## 🎯 ¿Por qué importa?

## <sección de contenido>

## 🧠 Modelo mental

## 🔗 Ver también
```

### Plantilla de referencia (`reference/`)

Tablas de códigos/estados con interpretación para troubleshooting.

---

## 📛 Convenciones de naming

```text
Tipo         | Formato                            | Ejemplo
-------------|------------------------------------|----------------------------------------------
guides/      | `comando.md`                       | `awk.md`, `tcpdump.md`, `systemd_journalctl.md`
scenarios/   | `NN-short-kebab-name.md`           | `09-arp-spoofing.md`, `07-high-io-wait.md`
concepts/    | `kebab-name.md`                    | `how-to-think-like-sysadmin.md`
reference/   | `kebab-name.md`                    | `http-status-codes.md`, `troubleshooting-patterns.md`
labs/        | `docker-compose.<domain>-<name>.yml` | `docker-compose.web-cors.yml`
```

- Sin emojis en filenames.
- Sin números en `concepts/` ni `reference/`.
- Escenarios usan `NN` secuencial por dominio.

---

## 🔗 Formato de links

```md
- [`awk`](awk.md) — descripción breve                          # mismo directorio
- [`scenario`](../scenarios/system/01-nombre.md) — descripción  # subir a raíz, bajar
- [`curl`](../../guides/curl.md) — descripción                  # desde scenarios/ o concepts/
- [`name`](../../ruta/al/archivo.md) — descripción              # formato estándar
```

**Reglas:**

- Usar `./` o directamente `filename.md` para archivos en el mismo directorio.
- Usar `../` para subir un nivel (nunca para referenciar hermanos).
- Siempre incluir descripción breve después del link.
- Formato correcto: `` [`nombre`](ruta/nombre.md) — descripción breve ``
- Formato incorrecto: `[ruta/nombre.md]()`, `[../../ruta/algo.md]()`

---

## 🔒 Portabilidad (reglas SRE)

- Compatible con POSIX (`sh`).
- Funciona en BusyBox / Alpine Linux.
- No usa flags GNU-only (`grep -P`, `sed -r`, `sort -V`, etc.).
- Sin bashismos (`<()`, arrays, `${!var}`, `[[ ]]`, etc.).
- Preferir herramientas estándar: `ps`, `awk`, `grep`, `ss`, `ip`, `df`, `du`, `free`, `top`, `dig`, `curl`, `ping`, `iptables`, `nc`.

**Validación automática en CI:** `scripts/validate_sre.sh` detecta `grep -P`, `grep -oP`, process substitution `<(`.

---

## 🔄 Git workflow

### Crear rama

```bash
git checkout -b feat/<scope>-<nombre>
```

### Commit

```bash
git commit -m "feat(system): add zombie process troubleshooting scenario"
git commit -m "refactor: move DNS scenarios from web to networking"
git commit -m "fix(docs): correct broken scenario reference links"
```

### PR

- Una feature por PR.
- Un scenario por rama/PR.
- Refactors en PR separada.

### Cleanup

```bash
git checkout main && git pull
git branch -d feat/<nombre>
git push origin --delete feat/<nombre>
```

---

## 🚨 CI/CD

Archivo: `.github/workflows/sre-validate.yml`

```yaml
- Ejecuta en push/PR a main
- Instala pnpm, Node 20
- pnpm install
- pnpm validate  # lint:md + lint:sh + validate:sre
```

---

## ✅ Checklist antes de commit (guías)

- [ ] metadata: Nivel + Archivos de práctica + Ver escenarios
- [ ] Quick command (inline code)
- [ ] Quick run (bloque ```bash)
- [ ] Índice (si 4+ secciones)
- [ ] ¿Qué es <tool>?
- [ ] Modelo mental
- [ ] Sintaxis básica
- [ ] Salida clave
- [ ] Opciones principales
- [ ] Uso en troubleshooting
- [ ] Combinación con otras herramientas
- [ ] Uno-liners imprescindibles
- [ ] Errores comunes
- [ ] Buenas prácticas
- [ ] Referencias en formato estándar
- [ ] Headers con emoji estándar: ⚡, 🧠, 📝, 🔑, 🎛️, 📋, 🔍, 🛠️, 💡, ⚠️, ✅, 🔗
- [ ] `pnpm lint:md` → 0 errores

---

## ✅ Checklist antes de commit (escenarios)

- [ ] Título con `🧩`
- [ ] Metadata: Dominio, Nivel, Herramientas, Archivos
- [ ] Quick command robusto
- [ ] Salida esperada con interpretación
- [ ] Diagnóstico con patrones clave
- [ ] Procedimiento con pasos numerados
- [ ] Mitigación con Verificar / Acción / Rollback
- [ ] Interpretación final
- [ ] Variante Alpine si usa systemctl/journalctl/apt/ufw/bc
- [ ] Referencias en formato estándar
- [ ] Sin bloques `### Explicación paso a paso`
- [ ] Sin links vacíos
- [ ] Sin comandos peligrosos como primera acción
- [ ] `pnpm lint:md` → 0 errores

---

## 🐧 Variante Alpine

Incluir solo si el escenario usa `systemctl`, `journalctl`, `apt`, `ufw`, `fallocate`, `bc`, `watch` o `column`.

| Variante | Cuándo usarla | Comandos Alpine |
|----------|--------------|-----------------|
| A | Solo `systemctl` | `rc-service <svc> restart` |
| B | `systemctl` + `journalctl` | `rc-service` + `logread` |
| C | `apt` + `ufw` + `systemctl` | `apk add`, `iptables`, `rc-service` |
| D | `watch`, `column`, `bc` | `apk add procps util-linux bc` |

---

## 🧠 Modelo mental del repo

```text
guide   → qué hace un comando
scenario → cuándo usarlo para resolver un problema
lab     → dónde practicarlo
```

Cada archivo debe responder:

1. ¿Qué problema resuelve?
2. ¿Qué comando uso primero?
3. ¿Qué salida espero?
4. ¿Cómo interpreto esa salida?
5. ¿Qué hago si está mal?
6. ¿Cómo vuelvo atrás?
7. ¿Dónde sigo aprendiendo?

---

## 🐞 Links rotos conocidos

✅ **Links corregidos en PR:** `../` → `./` en 10 guías. `fuser.md` y `kill.md` creados. `tmux.md` referencia corregida a `01-migrate-to-production.md`.

✅ **Índice actualizado en PR:** `guides/README.md` ahora lista las 49 guías, incluyendo `tmux.md`, `redirections.md`, `kill.md`, `fuser.md` y las secciones de infraestructura de red y Dahua.

---

## 🎯 Proyecto integrador

`scenarios/infrastructure/07-integrative-project.md` — 5 fases, 4-6 horas.
Entorno Docker: `labs/docker-compose.integrative.yml` (7 servicios).

---

## 📋 Regla de cierre de sesión

**Siempre** mostrar al final de la sesión el cuadro de prioridades actualizado después de hacer un PR o completar una tarea, para que el usuario decida qué sigue. Si hay pendientes, mostrar tabla priorizada. Si no hay más pendientes, decirlo.

---

## 📚 Progresión de aprendizaje recomendada

1. Leer `concepts/how-to-think-like-sysadmin.md` (modelo mental)
2. Leer `concepts/baseline-and-anomalies.md` (baseline)
3. Elegir un escenario básico, ejecutar comandos, abrir guías on demand
4. Labs de calentamiento: `broken`, `performance`, `network`
5. Escenarios en espiral de complejidad
6. Proyecto integrador
