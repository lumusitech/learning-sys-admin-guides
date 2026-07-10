# cgroups (Control Groups) — Referencia rápida

cgroups: cómo el kernel limita CPU, memoria e I/O por proceso o grupo de procesos. Esencial para entender Docker, systemd slices y límites de recursos.

---

## 🧠 ¿Qué son los cgroups?

Mecanismo del kernel Linux que organiza procesos en grupos jerárquicos y les aplica límites de recursos (CPU, memoria, I/O, dispositivos).

**Todo contenedor Docker, toda unit de systemd y todo proceso corre dentro de un cgroup.**

---

## 📊 cgroups v1 vs v2

| Característica | cgroups v1 | cgroups v2 |
|---------------|-----------|-----------|
| Estructura | Jerarquías separadas por subsistema | Jerarquía unificada |
| Archivos de control | `/sys/fs/cgroup/<subsistema>/` | `/sys/fs/cgroup/<grupo>/` |
| Memoria | `memory.limit_in_bytes` | `memory.max` |
| CPU | `cpu.shares`, `cpu.cfs_quota_us` | `cpu.weight`, `cpu.max` |
| Soporte | Legacy, aún en muchos sistemas | Recomendado, requerido para rootless containers |
| Verificar activo | `mount \| grep cgroup` | `stat -fc %T /sys/fs/cgroup` debe decir `cgroup2fs` |

```bash
# ¿Qué versión usa el sistema?
mount | grep cgroup
# v1: múltiples entradas con tipo cgroup
# v2: una sola entrada con tipo cgroup2
```

---

## 🎛️ Límites de recursos principales

### CPU

| v1 | v2 | Qué hace |
|----|----|---------|
| `cpu.cfs_quota_us` | `cpu.max "$QUOTA $PERIOD"` | Límite absoluto: usecs de CPU por período |
| `cpu.cfs_period_us` | (segundo valor en cpu.max) | Período de medición (típico 100000 = 100ms) |
| `cpu.shares` | `cpu.weight` | Peso relativo cuando hay contención |

### Memoria

| v1 | v2 | Qué hace |
|----|----|---------|
| `memory.limit_in_bytes` | `memory.max` | Límite absoluto de memoria |
| `memory.soft_limit_in_bytes` | `memory.high` | Soft limit: throttle, no matar |
| `memory.oom_control` | `memory.oom.group` | Control de OOM killer |

### I/O

| v1 | v2 | Qué hace |
|----|----|---------|
| `blkio.throttle.read_bps_device` | `io.max` | Límite de lectura en bytes/seg |
| `blkio.throttle.write_bps_device` | `io.max` | Límite de escritura en bytes/seg |

---

## 🐳 Docker y cgroups

```bash
# Ver cgroups de un contenedor
docker inspect <container> | grep -i cgroup

# ¿Dónde están los archivos del cgroup del contenedor?
# systemd-cgroup: /sys/fs/cgroup/system.slice/docker-<ID>.scope/
# cgroupfs:       /sys/fs/cgroup/<subsistema>/docker/<ID>/

# Ver límites de memoria del contenedor
cat /sys/fs/cgroup/system.slice/docker-<ID>.scope/memory.max

# Ver uso actual de CPU del contenedor
cat /sys/fs/cgroup/system.slice/docker-<ID>.scope/cpu.stat
```

---

## 🛠️ Troubleshooting con cgroups

### El proceso fue matado pero no hay OOM en dmesg

```bash
# Ver si el cgroup mató el proceso
cat /sys/fs/cgroup/<ruta>/memory.events
# oom_kill 1 → fue matado por OOM del cgroup
```

### Un contenedor no usa más del 50% de CPU aunque está disponible

```bash
# El límite está en cpu.max (v2) o cpu.cfs_quota_us (v1)
cat /sys/fs/cgroup/<ruta>/cpu.max
# "200000 100000" = 2 CPUs máximo
# "50000 100000" = 0.5 CPU → ese es el cuello
```

### systemd-cgtop: monitoreo en vivo

```bash
systemd-cgtop             # top para cgroups
# Muestra CPU, memoria, I/O por cgroup
# Las filas son servicios, scopes, slices
```

---

## 📋 systemd y cgroups

systemd organiza todo en slices:

```text
-.slice                         # root
├── system.slice                # servicios del sistema
│   ├── nginx.service
│   ├── sshd.service
│   └── docker.service
├── user.slice                  # sesiones de usuario
│   └── user-1000.slice
└── machine.slice               # máquinas virtuales / contenedores
```

```bash
systemctl status <servicio>     # muestra el cgroup del servicio
systemd-cgls                    # árbol de cgroups
cat /proc/<PID>/cgroup          # a qué cgroup pertenece un proceso
```

---

## 🔗 Ver también

- [`reference/file-descriptors.md`](file-descriptors.md) — file descriptors y límites
- [`guides/docker.md`](../guides/docker.md) — Docker troubleshooting
- [`guides/systemd.md`](../guides/systemd.md) — systemd y unidades de servicio
- [`guides/top.md`](../guides/top.md) — monitoreo de procesos
- [`scenarios/system/14-docker-troubleshooting.md`](../scenarios/system/14-docker-troubleshooting.md) — Docker troubleshooting
- [`scenarios/system/05-system-memory-issues-oom.md`](../scenarios/system/05-system-memory-issues-oom.md) — OOM killer
