# 🐧 sys-admin-guides

Guías de referencia + laboratorio Docker + escenarios prácticos para **administración de servidores Linux y redes**.

**Enfoque:** cada opción explicada, cada salida interpretada, uso real en troubleshooting, fallas y seguridad.

> ✅ *"Aprendo herramienta por herramienta, pero practico cómo se usan en conjunto."*

---

## 🚀 Empezar rápido

```bash
git clone https://github.com/lumusitech/learning-sys-admin-guides.git
cd learning-sys-admin-guides
```

### Modos de uso

| Modo | Ruta |
|------|------|
| 📚 **Aprendizaje clásico** | `guides/` → `labs/` → `scenarios/` |
| 🧪 **Modo producción** | `scenarios/` → `labs/` → `guides/` |
| ⚡ **Referencia rápida** | Abrir guía y copiar comando |

---

## 🧱 Estructura

### `guides/` — guías por herramienta

Incluye herramientas de texto/datos (`awk` `sed` `grep` `find` `xargs`…), redes (`ip` `ss` `tcpdump` `nmap` `iptables`…), sistema (`systemd` `journalctl`) e infraestructura (nginx, backups, segmentación de red, servidor de producción).

[Ver índice →](guides/README.md)

### `labs/` — archivos de práctica + laboratorio Docker

Logs de ejemplo (`auth.log`, `nginx_access.log`, `firewall.log`…) y **5 compose files** para practicar sin riesgo: servicios funcionando, rotos, desde cero, escenarios de red y servicios vulnerables.

[Ver laboratorio →](labs/README.md)

### `scenarios/` — problemas reales que combinan herramientas

Incidentes agrupados por dominio: **networking**, **system**, **security**, **web**, **infrastructure**. Cada uno resuelve un problema con pipes y se integra con el lab.

[Ver escenarios →](scenarios/README.md)

### `concepts/` — patrones de pensamiento de sysadmin

Guías conceptuales sobre cómo pensar como administrador de sistemas: patrones normales vs anómalos, lectura de logs, latencia vs pérdida, errores comunes.

[Ver conceptos →](concepts/)

---

## 🧠 Filosofía

- **No solo comandos:** interpretación de outputs (columnas, flags, estados, errores)
- **No solo teoría:** datos reales (logs) y laboratorio reproducible (Docker)
- **No solo "seguridad":** también fallas reales, performance y recuperación
- **Pensamiento real de sysadmin:** pipes y troubleshooting

---

## 🧪 Cómo aprender

### Ruta A — herramienta por herramienta

1. Leer guía en `guides/`
2. Probar con logs en `labs/`
3. Aplicar en `scenarios/`

### Ruta B — modo incidente

1. Elegir escenario en `scenarios/`
2. Usar logs del `labs/`
3. Volver a `guides/` para entender las herramientas

---

## 💡 Diferencial

| Este repo NO es | Este repo ES |
|----------------|--------------|
| Solo cheat sheet | Handbook de sysadmin |
| Solo teoría | Laboratorio reproducible |
| Herramientas aisladas | Simulador de incidentes reales |
| Comandos sin contexto | Cada salida interpretada |

---

## ✅ Licencia

MIT
