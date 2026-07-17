#!/bin/bash
BACKUP_DIR="/root/ops-practice/backups/redis"
DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="/root/ops-practice/backups/backup.log"

mkdir -p $BACKUP_DIR
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting Redis backup..." >> $LOG_FILE

# 方法1: 使用BGSAVE生成RDB快照（不阻塞服务）
docker exec redis-test redis-cli BGSAVE

# 等2秒让BGSAVE完成
sleep 2

# 复制RDB文件出来
docker cp redis-test:/data/dump.rdb $BACKUP_DIR/redis_rdb_$DATE.rdb

# 方法2: 同时备份AOF文件（如果开启了）
docker exec redis-test redis-cli CONFIG GET appendonly 2>/dev/null | grep -q "yes"
if [ $? -eq 0 ]; then
    docker cp redis-test:/data/appendonly.aof $BACKUP_DIR/redis_aof_$DATE.aof 2>/dev/null
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] AOF backup done" >> $LOG_FILE
fi

# 压缩RDB
gzip -f $BACKUP_DIR/redis_rdb_$DATE.rdb

# 删除7天前的备份
find $BACKUP_DIR -name "redis_rdb_*.rdb.gz" -mtime +7 -delete
find $BACKUP_DIR -name "redis_aof_*.aof" -mtime +7 -delete

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Redis backup success: redis_rdb_${DATE}.rdb.gz" >> $LOG_FILE
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Done." >> $LOG_FILE
