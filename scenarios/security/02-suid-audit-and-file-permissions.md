⬅️ [Volver a scenarios](../README.md)

# 🧩 Escenario: Auditoría de archivos SUID y permisos inseguros

**Dominio:** security
**Nivel:** 🟡 Intermedio
**Herramientas:** `find`, `xargs`, `awk`, `sort`, `diff`, `ls`
**Archivos:** Sistema de archivos en vivo (`/`)

## ⚡ Quick command (SRE)

**Quick command (SRE):** `find / -type f -perm -4000 2>/dev/null | head -50`

**Quick command (original):** `find / -type f -perm -4000 2>/dev/null | xargs -I {} ls -la {} | awk '{print $1, $3, $4, $NF}' | sort -k4`

**Cuándo usar este escenario:**
- Auditoría de seguridad periódica
- Detectar binarios con SUID que no deberían tenerlo
- Buscar cambios en permisos entre snapshots

**Archivo(s) de práctica:** no aplica (producción)

---

## 🎯 Problema

Es necesario auditar el sistema para detectar configuraciones inseguras de permisos que puedan permitir escalada de privilegios o comprometer la integridad del sistema. Para ello, se requiere:

- encontrar archivos con permisos SUID/SGID que permitan escalada de privilegios
- detectar cambios en la lista de SUID entre snapshots
- identificar directorios world-writable, archivos sin dueño y enlaces rotos

---

## 🧠 Contexto

Los archivos con SUID (setuid) se ejecutan con los permisos del dueño del archivo. Si un atacante logra ejecutar un binario SUID que no debería tener ese permiso, puede escalar a root. Es necesario auditar periódicamente.

---

## ✅ Datos de entrada

- **Producción:** Sistema de archivos en vivo (`find / ...`)
- **Práctica:** Cualquier sistema Linux (o contenedor Docker)

---

## ⚡ Quick run (todos los SUID)

```bash
find / -type f -perm -4000 2>/dev/null | xargs -I {} ls -la {} | awk '{ print $1, $3, $4, $NF }' | sort -k4
```

---

## 🔍 Paso a paso

1. `find / -type f -perm -4000` → busca archivos con bit SUID
2. `2>/dev/null` → descarta errores de permisos
3. `xargs -I {} ls -la {}` → lista detalles de cada archivo
4. `awk '{ print $1, $3, $4, $NF }'` → permisos, owner, grupo, nombre
5. `sort -k4` → ordena por nombre

---

## ✅ Salida esperada

```
-rwsr-xr-x root root /usr/bin/passwd
-rwsr-xr-x root root /usr/bin/su
-rwsr-xr-x root root /usr/bin/sudo
```

- Binarios conocidos (passwd, su, sudo, mount) → normal
- Binarios como `nmap`, `vim`, `python`, `bash` con SUID → **PELIGROSO**
- Scripts `.sh` o `.py` con SUID → **CRÍTICO**

---

## 📌 Pipelines de diagnóstico

### Archivos SGID

```bash
find / -type f -perm -2000 2>/dev/null | xargs -I {} ls -la {} | awk '{ print $1, $3, $4, $NF }'
```

### Detectar cambios en SUID (snapshot)

```bash
# Snapshot inicial
find / -type f -perm -4000 2>/dev/null | sort > /tmp/suid_before.txt
# ... después de cambios ...
find / -type f -perm -4000 2>/dev/null | sort > /tmp/suid_after.txt
# Comparar
diff /tmp/suid_before.txt /tmp/suid_after.txt | awk '{ if($1==">")print "AÑADIDO:", $2; if($1=="<")print "ELIMINADO:", $2 }'
```

### Directorios world-writable

```bash
find / -type d -perm -o+w 2>/dev/null | grep -v "^/proc\|^/sys\|^/dev" | head -30 | xargs -I {} ls -ld {} | awk '{ print $1, $NF }'
```

### Archivos sin dueño ni grupo

```bash
find / -type f \( -nouser -o -nogroup \) 2>/dev/null | xargs -I {} ls -la {} | awk '{ print $1, $3, $4, $NF, "-> ORPHAN" }'
```

### Archivos con permisos 777

```bash
find / -type f -perm 777 2>/dev/null | head -30 | xargs -I {} ls -la {} | awk '{ print $1, $NF }'
```

### Enlaces simbólicos rotos

```bash
find / -type l ! -exec test -e {} \; 2>/dev/null -print | head -20 | while read l; do echo "ROTO: $l -> $(readlink "$l")"; done
```

### Auditoría completa

```bash
echo "=== AUDITORÍA DE PERMISOS ==="
echo "SUID: $(find / -type f -perm -4000 2>/dev/null | wc -l)"
echo "SGID: $(find / -type f -perm -2000 2>/dev/null | wc -l)"
echo "World-writable: $(find / -type d -perm -o+w 2>/dev/null | grep -v "^/proc\|^/sys\|^/dev" | wc -l)"
echo "Archivos sin dueño: $(find / -type f -nouser 2>/dev/null | wc -l)"
echo "Archivos 777: $(find / -type f -perm 777 2>/dev/null | wc -l)"
echo "--- SUID PELIGROSO ---"
find / -type f -perm -4000 2>/dev/null | xargs -I {} ls -la {} | awk '/nmap|find|vim|less|more|bash|sh|python|perl/{print "PELIGROSO:", $NF}'
```

---

## 🧯 Mitigación

| Hallazgo | Acción |
|----------|--------|
| SUID en binario no estándar | `chmod u-s <archivo>` |
| SUID en script (bash/python) | `chmod u-s <archivo>` y revisar por qué tiene SUID |
| World-writable en /etc | `chmod o-w <directorio>` |
| Archivo sin dueño | `chown root:root <archivo>` |

⚠️ No quites SUID de binarios del sistema (`passwd`, `sudo`) sin entender su función.

### Rollback

```bash
# Si rompiste algo, restaurar SUID original
chmod u+s /usr/bin/passwd
```

---

## 🛡️ Prevención

- [ ] Monitorear cambios en SUID con `aide` o `tripwire`
- [ ] Script de auditoría semanal en cron
- [ ] Política: "ningún script debe tener SUID"
- [ ] Usar `capabilities` de Linux en vez de SUID cuando sea posible

---

## 🧪 Variantes

### Buscar SUID en directorios específicos

```bash
find /usr/local /opt /home -type f -perm -4000 2>/dev/null
```

### Chequear sticky bit en /tmp

```bash
ls -ld /tmp | awk '{ print $1 }'
# Si no tiene 't' al final, falta sticky bit
```

---

## 🧑‍🏫 Modo docente

**Preguntas:** ¿Por qué `nmap` con SUID es peligroso? ¿Qué es un ataque TOCTOU con enlaces simbólicos?
**Ejercicio:** Hacer snapshot de SUID, instalar un paquete, detectar los cambios. Proponer una política de monitoreo automático.
**Evaluación:** identificación correcta de SUID peligroso, snapshot funcional, mitigación sin romper el sistema.

---

## 🧪 Cómo practicarlo en el lab

```bash
cd labs && docker compose -f docker-compose.from-scratch.yml up -d ubuntu-bare
# Auditar SUID dentro del contenedor
docker exec -it ubuntu-bare bash
find / -type f -perm -4000 2>/dev/null | head -20
```

[Ver laboratorio completo →](../../labs/README.md)

---

## 🔗 Referencias

- [`guides/find.md`](../../guides/find.md) — `-perm`, `-nouser`, `-nogroup`
- [`guides/xargs.md`](../../guides/xargs.md) — ejecución sobre resultados
- [`guides/awk.md`](../../guides/awk.md) — formateo y filtrado
- [`guides/sort.md`](../../guides/sort.md) — ordenamiento
