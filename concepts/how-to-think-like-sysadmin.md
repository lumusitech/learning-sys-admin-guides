
# Cómo pensar como un sysadmin — Patrones de diagnóstico

## 🧠 ¿Qué es?

Pensar como un sysadmin implica identificar rápidamente qué comportamiento es normal y cuál es anómalo, y reducir el problema eliminando hipótesis incorrectas de forma sistemática.

La diferencia entre un principiante y un sysadmin experimentado no es el conocimiento de comandos, sino la capacidad de interpretar señales del sistema.

---

## 🎯 ¿Por qué importa?

- Reduce el tiempo de diagnóstico
- Evita cambios innecesarios o peligrosos
- Permite identificar patrones de fallo repetitivos
- Mejora la capacidad de respuesta ante incidentes

Un diagnóstico incorrecto genera más downtime que el problema original.

---

## 🧩 Conceptos clave

### Normal vs anómalo

Un sysadmin no mira valores absolutos, sino patrones:

- ¿Este comportamiento es esperado?
- ¿Cambió respecto a antes?
- ¿Es sostenido o puntual?

---

### Señales del sistema

El sistema siempre deja pistas:

- uso de CPU
- consumo de memoria
- I/O de disco
- latencia de red
- logs

Interpretar estas señales correctamente es la base del diagnóstico.

---

### Reducción del problema

Diagnosticar es descartar hipótesis:

- ¿es la red?
- ¿es la aplicación?
- ¿es el sistema?
- ¿es un cambio reciente?

Cada paso elimina una clase completa de causas.

---

## 🔄 Cómo encaja en el sistema

Este modelo mental se aplica en todas las capas:

- sistema operativo → procesos, memoria, disco
- red → conectividad, latencia, pérdida
- aplicaciones → errores, logs, comportamiento
- infraestructura → DNS, balanceadores, firewall

---

## ⚠️ Errores comunes

- Saltar directo a soluciones sin diagnosticar
- Cambiar múltiples variables al mismo tiempo
- Ignorar patrones históricos (baseline)
- Depender solo de comandos sin interpretar resultados
- Sobrecargar el diagnóstico con herramientas innecesarias

---

## 🧠 Modelo mental de diagnóstico

Un sysadmin trabaja así:

1. Observa el síntoma
2. Identifica qué capa podría estar fallando
3. Verifica lo más simple primero
4. Reduce el problema paso a paso
5. Confirma hipótesis con evidencia

El objetivo no es "probar cosas", sino **entender el sistema**.

---

## 📊 Patrones normales vs anómalos (referencia conceptual)

(ACÁ DEJÁS TUS TABLAS — son excelentes ✅)

---

## 📜 Lectura de logs (conceptual)

Los logs no se leen línea por línea, se interpretan por patrones:

- repetición
- frecuencia
- correlación temporal
- origen (IP, servicio, usuario)

Un solo error no es problema. Un patrón repetido sí.

---

## 🔗 Ver también

- [`guides/systemd_journalctl.md`](../guides/systemd_journalctl.md)
- [`guides/ip_ss.md`](../guides/ip_ss.md)
- [`guides/ping_traceroute.md`](../guides/ping_traceroute.md)
- [`guides/tcpdump.md`](../guides/tcpdump.md)
- [`scenarios/system/01-top-processes-and-resources.md`](../scenarios/system/01-top-processes-and-resources.md)
