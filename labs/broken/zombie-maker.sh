#!/bin/sh
# zombie-maker.sh — Crea un proceso zombie para práctica de diagnóstico
# El padre (este script) crea un hijo que termina inmediatamente,
# pero el padre NO llama a wait(), así que el hijo queda como zombie.

echo "=== Creando proceso zombie ==="

# Crear un proceso hijo que termina inmediatamente
( exit 0 ) &
CHILD_PID=$!

# El padre NO hace wait() — el hijo queda como zombie
# Mantener el padre vivo con sleep infinito
echo "Zombie creado. PID hijo: $CHILD_PID"
echo "Buscalo con: ps aux | grep Z"
echo "El PPID del zombie es este script (PID $$)"

# Mantener el padre vivo
while true; do sleep 1000; done
