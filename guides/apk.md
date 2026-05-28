# apk — Guía completa

**Nivel:** 🟢 Básico
**Archivos de práctica:** Sistema en vivo (Alpine Linux)
**Ver escenarios relacionados:** [`system/03-new-server-provisioning`](../scenarios/system/03-new-server-provisioning.md), [`infrastructure/01-migrate-to-production`](../scenarios/infrastructure/01-migrate-to-production.md)

---

## ⚡ Quick command

`apk add <paquete>`

---

## ⚡ Quick run

```bash
apk update && apk upgrade
```

---

## Índice

1. [¿Qué es apk?](#qué-es-apk)
2. [Sintaxis básica](#sintaxis-básica)
3. [Buscar e instalar](#buscar-e-instalar)
4. [Actualizar y eliminar](#actualizar-y-eliminar)
5. [Información del sistema](#información-del-sistema)
6. [Gestión de versiones](#gestión-de-versiones)
7. [Equivalentes desde apt](#equivalentes-desde-apt)
8. [Solución de problemas](#solución-de-problemas)

---

## ¿Qué es apk?

**apk** (Alpine Linux Package Manager) es el gestor de paquetes de Alpine Linux. Es minimalista, rápido y usa BusyBox como shell base. A diferencia de `apt` (Debian), `apk` es un solo binario sin separación entre `apt-get` y `apt-cache`.

Se usa para:

- instalar paquetes en contenedores Docker Alpine;
- mantener actualizado un servidor Alpine;
- buscar qué paquete contiene un binario;
- auditar qué está instalado en el sistema.

---

## Sintaxis básica

```bash
apk <comando> [opciones] [paquete...]
```

```bash
apk add nginx              # Instalar paquete
apk del nginx              # Eliminar paquete
apk update                 # Actualizar índices de repositorios
apk upgrade                # Actualizar paquetes instalados
apk search nginx           # Buscar paquetes
apk info nginx             # Información de un paquete
apk list --installed       # Listar paquetes instalados
```

---

## Buscar e instalar

### Buscar un paquete por nombre

```bash
apk search nginx
apk search -v nginx            # Descripción completa
apk search -d "web server"     # Buscar por descripción
apk search -e nginx            # Búsqueda exacta
```

### Instalar paquetes

```bash
apk add nginx                  # Instalar un paquete
apk add nginx mysql htop       # Varios paquetes
apk add --no-cache nginx       # Sin cachear el paquete (menos espacio en disco)
```

La diferencia principal con `apt`: `apk` no separa `update` e `install`. Si los índices no están actualizados, `apk add` actualiza automáticamente.

### Mostrar contenido de un paquete (archivos que instala)

```bash
apk info -L nginx
```

---

## Actualizar y eliminar

### Actualizar índices y paquetes

```bash
apk update                    # Actualizar índices
apk upgrade                   # Actualizar paquetes instalados
apk upgrade --available       # Forzar downgrade si el pin bajó
```

```bash
# Equivalente a apt update && apt upgrade -y
apk update && apk upgrade
```

### Eliminar paquetes

```bash
apk del nginx                 # Eliminar paquete y dependencias no usadas
apk del nginx --purge         # Eliminar también archivos de configuración
```

### Auto-eliminar dependencias no usadas

A diferencia de `apt autoremove`, `apk del` elimina automáticamente las dependencias que no son necesarias para otros paquetes. No hace falta un paso adicional.

---

## Información del sistema

### Paquetes instalados

```bash
apk list --installed
apk list --installed | wc -l               # Contar paquetes
apk list --installed | grep nginx           # Buscar entre instalados
```

### Información detallada de un paquete

```bash
apk info nginx
apk info -a nginx               # Todo sobre el paquete (dependencias, tamaño, checksum)
apk info -s nginx               # Tamaño instalado
apk info -L nginx               # Archivos que instala
```

### Dependencias

```bash
apk info -R nginx               # Paquetes que requiere (dependencias)
apk info -r nginx               # Paquetes que dependen de él (reverse dependencies)
```

---

## Gestión de versiones

### Versión disponible vs instalada

```bash
apk list --upgradable           # Paquetes con actualización disponible
apk version -v                  # Comparar versiones instaladas vs repositorios
```

### Instalar una versión específica

```bash
apk add nginx=1.24.0-r12        # Versión exacta
apk add 'nginx<1.25'            # Restricción de versión
```

### Mantener un paquete en una versión

```bash
apk add nginx --pin             # Evitar que se actualice con apk upgrade
```

---

## Equivalentes desde apt

| Operación | Debian/Ubuntu | Alpine |
|-----------|---------------|--------|
| Actualizar índices | `apt update` | `apk update` |
| Instalar | `apt install -y nginx` | `apk add nginx` |
| Eliminar | `apt remove nginx` | `apk del nginx` |
| Actualizar sistema | `apt upgrade -y` | `apk upgrade` |
| Buscar | `apt search nginx` | `apk search nginx` |
| Info del paquete | `apt show nginx` | `apk info nginx` |
| Archivos del paquete | `dpkg -L nginx` | `apk info -L nginx` |
| Paquetes instalados | `apt list --installed` | `apk list --installed` |
| Paquetes upgradables | `apt list --upgradable` | `apk list --upgradable` |
| Limpiar cache | `apt clean` | `rm -rf /var/cache/apk/*` |

---

## Solución de problemas

### Paquete no encontrado

```bash
# Verificar repositorios configurados
cat /etc/apk/repositories

# Los repositorios de la comunidad pueden estar desactivados.
# Activar community:
echo "https://dl-cdn.alpinelinux.org/alpine/v$(cat /etc/alpine-release | cut -d. -f1,2)/main" > /etc/apk/repositories
echo "https://dl-cdn.alpinelinux.org/alpine/v$(cat /etc/alpine-release | cut -d. -f1,2)/community" >> /etc/apk/repositories
apk update
```

### Archivos de configuración

Los archivos de configuración de `apk` están en:

```bash
/etc/apk/repositories      # Fuentes de paquetes
/etc/apk/world             # Paquetes explícitamente instalados (no tocar manualmente)
/var/cache/apk/            # Cache de paquetes descargados
```

### Integridad de paquetes

```bash
apk audit                  # Verificar archivos modificados respecto al paquete original
apk audit --backup         # Archivos de configuración modificados
apk audit --recursive      # Incluir dependencias
```

---

## Referencias internas

- [`openrc`](../openrc.md) — gestión de servicios en Alpine Linux
- [`busybox`](../busybox.md) — toolchain mínima de Alpine (commands POSIX incluidos)
- [`production_server`](../production_server.md) — hardening y configuración de servidor
