# Escenario: Auditoría de archivos SUID y permisos inseguros

## Problema

Los archivos con permisos SUID/SGID (setuid/setgid) son un riesgo de seguridad: si un atacante logra ejecutarlos, puede escalar privilegios. Necesitamos auditar periódicamente estos archivos, detectar cambios y encontrar permisos inseguros.

## Pipeline: Encontrar todos los archivos SUID

```bash
find / -type f -perm -4000 2>/dev/null \
  | xargs -I {} ls -la {} \
  | awk '{ print $1, $3, $4, $NF }' \
  | sort -k4
```

### Explicación paso a paso

1. **`find / -type f -perm -4000`** — Busca archivos con bit SUID (4000 octal). `-perm -4000` significa "todos los bits de 4000 deben estar presentes"
2. **`2>/dev/null`** — Descarta errores de permisos (directorios sin acceso)
3. **`xargs -I {} ls -la {}`** — Ejecuta `ls -la` por cada archivo encontrado
4. **`awk '{ print $1, $3, $4, $NF }'`** — Extrae permisos, owner, grupo, nombre
5. **`sort -k4`** — Ordena por nombre de archivo

## Pipeline: Archivos SGID

```bash
find / -type f -perm -2000 2>/dev/null \
  | xargs -I {} ls -la {} \
  | awk '{ print $1, $3, $4, $NF }'
```

## Pipeline: Buscar cambios en archivos SUID (con comparación)

```bash
# Tomar snapshot inicial
find / -type f -perm -4000 2>/dev/null | sort > /tmp/suid_before.txt

# ... tiempo después ...
find / -type f -perm -4000 2>/dev/null | sort > /tmp/suid_after.txt

# Comparar
diff /tmp/suid_before.txt /tmp/suid_after.txt \
  | awk '{
      if ($1 == ">") print "AÑADIDO:", $2
      if ($1 == "<") print "ELIMINADO:", $2
    }'
```

## Pipeline: Directorios world-writable

```bash
find / -type d -perm -o+w 2>/dev/null \
  | grep -v "^/proc\|^/sys\|^/dev" \
  | head -30 \
  | xargs -I {} ls -ld {} \
  | awk '{ print $1, $NF }'
```

## Pipeline: Archivos sin dueño ni grupo

```bash
find / -type f \( -nouser -o -nogroup \) 2>/dev/null \
  | xargs -I {} ls -la {} \
  | awk '{ print $1, $3, $4, $NF, "-> ORPHAN" }'
```

## Pipeline: Archivos con permisos 777

```bash
find / -type f -perm 777 2>/dev/null \
  | head -30 \
  | xargs -I {} ls -la {} \
  | awk '{ print $1, $NF }'
```

## Pipeline: Enlaces simbólicos rotos (potencial race condition)

```bash
find / -type l ! -exec test -e {} \; 2>/dev/null \
  -print \
  | head -20 \
  | while read link; do
      target=$(readlink "$link")
      echo "ROTO: $link -> $target"
    done
```

## Pipeline: Auditoría completa de permisos

```bash
#!/bin/bash
echo "=== AUDITORÍA DE PERMISOS ==="
echo ""

echo "Archivos con SUID:"
find / -type f -perm -4000 2>/dev/null | wc -l

echo ""
echo "Archivos con SGID:"
find / -type f -perm -2000 2>/dev/null | wc -l

echo ""
echo "Directorio world-writable:"
find / -type d -perm -o+w 2>/dev/null | grep -v "^/proc\|^/sys\|^/dev" | wc -l

echo ""
echo "Archivos sin dueño:"
find / -type f -nouser 2>/dev/null | wc -l

echo ""
echo "Archivos sin grupo:"
find / -type f -nogroup 2>/dev/null | wc -l

echo ""
echo "Archivos 777:"
find / -type f -perm 777 2>/dev/null | wc -l

echo ""
echo "=== SUID peligroso detectado ==="
find / -type f -perm -4000 2>/dev/null \
  | xargs -I {} ls -la {} \
  | awk '
    /nmap|find|vim|less|more|bash|sh|python|perl/ {
      print "PELIGROSO:", $NF, "- puede usarse para escalar privilegios"
    }'
```

## Interpretación

| Hallazgo | Riesgo | Acción |
|----------|--------|--------|
| SUID en binarios no estándar | Alto | Investigar por qué tiene SUID |
| SUID en scripts (bash, python, perl) | Crítico | Escalada directa a root |
| World-writable en /etc | Crítico | Cualquier usuario puede modificar configs |
| Archivos sin dueño | Medio | Posible remanente de paquete desinstalado |
| Enlaces rotos en /tmp | Bajo-Medio | Posible race condition (TOCTOU) |
| Directorios sin sticky bit | Medio | Cualquiera puede borrar archivos ajenos |

## Comandos relacionados

- [`find.md`](../../guides/find.md) — `-perm`, `-nouser`, `-nogroup`, `-type`
- [`xargs.md`](../../guides/xargs.md) — ejecución de comandos sobre resultados
- [`awk.md`](../../guides/awk.md) — formateo y filtrado de salida
- [`sort.md`](../../guides/sort.md) + [`diff`] — comparación de snapshots
