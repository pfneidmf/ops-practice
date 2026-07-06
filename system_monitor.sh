#!/bin/bash
LOG="/var/log/ops-monitor/monitor-$(date +%Y%m%d).log"
mkdir -p /var/log/ops-monitor
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 | xargs)
MEM=$(free | awk 'NR==2{printf "%.1f", $3*100/$2}')
DISK=$(df -h / | awk 'NR==2{print $5}' | tr -d '%')
echo "[$TIMESTAMP] CPU:${CPU}% MEM:${MEM}% DISK:${DISK}%" >> $LOG
