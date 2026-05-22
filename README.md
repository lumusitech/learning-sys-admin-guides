# 🐧 sys-admin-guides

[![SRE Validation](https://github.com/lumusitech/learning-sys-admin-guides/actions/workflows/sre-validate.yml/badge.svg?branch=main)](https://github.com/lumusitech/learning-sys-admin-guides/actions/workflows/sre-validate.yml)

Guías de referencia + laboratorio Docker + escenarios prácticos para **administración de servidores Linux y redes**.

**Enfoque:** cada opción explicada, cada salida interpretada, uso real en troubleshooting, fallas y seguridad.

**Quality Gates (CI):** [SRE Validation](.github/workflows/sre-validate.yml) — bloquea regresiones de portabilidad (`grep -P`, `\K`, `<(`).

> ✅ *"Aprendo herramienta por herramienta, pero practico cómo se usan en conjunto."*

---

## ✅ Garantías de portabilidad

- ✅ Compatible con POSIX (sh)
- ✅ Funciona en BusyBox / Alpine Linux
- ✅ No usa flags GNU-only (grep -P, etc.)
- ✅ Sin bashismos (<(), arrays, etc.)
- ✅ Pipelines reproducibles en entornos mínimos


---

## 🧭 ¿Por dónde empezar?

Este repo puede usarse de 3 formas:

### 🧑‍🎓 Aprendizaje progresivo (RECOMENDADO)
1. 👉 [concepts/](concepts/) — cómo pensar como sysadmin  
2. 👉 [guides/](guides/) — aprender cada herramienta  
3. 👉 [labs/](labs/) — practicar con datos reales  
4. 👉 [scenarios/](scenarios/) — resolver problemas reales  

---

### ⚡ Resolución rápida (modo producción)
1. 👉 [scenarios/](scenarios/) — encontrar problema  
2. ejecutar **Quick command (SRE)**  
3. validar con 👉 [labs/](labs/)  
4. profundizar en 👉 [guides/](guides/)  

---

### 📚 Referencia rápida
- abrir 👉 [guides/](guides/)  
- copiar comandos  
- adaptar al caso  

---

## 🧱 Estructura (navegación directa)

### 🧠 [concepts/](concepts/) — mindset de sysadmin
Patrones de pensamiento:
- cómo analizar logs
- cómo diagnosticar problemas
- cómo pensar como SRE

---

### 🛠️ [guides/](guides/) — herramientas
Aprender cada comando:
- grep, awk, sort, uniq, etc.
- redes (ip, ss, tcpdump)
- sistema (systemctl, journalctl)

---

### 🧪 [labs/](labs/) — práctica real
- logs de ejemplo
- entorno Docker
- datos reproducibles

---

### 🚨 [scenarios/](scenarios/) — problemas reales
Casos como:
- brute force SSH
- port scan
- errores web
- performance issues

👉 Cada uno incluye:
- problema real
- quick command (SRE)
- pipeline completo
- interpretación

---

## 🔄 Flujo de trabajo (muy importante)


```bash
problema → scenarios → quick command → labs → guides
```

## ✅ Licencia

MIT
