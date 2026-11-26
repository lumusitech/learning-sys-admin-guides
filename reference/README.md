
⬅️ [Volver al README principal](../README.md)

---

## 🧭 Navegación

- 🧠 [concepts/](../concepts/) — pensar como sysadmin
- 🛠️ [guides/](../guides/) — herramientas
- 🧪 [labs/](../labs/) — práctica
- 🚨 [scenarios/](../scenarios/) — casos reales

---

# Reference — Mapas rápidos de consulta

Tablas de consulta para tener a mano mientras diagnosticás. No explican herramientas: resuelven "¿qué significa este código?" o "¿qué comando uso para este síntoma?".

## 🎯 Cuándo usar esta sección

Usá `reference/` cuando:

- ves un código, estado o señal y no sabés qué significa
- el síntoma es claro pero no sabés qué herramienta usar
- necesitás un puerto, una ruta del filesystem o un límite del kernel
- querés confirmar una operación entre gestores de paquetes

👉 Esto es para consultar en medio de un incidente

---

👉 Esta sección es de consulta:

- NO enseña la herramienta (eso es `guides/`)
- NO resuelve el problema paso a paso (eso es `scenarios/`)
- SOLO traduce códigos, estados y síntomas a información accionable

Para aprender la herramienta, ver `guides/`. Para resolver un caso completo, ver `scenarios/`.

---

## 📚 Referencias disponibles

| Referencia | Nivel | Descripción |
|------------|-------|-------------|
| [Síntoma → Herramienta](symptom-to-tool.md) | 🟢 Básico | El problema es claro pero no sabés qué comando usar |
| [Troubleshooting Patterns](troubleshooting-patterns.md) | 🟢 Básico | Problema → qué herramienta usar (no cómo) |
| [Códigos de estado HTTP](http-status-codes.md) | 🟢 Básico | 2xx, 3xx, 4xx, 5xx — interpretación para troubleshooting web |
| [Puertos TCP/UDP](port-numbers.md) | 🟢 Básico | Puertos comunes para usar con `ss`, `netstat`, `lsof`, `nmap` |
| [Señales de Linux](signals-table.md) | 🟢 Básico | Señales esenciales para administrar procesos (`kill`, `pkill`) |
| [File Descriptors y ulimit](file-descriptors.md) | 🟡 Intermedio | Fugas de FD y el error "too many open files" |
| [Estados de conexión TCP](tcp-connection-states.md) | 🟡 Intermedio | `ESTABLISHED`, `TIME_WAIT`, `CLOSE_WAIT` vistos con `ss` o `tcpdump` |
| [Proceso de boot de Linux](boot-process.md) | 🟡 Intermedio | Etapas del arranque para diagnosticar fallos de inicio |
| [Linux Filesystem Hierarchy](disk-layout.md) | 🟡 Intermedio | Dónde vive cada cosa: troubleshooting de disco y permisos |
| [cgroups](cgroups.md) | 🟡 Intermedio | Límites de CPU, memoria e I/O: Docker, systemd slices, OOM |
| [Gestores de paquetes](package-managers.md) | 🟡 Intermedio | Operaciones equivalentes en apt, apk, pacman y dnf |
| [Dahua](dahua-cheatsheet.md) | 🟡 Intermedio | Administración de cámaras IP Dahua desde terminal |

---

## 🔗 Relación con otras secciones

- [`concepts/`](../concepts/) → cómo pensar el problema
- [`guides/`](../guides/) → cómo funciona la herramienta
- [`scenarios/`](../scenarios/) → el caso completo resuelto
- `reference/` → qué significa lo que estás viendo

Ruta en un incidente: `scenarios/` → `reference/` → `guides/` → `labs/`

⬅️ [Volver al README principal](../README.md)
