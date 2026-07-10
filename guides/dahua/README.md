# 📹 Dahua — Administración desde Terminal

Guías especializadas para administrar dispositivos Dahua (cámaras IP, NVR, DVR) exclusivamente desde la línea de comandos.

**Enfoque:** sin UI, sin SmartPSS, sin navegador. Solo terminal, scripts y APIs.

---

## ¿Por qué Dahua?

Dahua es el fabricante #2 de videovigilancia IP a nivel global (después de Hikvision). Sus dispositivos son ubicuos en:

- Cámaras IP (series WizSense, WizMind, Lite)
- NVR / XVR (híbridos)
- Centrales de alarma
- Barreras vehiculares y lectores de patentes (LPR/ANPR)

Todas las cámaras Dahua modernas exponen una **API REST** (CGI/ISAPI) y **RTSP** que se puede consultar y configurar desde terminal sin abrir un navegador.

---

## 🚨 Línea roja

Estas guías enseñan a **consultar y diagnosticar** dispositivos Dahua.

No cubren:

- Actualización de firmware
- Configuración de horarios complejos (mejor desde UI)
- Configuración inicial de NVR server (mejor desde UI o SmartPSS)

---

## 📑 Guías

| Guía | Nivel | Descripción |
|------|-------|-------------|
| [`dahua-discovery.md`](dahua-discovery.md) | 🟢 Básico | Descubrir cámaras Dahua en la red (nmap, ONVIF, DHCP) |
| [`dahua-camera-api.md`](dahua-camera-api.md) | 🟡 Intermedio | API REST/ISAPI: consultar estado, cambiar IP, hora, contraseña |
| [`dahua-rtsp-stream.md`](dahua-rtsp-stream.md) | 🟡 Intermedio | Diagnóstico de video: RTSP, codecs, resolución, FPS |
| [`dahua-mass-config.md`](dahua-mass-config.md) | 🔴 Avanzado | Scripting: configurar 50 cámaras en segundos |
| [`dahua-nvr-ssh.md`](dahua-nvr-ssh.md) | 🔴 Avanzado | Acceso SSH a NVR Dahua: procesos, discos, logs, grabaciones |
| [`dahua-wizsense-wizmind.md`](dahua-wizsense-wizmind.md) | 🔴 Avanzado | Diferencias WizSense vs WizMind, APIs de IA |
| [`dahua-troubleshooting.md`](dahua-troubleshooting.md) | 🟡 Intermedio | Fallas comunes y cómo diagnosticarlas desde terminal |

---

## 🔗 Referencias

- [Referencia rápida de comandos](../../reference/dahua-cheatsheet.md)
- [Escenarios prácticos](../../scenarios/dahua/)
- Documentación oficial Dahua API: https://www.dahuasecurity.com/support/api
- ONVIF standard: https://www.onvif.org

---

## ⚠️ Nota legal

Estas guías son para administradores de sistemas con autorización sobre los dispositivos. Escaneos no autorizados pueden violar leyes locales. Usar con responsabilidad.
