# Skill: Web Labs Creator

## Rol

Creás entornos de práctica para escenarios web (CORS, WebSocket, etc.) dentro de `labs/`, siguiendo el estándar del repo. Cada lab debe ser reproducible con Docker Compose, documentado en `labs/README.md` y alineado con los skills existentes (`scenario-creator-skill`, `reference-creator-skill`, `concepts-creator-skill`).

Todos los scripts incluidos deben respetar POSIX (sin bashismos) y la documentación Markdown debe pasar `pnpm lint:md` sin errores. Usá `pnpm validate` para validar el conjunto (lint:md, lint:sh, validate:sre).

---

## Plantilla de laboratorio (CORS)

```txt
labs/
├── docker-compose.web-cors.yml
├── cors/
│   ├── frontend.conf
│   ├── api-broken.conf
│   └── api-fixed.conf
└── cors/
    └── client.Dockerfile (opcional)
```

### Convenciones

- Nombre del compose: `docker-compose.<domain>-<feature>.yml`
- Redes: `lab-<domain>-<feature>` (ej.: `lab-web-cors`)
- Servicios: `<role>-<feature>` (ej.: `cors-frontend`, `cors-api`, `cors-client`)
- Puertos: exponer solo lo necesario y usar hostnames predecibles
- Logs: stdout/stderr y `tail -f /dev/null` para mantener contenedores vivos
- Healthchecks: probar endpoints internos con `curl`

### Estructura de README (por lab)

- Título claro con emoji
- Tabla de servicios (nombre, puerto, rol)
- Comandos de levantamiento y verificación
- Ejemplo de diagnóstico (quick commands)
- Referencias a scenarios relacionados

---

## Plantilla de laboratorio (WebSocket)

```txt
labs/
├── docker-compose.web-websocket.yml
├── ws/
│   ├── nginx-broken.conf
│   ├── nginx-fixed.conf
│   └── server-setup.sh
└── ws/
    └── client.Dockerfile (opcional)
```

### Convenciones

- Para WebSocket: incluir `proxy_http_version 1.1`, headers de upgrade y timeouts explícitos
- Proveer un script de setup del servidor con instalación de dependencias y arranque del servicio
- Documentar comprobaciones de handshake con `curl -i` y lectura de logs de `nginx`

---

## Checklist de entrega

- [ ] Archivos creados bajo `labs/` y subcarpetas temáticas
- [ ] `labs/README.md` actualizado con tabla y ejemplos
- [ ] Scenarios relacionados referencian los archivos de lab en metadata
- [ ] Sin bashismos en scripts (sh, no bash)
- [ ] `pnpm validate` pasa sin errores
- [ ] Commits y PR por fase, siguiendo la convención del repo

---

## Referencias

- [scenario-creator-skill](scenario-creator-skill.md)
- [reference-creator-skill](reference-creator-skill.md)
- [concepts-creator-skill](concepts-creator-skill.md)
- [labs/README](../labs/README.md)
