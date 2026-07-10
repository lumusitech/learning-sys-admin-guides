# Contributing

Gracias por tu interés en contribuir a **sys-admin-guides**, un sistema de aprendizaje práctico para administración de servidores Linux y redes.

**Frase guía del proyecto:** No estamos coleccionando comandos. Estamos construyendo un sistema de entrenamiento para pensar como sysadmin/SRE.

---

## 📋 Contenido

- [Cómo contribuir](#cómo-contribuir)
- [Antes de empezar](#antes-de-empezar)
- [Convenciones de contenido](#convenciones-de-contenido)
- [Git workflow](#git-workflow)
- [Estándares de calidad](#estándares-de-calidad)
- [Validación local](#validación-local)
- [Pull Request checklist](#pull-request-checklist)

---

## Cómo contribuir

1. Hacé un fork del repositorio.
2. Cread una rama con el nombre descriptivo:
   - `feat/guide-<nombre>` — nueva guía
   - `feat/scenario-<nombre>` — nuevo escenario
   - `feat/concept-<nombre>` — nuevo concepto
   - `feat/reference-<nombre>` — nueva referencia
   - `feat/lab-<nombre>` — nuevo laboratorio Docker
   - `fix/<descripción>` — corrección
   - `refactor/<descripción>` — reestructuración
3. Trabajá en tu rama.
4. Asegurate de pasar todas las validaciones locales.
5. Abrí un Pull Request contra `main`.

---

## Antes de empezar

Leé los siguientes archivos para entender el proyecto:

- [`README.md`](README.md) — visión general, roadmap de aprendizaje
- [`AGENTS.md`](AGENTS.md) — convenciones detalladas, plantillas, workflow
- [`TODO.md`](TODO.md) — pendientes y prioridades actuales
- `scenarios/_TEMPLATE.md` — plantilla de escenario

---

## Convenciones de contenido

### Naming

| Tipo         | Formato                            | Ejemplo                            |
|-------------|------------------------------------|------------------------------------|
| guides/      | `comando.md`                       | `awk.md`, `tcpdump.md`            |
| scenarios/   | `NN-short-kebab-name.md`           | `09-arp-spoofing.md`              |
| concepts/    | `kebab-name.md`                    | `how-to-think-like-sysadmin.md`   |
| reference/   | `kebab-name.md`                    | `http-status-codes.md`            |
| labs/        | `docker-compose.<domain>-<name>.yml` | `docker-compose.web-cors.yml`    |

- Sin emojis en filenames.
- Sin números en `concepts/` ni `reference/`.
- Escenarios usan `NN` secuencial por dominio.

### Formato de links

```md
[`nombre`](ruta/nombre.md) — descripción breve
```

- `./` o nombre directo para mismo directorio.
- `../` para subir un nivel (nunca para hermanos).
- Siempre incluir descripción breve después del link.

### Headers con emoji estándar

| Emoji | Sección               |
|-------|-----------------------|
| ⚡    | Quick command / run   |
| 🧠    | Modelo mental         |
| 📝    | Sintaxis básica       |
| 🔑    | Salida clave          |
| 🎛️   | Opciones principales  |
| 📋    | Patrones de uso       |
| 🔍    | Troubleshooting       |
| 🛠️   | Combinación           |
| 💡    | Uno-liners            |
| ⚠️    | Errores comunes       |
| ✅    | Buenas prácticas      |
| 🔗    | Referencias           |

### Portabilidad (SRE)

Todo contenido debe ser compatible con:

- POSIX (`sh`)
- BusyBox / Alpine Linux
- Sin flags GNU-only (`grep -P`, `sed -r`, `sort -V`)
- Sin bashismos (`<()`, arrays, `${!var}`, `[[ ]]`)
- Preferir herramientas estándar: `ps`, `awk`, `grep`, `ss`, `ip`, `df`, `du`, `free`, `top`, `dig`, `curl`, `ping`, `iptables`, `nc`

---

## Git workflow

### Commits

Usar formato [Conventional Commits](https://www.conventionalcommits.org/):

```bash
git commit -m "feat(scenario): add zombie process troubleshooting scenario"
git commit -m "fix(docs): correct broken reference links in scenario 07"
git commit -m "refactor: move DNS scenarios from web to networking"
git commit -m "docs: update README counters after Sprint 4"
```

### Pull Requests

- Una feature por PR.
- Un escenario por rama/PR (excepción: sprints coordinados).
- Refactors en PR separada.
- El título del PR debe describir el cambio.
- Incluir en la descripción: qué cambia, por qué, y qué validación pasó.

### Cleanup

```bash
git checkout main && git pull
git branch -d feat/<nombre>
git push origin --delete feat/<nombre>
```

---

## Estándares de calidad

### Para guías

Cada guía debe incluir:

- ⚡ Quick command + Quick run
- 🧠 Modelo mental de la herramienta
- 📝 Sintaxis básica con ejemplos
- 🔑 Explicación de la salida clave
- 🎛️ Opciones principales relevantes
- 🔍 Uso en troubleshooting
- 🛠️ Combinación con otras herramientas
- 💡 Uno-liners imprescindibles
- ⚠️ Errores comunes
- ✅ Buenas prácticas
- 🔗 Referencias internas a escenarios y labs relacionados

### Para escenarios

Cada escenario debe incluir:

- Título con 🧩
- Metadata (dominio, nivel, herramientas, archivos)
- ⚡ Quick command SRE
- ✅ Salida esperada con interpretación
- 🧠 Diagnóstico estructurado
- 🛠️ Procedimiento numerado (runbook)
- 🧯 Mitigación (verificar / acción / rollback)
- ✅ Interpretación final
- 🐧 Variante Alpine solo si usa systemctl/journalctl/apt/ufw
- 🔗 Referencias en formato estándar
- Sin bloques `### Explicación paso a paso`

### Para laboratorios Docker

Cada lab debe:

- Usar imágenes Alpine cuando sea posible
- Exponer puertos documentados
- Incluir fallas configurables (para labs "broken")
- Tener un script de sanity check o instrucciones de verificación

---

## Validación local

```bash
pnpm install
pnpm lint:md        # Markdown lint
pnpm lint:sh        # ShellCheck en scripts/*.sh
pnpm validate:sre   # Validación SRE (bashismos, grep -P)
pnpm validate       # Todo lo anterior
```

### CI/CD

Cada push/PR ejecuta automáticamente `pnpm validate` mediante GitHub Actions (`.github/workflows/sre-validate.yml`). El PR no se aprueba si falla la validación.

---

## Pull Request checklist

Antes de abrir un PR, verificá:

- [ ] `pnpm validate` pasa sin errores
- [ ] Todos los links son válidos (internos y externos)
- [ ] Los comandos funcionan en Alpine/BusyBox
- [ ] Los contadores en README.md y AGENTS.md están actualizados
- [ ] No hay bashismos ni flags GNU-only
- [ ] No hay archivos secrets o credenciales en el commit
- [ ] La rama está actualizada con main
- [ ] El título y descripción del PR son descriptivos

---

## Preguntas

Si tenés dudas, abrí un [issue](https://github.com/lumusitech/learning-sys-admin-guides/issues).
