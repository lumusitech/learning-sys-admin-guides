# 🧩 Escenario: Detectar ataque de fuerza bruta SSH

**Dominio:** networking / security
**Nivel:** 🟡 Intermedio
**Herramientas:** `grep`, `awk`, `sort`, `uniq`, `head` (+ opcional `iptables`)
**Datos:** Producción `/var/log/auth.log` | Práctica `labs/auth.log`

**Quick command (SRE):** `awk '/Failed password/ {for(i=1;i<=NF;i++) if($i=="from"){c[$(i+1)]++; break}} END{for(ip in c) print c[ip], ip}' labs/auth.log | sort -rn | head -10`

**Quick command (original):** `awk '/Failed password/{for(i=1;i<=NF;i++)if($i=="from")print $(i+1)}' labs/auth.log | sort | uniq -c | sort -rn | head`

**Cuándo usar este escenario:**
- Servidor lento, CPU alta con muchos procesos sshd
- Logs de autenticación creciendo rápido
- Sospecha de ataque de fuerza bruta

**Archivo(s) de práctica:** `labs/auth.log`

---

## 🎯 Objetivo

1. Identificar **IPs atacantes** y su frecuencia.
2. Generar un **reporte accionable** (top IPs, usuarios atacados, severidad).
3. Proponer **mitigación segura** sin bloquearte a vos mismo.

---

## 🧠 Contexto (problema real)

El servidor presenta:

- múltiples intentos SSH fallidos (posible brute force)
- carga alta o muchos logs creciendo rápido
- riesgo de compromiso si hay contraseñas débiles o usuarios expuestos

---

## ✅ Datos de entrada

- **Producción**:
  - `/var/log/auth.log` (Debian/Ubuntu)
  - o `journalctl -u ssh -S today` (si tu distro loguea via systemd)
- **Práctica**: `labs/auth.log` del repo

---

## ⚡ Quick run (top IPs atacantes) — recomendado para empezar

> Variante portable (sin `grep -P`), funciona en ambientes mínimos.

```bash
awk '
  /Failed password/ {
    for (i=1; i<=NF; i++)
      if ($i=="from") { print $(i+1) }
  }
' labs/auth.log \
| sort | uniq -c | sort -rn | head -10
```

### ¿Qué hace?

- `awk` detecta líneas de "Failed password" y extrae el campo después de `from`.
- `sort | uniq -c` agrupa y cuenta por IP.
- `sort -rn` ordena por más intentos.
- `head` te deja un top útil.

---

## 🔍 Paso a paso (explicación del pipeline)

1. `awk /Failed password/` → filtra solo intentos fallidos.
2. `if ($i=="from") print $(i+1)` → extrae la IP sin regex frágiles.
3. `sort` → necesario para que `uniq -c` cuente correctamente.
4. `uniq -c` → cuenta ocurrencias por IP.
5. `sort -rn` → orden descendente (más atacantes primero).
6. `head -10` → top 10.

---

## ✅ Salida esperada

```
150 192.168.1.200
 89 10.0.0.50
 45 203.0.113.45
  3 192.168.1.100
  1 10.0.0.1
```

### Interpretación por severidad (regla simple)

Usá el conteo como heurística inicial:

| Intentos | Interpretación |
|----------|----------------|
| 1–3 | Error humano / bots muy leves |
| 5–20 | Automatización suave / escaneo |
| 20–100+ | Brute force activo |
| Muchas IPs distintas | Ataque distribuido (botnet) |

💡 Esto no reemplaza correlación por tiempo; te da **triage** rápido.

---

## 📌 Reporte enriquecido

### Top usuarios atacados

```bash
awk '
  /Failed password/ {
    for (i=1; i<=NF; i++)
      if ($i=="for") { print $(i+1) }
  }
' labs/auth.log \
| sort | uniq -c | sort -rn | head -10
```

### Top IP + usuario (quién ataca a quién)

```bash
awk '
  /Failed password/ {
    ip=""; user="";
    for (i=1; i<=NF; i++) {
      if ($i=="from") ip=$(i+1);
      if ($i=="for")  user=$(i+1);
    }
    if (ip!="" && user!="") print ip, user;
  }
' labs/auth.log \
| sort | uniq -c | sort -rn | head -20
```

**Cómo leerlo:**

- Misma IP atacando muchos usuarios → diccionario / broad scan
- Muchas IPs atacando el mismo usuario → objetivo puntual o botnet

### Picos por minuto (ventana de tiempo)

```bash
awk '
  /Failed password/ { minuto=$1" "$2" "$3; c[minuto]++ }
  END { for (m in c) print c[m], m }
' labs/auth.log \
| sort -rn | head -10
```

**Interpretación:**

- picos concentrados → ataque activo "ahora"
- ruido bajo constante → bots de internet "de fondo"

### Watch en tiempo real (cuando el ataque está ocurriendo)

```bash
sudo tail -f /var/log/auth.log \
  | grep --line-buffered "Failed password" \
  | awk '{ for (i=1; i<=NF; i++) if ($i=="from") { print $(i+1); fflush() } }' \
  | sort | uniq -c
```

> Nota: el conteo en tiempo real con `sort | uniq -c` es limitado porque `uniq` requiere entradas agrupadas; para "real-time" robusto conviene agregar una ventana/refresh (ej. ejecutar cada X segundos con un script). Aun así, te sirve para confirmar rápidamente si hay intentos y qué IP aparece.

---

## 🧯 Mitigación (producción) — segura y reversible

### 1. Mitigación temporal (bloqueo de top IPs)

Primero generá comandos (NO ejecutes ciego):

```bash
awk '
  /Failed password/ {
    for (i=1; i<=NF; i++)
      if ($i=="from") { print $(i+1) }
  }
' /var/log/auth.log \
| sort | uniq -c | sort -rn \
| awk '$1>=20 { print "iptables -I INPUT -s " $2 " -p tcp --dport 22 -j DROP" }' \
| head -10
```

**Buenas prácticas:**

- empezá con un umbral alto (ej. >=20)
- aplicá primero 1 regla, verificá SSH, luego seguí
- guardá rollback: `iptables -S > /root/iptables.backup.rules`

### 2. Rollback (volver atrás)

Si te equivocaste:

```bash
iptables-restore < /root/iptables.backup.rules
```

---

## 🛡️ Prevención (hardening mínimo recomendado)

Checklist rápido (sin casarte con una herramienta):

- [ ] Deshabilitar login de root por SSH (`PermitRootLogin no`)
- [ ] Usar claves públicas (no password) o MFA si aplica
- [ ] Cambiar puerto no es seguridad real, pero reduce ruido
- [ ] Rate limiting / fail2ban para automatizar
- [ ] Permitir SSH solo desde rangos conocidos si podés (VPN/bastion)

---

## 🧪 Variantes

### Solo intentos de root

```bash
grep "Failed password for root" labs/auth.log | wc -l
```

### Detectar "Accepted password" sospechoso (posible compromiso)

```bash
grep "Accepted password" labs/auth.log | tail -20
```

---

## 🧑‍🏫 Modo docente (ideal para clase / práctica evaluable)

### Ejercicio 1

1. Sacá el top 5 de IPs con más fallos.
2. Clasificá cada IP según severidad (leve/medio/alto).
3. Proponé una mitigación y un rollback.

### Ejercicio 2

Encontrá:

- top 3 usuarios atacados
- ¿es un usuario específico o muchos?

### Criterios de evaluación

- pipeline correcto (extrae IP/usuario sin falsos positivos)
- interpretación razonable (no confundir ruido con ataque)
- mitigación segura (incluye rollback y evita bloquearte)

---

## 🧪 Cómo practicarlo en el lab

```bash
# 1. Iniciar servicios SSH (weak + monitoring)
cd labs && docker compose up -d ssh-weak monitoring

# 2. Ejecutar ataque simulado desde monitoring
docker exec -it monitoring bash
for i in $(seq 1 50); do
  sshpass -p "wrong$i" ssh -o StrictHostKeyChecking=no admin@ssh-weak "exit" 2>/dev/null
done

# 3. Ver logs del ataque
docker logs ssh-weak 2>&1 | grep "Failed password" | head -20

# 4. Aplicar los pipelines de este escenario sobre los logs del contenedor
docker logs ssh-weak 2>&1 | awk '/Failed password/ ...'
```

[Ver laboratorio completo →](../../labs/README.md)

---

## 🔗 Referencias (guías del repo)

- [`guides/grep.md`](../../guides/grep.md) — filtros y extracción
- [`guides/awk.md`](../../guides/awk.md) — parseo robusto por campos
- [`guides/sort.md`](../../guides/sort.md) + [`guides/uniq.md`](../../guides/uniq.md) — agregación por frecuencia
- [`guides/iptables.md`](../../guides/iptables.md) — bloqueo/mitigación
- [`guides/ssh.md`](../../guides/ssh.md) — hardening SSH y auditoría
