
# Defensa en profundidad — Guía conceptual

## 🧠 ¿Qué es?

La defensa en profundidad es una estrategia de seguridad que aplica múltiples capas de control para proteger un sistema. Si una capa falla, la siguiente contiene el daño.

No existe un firewall o antivirus que detenga todo. La seguridad real está en la superposición de barreras independientes.

---

## 🎯 ¿Por qué importa?

- ninguna capa es invulnerable por sí sola
- la contención limita el daño cuando una capa falla
- reduce la superficie de ataque progresivamente
- permite priorizar esfuerzos según riesgo real

---

## 🧱 Principios rectores

### Defensa por capas

Cada capa asume que la capa anterior fue vulnerada. El objetivo no es impedir todo ataque, sino **limitar el radio de explosión** cuando uno ocurre.

| Capa | Qué protege | Ejemplos |
|------|-------------|----------|
| Física | Acceso al hardware | Datacenter con control de acceso, bastionado de switches |
| Red | Acceso a la red interna | Firewalls, segmentación VLAN, ACLs |
| Host | El sistema operativo | Hardening, SELinux/AppArmor, parches |
| Aplicación | El servicio o software | Input validation, auth, rate limiting |
| Datos | La información almacenada | Cifrado en reposo y tránsito, backups |
| Usuario | Acceso de personas | MFA, least privilege, auditoría |

### Privilegio mínimo (Least Privilege)

Cada entidad (usuario, proceso, servicio) debe tener solo los permisos necesarios para cumplir su función.

Ejemplos:

- un proceso nginx no necesita acceso a `/home`
- un usuario de base de datos no necesita `DROP TABLE`
- un backup no necesita ejecutar código

Contraejemplo clásico: servicios corriendo como `root`.

### Aislamiento (Segmentation)

Separar componentes para que una vulnerabilidad en uno no comprometa los demás.

Formas de aislamiento:

| Tipo | Descripción |
|------|-------------|
| De red | Subredes separadas por función (web, DB, admin) |
| De procesos | Contenedores, namespaces, cgroups |
| De datos | Bases separadas, esquemas distintos, lecturas vs escrituras |
| De ejecución | Entornos distintos: dev, staging, producción |

### Hardening progresivo

No se endurece todo de entrada. Se aplican medidas en orden de prioridad según el riesgo:

1. lo que más duele si falla
2. lo que está más expuesto
3. lo que es más fácil de romper si lo endurecés mal

---

## 🧱 Las capas en detalle

### Capa física

- acceso restringido a datacenter o sala de servidores
- consolas bloqueadas, BIOS con contraseña
- arranque desde disco externo deshabilitado

### Capa de red

- firewall: denegar todo por defecto, abrir solo lo necesario
- segmentación: servidores web no hablan directamente con la base de datos
- VPN para acceso remoto, no puertos SSH expuestos a internet
- rate limiting en puertos críticos
- monitoreo de tráfico anómalo (port scans, conexiones masivas)

### Capa de host

- sistema mínimo: solo paquetes necesarios
- parches de seguridad al día
- SSH con clave pública, sin root login, puerto no estándar
- SELinux o AppArmor activo
- auditoría de archivos del sistema (AIDE, Tripwire)
- `fail2ban` o similar para login scanning

### Capa de aplicación

- input validation en toda entrada externa
- autenticación y autorización separadas
- rate limiting por IP y por usuario
- logs de acceso y errores con contexto suficiente
- no hardcodear credenciales (usar secrets management)

### Capa de datos

- cifrado en reposo (disco, backups)
- cifrado en tránsito (TLS siempre)
- backups offline y probados
- retención y rotación de logs
- separación de datos sensibles (tokenizar o seudonimizar)

### Capa de usuario

- MFA obligatorio para acceso administrativo
- grupos RBAC bien definidos
- revisión periódica de accesos
- capacitación en seguridad básica

---

## 🔄 Modelo de contención

Cuando ocurre un incidente, las capas contienen el daño:

```text
atacante vulnera app web
  → capa de aplicación: logs registran el ataque
  → capa de host: el proceso está limitado por su usuario sin permisos
  → capa de red: no puede conectarse a la base de datos desde ese segmento
  → capa de datos: aunque acceda, los datos están cifrados
```

Cada capa que el atacante debe atravesar es una oportunidad de detectarlo y bloquearlo.

---

## ❌ Errores comunes

- confiar en una sola capa (un firewall y listo)
- endurecer sin probar (cambio que rompe producción y se revierte)
- olvidar las capas internas (todo enfocado en el perímetro)
- permisos excesivos por comodidad (root para todo "por las dudas")
- no revisar logs (tener las capas pero no mirar las alertas)

---

## 🧠 Modelo mental

La defensa en profundidad no es una configuración. Es una postura.

Cada decisión de diseño debe responder: **"si esta capa falla, ¿qué contiene el daño?"**

Si la respuesta es "nada", falta una capa.

---

## 🔗 Ver también

- [`troubleshooting-patterns`](../reference/troubleshooting-patterns.md) — patrones de diagnóstico en seguridad
- [`scenarios/security/02-suid-audit-and-file-permissions.md`](../scenarios/security/02-suid-audit-and-file-permissions.md) — auditoría de permisos SUID/SGID
- [`scenarios/networking/03-port-scan-detection.md`](../scenarios/networking/03-port-scan-detection.md) — detección de port scanning
- [`scenarios/networking/08-firewall-blocked-port.md`](../scenarios/networking/08-firewall-blocked-port.md) — troubleshooting de firewall
