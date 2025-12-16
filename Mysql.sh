#!/bin/bash

# MySQL Docker部署和初始化脚本
set -e

echo "开始部署MySQL容器和初始化数据库..."

# 检查/docker/mysql目录是否存在
if [ -d "/docker/mysql" ]; then
    echo "发现已存在的MySQL目录: /docker/mysql"
    echo "目录内容:"
    ls -la /docker/mysql/

    read -p "是否清空现有目录并重新部署? (y/n): " CLEAR_DIR

    if [ "$CLEAR_DIR" = "y" ] || [ "$CLEAR_DIR" = "Y" ]; then
        echo "清空现有目录..."
        rm -rf /docker/mysql/*
        rm -rf /docker/mysql/.* 2>/dev/null || true
        echo "目录已清空"

        # 重新创建目录结构
        mkdir -p /docker/mysql/conf
        mkdir -p /docker/mysql/data
        mkdir -p /docker/mysql/log

        DIR_CLEARED=true
    else
        echo "保留现有目录继续执行..."

        # 确保必要的子目录存在
        mkdir -p /docker/mysql/conf
        mkdir -p /docker/mysql/data
        mkdir -p /docker/mysql/log

        # 检查是否有配置文件
        if [ -f "/docker/mysql/conf/my.cnf" ]; then
            read -p "发现现有配置文件 /docker/mysql/conf/my.cnf，是否覆盖? (y/n): " OVERRIDE_CONFIG
            if [ "$OVERRIDE_CONFIG" = "n" ] || [ "$OVERRIDE_CONFIG" = "N" ]; then
                SKIP_CONFIG=true
                echo "将使用现有配置文件"
            fi
        fi
    fi
fi

# 如果目录不存在或已被清空，则创建目录
if [ ! -d "/docker/mysql" ] || [ "$DIR_CLEARED" = "true" ]; then
    echo "创建目录..."
    mkdir -p /docker/mysql/conf
    mkdir -p /docker/mysql/data
    mkdir -p /docker/mysql/log
fi

# 创建MySQL配置文件（如果需要）
if [ "$SKIP_CONFIG" != "true" ]; then
    echo "创建MySQL配置文件..."
    cat > /docker/mysql/conf/my.cnf << 'EOF'
[client]
# 端口号
port=3306

[mysql]
no-beep
# 配置了 MySQL 客户端的默认字符集
default-character-set=utf8mb4

[mysqld]
# 端口号
port=3306
# 数据目录
datadir=/var/lib/mysql
# 设置了 MySQL 服务器的字符集为 UTF-8
character-set-server=utf8mb4
# 设置了 MySQL 服务器的排序规则为 utf8mb4_unicode_ci，通常用于支持国际化和多语言字符的正确排序
collation-server=utf8mb4_unicode_ci
# 用于禁用客户端字符集握手，允许客户端和服务器之间的字符集设置更加灵活
skip-character-set-client-handshake
# 禁用了主机名解析，以提高连接性能
skip-name-resolve
# 默认存储引擎
default-storage-engine=INNODB
# 将 SQL 模式设置为严格
sql-mode="STRICT_TRANS_TABLES,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION"
#  最大连接数
max_connections=1024
# 表缓存
table_open_cache=2000
# 表内存
tmp_table_size=16M
# 线程缓存
thread_cache_size=10
# 设置大小写不敏感
lower_case_table_names=1
# 设置数据库的默认时区为 UTC+8
default_time_zone = '+8:00'

# myisam设置
myisam_max_sort_file_size=100G
myisam_sort_buffer_size=8M
key_buffer_size=8M
read_buffer_size=0
read_rnd_buffer_size=0

# innodb设置
innodb_flush_log_at_trx_commit=1
innodb_log_buffer_size=1M
innodb_buffer_pool_size=8M
innodb_log_file_size=48M
innodb_thread_concurrency=33
innodb_autoextend_increment=64
innodb_buffer_pool_instances=8
innodb_concurrency_tickets=5000
innodb_old_blocks_time=1000
innodb_open_files=300
innodb_stats_on_metadata=0
innodb_file_per_table=1
innodb_checksum_algorithm=0
# 其他设置
back_log=80
flush_time=0
join_buffer_size=256K
max_allowed_packet=4M
max_connect_errors=100
open_files_limit=4161
sort_buffer_size=256K
table_definition_cache=1400
binlog_row_event_max_size=8K
sync_master_info=10000
sync_relay_log=10000
sync_relay_log_info=10000
EOF

    echo "MySQL配置文件已创建: /docker/mysql/conf/my.cnf"
fi

# 检查是否已存在MySQL容器
EXISTING_CONTAINER=$(docker ps -a | grep mysql | awk '{print $1}')
if [ ! -z "$EXISTING_CONTAINER" ]; then
    echo "发现已存在的MySQL容器: $EXISTING_CONTAINER"
    read -p "是否停止并删除现有容器? (y/n): " DELETE_EXISTING
    if [ "$DELETE_EXISTING" = "y" ] || [ "$DELETE_EXISTING" = "Y" ]; then
        echo "停止并删除现有容器..."
        docker stop $EXISTING_CONTAINER 2>/dev/null || true
        docker rm $EXISTING_CONTAINER 2>/dev/null || true
        echo "现有容器已删除"
    else
        echo "使用现有容器继续执行..."
        MYSQL_CONTAINER=$EXISTING_CONTAINER
    fi
fi

# 如果容器不存在或已被删除，则创建新容器
if [ -z "$MYSQL_CONTAINER" ]; then
    # 检查是否有旧的数据目录，询问是否备份
    if [ -d "/docker/mysql/data" ] && [ "$(ls -A /docker/mysql/data 2>/dev/null)" ]; then
        echo "发现数据目录中存在数据: /docker/mysql/data"
        read -p "是否备份现有数据? (y/n): " BACKUP_DATA

        if [ "$BACKUP_DATA" = "y" ] || [ "$BACKUP_DATA" = "Y" ]; then
            BACKUP_DIR="/docker/mysql/backup_$(date +%Y%m%d_%H%M%S)"
            echo "正在备份数据到: $BACKUP_DIR"
            mkdir -p "$BACKUP_DIR"
            cp -r /docker/mysql/data/* "$BACKUP_DIR/" 2>/dev/null || true
            cp -r /docker/mysql/conf/* "$BACKUP_DIR/" 2>/dev/null || true
            echo "备份完成: $BACKUP_DIR"
        else
            echo "不备份数据，继续执行..."
        fi
    fi

    # 拉取MySQL 5.7镜像
    echo "拉取MySQL 5.7镜像..."
    docker pull mysql:5.7

    # 运行MySQL容器
    echo "启动MySQL容器..."
    docker run \
    --name mysql \
    -d \
    -p 3306:3306 \
    --restart=always \
    -v /docker/mysql/log:/var/log/mysql \
    -v /docker/mysql/data:/var/lib/mysql \
    -v /docker/mysql/conf:/etc/mysql/conf.d \
    -v /etc/localtime:/etc/localtime:ro \
    -e MYSQL_ROOT_PASSWORD=root \
    mysql:5.7

    MYSQL_CONTAINER="mysql"

    # 等待MySQL启动
    echo "等待MySQL服务启动..."
    sleep 30
fi

# 检查容器状态
if ! docker ps | grep -q $MYSQL_CONTAINER; then
    echo "MySQL容器未运行，尝试启动..."
    docker start $MYSQL_CONTAINER
    sleep 15
fi

# 测试MySQL连接
echo "测试MySQL连接..."
if ! docker exec $MYSQL_CONTAINER mysql -uroot -proot -e "SELECT 1;" &>/dev/null; then
    echo "MySQL连接测试失败，请检查容器状态"
    echo "查看日志: docker logs $MYSQL_CONTAINER"
    exit 1
fi

echo "MySQL连接测试成功！"

# 生成随机密码
RANDOM_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)

# 创建SQL文件 - 修复SQL语句，移除IF NOT EXISTS语法
SQL_FILE="./initMysql.sql"

cat > $SQL_FILE << EOF
CREATE DATABASE IF NOT EXISTS \`burp_monitor\`;
USE \`burp_monitor\`;

CREATE USER IF NOT EXISTS 'burp_user'@'%' IDENTIFIED BY '$RANDOM_PASSWORD';
GRANT ALL PRIVILEGES ON \`burp_monitor\`.* TO 'burp_user'@'%';
FLUSH PRIVILEGES;

-- 创建表（使用简单的CREATE TABLE语法）
CREATE TABLE \`http_traffic\` (
    \`id\` VARCHAR(36) PRIMARY KEY,
    \`timestamp\` DATETIME NOT NULL,
    \`tool\` VARCHAR(50) NOT NULL,
    \`host\` VARCHAR(255) NOT NULL,
    \`port\` INT NOT NULL,
    \`protocol\` VARCHAR(10) NOT NULL,
    \`method\` VARCHAR(10) NOT NULL,
    \`url\` TEXT NOT NULL,
    \`path\` TEXT NOT NULL,
    \`query_string\` TEXT,
    \`request_headers\` MEDIUMTEXT,
    \`request_body\` MEDIUMTEXT,
    \`request_length\` INT,
    \`response_headers\` MEDIUMTEXT,
    \`response_body\` MEDIUMTEXT,
    \`response_length\` INT,
    \`status_code\` INT,
    \`mime_type\` VARCHAR(100),
    \`is_complete\` BOOLEAN DEFAULT FALSE,
    \`team_id\` VARCHAR(50)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 单独创建索引（不使用IF NOT EXISTS）
CREATE INDEX idx_timestamp ON \`http_traffic\`(\`timestamp\`);
CREATE INDEX idx_tool ON \`http_traffic\`(\`tool\`);
CREATE INDEX idx_host ON \`http_traffic\`(\`host\`);
CREATE INDEX idx_method ON \`http_traffic\`(\`method\`);
CREATE INDEX idx_status_code ON \`http_traffic\`(\`status_code\`);
CREATE INDEX idx_is_complete ON \`http_traffic\`(\`is_complete\`);
CREATE INDEX idx_tool_timestamp ON \`http_traffic\`(\`tool\`, \`timestamp\` DESC);
CREATE INDEX idx_team_id ON \`http_traffic\`(\`team_id\`);

-- 添加注释
ALTER TABLE \`http_traffic\` COMMENT = 'HTTP流量监控数据表';

EOF

echo "SQL文件已生成: $SQL_FILE"

# 导入到MySQL容器
echo "正在导入SQL到MySQL容器..."
docker exec -i $MYSQL_CONTAINER mysql -uroot -proot < $SQL_FILE

if [ $? -eq 0 ]; then
    echo "=========================================="
    echo "MySQL部署和初始化成功！"
    echo "=========================================="
    echo "容器信息:"
    echo "   容器名称: $MYSQL_CONTAINER"
    echo "   端口: 3306"
    echo "   root密码: root"
    echo ""
    echo "应用数据库信息:"
    echo "   主机: % (任何主机)"
    echo "   端口: 3306"
    echo "   用户名: burp_user"
    echo "   密码: $RANDOM_PASSWORD"
    echo "   数据库: burp_monitor"
    echo "   表: http_traffic"
    echo ""
    echo "数据目录: /docker/mysql/data"
    echo "配置目录: /docker/mysql/conf"
    echo "日志目录: /docker/mysql/log"
    echo "=========================================="

    # 测试burp_user连接
    echo "测试burp_user连接..."
    if docker exec -i $MYSQL_CONTAINER mysql -uburp_user -p$RANDOM_PASSWORD -e "USE burp_monitor; SHOW TABLES;" &>/dev/null; then
        echo "burp_user连接测试成功！"

        # 显示表结构
        echo "检查表结构..."
        docker exec -i $MYSQL_CONTAINER mysql -uburp_user -p$RANDOM_PASSWORD -e "USE burp_monitor; DESCRIBE http_traffic;" 2>/dev/null || echo "无法显示表结构"

        # 显示索引
        echo "检查索引..."
        docker exec -i $MYSQL_CONTAINER mysql -uburp_user -p$RANDOM_PASSWORD -e "USE burp_monitor; SHOW INDEX FROM http_traffic;" 2>/dev/null || echo "无法显示索引"
    else
        echo "burp_user连接测试失败，但数据库已创建"
    fi

    # 清理临时文件
    rm -f $SQL_FILE
    echo "临时SQL文件已清理"
else
    echo "错误: SQL导入失败"
    echo "请检查:"
    echo "1. MySQL容器是否正在运行"
    echo "2. root密码是否正确"
    echo "3. 可以手动执行: docker exec -it $MYSQL_CONTAINER mysql -uroot -proot"
    exit 1
fi

echo "所有操作完成！"