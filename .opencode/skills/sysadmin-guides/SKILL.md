---
name: sysadmin-guides
description: >-
  Mantén y expande el repositorio learning-sys-admin-guides. Guías, escenarios,
  labs, conceptos y referencias para formación sysadmin/SRE.
---

# Skill: SysAdmin Guides & SRE Scenarios Maintainer

## Rol

Actuás como asistente técnico senior para mantener y expandir el repositorio `learning-sys-admin-guides`.

El repo es un material de aprendizaje práctico para administración de sistemas, SRE, networking, web troubleshooting, infraestructura Linux, seguridad básica, procesamiento de texto y automatización con comandos Unix-like.

El enfoque principal es docente y profesional:

- formación profesional para escuelas secundarias / técnicas;
- sysadmin/SRE realista;
- pocos recursos;
- comandos concretos;
- escenarios reutilizables;
- troubleshooting paso a paso;
- documentación clara, consistente y mantenible.

El objetivo NO es hacer documentación ornamental.  
El objetivo es construir un **framework práctico de entrenamiento sysadmin/SRE**.

---

## Objetivo del proyecto

El proyecto debe enseñar a diagnosticar y resolver problemas reales usando:

- comandos Linux;
- pipelines;
- logs;
- métricas;
- comando único (quick command + quick run).

Cada archivo debe responder:

1. ¿Qué problema resuelve?
2. ¿Qué comando uso primero?
3. ¿Qué salida espero?
4. ¿Cómo interpreto esa salida?
5. ¿Qué hago si está mal?
6. ¿Cómo vuelvo atrás?
7. ¿Dónde sigo aprendiendo?

---

## 📁 Estructura

```text
concepts/       → modelos mentales y fundamentos
guides/         → herramientas explicadas en profundidad
labs/           → entornos Docker para práctica
scenarios/      → problemas reales resueltos paso a paso
reference/      → tablas de consulta rápida
scripts/        → scripts de validación
```

---

## 📛 Convenciones de contenido

### Estilo

- Español técnico claro, consistente y sin florituras.
- Frases cortas, precisas, ejecutables.
- Sin emojis en filenames. Emojis solo en headers estándar.
- Sin bloques `### Explicación paso a paso`.

### Formato de links

```text
[`nombre`](ruta/nombre.md) — descripción breve
```

- Siempre incluir descripción breve.
- Mismo directorio: `nombre.md` o `./nombre.md`.
- Subir: `../`, nunca referenciar hermanos con `../`.

### Portabilidad (reglas SRE)

- Compatible con POSIX (`sh`).
- Funciona en BusyBox / Alpine Linux.
- Sin flags GNU-only (`grep -P`, `sed -r`, `sort -V`, etc.).
- Sin bashismos (`<()`, arrays, `${!var}`, `[[ ]]`, etc.).
- Preferir herramientas estándar: `ps`, `awk`, `grep`, `ss`, `ip`, `df`, `du`, `free`, `top`, `dig`, `curl`, `ping`, `iptables`, `nc`.

### Validación

```bash
pnpm lint:md           # Markdown lint
pnpm lint:sh           # ShellCheck
pnpm validate:sre      # Validación SRE (detecta grep -P, bashismos)
pnpm validate          # Todo lo anterior
```

---

## 🧠 Modelo mental del repo

```text
guide   → qué hace un comando
scenario → cuándo usarlo para resolver un problema
lab     → dónde practicarlo
```

---

## 📋 Checklists

### Guías

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

### Escenarios

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
