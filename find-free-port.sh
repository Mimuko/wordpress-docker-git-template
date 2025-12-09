#!/bin/bash

# 空いているポートを見つける関数
find_free_port() {
    local start_port=$1
    local end_port=$2
    local port=$start_port
    
    while [ $port -le $end_port ]; do
        if ! netstat -an | grep -q ":$port " 2>/dev/null; then
            if ! ss -an | grep -q ":$port " 2>/dev/null; then
                echo $port
                return 0
            fi
        fi
        port=$((port + 1))
    done
    
    echo ""
    return 1
}

# WordPressポートを検索（デフォルト: 8082-8090）
WP_PORT=${WORDPRESS_PORT:-8082}
if netstat -an 2>/dev/null | grep -q ":$WP_PORT " || ss -an 2>/dev/null | grep -q ":$WP_PORT "; then
    echo "ポート $WP_PORT は使用中です。空いているポートを検索中..."
    FREE_PORT=$(find_free_port 8082 8090)
    if [ -n "$FREE_PORT" ]; then
        export WORDPRESS_PORT=$FREE_PORT
        echo "WordPressポートを $FREE_PORT に設定しました。"
    else
        echo "エラー: 8082-8090の範囲で空いているポートが見つかりませんでした。"
        exit 1
    fi
else
    export WORDPRESS_PORT=$WP_PORT
    echo "WordPressポート: $WORDPRESS_PORT"
fi

# phpMyAdminポートを検索（デフォルト: 8083-8091）
PMA_PORT=${PHPMYADMIN_PORT:-8083}
if netstat -an 2>/dev/null | grep -q ":$PMA_PORT " || ss -an 2>/dev/null | grep -q ":$PMA_PORT "; then
    echo "ポート $PMA_PORT は使用中です。空いているポートを検索中..."
    FREE_PORT=$(find_free_port 8083 8091)
    if [ -n "$FREE_PORT" ]; then
        export PHPMYADMIN_PORT=$FREE_PORT
        echo "phpMyAdminポートを $FREE_PORT に設定しました。"
    else
        echo "エラー: 8083-8091の範囲で空いているポートが見つかりませんでした。"
        exit 1
    fi
else
    export PHPMYADMIN_PORT=$PMA_PORT
    echo "phpMyAdminポート: $PHPMYADMIN_PORT"
fi

echo ""
echo "設定されたポート:"
echo "  WordPress: http://localhost:$WORDPRESS_PORT"
echo "  phpMyAdmin: http://localhost:$PHPMYADMIN_PORT"
echo ""

# docker-composeを実行
docker-compose "$@"

