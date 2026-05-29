# OpenRC — Guía completa

**Nivel:** 🟡 Intermedio
**Archivos de práctica:** Sistema en vivo (Alpine Linux)
**Ver escenarios relacionados:** Todos los escenarios con Variante Alpine en [`scenarios/`](../scenarios/)

---

## ⚡ Quick command

`rc-service nginx status`

---

## ⚡ Quick run

```bash
rc-service nginx restart && rc-service nginx status
```

---

## 📑 Índice

1. [¿Qué es OpenRC?](#qué-es-openrc)
2. [Modelo mental](#modelo-mental)
3. [Sintaxis básica](#sintaxis-básica)
4. [Gestión de servicios (rc-service)](#gestión-de-servicios-rc-service)
5. [Inicio automático (rc-update)](#inicio-automático-rc-update)
6. [Estado del sistema (rc-status)](#estado-del-sistema-rc-status)
7. [Configuración de servicios](#configuración-de-servicios)
8. [Equivalentes desde systemd](#equivalentes-desde-systemd)
9. [Servicios comunes en Alpine](#servicios-comunes-en-alpine)
10. [Uno-liners imprescindibles](#uno-liners-imprescindibles)

---

## 🧠 ¿Qué es OpenRC?

**OpenRC** es el sistema de init y gestor de servicios de Alpine Linux (y otras distribuciones que no usan systemd). Es compatible con POSIX, minimalista y basado en scripts shell.

A diferencia de systemd, OpenRC:

- Usa scripts shell en `/etc/init.d/`;
- No unifica logs, servicios, cron, timer, network y syslog en un solo demonio;
- Cada servicio tiene un archivo de configuración en `/etc/conf.d/`;
- No hay `journalctl` — los logs van a `/var/log/messages` o `logread`.

---

## 🧠 Modelo mental

OpenRC separa la funcionalidad en tres comandos:

- **`rc-service`**: start, stop, restart, status, reload (equivalente a `systemctl`).
- **`rc-update`**: agregar o quitar servicios del inicio automático (equivalente a `systemctl enable/disable`).
- **`rc-status`**: ver qué servicios están corriendo (equivalente a `systemctl list-units --state=running`).

Los scripts de servicio están en `/etc/init.d/` y se configuran en `/etc/conf.d/`.

---

## 📝 Sintaxis básica

```bash
rc-service <servicio> <acción>      # Gestionar un servicio
rc-update <acción> <servicio>       # Gestionar inicio automático
rc-status [runlevel]                # Ver estado de servicios
```

---

## Gestión de servicios (rc-service)

Acciones disponibles para cualquier servicio:

```bash
rc-service nginx start              # Iniciar
rc-service nginx stop               # Detener
rc-service nginx restart            # Reiniciar
rc-service nginx status             # Estado
rc-service nginx reload             # Recargar configuración
```

```bash
# Verificar si un servicio está activo
rc-service nginx status && echo "OK: nginx corriendo" || echo "ERROR: nginx caído"
```

---

## Inicio automático (rc-update)

Controla qué servicios arrancan automáticamente al iniciar el sistema.

### Runlevels (niveles de ejecución)

- `default`: nivel normal de arranque (la mayoría de servicios van aquí).
- `boot`: servicios del kernel y sistema básico.
- `sysinit`: inicialización del sistema.
- `shutdown`: servicios que se ejecutan al apagar.

```bash
# Agregar al inicio automático
rc-update add nginx default

# Quitar del inicio automático
rc-update del nginx default

# Ver servicios configurados para cada runlevel
rc-update show
```

### rc-update vs systemctl enable

| systemd | OpenRC |
|---------|--------|
| `systemctl enable nginx` | `rc-update add nginx default` |
| `systemctl disable nginx` | `rc-update del nginx default` |
| `systemctl list-unit-files` | `rc-update show` |

---

## Estado del sistema (rc-status)

```bash
rc-status                          # Todos los servicios del runlevel default
rc-status --all                    # Todos los runlevels
rc-status --crashed                # Servicios que fallaron
rc-status -a | grep -i 'stopped'  # Servicios detenidos
```

### Equivalente a systemctl --failed

```bash
rc-status --crashed
```

---

## Configuración de servicios

Cada servicio tiene dos archivos:

| Archivo | Propósito | Ejemplo |
|---------|-----------|---------|
| `/etc/init.d/<servicio>` | Script de control (no editar manualmente) | `/etc/init.d/nginx` |
| `/etc/conf.d/<servicio>` | Variables de configuración del servicio | `/etc/conf.d/nginx` |

```bash
cat /etc/conf.d/nginx              # Ver configuración del servicio
echo 'NGINX_OPTS="-g \"daemon off;\""' >> /etc/conf.d/nginx
rc-service nginx restart
```

### Servicios dependientes

```bash
rc-update -v show                  # Mostrar dependencias entre servicios
```

---

## Equivalentes desde systemd

| Operación | systemd | OpenRC |
|-----------|---------|--------|
| Iniciar | `systemctl start nginx` | `rc-service nginx start` |
| Detener | `systemctl stop nginx` | `rc-service nginx stop` |
| Reiniciar | `systemctl restart nginx` | `rc-service nginx restart` |
| Estado | `systemctl status nginx` | `rc-service nginx status` |
| Recargar | `systemctl reload nginx` | `rc-service nginx reload` |
| Habilitar | `systemctl enable nginx` | `rc-update add nginx default` |
| Deshabilitar | `systemctl disable nginx` | `rc-update del nginx default` |
| Habilitar + iniciar | `systemctl enable --now nginx` | `rc-update add nginx default && rc-service nginx start` |
| Servicios activos | `systemctl list-units --state=running` | `rc-status` |
| Servicios fallidos | `systemctl --failed` | `rc-status --crashed` |
| Logs | `journalctl -u nginx` | `logread \| grep nginx` o `/var/log/messages` |
| Ver unidad | `systemctl cat nginx` | `cat /etc/init.d/nginx` |
| Tiempo de ejecución | `systemd-analyze` | (no existe; medir con `time` en boot) |

---

## Servicios comunes en Alpine

| Servicio | Instalación | Inicio | Habilitar |
|----------|------------|--------|-----------|
| nginx | `apk add nginx` | `rc-service nginx start` | `rc-update add nginx` |
| sshd | `apk add openssh` | `rc-service sshd start` | `rc-update add sshd` |
| MariaDB | `apk add mariadb` | `rc-service mariadb start` | `rc-update add mariadb` |
| chronyd | `apk add chrony` | `rc-service chronyd start` | `rc-update add chronyd` |
| networking | (viene instalado) | `rc-service networking restart` | `rc-update add networking` |
| fail2ban | `apk add fail2ban` | `rc-service fail2ban start` | `rc-update add fail2ban` |
| dnsmasq | `apk add dnsmasq` | `rc-service dnsmasq start` | `rc-update add dnsmasq` |
| nfs | `apk add nfs-utils` | `rc-service nfs start` | `rc-update add nfs` |
| samba | `apk add samba` | `rc-service samba start` | `rc-update add samba` |
| docker | `apk add docker` | `rc-service docker start` | `rc-update add docker` |

---

## 💡 Uno-liners imprescindibles

```bash
rc-service nginx restart                 # Reiniciar servicio
rc-status -a | grep -i 'started'         # Todos los servicios corriendo
rc-update show                           # Servicios con inicio automático
rc-service --list                        # Listar servicios disponibles
rc-status --crashed                      # Servicios que fallaron
rc-service ntpd status && rc-service ntpd start   # Verificar e iniciar
```

---

## 🔗 Referencias internas

- [`apk`](../apk.md) — gestor de paquetes de Alpine Linux
- [`busybox`](../busybox.md) — toolchain mínima de Alpine
- [`systemd_journalctl`](../systemd_journalctl.md) — sistema de init alternativo (Debian/Ubuntu)
