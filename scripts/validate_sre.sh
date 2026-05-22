#!/bin/sh
set -eu

echo "🔍 Validando estándares SRE..."

fail() {
  echo "❌ ERROR: $1"
  exit 1
}

# Detectar solo usos "reales" (comando grep), no menciones en Markdown.
# Regla: el carácter anterior a "grep" debe ser inicio de línea o espacio o separador típico (; | &)
# y no un backtick.
if grep -R -n -E '(^|[[:space:];|&])grep[[:space:]][^#`]*[[:space:]]-P([[:space:]]|$)' scenarios/ >/dev/null 2>&1; then
  fail "uso de grep -P encontrado (no portable)"
fi

# También bloquear grep -oP (más común que -P solo)
if grep -R -n -E '(^|[[:space:];|&])grep[[:space:]][^#`]*[[:space:]]-oP([[:space:]]|$)' scenarios/ >/dev/null 2>&1; then
  fail "uso de grep -oP encontrado (no portable)"
fi

# Bloquear process substitution <(  (bashismo)
if grep -R -n "<(" scenarios/ >/dev/null 2>&1; then
  fail "process substitution <( encontrado (no POSIX)"
fi

echo "✅ Validación SRE OK"
exit 0
