#!/usr/bin/env bash
# nekoimi 2023-04-17

# define
WORKSPACE_DIR=/opt/backup
COMMAND=$1
NOW_DATE=$(date +"%Y-%m-%d")

echo "----------------- define -----------------"
echo "DEFINE: WORKSPACE_DIR --->  $WORKSPACE_DIR"
echo "DEFINE: COMMAND --------->  $COMMAND"

# 配置
VAR_DB_HOST=${BACKUP_DB_HOST:-"NO_HOST"}
VAR_DB_PORT=${BACKUP_DB_PORT:-"NO_PORT"}
VAR_USER=${BACKUP_USER:-"NO_USER"}
VAR_PASSWORD=${BACKUP_PASSWORD:-"NO_PASS"}
VAR_DB=${BACKUP_DB:-""}
VAR_STORAGE_NUMBER=${BACKUP_STORAGE_NUMBER:-"30"}

echo "----------------- config -----------------"
echo "CONFIG: DB_HOST --------------->  $VAR_DB_HOST"
echo "CONFIG: DB_PORT --------------->  $VAR_DB_PORT"
echo "CONFIG: USER ------------------>  $VAR_USER"
echo "CONFIG: PASSWORD -------------->  $VAR_PASSWORD"
echo "CONFIG: DB -------------------->  $VAR_DB"
echo "CONFIG: STORAGE_NUMBER -------->  $VAR_STORAGE_NUMBER"

# Function
FUNC_NOW_TIME() {
  _TIME=$(date +"%Y-%m-%d %H:%M:%S")
  echo "$_TIME"
}

FUNC_BACKUP_EXECUTE() {
  BACKUP_DB=$1
  echo "创建备份: $BACKUP_DB"
  BACKUP_SAVE_DIR="$WORKSPACE_DIR/$BACKUP_DB"
  mkdir -p "$BACKUP_SAVE_DIR"
  # Backup
  BACKUP_COMMAND="mysqldump --single-transaction -u $VAR_USER -p$VAR_PASSWORD -h $VAR_DB_HOST -P $VAR_DB_PORT --databases $BACKUP_DB > $BACKUP_SAVE_DIR/$NOW_DATE.sql"
  echo "$BACKUP_COMMAND"
  mysqldump --single-transaction -u $VAR_USER -p$VAR_PASSWORD -h $VAR_DB_HOST -P $VAR_DB_PORT --databases $BACKUP_DB > "$BACKUP_SAVE_DIR/$NOW_DATE.sql"
  echo "backup: $BACKUP_DB at $(FUNC_NOW_TIME)" >> "$BACKUP_SAVE_DIR/backup.log"
}

FUNC_CLEANUP_EXECUTE() {
  BACKUP_DB=$1
  echo "清理备份: $BACKUP_DB"
  # Cleanup
  BACKUP_SAVE_DIR="$WORKSPACE_DIR/$BACKUP_DB"
  if [ -d $BACKUP_SAVE_DIR ]; then
    # 统计已有的备份数量
    BACKUP_COUNT=$(ls -lcrt $BACKUP_SAVE_DIR/*.sql | awk 'NR>1 {print $9}' | wc -l)
    echo "已有 $BACKUP_COUNT 个备份"
    if [ $BACKUP_COUNT -gt $VAR_STORAGE_NUMBER ]; then
        BACKUP_CLEANUP_NUM=$(($BACKUP_COUNT - $VAR_STORAGE_NUMBER))
        echo "需要清除 $BACKUP_CLEANUP_NUM 个备份"
        CLEANUP_ARR=($(ls -lcrt $BACKUP_SAVE_DIR/*.sql | awk '{print $9}' | head -$BACKUP_CLEANUP_NUM))
        for CLEANUP_FILE in "${CLEANUP_ARR[@]}" ; do
          echo "清除: $CLEANUP_FILE"
          rm -f $CLEANUP_FILE && echo "cleanup: $CLEANUP_FILE at $(FUNC_NOW_TIME)" >> "$BACKUP_SAVE_DIR/cleanup.log"
        done
    fi
  fi
}

# 执行备份
echo "----------------- backup -----------------"
# VAR_DB 可能是多个数据库，需要循环备份
DB_NAME_ARR=($(echo "${VAR_DB}" | sed 's/,/ /g'))
for DB_NAME in "${DB_NAME_ARR[@]}" ; do
  echo ""
  FUNC_BACKUP_EXECUTE "$DB_NAME"
  FUNC_CLEANUP_EXECUTE "$DB_NAME"
  echo ""
done

echo "DONE."
