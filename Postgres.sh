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
    echo "执行SQL文件: $SQL_FILE"
    
    # 执行SQL并捕获输出
    SQL_OUTPUT=$(docker exec -i $PG_CONTAINER psql -U postgres < $SQL_FILE 2>&1)
    SQL_EXIT_CODE=$?
    
    # 显示SQL执行输出（过滤掉NOTICE）
    echo "$SQL_OUTPUT" | grep -v "NOTICE" | grep -v "^$" || true
    
    rm -f $SQL_FILE
    
    # 等待数据库创建完成
    echo "等待数据库创建完成..."
    sleep 3
    
    # 强制验证数据库是否存在（多次尝试）
    DB_EXISTS=false
    for i in {1..5}; do
        if docker exec $PG_CONTAINER psql -U postgres -lqt 2>/dev/null | cut -d \| -f 1 | grep -qw burp_monitor; then
            DB_EXISTS=true
            break
        fi
        echo "   等待数据库创建... ($i/5)"
        sleep 1
    done
    
    # 验证用户是否存在
    USER_EXISTS=false
    if docker exec $PG_CONTAINER psql -U postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='burp_user'" 2>/dev/null | grep -q 1; then
        USER_EXISTS=true
    fi
    
    # 显示验证结果
    echo ""
    echo "验证结果:"
    if [ "$DB_EXISTS" = true ]; then
        echo "   ✓ 数据库 burp_monitor 已成功创建并验证存在"
        # 显示数据库详细信息
        docker exec $PG_CONTAINER psql -U postgres -lqt | grep burp_monitor
    else
        echo "   ✗ 数据库 burp_monitor 创建失败或不存在！"
        echo "   尝试手动创建..."
        docker exec -i $PG_CONTAINER psql -U postgres << EOF
CREATE DATABASE burp_monitor
    ENCODING 'UTF8'
    LC_COLLATE 'en_US.utf8'
    LC_CTYPE 'en_US.utf8'
    TEMPLATE template0;
EOF
        sleep 2
        # 再次验证
        if docker exec $PG_CONTAINER psql -U postgres -lqt 2>/dev/null | cut -d \| -f 1 | grep -qw burp_monitor; then
            echo "   ✓ 数据库 burp_monitor 手动创建成功"
            DB_EXISTS=true
        else
            echo "   ✗ 数据库创建仍然失败，请检查PostgreSQL日志"
            docker logs $PG_CONTAINER --tail 20
        fi
    fi
    
    if [ "$USER_EXISTS" = true ]; then
        echo "   ✓ 用户 burp_user 已成功创建并验证存在"
    else
        echo "   ✗ 用户 burp_user 创建失败或不存在！"
        echo "   尝试手动创建..."
        docker exec -i $PG_CONTAINER psql -U postgres << EOF
CREATE USER burp_user WITH PASSWORD '$BURP_USER_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE burp_monitor TO burp_user;
EOF
        sleep 1
        # 再次验证
        if docker exec $PG_CONTAINER psql -U postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='burp_user'" 2>/dev/null | grep -q 1; then
            echo "   ✓ 用户 burp_user 手动创建成功"
            USER_EXISTS=true
        else
            echo "   ✗ 用户创建仍然失败"
        fi
    fi
    
    if [ "$DB_EXISTS" = true ] && [ "$USER_EXISTS" = true ]; then
        echo ""
        echo "数据库和用户创建完成并验证成功"
    else
        echo ""
        echo "警告：数据库或用户创建可能存在问题，但将继续执行..."
    fi

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
        team_id VARCHAR(50),
        note VARCHAR(5),
        api_hash VARCHAR(64)
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
    CREATE INDEX IF NOT EXISTS idx_api_hash ON http_traffic(api_hash);

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

# 首先检查数据库是否存在（使用多种方法验证）
echo "1. 检查数据库是否存在..."
DB_FOUND=false

# 方法1: 使用 psql -l
if docker exec $PG_CONTAINER psql -U postgres -lqt 2>/dev/null | cut -d \| -f 1 | tr -d ' ' | grep -qw burp_monitor; then
    DB_FOUND=true
    echo "   ✓ 数据库 burp_monitor 存在（方法1验证）"
fi

# 方法2: 使用 SQL 查询
if docker exec $PG_CONTAINER psql -U postgres -tAc "SELECT 1 FROM pg_database WHERE datname='burp_monitor'" 2>/dev/null | grep -q 1; then
    DB_FOUND=true
    echo "   ✓ 数据库 burp_monitor 存在（方法2验证）"
fi

# 方法3: 尝试连接数据库
if docker exec $PG_CONTAINER psql -U postgres -d burp_monitor -c "SELECT 1;" >/dev/null 2>&1; then
    DB_FOUND=true
    echo "   ✓ 数据库 burp_monitor 可以连接（方法3验证）"
fi

if [ "$DB_FOUND" = false ]; then
    echo "   ✗ 数据库 burp_monitor 不存在！"
    echo "   显示所有数据库列表:"
    docker exec $PG_CONTAINER psql -U postgres -l
    echo ""
    echo "   尝试重新创建数据库..."
    docker exec -i $PG_CONTAINER psql -U postgres << EOF
DROP DATABASE IF EXISTS burp_monitor;
CREATE DATABASE burp_monitor
    ENCODING 'UTF8'
    LC_COLLATE 'en_US.utf8'
    LC_CTYPE 'en_US.utf8'
    TEMPLATE template0;
GRANT ALL PRIVILEGES ON DATABASE burp_monitor TO burp_user;
EOF
    sleep 3
    # 再次验证
    if docker exec $PG_CONTAINER psql -U postgres -d burp_monitor -c "SELECT 1;" >/dev/null 2>&1; then
        echo "   ✓ 数据库重新创建成功"
        DB_FOUND=true
    else
        echo "   ✗ 数据库创建失败，请检查PostgreSQL日志:"
        docker logs $PG_CONTAINER --tail 30
    fi
fi

# 检查用户是否存在
echo "2. 检查用户是否存在..."
if docker exec $PG_CONTAINER psql -U postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='burp_user'" | grep -q 1; then
    echo "   ✓ 用户 burp_user 存在"
else
    echo "   ✗ 用户 burp_user 不存在！"
    echo "   尝试重新创建用户..."
    docker exec -i $PG_CONTAINER psql -U postgres << EOF
CREATE USER burp_user WITH PASSWORD '$BURP_USER_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE burp_monitor TO burp_user;
EOF
fi

# 验证数据库连接
echo "3. 测试数据库连接..."
if docker exec $PG_CONTAINER psql -U burp_user -d burp_monitor -c "SELECT 1;" >/dev/null 2>&1; then
    echo "   ✓ 数据库连接成功"
else
    echo "   ✗ 数据库连接失败，尝试使用postgres用户连接..."
    if docker exec $PG_CONTAINER psql -U postgres -d burp_monitor -c "SELECT 1;" >/dev/null 2>&1; then
        echo "   ✓ 使用postgres用户连接成功"
        echo "   重新授予权限..."
        docker exec -i $PG_CONTAINER psql -U postgres -d burp_monitor << EOF
GRANT ALL ON SCHEMA public TO burp_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO burp_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO burp_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO burp_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO burp_user;
EOF
    else
        echo "   ✗ 数据库连接失败！"
    fi
fi

# 验证表结构
echo "4. 验证表结构..."
TABLE_COUNT=$(docker exec $PG_CONTAINER psql -U postgres -d burp_monitor -tAc "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'http_traffic';" 2>/dev/null)
if [ "$TABLE_COUNT" = "1" ]; then
    echo "   ✓ 表 http_traffic 存在"
    
    # 检查表字段数量
    COLUMN_COUNT=$(docker exec $PG_CONTAINER psql -U postgres -d burp_monitor -tAc "SELECT count(*) FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'http_traffic';" 2>/dev/null)
    echo "   ✓ 表包含 $COLUMN_COUNT 个字段"
    
    # 检查索引
    INDEX_COUNT=$(docker exec $PG_CONTAINER psql -U postgres -d burp_monitor -tAc "SELECT count(*) FROM pg_indexes WHERE tablename = 'http_traffic' AND schemaname = 'public';" 2>/dev/null)
    echo "   ✓ 表包含 $INDEX_COUNT 个索引"
    
    # 测试插入和删除
    echo "5. 测试数据操作..."
    TEST_ID="test-$(date +%s)"
    if docker exec $PG_CONTAINER psql -U postgres -d burp_monitor -c "INSERT INTO http_traffic (id, timestamp, tool, host, port, protocol, method, url, path, is_complete) VALUES ('$TEST_ID', NOW(), 'Test', 'test.example.com', 80, 'http', 'GET', 'http://test.example.com/', '/', TRUE);" >/dev/null 2>&1; then
        echo "   ✓ 插入测试数据成功"
        if docker exec $PG_CONTAINER psql -U postgres -d burp_monitor -c "DELETE FROM http_traffic WHERE id = '$TEST_ID';" >/dev/null 2>&1; then
            echo "   ✓ 删除测试数据成功"
            echo ""
            echo "=========================================="
            echo "✓ 数据库验证成功！"
            echo "=========================================="
        else
            echo "   ⚠ 删除测试数据失败（不影响使用）"
        fi
    else
        echo "   ✗ 插入测试数据失败"
        echo "   检查表结构..."
        docker exec $PG_CONTAINER psql -U postgres -d burp_monitor -c "\d http_traffic" 2>&1 | head -20
    fi
else
    echo "   ✗ 表 http_traffic 不存在！"
    echo "   尝试重新创建表..."
    docker exec -i $PG_CONTAINER psql -U postgres -d burp_monitor << 'EOF'
    -- 授予模式权限
    GRANT ALL ON SCHEMA public TO burp_user;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO burp_user;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO burp_user;

    -- 创建HTTP流量记录表
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
        team_id VARCHAR(50),
        note VARCHAR(5),
        api_hash VARCHAR(64)
    );

    -- 创建索引
    CREATE INDEX IF NOT EXISTS idx_timestamp ON http_traffic(timestamp);
    CREATE INDEX IF NOT EXISTS idx_tool ON http_traffic(tool);
    CREATE INDEX IF NOT EXISTS idx_host ON http_traffic(host);
    CREATE INDEX IF NOT EXISTS idx_method ON http_traffic(method);
    CREATE INDEX IF NOT EXISTS idx_status_code ON http_traffic(status_code);
    CREATE INDEX IF NOT EXISTS idx_is_complete ON http_traffic(is_complete);
    CREATE INDEX IF NOT EXISTS idx_tool_timestamp ON http_traffic(tool, timestamp DESC);
    CREATE INDEX IF NOT EXISTS idx_team_id ON http_traffic(team_id);
    CREATE INDEX IF NOT EXISTS idx_api_hash ON http_traffic(api_hash);

    -- 授予表权限
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO burp_user;
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO burp_user;
EOF
    echo "   表结构已重新创建"
fi

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
echo "=========================================="
echo "最终验证：显示所有数据库列表"
echo "=========================================="
docker exec $PG_CONTAINER psql -U postgres -c "\l" 2>/dev/null || docker exec $PG_CONTAINER psql -U postgres -l

echo ""
echo "=========================================="
echo "验证 burp_monitor 数据库"
echo "=========================================="
if docker exec $PG_CONTAINER psql -U postgres -d burp_monitor -c "SELECT current_database(), version();" >/dev/null 2>&1; then
    echo "✓ 数据库 burp_monitor 可以正常连接"
    echo ""
    echo "数据库信息:"
    docker exec $PG_CONTAINER psql -U postgres -d burp_monitor -c "
        SELECT 
            '数据库名称' as info, current_database() as value
        UNION ALL
        SELECT '数据库大小', pg_size_pretty(pg_database_size(current_database()))
        UNION ALL
        SELECT '表数量', count(*)::text FROM information_schema.tables WHERE table_schema = 'public';
    " 2>/dev/null || echo "无法获取数据库信息"
else
    echo "✗ 数据库 burp_monitor 无法连接！"
    echo ""
    echo "请检查以下内容:"
    echo "1. 容器是否正常运行: docker ps | grep pgsql"
    echo "2. PostgreSQL日志: docker logs pgsql --tail 50"
    echo "3. 尝试手动连接: docker exec -it pgsql psql -U postgres -l"
fi

echo ""
echo "PostgreSQL部署完成！"
echo "请务必保存密码文件: $PASSWORD_FILE"