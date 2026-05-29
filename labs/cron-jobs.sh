#!/bin/sh
# cron-jobs.sh — Simula diferentes tipos de fallos de cron para práctica
# Uso: llamado desde crontab

LOGFILE="/var/log/cron-jobs.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

log() {
    echo "[$TIMESTAMP] $1" >> "$LOGFILE"
}

case "$1" in
    backup)
        log "BACKUP: Iniciando backup diario..."
        mkdir -p /tmp/backup
        tar czf /tmp/backup/backup-$(date +%Y%m%d).tar.gz /etc 2>/dev/null
        log "BACKUP: Completado OK"
        ;;

    reporte-roto)
        # Este job falla porque usa un comando que no existe
        log "REPORTE: Generando reporte..."
        generar-reporte --output /tmp/reporte.txt 2>&1
        # Si el comando falla, no se loguea el error (fallo silencioso)
        ;;

    limpieza-sin-permisos)
        # Este job falla por falta de permisos
        log "LIMPIEZA: Limpiando archivos temporales..."
        rm -rf /var/log/* 2>&1
        # Si falla por permisos, no se loguea
        ;;

    notificacion)
        # Este job intenta enviar mail pero no hay MTA
        log "NOTIF: Enviando notificación..."
        echo "Reporte diario: todo OK" | mail -s "Reporte" admin@empresa.com 2>&1
        # Si falla el mail, el error va a /var/mail/root o se pierde
        ;;

    *)
        log "UNKNOWN: Job desconocido: $1"
        ;;
esac
