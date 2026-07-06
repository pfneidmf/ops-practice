#!/bin/bash
find /var/log/ops-monitor -name "monitor-*.log" -mtime +7 -delete 2>/dev/null
