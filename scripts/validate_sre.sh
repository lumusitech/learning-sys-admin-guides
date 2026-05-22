#!/bin/sh

echo "🔍 Validando estándares SRE..."

# 1. grep -P (NO permitido)
if grep -R "grep -P" scenarios/ >/dev/null 2>&1; then
  echo "❌ ERROR: grep -P encontrado"
  exit 1
fi

# 2. \K (NO permitido)
if grep -R "\\K" scenarios/ >/dev/null 2>&1; then
  echo "❌ ERROR: uso de \\K encontrado"
  exit 1
fi

# 3. process substitution (NO POSIX)
if grep -R "<(" scenarios/ >/dev/null 2>&1; then
  echo "❌ ERROR: process substitution <( encontrado"
  exit 1
fi

# 4. Validación OK
echo "✅ Validación SRE OK"
exit 0
