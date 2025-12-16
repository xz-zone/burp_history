#!/bin/bash

# PostgreSQL Docker部署脚本
set -e

echo "开始部署PostgreSQL容器..."

# 检查/docker/postgres目录是否存在
if [ -d "/docker/postgres" ]; then
    echo "发现已存在的PostgreSQL目录: /docker/postgres"
    echo "目录内容:"
    ls -la /docker/postgres/

    read -p "是否清空现有目录并重新部署? (y/n): " CLEAR_DIR

    if [ "$CLEAR_DIR" = "y" ] || [ "$CLEAR_DIR" = "Y" ]; then
        echo "清空现有目录..."
        rm -rf /docker/postgres/*
        rm -rf /docker/postgres/.* 2>/dev/null || true
        echo "目录已清空"

        # 重新创建目录结构
        mkdir -p /docker/postgres/conf
        mkdir -p /docker/postgres/data
        mkdir -p /docker/postgres/log
        chmod 755 /docker/postgres/{data,log,conf} 2>/dev/null || true

        DIR_CLEARED=true
    else
        echo "保留现有目录继续执行..."

        # 确保必要的子目录存在
        mkdir -p /docker/postgres/conf
        mkdir -p /docker/postgres/data
        mkdir -p /docker/postgres/log

        # 检查是否有配置文件
        if [ -f "/docker/postgres/conf/postgresql.conf" ] || [ -f "/docker/postgres/conf/pg_hba.conf" ]; then
            read -p "发现现有配置文件，是否覆盖? (y/n): " OVERRIDE_CONFIG
            if [ "$OVERRIDE_CONFIG" = "n" ] || [ "$OVERRIDE_CONFIG" = "N" ]; then
                SKIP_CONFIG=true
                echo "将使用现有配置文件"
            fi
        fi

        # 检查是否有密码文件
        if [ -f "/docker/postgres/passwords.txt" ]; then
            read -p "发现现有密码文件，是否备份? (y/n): " BACKUP_PASSWORD
            if [ "$BACKUP_PASSWORD" = "y" ] || [ "$BACKUP_PASSWORD" = "Y" ]; then
                BACKUP_FILE="/docker/postgres/passwords_backup_$(date +%Y%m%d_%H%M%S).txt"
                cp /docker/postgres/passwords.txt "$BACKUP_FILE"
                echo "密码文件已备份到: $BACKUP_FILE"
            fi
        fi
    fi
fi

# 如果目录不存在或已被清空，则创建目录
if [ ! -d "/docker/postgres" ] || [ "$DIR_CLEARED" = "true" ]; then
    echo "创建目录并设置权限..."
    mkdir -p /docker/postgres/conf
    mkdir -p /docker/postgres/data
    mkdir -p /docker/postgres/log
    chmod 755 /docker/postgres/{data,log,conf}
fi

# 生成随机密码函数
generate_random_password() {
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1
}

# 生成随机密码
echo "生成随机密码..."
POSTGRES_PASSWORD=$(generate_random_password)
BURP_USER_PASSWORD=$(generate_random_password)

# 保存密码到文件
PASSWORD_FILE="/docker/postgres/passwords.txt"
cat > $PASSWORD_FILE << EOF
# Burp Traffic Recorder PostgreSQL 密码文件
# 生成时间: $(date)
# 请妥善保管此文件！

PostgreSQL root 用户密码: $POSTGRES_PASSWORD
Burp Traffic Recorder 数据库用户密码: $BURP_USER_PASSWORD

数据库连接信息:
主机: localhost 或 服务器IP
端口: 5432
数据库: burp_monitor
用户名: burp_user
密码: $BURP_USER_PASSWORD

EOF

chmod 600 $PASSWORD_FILE

echo "随机密码已生成并保存到: $PASSWORD_FILE"

# 创建PostgreSQL配置文件（如果需要）
if [ "$SKIP_CONFIG" != "true" ]; then
    echo "创建PostgreSQL配置文件..."
    cat > /docker/postgres/conf/postgresql.conf << 'EOF'
# PostgreSQL Configuration File

#------------------------------------------------------------------------------
# CONNECTIONS AND AUTHENTICATION
#------------------------------------------------------------------------------

listen_addresses = '*'
port = 5432
max_connections = 100

#------------------------------------------------------------------------------
# RESOURCE USAGE
#------------------------------------------------------------------------------

shared_buffers = 128MB
work_mem = 4MB
maintenance_work_mem = 64MB

#------------------------------------------------------------------------------
# WRITE-AHEAD LOG
#------------------------------------------------------------------------------

wal_level = replica
fsync = on
synchronous_commit = on

#------------------------------------------------------------------------------
# ERROR REPORTING AND LOGGING
#------------------------------------------------------------------------------

log_destination = stderr
logging_collector = off

#------------------------------------------------------------------------------
# CLIENT CONNECTION DEFAULTS
#------------------------------------------------------------------------------

timezone = 'Asia/Shanghai'
EOF

    # 创建客户端认证配置文件
    cat > /docker/postgres/conf/pg_hba.conf << 'EOF'
# PostgreSQL Client Authentication Configuration File

# TYPE  DATABASE        USER            ADDRESS                 METHOD

local   all             all                                     trust
host    all             all             127.0.0.1/32            trust
host    all             all             ::1/128                 trust
local   replication     all                                     trust
host    replication     all             127.0.0.1/32            trust
host    replication     all             ::1/128                 trust
host    burp_monitor    burp_user       0.0.0.0/0               md5
host    all             all             0.0.0.0/0               md5
EOF

    echo "PostgreSQL配置文件已创建"
fi

# 检查是否已存在PostgreSQL容器
EXISTING_CONTAINER=$(docker ps -a --filter "name=pgsql" --format "{{.Names}}")
if [ ! -z "$EXISTING_CONTAINER" ]; then
    echo "发现已存在的PostgreSQL容器: $EXISTING_CONTAINER"
    read -p "是否停止并删除现有容器? (y/n): " DELETE_EXISTING
    if [ "$DELETE_EXISTING" = "y" ] || [ "$DELETE_EXISTING" = "Y" ]; then
        echo "停止并删除现有容器..."
        docker stop $EXISTING_CONTAINER 2>/dev/null || true
        docker rm $EXISTING_CONTAINER 2>/dev/null || true
        echo "现有容器已删除"
    else
        echo "使用现有容器继续执行..."
        PG_CONTAINER=$EXISTING_CONTAINER
    fi
fi

# 如果容器不存在或已被删除，则创建新容器
if [ -z "$PG_CONTAINER" ]; then
    # 检查是否有数据目录，询问是否清理
    if [ -d "/docker/postgres/data" ] && [ "$(ls -A /docker/postgres/data 2>/dev/null)" ]; then
        echo "发现数据目录中存在数据: /docker/postgres/data"

        if [ "$CLEAR_DIR" != "y" ] && [ "$CLEAR_DIR" != "Y" ]; then
            read -p "是否清理数据目录? (这将删除所有数据) (y/n): " CLEAN_DATA

            if [ "$CLEAN_DATA" = "y" ] || [ "$CLEAN_DATA" = "Y" ]; then
                echo "清理数据目录..."
                rm -rf /docker/postgres/data/*
                echo "数据目录已清理"
            else
                echo "保留现有数据目录..."
                DATA_PRESENT=true
            fi
        fi
    fi

    # 拉取PostgreSQL镜像
    echo "拉取PostgreSQL 13.2镜像..."
    docker pull postgres:13.2

    # 运行PostgreSQL容器
    echo "启动PostgreSQL容器..."
    docker run \
    --name pgsql \
    -d \
    -p 5432:5432 \
    --restart=always \
    -v /docker/postgres/data:/var/lib/postgresql/data \
    -v /docker/postgres/conf:/etc/postgresql/conf.d \
    -e POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
    -e TZ=Asia/Shanghai \
    -e LANG=en_US.utf8 \
    postgres:13.2 \
    -c 'config_file=/etc/postgresql/conf.d/postgresql.conf' \
    -c 'hba_file=/etc/postgresql/conf.d/pg_hba.conf'

    PG_CONTAINER="pgsql"

    # 等待PostgreSQL启动
    echo "等待PostgreSQL服务启动..."
    for i in {1..30}; do
        if docker exec $PG_CONTAINER pg_isready -U postgres >/dev/null 2>&1; then
            echo "PostgreSQL已启动"
            break
        fi
        echo "等待PostgreSQL启动... ($i/30)"
        sleep 2
    done
fi

# 检查容器状态
if ! docker ps | grep -q $PG_CONTAINER; then
    echo "PostgreSQL容器未运行，尝试启动..."
    docker start $PG_CONTAINER
    sleep 5
    for i in {1..15}; do
        if docker exec $PG_CONTAINER pg_isready -U postgres >/dev/null 2>&1; then
            echo "PostgreSQL已启动"
            break
        fi
        echo "等待PostgreSQL启动... ($i/15)"
        sleep 2
    done
fi

# 检查容器是否正常运行
if ! docker ps | grep -q $PG_CONTAINER; then
    echo "PostgreSQL容器启动失败，请检查日志..."
    docker logs $PG_CONTAINER
    exit 1
fi

echo "=========================================="
echo "PostgreSQL容器部署成功！"
echo "容器名称: $PG_CONTAINER"
echo "端口: 5432"
echo "数据目录: /docker/postgres/data"
echo "配置目录: /docker/postgres/conf"
echo "=========================================="

# 测试连接
echo "测试PostgreSQL连接..."
if docker exec $PG_CONTAINER psql -U postgres -c "SELECT version();" >/dev/null 2>&1; then
    echo "PostgreSQL连接测试成功！"
else
    echo "PostgreSQL连接测试失败，请检查容器日志..."
    docker logs $PG_CONTAINER --tail 20
    exit 1
fi

# 检查是否需要初始化数据库
if [ "$DATA_PRESENT" = "true" ]; then
    read -p "检测到已有数据目录，是否需要重新初始化数据库? (这会覆盖现有数据) (y/n): " REINIT_DB

    if [ "$REINIT_DB" != "y" ] && [ "$REINIT_DB" != "Y" ]; then
        echo "跳过数据库初始化，使用现有数据..."
        echo "现有数据库状态:"
        docker exec $PG_CONTAINER psql -U postgres -c "
        SELECT '数据库状态检查' as status;
        SELECT datname as database_name FROM pg_database WHERE datname = 'burp_monitor';
        "

        # 测试现有数据库连接
        if docker exec $PG_CONTAINER psql -U postgres -d burp_monitor -c "SELECT 1;" >/dev/null 2>&1; then
            echo "现有burp_monitor数据库可正常访问"
        else
            echo "注意: 现有burp_monitor数据库可能不存在或无法访问"
        fi

        SKIP_DB_INIT=true
    fi
fi

# 初始化Burp Traffic Recorder数据库（如果需要）
if [ "$SKIP_DB_INIT" != "true" ]; then
    echo "开始初始化Burp Traffic Recorder数据库..."

    # 创建SQL文件用于初始化
    SQL_FILE="/docker/postgres/init.sql"
    cat > $SQL_FILE << EOF
-- 如果数据库已存在，先删除
DROP DATABASE IF EXISTS burp_monitor;
DROP USER IF EXISTS burp_user;

-- 创建应用用户
CREATE USER burp_user WITH PASSWORD '$BURP_USER_PASSWORD';

-- 创建数据库
CREATE DATABASE burp_monitor
    ENCODING 'UTF8'
    LC_COLLATE 'en_US.utf8'
    LC_CTYPE 'en_US.utf8'
    TEMPLATE template0;

-- 授予数据库权限
GRANT ALL PRIVILEGES ON DATABASE burp_monitor TO burp_user;
EOF

    echo "创建数据库和用户..."
    docker exec -i $PG_CONTAINER psql -U postgres < $SQL_FILE
    rm -f $SQL_FILE

    echo "数据库和用户创建完成"

    # 等待一下确保数据库创建完成
    sleep 2

    # 初始化表结构 - 使用优化的SQL
    echo "初始化表结构..."
    docker exec -i $PG_CONTAINER psql -U postgres -d burp_monitor << 'EOF'
    -- 授予模式权限
    GRANT ALL ON SCHEMA public TO burp_user;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO burp_user;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO burp_user;

    -- 创建HTTP流量记录表 - 使用与Java代码一致的数据类型
    CREATE TABLE IF NOT EXISTS http_traffic (
        id VARCHAR(36) PRIMARY KEY,
        timestamp TIMESTAMP NOT NULL,
        tool VARCHAR(50) NOT NULL,
        host VARCHAR(255) NOT NULL,
        port INTEGER NOT NULL,
        protocol VARCHAR(10) NOT NULL,
        method VARCHAR(10) NOT NULL,
        url TEXT NOT NULL,
        path TEXT NOT NULL,
        query_string TEXT,
        request_headers TEXT,
        request_body TEXT,
        request_length INTEGER,
        response_headers TEXT,
        response_body TEXT,
        response_length INTEGER,
        status_code INTEGER,
        mime_type VARCHAR(100),
        is_complete BOOLEAN DEFAULT FALSE,
        team_id VARCHAR(50)
    );

    -- 创建性能索引（PostgreSQL支持IF NOT EXISTS语法）
    CREATE INDEX IF NOT EXISTS idx_timestamp ON http_traffic(timestamp);
    CREATE INDEX IF NOT EXISTS idx_tool ON http_traffic(tool);
    CREATE INDEX IF NOT EXISTS idx_host ON http_traffic(host);
    CREATE INDEX IF NOT EXISTS idx_method ON http_traffic(method);
    CREATE INDEX IF NOT EXISTS idx_status_code ON http_traffic(status_code);
    CREATE INDEX IF NOT EXISTS idx_is_complete ON http_traffic(is_complete);
    CREATE INDEX IF NOT EXISTS idx_tool_timestamp ON http_traffic(tool, timestamp DESC);
    CREATE INDEX IF NOT EXISTS idx_team_id ON http_traffic(team_id);

    -- 授予表权限
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO burp_user;
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO burp_user;

    -- 设置表注释（可选）
    COMMENT ON TABLE http_traffic IS 'HTTP流量监控数据表';
EOF

    echo "数据库初始化完成"
fi

# 验证数据库设置
echo "验证数据库设置..."
docker exec $PG_CONTAINER psql -U postgres -d burp_monitor -c "
-- 验证表创建
SELECT '=== 数据库验证 ===' as status;
SELECT '数据库: ' || current_database() as db_name;
SELECT '用户: ' || current_user as current_user;
SELECT '表数量: ' || count(*) as table_count FROM information_schema.tables WHERE table_schema = 'public';

-- 验证表结构
SELECT
    column_name,
    data_type,
    character_maximum_length,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
    AND table_name = 'http_traffic'
ORDER BY ordinal_position;

-- 验证索引
SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'http_traffic'
    AND schemaname = 'public';

-- 测试插入
INSERT INTO http_traffic (
    id, timestamp, tool, host, port, protocol, method, url, path,
    query_string, request_headers, request_body, request_length,
    response_headers, response_body, response_length, status_code,
    mime_type, is_complete, team_id
) VALUES (
    'test-' || md5(random()::text),
    NOW(),
    'Test',
    'test.example.com',
    80,
    'http',
    'GET',
    'http://test.example.com/',
    '/',
    '',
    '',
    '',
    0,
    '',
    '',
    0,
    200,
    'text/html',
    TRUE,
    'test-team'
);

-- 验证数据
SELECT '插入测试数据成功' as test_result;
SELECT count(*) as record_count FROM http_traffic;

-- 清理测试数据
DELETE FROM http_traffic WHERE team_id = 'test-team';
SELECT '清理测试数据完成' as cleanup_result;
" 2>/dev/null || echo "注意: 数据库验证失败"

echo "=========================================="
echo "PostgreSQL 部署完成！"
echo "=========================================="
echo ""
echo "重要提示：密码已保存到安全文件: $PASSWORD_FILE"
echo "请立即查看并妥善保管密码文件！"
echo ""
echo "数据库连接信息:"
echo "────────────────────────────────────────────"
echo "主机: localhost 或 服务器IP"
echo "端口: 5432"
echo "PostgreSQL root用户: postgres"
echo "root密码: ***（查看密码文件）"
echo "数据库: burp_monitor"
echo "用户名: burp_user"
echo "密码: ***（查看密码文件）"
echo "────────────────────────────────────────────"
echo ""
echo "容器状态:"
docker ps --filter "name=$PG_CONTAINER" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "PostgreSQL部署完成！"
echo "请务必保存密码文件: $PASSWORD_FILE"