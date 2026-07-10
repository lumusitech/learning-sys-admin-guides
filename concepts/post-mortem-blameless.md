
# Post-mortem blameless — Cultura de mejora continua

## 🧠 ¿Qué es?

Un post-mortem es un análisis estructurado de un incidente para entender qué pasó, por qué pasó y cómo evitar que vuelva a pasar. La palabra viene de la medicina forense: "después de la muerte", porque se hace cuando el incidente ya terminó.

La clave del post-mortem blameless es que el objetivo **no es encontrar al culpable, sino encontrar la causa sistémica**. Si el mismo error lo podría haber cometido cualquier persona del equipo, el problema no es la persona: es el sistema.

Los 5 porqués (5 Whys) son la técnica de análisis más usada: preguntar "¿por qué?"五次, cada respuesta lleva a una causa más profunda, hasta llegar a la causa raíz.

La diferencia entre un equipo que mejora y uno que repite los mismos errores es la calidad de sus post-mortems.

---

## 🎯 ¿Por qué importa?

Sin post-mortem blameless:

- los mismos incidentes se repiten
- el equipo oculta errores por miedo a represalias
- se culpa a personas en vez de corregir procesos
- el conocimiento se pierde cuando alguien se va del equipo
- no hay mejora continua, solo bomberos apagando incendios

Con post-mortem blameless:

- cada incidente deja al sistema más robusto que antes
- el equipo aprende sin miedo
- se documentan causas raíz y acciones correctivas
- se construye una cultura de confianza y mejora

---

## 📋 Estructura de un post-mortem

Un post-mortem efectivo responde siete preguntas:

### 1. Resumen

Una línea que describa el incidente en lenguaje no técnico.

> "El 10 de julio de 2026, el servidor de producción dejó de responder durante 45 minutos debido a un memory leak en la API."

### 2. Línea de tiempo

Cronología exacta del incidente (en UTC):

| Hora | Evento |
|------|--------|
| 14:02 | Deploy v3.2.1 a producción |
| 14:15 | Primeros 5xx reportados por monitoreo |
| 14:18 | Ingeniero notificado por alerta |
| 14:22 | Diagnóstico inicial: alta latencia en API |
| 14:30 | Memory leak identificado en nuevo endpoint |
| 14:35 | Decisión de rollback |
| 14:45 | Rollback completado, servicio restaurado |
| 14:47 | Confirmación de salud con `curl` |

### 3. Impacto

Qué consecuencias tuvo el incidente:

- **Duración**: 45 minutos
- **Usuarios afectados**: ~2.000 requests fallidos
- **Downtime**: Servicio no disponible 0%
- **Errores**: ~500 respuestas HTTP 502

### 4. Causa raíz (5 Whys)

El análisis con 5 porqués:

1. **¿Por qué el servidor dejó de responder?** → Porque la API consumió toda la RAM y OOM-killer mató el proceso.

2. **¿Por qué la API consumió toda la RAM?** → Porque el nuevo endpoint `/reports` no liberaba memoria después de generar reportes grandes.

3. **¿Por qué no liberaba memoria?** → Porque la librería de generación de PDF retenía referencias a objetos después de usarlos.

4. **¿Por qué no se detectó en staging?** → Porque staging tiene menos datos de prueba y los reportes eran pequeños.

5. **¿Por qué no había tests de carga con datos reales?** → Porque no existía un entorno de staging con datos completos ni tests de memoria.

**Causa raíz**: Falta de tests de carga y datos de prueba realistas en staging.

### 5. Acciones correctivas

Cada acción debe tener un responsable y una fecha.

| Acción | Responsable | Fecha |
|--------|-------------|-------|
| Agregar test de memoria para endpoint `/reports` | @dev1 | 15-jul |
| Crear dataset de staging con volumen de producción | @ops1 | 20-jul |
| Configurar alerta de memoria por pod > 80% | @ops1 | 12-jul |
| Agregar step de rollback automático al pipeline | @dev2 | 25-jul |

### 6. Lecciones aprendidas

Qué cambió en el equipo a partir del incidente:

- Los endpoints con generación de archivos deben tener límite de tamaño
- Staging debe reflejar producción en volumen de datos
- Toda feature nueva debe pasar una prueba de estrés básica

### 7. Blameless statement

Afirmación explícita de que no se busca culpables:

> "Ninguna persona causó este incidente intencionalmente. El deploy fue aprobado siguiendo el proceso estándar. El memory leak era indetectable sin los datos adecuados en staging. Las acciones correctivas están diseñadas para fortalecer el sistema, no para señalar a nadie."

---

## 🧠 Modelo mental

Pensá en un post-mortem como la **autopsia de un incidente**.

Así como una autopsia no busca castigar al cuerpo, un post-mortem no busca castigar a la persona. Busca entender la causa de muerte para prevenir futuras muertes.

Cada incidente es una oportunidad de mejorar el sistema. Si después del incidente todo sigue igual, perdiste la oportunidad.

Los 5 porqués son como pelar una cebolla: cada capa de "¿por qué?" te acerca más a la causa real. La primera respuesta suele ser un síntoma. La quinta suele ser un problema de proceso, diseño o cultura.

---

## 🔗 Ver también

- [`concept`](sre-fundamentals.md) — SLI, SLO, error budget, post-mortem como parte del ciclo SRE
- [`concept`](how-to-think-like-sysadmin.md) — patrón de diagnóstico y reducción de problemas
- [`concept`](baseline-and-anomalies.md) — detección temprana de anomalías para evitar incidentes
- [`scenario`](../scenarios/infrastructure/08-prometheus-grafana.md) — monitoreo para detectar incidentes antes que los usuarios
- [`scenario`](../scenarios/web/01-performance-and-error-analysis.md) — análisis de rendimiento y errores
