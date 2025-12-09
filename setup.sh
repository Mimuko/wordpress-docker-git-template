#!/bin/bash

# 新規プロジェクト初期化スクリプト

echo "=========================================="
echo "WordPress Docker テンプレート セットアップ"
echo "=========================================="
echo ""

# 現在のディレクトリ名を取得
CURRENT_DIR=$(basename "$PWD")

# プロジェクト名の入力
read -p "プロジェクト名を入力してください（現在: $CURRENT_DIR、Enterで現在の名前を使用）: " PROJECT_NAME

# プロジェクト名が空の場合は現在のディレクトリ名を使用
if [ -z "$PROJECT_NAME" ]; then
    PROJECT_NAME="$CURRENT_DIR"
    echo "プロジェクト名を現在のディレクトリ名（$PROJECT_NAME）に設定しました。"
fi

# フォルダ名をプロジェクト名に変更（現在の名前と異なる場合）
if [ "$CURRENT_DIR" != "$PROJECT_NAME" ]; then
    echo ""
    echo "フォルダ名を '$CURRENT_DIR' から '$PROJECT_NAME' に変更します..."
    cd ..
    if [ -d "$PROJECT_NAME" ]; then
        echo "エラー: '$PROJECT_NAME' という名前のフォルダが既に存在します。"
        exit 1
    fi
    mv "$CURRENT_DIR" "$PROJECT_NAME"
    cd "$PROJECT_NAME"
    echo "フォルダ名を変更しました。"
fi

# 環境名の選択
echo ""
echo "環境を選択してください:"
echo "1) dev (開発環境)"
echo "2) stg (ステージング環境)"
echo "3) prod (本番環境)"
echo "4) カスタム"
read -p "選択 (1-4): " ENV_CHOICE

case $ENV_CHOICE in
    1) ENV_NAME="dev" ;;
    2) ENV_NAME="stg" ;;
    3) ENV_NAME="prod" ;;
    4) 
        read -p "環境名を入力してください: " ENV_NAME
        if [ -z "$ENV_NAME" ]; then
            ENV_NAME="dev"
        fi
        ;;
    *) ENV_NAME="dev" ;;
esac

# 空いているポートを見つける関数
find_free_port() {
    local start_port=$1
    local end_port=$2
    local port=$start_port
    
    while [ $port -le $end_port ]; do
        if ! netstat -an 2>/dev/null | grep -q ":$port " && ! ss -an 2>/dev/null | grep -q ":$port "; then
            echo $port
            return 0
        fi
        port=$((port + 1))
    done
    
    echo ""
    return 1
}

# ポート番号の設定
echo ""
echo "ポート番号の設定方法を選択してください:"
echo "1) 自動検出（推奨）"
echo "2) 手動入力"
read -p "選択 (1-2、デフォルト: 1): " PORT_CHOICE
PORT_CHOICE=${PORT_CHOICE:-1}

if [ "$PORT_CHOICE" = "2" ]; then
    # 手動入力
    read -p "WordPressポート番号（デフォルト: 8082）: " WP_PORT
    WP_PORT=${WP_PORT:-8082}
    
    read -p "phpMyAdminポート番号（デフォルト: 8083）: " PMA_PORT
    PMA_PORT=${PMA_PORT:-8083}
else
    # 自動検出
    echo ""
    echo "空いているポートを検索中..."
    
    # WordPressポートの検出
    DEFAULT_WP_PORT=8082
    if netstat -an 2>/dev/null | grep -q ":$DEFAULT_WP_PORT " || ss -an 2>/dev/null | grep -q ":$DEFAULT_WP_PORT "; then
        FREE_PORT=$(find_free_port 8082 8090)
        if [ -n "$FREE_PORT" ]; then
            WP_PORT=$FREE_PORT
            echo "WordPressポート $DEFAULT_WP_PORT は使用中のため、$WP_PORT に設定しました。"
        else
            echo "警告: 8082-8090の範囲で空いているポートが見つかりませんでした。$DEFAULT_WP_PORT を使用します。"
            WP_PORT=$DEFAULT_WP_PORT
        fi
    else
        WP_PORT=$DEFAULT_WP_PORT
        echo "WordPressポート: $WP_PORT"
    fi
    
    # phpMyAdminポートの検出（WordPressポートと重複しないように）
    DEFAULT_PMA_PORT=8083
    if [ "$DEFAULT_PMA_PORT" = "$WP_PORT" ]; then
        DEFAULT_PMA_PORT=$((WP_PORT + 1))
    fi
    
    if netstat -an 2>/dev/null | grep -q ":$DEFAULT_PMA_PORT " || ss -an 2>/dev/null | grep -q ":$DEFAULT_PMA_PORT "; then
        FREE_PORT=$(find_free_port $DEFAULT_PMA_PORT 8091)
        if [ -n "$FREE_PORT" ]; then
            PMA_PORT=$FREE_PORT
            echo "phpMyAdminポート $DEFAULT_PMA_PORT は使用中のため、$PMA_PORT に設定しました。"
        else
            echo "警告: $DEFAULT_PMA_PORT-8091の範囲で空いているポートが見つかりませんでした。$DEFAULT_PMA_PORT を使用します。"
            PMA_PORT=$DEFAULT_PMA_PORT
        fi
    else
        PMA_PORT=$DEFAULT_PMA_PORT
        echo "phpMyAdminポート: $PMA_PORT"
    fi
fi

# .envファイルの作成
if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        cp .env.example .env
        echo ".envファイルを作成しました。"
    else
        # .env.exampleが存在しない場合は新規作成
        cat > .env << EOF
# WordPress Docker 環境変数設定
WORDPRESS_PORT=$WP_PORT
PHPMYADMIN_PORT=$PMA_PORT
WORDPRESS_DB_HOST=db
WORDPRESS_DB_USER=wordpress
WORDPRESS_DB_PASSWORD=wordpress
WORDPRESS_DB_NAME=wordpress
MYSQL_DATABASE=wordpress
MYSQL_USER=wordpress
MYSQL_PASSWORD=wordpress
MYSQL_ROOT_PASSWORD=root
DB_VOLUME_NAME=db_data_$ENV_NAME
EOF
        echo ".envファイルを新規作成しました。"
    fi
else
    echo "警告: .envファイルは既に存在します。更新します。"
fi

# .envファイルの更新
if [ -f .env ]; then
    # sedコマンドの互換性を考慮（macOSとLinuxの両方に対応）
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOSの場合
        sed -i '' "s/^WORDPRESS_PORT=.*/WORDPRESS_PORT=$WP_PORT/" .env
        sed -i '' "s/^PHPMYADMIN_PORT=.*/PHPMYADMIN_PORT=$PMA_PORT/" .env
        sed -i '' "s/^DB_VOLUME_NAME=.*/DB_VOLUME_NAME=db_data_$ENV_NAME/" .env
    else
        # Linuxの場合
        sed -i.bak "s/^WORDPRESS_PORT=.*/WORDPRESS_PORT=$WP_PORT/" .env
        sed -i.bak "s/^PHPMYADMIN_PORT=.*/PHPMYADMIN_PORT=$PMA_PORT/" .env
        sed -i.bak "s/^DB_VOLUME_NAME=.*/DB_VOLUME_NAME=db_data_$ENV_NAME/" .env
        rm -f .env.bak
    fi
    echo ".envファイルを更新しました。"
else
    echo "エラー: .envファイルの作成に失敗しました。"
    exit 1
fi

# docker-compose.ymlの更新
if [ -f docker-compose.yml ]; then
    sed -i.bak "s/name: db_data_dev/name: db_data_$ENV_NAME/" docker-compose.yml
    rm -f docker-compose.yml.bak
    echo "docker-compose.ymlを更新しました。"
fi

# wp-config.phpの更新（ポート番号を環境変数から取得するように）
if [ -f wordpress/wp-config.php ]; then
    # 既存のハードコードされたポートを環境変数に置き換え
    sed -i.bak "s|define('WP_SITEURL', 'http://localhost:[0-9]*');|define('WP_SITEURL', getenv('WP_SITEURL') ?: 'http://localhost:$WP_PORT');|" wordpress/wp-config.php
    sed -i.bak "s|define('WP_HOME', 'http://localhost:[0-9]*');|define('WP_HOME', getenv('WP_HOME') ?: 'http://localhost:$WP_PORT');|" wordpress/wp-config.php
    rm -f wordpress/wp-config.php.bak
    echo "wp-config.phpを更新しました。"
fi

echo ""
echo "=========================================="
echo "セットアップ完了！"
echo "=========================================="
echo ""
echo "プロジェクト名: $PROJECT_NAME"
echo "環境: $ENV_NAME"
echo "WordPressポート: $WP_PORT"
echo "phpMyAdminポート: $PMA_PORT"
echo "DB Volume名: db_data_$ENV_NAME"
echo ""
echo "次のコマンドで起動できます:"
echo "  ./docker-compose-up.sh"
echo "  または"
echo "  docker-compose up -d"
echo ""
echo "アクセスURL:"
echo "  WordPress: http://localhost:$WP_PORT"
echo "  phpMyAdmin: http://localhost:$PMA_PORT"
echo ""

