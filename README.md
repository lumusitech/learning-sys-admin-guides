# 🐧 sys-admin-guides

Guías de referencia + laboratorio Docker + escenarios prácticos para **administración de servidores Linux y redes**.
Enfoque: **cada opción explicada**, **cada salida interpretada**, y **casos reales** de troubleshooting, fallas y seguridad.

> ✅ "Aprendo herramienta por herramienta, pero practico como se usa en conjunto"
> Este repo está pensado exactamente así: primero dominas herramientas (guides), luego practicás con datos y un lab (labs), y finalmente resolvés incidentes reales (scenarios).

---

## 🚀 Empezar rápido

```bash
git clone https://github.com/lumusitech/learning-sys-admin-guides.git
cd learning-sys-admin-guides
```

Elegí tu modo (según tu objetivo):

- **📚 Referencia por herramienta**: empezá por el índice de guías → [`guides/`](guides/README.md)
- **🧪 Practicar sin riesgo (Docker lab)**: levantá el laboratorio → [`labs/`](labs/README.md)
- **🧩 Resolver problemas reales (pipes)**: hacé escenarios → [`scenarios/`](scenarios/README.md)

---

## 🧭 Navegación (índices)

- [📚 Guías por herramienta](guides/README.md)
- [🧪 Laboratorio Docker + dataset](labs/README.md)
- [🧩 Escenarios prácticos (pipes)](scenarios/README.md)

---

## 🧱 ¿Qué hay dentro?

### `guides/` — guías por herramienta (base sólida)

Incluye herramientas de texto/datos (`awk`/`sed`/`grep`/`find`/`xargs`...), redes (`ip`/`ss`/`tcpdump`/`nmap`/`iptables`...), sistema (`systemd`/`journalctl`) y también guías de infra y producción (nginx, backups, segmentación de red, servidor de producción, etc.).

[Ver índice completo →](guides/README.md)

### `labs/` — dataset + laboratorio Docker (práctica sin romper nada)

Trae logs/outputs de ejemplo y un laboratorio Docker con **5 compose files** distintos: servicios funcionando, servicios rotos, servidores desde cero, escenarios de red y servicios vulnerables. Incluye prácticas sugeridas (brute force, port scan, capturas, túneles, etc.).

[Ver laboratorio →](labs/README.md)

### `scenarios/` — problemas reales (cómo se usa todo junto)

Escenarios agrupados por dominio: **networking**, **system**, **security**, **web**, **infrastructure**. Cada uno resuelve un incidente real combinando herramientas con pipes. Se integra con el lab y las guías.

[Ver escenarios →](scenarios/README.md)

---

## 🧠 Filosofía (por qué este repo es distinto)

- **No solo comandos**: interpretación de columnas, flags, estados, errores.
- **No solo teoría**: datos reales (logs/outputs) y lab reproducible.
- **No solo "seguridad"**: también fallas reales, performance y recuperación.
- **Pipes de sysadmin**: `grep | awk | sort | uniq` para reportes, diagnósticos, mitigación.

---

## 🧪 Ruta recomendada (sin obligarte a un "path" rígido)

**Ruta A — herramienta por herramienta (tu estilo)**

1. Elegí una herramienta en `guides/`
2. Practicá con un archivo de `labs/`
3. Cerrá con un escenario que la combine

**Ruta B — por incidente (modo producción)**

1. Elegí un escenario en `scenarios/`
2. Ejecutá/analizá con datos de `labs/`
3. Volvé a las guías para profundizar la herramienta que te faltó

---

## ✅ Licencia

MIT
