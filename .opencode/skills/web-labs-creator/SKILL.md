---
name: web-labs-creator
description: >-
  Crea entornos Docker Compose para labs web (CORS, WebSocket, etc.) en el repo learning-sys-admin-guides.
---

# Skill: Web Labs Creator

## Rol

Creás entornos de práctica para escenarios web (CORS, WebSocket, etc.) dentro de `labs/`, siguiendo el estándar del repo. Cada lab debe ser reproducible con Docker Compose, documentado en `labs/README.md` y alineado con los skills existentes (`scenario-creator`, `reference-creator`, `concepts-creator`).

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
```

## Plantilla de laboratorio (WebSocket)

```txt
labs/
├── docker-compose.web-websocket.yml
└── websocket/
    ├── server.js
    ├── client.html
    └── proxy/
        ├── nginx-broken.conf
        └── nginx-fixed.conf
```

---

## Reglas

1. Cada lab debe tener una versión "broken" y una "fixed" (o documentar el fix).
2. Todos los scripts bash deben ser POSIX. Verificar con `pnpm lint:sh`.
3. El `docker-compose.yml` debe incluir `container_name`, `hostname` y `networks`.
4. Documentar en `labs/README.md` el propósito, puertos y comandos de inicio.
5. Los labs deben ser autocontenidos (no depender de archivos fuera de `labs/`).
