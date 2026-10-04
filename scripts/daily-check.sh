#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================="
echo "        每日运维巡检报告"
echo "        $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="
echo ""

echo -e "${YELLOW}[系统资源]${NC}"
echo "CPU负载: $(uptime | awk -F'load average:' '{print $2}')"
echo "内存使用:"
free -h | grep "Mem:" | awk '{printf "  总计: %s | 已用: %s | 可用: %s\n", $2, $3, $7}'
echo "磁盘使用:"
df -h | grep -E "/$|/data" | awk '{printf "  %s: %s/%s (%s)\n", $6, $3, $2, $5}'

DISK_USAGE=$(df -h / | tail -1 | awk '{print $5}' | tr -d '%')
if [ "$DISK_USAGE" -gt 80 ]; then
    echo -e "  ${RED}[警告] 磁盘使用率超过80%！当前：${DISK_USAGE}%${NC}"
    # 发送邮件告警，|| true 保证即使邮件失败脚本也不中断
    echo "服务器磁盘告警！当前使用率：${DISK_USAGE}%" | mail -s "【告警】磁盘不足" 1005840578@qq.com 2>/dev/null || true
else
    echo "  磁盘正常：${DISK_USAGE}%"
fi
echo ""

echo -e "${YELLOW}[Docker容器]${NC}"
RUNNING=$(docker ps -q | wc -l)
TOTAL=$(docker ps -aq | wc -l)
echo "运行中: $RUNNING / 总计: $TOTAL"
docker ps --format "  {{.Names}} | {{.Status}} | {{.Ports}}" 2>/dev/null || echo "  Docker未运行"
echo ""

echo -e "${YELLOW}[Nginx服务]${NC}"
NGINX_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ 2>/dev/null || echo "000")
if [ "$NGINX_STATUS" = "200" ]; then
    echo -e "  HTTP状态: ${GREEN}${NGINX_STATUS} OK${NC}"
else
    echo -e "  HTTP状态: ${RED}${NGINX_STATUS} 异常${NC}"
fi
echo ""

echo -e "${YELLOW}[网络连接]${NC}"
echo "当前TCP连接数: $(netstat -an 2>/dev/null | grep ESTABLISHED | wc -l)"
echo "监听端口:"
ss -tlnp 2>/dev/null | grep LISTEN | awk '{print $4}' | sort -u | head -5 | sed 's/^/  /'
echo ""

echo -e "${YELLOW}[Docker网络]${NC}"
docker network inspect app-network --format '{{range .Containers}}{{.Name}}: {{.IPv4Address}}{{println}}{{end}}' 2>/dev/null || echo "  app-network不存在"
echo ""

echo -e "${YELLOW}[今日访客/扫描统计]${NC}"
SCAN_COUNT=$(docker logs my-nginx --since 24h 2>/dev/null | grep -E 'GET|POST|HEAD' | awk '{print $1}' | sort -u | wc -l)
echo "  今日不同IP访问数: $SCAN_COUNT"
echo "  最新5个访问来源:"
docker logs my-nginx --since 24h 2>/dev/null | grep -E 'GET|POST|HEAD' | awk '{print $1}' | sort | uniq -c | sort -nr | head -5 | sed 's/^/    /'
echo ""

echo -e "${YELLOW}[今日面试题]${NC}"
QUESTIONS=(
    "Linux中，如何查看当前目录下每个子目录的大小？（du -sh *）"
    "Docker中，RUN和CMD的区别是什么？"
    "Nginx返回502和504分别代表什么？"
    "HTTP和HTTPS的区别？HTTPS为什么需要证书？"
    "Linux中，chmod 755是什么意思？"
    "如何查看一个进程打开了哪些文件？（lsof -p PID）"
    "TCP三次握手的过程是什么？"
    "Shell中，> 和 >> 的区别？"
    "如何查看系统最后100行日志？（tail -n 100 /var/log/messages）"
    "Docker容器之间如何通信？"
)
RANDOM_Q=${QUESTIONS[$RANDOM % ${#QUESTIONS[@]}]}
echo "  $RANDOM_Q"
echo ""

echo "=========================================="
echo "  巡检完成。如有异常，请立即处理。"
echo "=========================================="
