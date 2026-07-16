#!/bin/bash

# 配置
BACKUP_DIR="/root/ops-practice/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/mysql_full_$DATE.sql"
LOG_FILE="$BACKUP_DIR/backup.log"
MYSQL_CONTAINER="mysql-test"
MYSQL_USER="root"
MYSQL_PASS="yourpass123"  # TODO: 改成你的实际密码

# 创建备份目录
mkdir -p $BACKUP_DIR

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting MySQL backup..." >> $LOG_FILE

# 执行备份
docker exec $MYSQL_CONTAINER mysqldump -u$MYSQL_USER -p$MYSQL_PASS --all-databases > $BACKUP_FILE 2>> $LOG_FILE

# 检查备份是否成功
if [ $? -eq 0 ]; then
    # 压缩备份文件
    gzip $BACKUP_FILE
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Backup success: ${BACKUP_FILE}.gz" >> $LOG_FILE
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Backup FAILED!" >> $LOG_FILE
    rm -f $BACKUP_FILE
    exit 1
fi

# 删除7天前的备份
find $BACKUP_DIR -name "mysql_full_*.sql.gz" -mtime +7 -delete

# 显示当前备份列表
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Current backups:" >> $LOG_FILE
ls -lh $BACKUP_DIR/*.sql.gz 2>/dev/null >> $LOG_FILE

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Done." >> $LOG_FILE
