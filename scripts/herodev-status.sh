#!/bin/bash
# herodev-status - Retorna status de um serviço em JSON

SERVICE=$1

if [ -z "$SERVICE" ]; then
    echo '{"error":"Usage: herodev-status <service-name>"}'
    exit 1
fi

if systemctl is-active --quiet "$SERVICE"; then
    STATUS="running"
    PID=$(systemctl show -p MainPID --value "$SERVICE")
    UPTIME=$(systemctl show -p ActiveEnterTimestamp --value "$SERVICE")
    MEMORY=$(systemctl show -p MemoryCurrent --value "$SERVICE" 2>/dev/null || echo "0")
    
    echo "{\"service\":\"$SERVICE\",\"status\":\"$STATUS\",\"pid\":$PID,\"uptime\":\"$UPTIME\",\"memory\":$MEMORY}"
else
    echo "{\"service\":\"$SERVICE\",\"status\":\"stopped\",\"pid\":null,\"uptime\":null,\"memory\":0}"
fi
