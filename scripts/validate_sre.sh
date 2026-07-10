#!/bin/sh
set -eu

echo "🔍 Validando estándares SRE..."

ERRORS=0
TARGETS="scenarios/"

fail() {
  echo "❌ $1"
  ERRORS=$((ERRORS + 1))
}

show_matches() {
  echo "   Archivos afectados:"
  echo "$1" | sed 's/^/   /'
}

# grep -P (PCRE, no portable)
matches=$(grep -R -n -E '(^|[[:space:];|&])grep[[:space:]][^#`]*[[:space:]]-P([[:space:]]|$)' $TARGETS 2>/dev/null || true)
if [ -n "$matches" ]; then
  fail "grep -P encontrado (no portable)"
  show_matches "$matches"
fi

# grep -oP (combinación común)
matches=$(grep -R -n -E '(^|[[:space:];|&])grep[[:space:]][^#`]*[[:space:]]-oP([[:space:]]|$)' $TARGETS 2>/dev/null || true)
if [ -n "$matches" ]; then
  fail "grep -oP encontrado (no portable)"
  show_matches "$matches"
fi

# sed -r (GNU-only, no en BusyBox)
matches=$(grep -R -n -E '(^|[[:space:];|&])sed[[:space:]][^#`]*[[:space:]]-r([[:space:]]|$)' $TARGETS 2>/dev/null || true)
if [ -n "$matches" ]; then
  fail "sed -r encontrado (GNU-only, usar BRE o -E en sed POSIX)"
  show_matches "$matches"
fi

# sort -V (GNU-only, no en BusyBox)
matches=$(grep -R -n -E '(^|[[:space:];|&])sort[[:space:]][^#`]*[[:space:]]-V([[:space:]]|$)' $TARGETS 2>/dev/null || true)
if [ -n "$matches" ]; then
  fail "sort -V encontrado (GNU-only, no portable)"
  show_matches "$matches"
fi

# [[ ]] — bashismo condicional (solo en bloques de código sh/bash, no en markdown)
matches=$(grep -R -n -E '^[^#`]*\[\[[[:space:]]' $TARGETS 2>/dev/null || true)
if [ -n "$matches" ]; then
  fail "[[ ]] encontrado (bashismo, usar test o [ en POSIX)"
  show_matches "$matches"
fi

# Process substitution <(
matches=$(grep -R -n "<(" $TARGETS 2>/dev/null || true)
if [ -n "$matches" ]; then
  fail "process substitution <( encontrado (no POSIX)"
  show_matches "$matches"
fi

# Arrays bash: var=(  )
matches=$(grep -R -n -E '(^|[[:space:]])[a-zA-Z_][a-zA-Z0-9_]*=(\([[:space:]]*[^)]' $TARGETS 2>/dev/null || true)
if [ -n "$matches" ]; then
  fail "arrays bash (var=(...)) encontrado (no POSIX)"
  show_matches "$matches"
fi

# ${!var} indirect expansion (bashismo)
matches=$(grep -R -n '\${![a-zA-Z_]}' $TARGETS 2>/dev/null || true)
if [ -n "$matches" ]; then
  fail "indirect expansion \${!var} encontrado (bashismo, no POSIX)"
  show_matches "$matches"
fi

# (( )) arithmetic (bashismo, usar expr o $(( )))
matches=$(grep -R -n -E '(^|[[:space:]])\(\([[:space:]]*[a-zA-Z]' $TARGETS 2>/dev/null || true)
if [ -n "$matches" ]; then
  fail "aritmética (( )) encontrada (bashismo, usar expr o \$(( )) en POSIX)"
  show_matches "$matches"
fi

# local — not POSIX (bash/dash/zsh extension)
matches=$(grep -R -n -E '(^|[[:space:];])local[[:space:]]+[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*[=(]' $TARGETS 2>/dev/null || true)
if [ -n "$matches" ]; then
  fail "keyword 'local' encontrado (bashismo, no POSIX)"
  show_matches "$matches"
fi

if [ "$ERRORS" -gt 0 ]; then
  echo "❌ Validación SRE: $ERRORS error(es) encontrado(s)"
  exit 1
fi

echo "✅ Validación SRE OK"
exit 0
