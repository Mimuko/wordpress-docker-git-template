# WordPress Docker Git 開発テンプレート

WordPressのローカル開発環境をDockerで構築し、Gitでバージョン管理を行うためのテンプレートです。  
ポート競合の自動検出、環境別の設定切り替え、簡単セットアップスクリプトなど、開発を効率化する機能を搭載しています。

## 📥 インストール

このテンプレートを使用するには、GitHubからクローンしてください：

```bash
git clone https://github.com/YOUR_USERNAME/wordpress-docker-git-template.git my-project-name
cd my-project-name
```

または、GitHubの「Use this template」ボタンを使用して新しいリポジトリを作成することもできます。

## 📋 目次

- [主な機能](#主な機能)
- [フォルダ構成](#フォルダ構成)
- [クイックスタート](#クイックスタート)
- [詳細な使い方](#詳細な使い方)
- [環境変数の設定](#環境変数の設定)
- [トラブルシューティング](#トラブルシューティング)
- [注意点](#注意点)

## ✨ 主な機能

- 🐳 **Docker Compose** による簡単環境構築
- 🔌 **ポート自動検出機能** - ポートが使用中の場合、自動的に空いているポートを検索
- 🌍 **環境別設定** - dev/stg/prod など環境ごとにDB Volumeを分離
- 🚀 **セットアップスクリプト** - 新規プロジェクトの初期設定を自動化
- 📦 **Git管理最適化** - テーマ・プラグインのみGit管理、DB・uploadsは除外
- 🛠️ **WP-CLI対応** - WordPress CLIコマンドを簡単に実行可能

## 📁 フォルダ構成

```
.
├── docker-compose.yml          # Docker Compose設定ファイル
├── .env.example                # 環境変数のテンプレート
├── .gitignore                  # Git管理対象外の定義
├── setup.sh / setup.bat        # 新規プロジェクト初期化スクリプト
├── docker-compose-up.sh / .bat # ポート検出付き起動スクリプト
├── find-free-port.sh / .bat    # ポート自動検出スクリプト
├── README.md                   # このファイル
└── wordpress/
    ├── wp-content/
    │   ├── themes/             # Git管理（テーマ開発用）
    │   ├── plugins/            # Git管理（必要に応じて）
    │   └── uploads/            # Git管理しない（.gitignore済み）
    └── wp-config.php           # WordPress設定ファイル
```

## 🚀 クイックスタート

### 1. リポジトリをクローン

```bash
git clone https://github.com/YOUR_USERNAME/wordpress-docker-git-template.git my-new-project
cd my-new-project
```

### 2. セットアップスクリプトを実行

```bash
# Git Bashの場合
./setup.sh

# Windows CMDの場合
setup.bat
```

スクリプトが以下を自動設定します：
- プロジェクト名の入力
- 環境選択（dev/stg/prod）
- **ポート番号の自動検出**（使用中のポートを自動で検索）
- `.env`ファイルの作成
- 各種設定ファイルの更新

### 3. コンテナを起動

```bash
# ポート自動検出付きで起動（推奨）
./docker-compose-up.sh
# または
docker-compose-up.bat

# 通常の起動
docker-compose up -d
```

### 4. アクセス

- **WordPress**: http://localhost:8082（設定したポート番号）
- **phpMyAdmin**: http://localhost:8083（設定したポート番号）

### 手動セットアップ（スクリプトを使わない場合）

1. **環境変数ファイルを作成**
   ```bash
   cp .env.example .env
   ```

2. **`.env`ファイルを編集**（必要に応じて）
   ```env
   WORDPRESS_PORT=8082
   PHPMYADMIN_PORT=8083
   DB_VOLUME_NAME=db_data_dev
   ```

3. **コンテナを起動**
   ```bash
   docker-compose up -d
   ```

## 📖 詳細な使い方

### コンテナの起動・停止

```bash
# 起動（バックグラウンド）
docker-compose up -d

# 起動（ログ表示）
docker-compose up

# 停止
docker-compose down

# 停止（ボリュームも削除）
docker-compose down -v
```

### ポート自動検出機能の使用

ポートが使用中の場合、自動的に空いているポートを検索して使用します。

```bash
# ポート検出付きで起動
./docker-compose-up.sh
# または
docker-compose-up.bat

# ポート検出のみ実行（任意のdocker-composeコマンドを実行可能）
./find-free-port.sh up -d
./find-free-port.sh down
```

**ポート検索範囲:**
- WordPress: 8082-8090
- phpMyAdmin: 8083-8091

### WordPress CLI (WP-CLI) の使用

```bash
# プラグイン一覧
docker-compose run --rm wpcli plugin list

# プラグインのインストール
docker-compose run --rm wpcli plugin install akismet --activate

# テーマ一覧
docker-compose run --rm wpcli theme list

# データベースのエクスポート
docker-compose run --rm wpcli db export backup.sql

# データベースのインポート
docker-compose run --rm wpcli db import backup.sql

# その他のコマンド
docker-compose run --rm wpcli --info
```

### 環境別の切り替え

開発環境・ステージング環境・本番環境など、環境ごとにDB Volumeを分離できます。

**方法1: 環境変数で設定**
```bash
# .envファイルで設定
DB_VOLUME_NAME=db_data_dev    # 開発環境
DB_VOLUME_NAME=db_data_stg    # ステージング環境
DB_VOLUME_NAME=db_data_prod   # 本番環境
```

**方法2: セットアップスクリプトで設定**
```bash
./setup.sh
# 環境選択で dev/stg/prod を選択
```

**環境切り替え手順:**
```bash
# 1. 現在の環境を停止
docker-compose down

# 2. .envファイルのDB_VOLUME_NAMEを変更
# または setup.sh を再実行

# 3. 新しい環境で起動
docker-compose up -d
```

### データベースへのアクセス

**phpMyAdmin経由:**
- URL: http://localhost:8083
- サーバー: `db`
- ユーザー名: `root` / パスワード: `root`
- または ユーザー名: `wordpress` / パスワード: `wordpress`

**コマンドライン経由:**
```bash
docker-compose exec db mysql -u wordpress -pwordpress wordpress
```

## ⚙️ 環境変数の設定

`.env`ファイルで以下の環境変数を設定できます：

| 変数名 | デフォルト値 | 説明 |
|--------|------------|------|
| `WORDPRESS_PORT` | 8082 | WordPressのポート番号 |
| `PHPMYADMIN_PORT` | 8083 | phpMyAdminのポート番号 |
| `DB_VOLUME_NAME` | db_data_dev | データベースボリューム名（環境別に変更） |
| `WORDPRESS_DB_HOST` | db | データベースホスト名 |
| `WORDPRESS_DB_USER` | wordpress | データベースユーザー名 |
| `WORDPRESS_DB_PASSWORD` | wordpress | データベースパスワード |
| `WORDPRESS_DB_NAME` | wordpress | データベース名 |
| `MYSQL_ROOT_PASSWORD` | root | MySQL rootパスワード |

## 🔧 トラブルシューティング

### ポートが使用中で起動できない

**解決方法1: ポート自動検出スクリプトを使用**
```bash
./docker-compose-up.sh
```

**解決方法2: 手動でポートを変更**
`.env`ファイルでポート番号を変更：
```env
WORDPRESS_PORT=8090
PHPMYADMIN_PORT=8091
```

### コンテナが起動しない

```bash
# ログを確認
docker-compose logs

# 特定のサービスのログを確認
docker-compose logs wordpress
docker-compose logs db

# コンテナの状態を確認
docker-compose ps
```

### データベースに接続できない

1. データベースコンテナが起動しているか確認
   ```bash
   docker-compose ps
   ```

2. データベースコンテナのログを確認
   ```bash
   docker-compose logs db
   ```

3. ボリュームをリセット（**注意: データが削除されます**）
   ```bash
   docker-compose down -v
   docker-compose up -d
   ```

### WordPressの設定が反映されない

`wordpress/wp-config.php`のポート設定が環境変数と一致しているか確認してください。  
セットアップスクリプト（`setup.sh`）を実行すると自動的に更新されます。

## ⚠️ 注意点

### セキュリティ

- **開発環境専用**: このテンプレートはローカル開発環境用です。本番環境では使用しないでください。
- **パスワード**: デフォルトのパスワードは開発用です。本番環境では必ず変更してください。
- **環境変数**: 機密情報は`.env`ファイルで管理し、`.env`は`.gitignore`に含まれています。

### Git管理

- **管理対象**: テーマ（`wordpress/wp-content/themes/`）とプラグイン（`wordpress/wp-content/plugins/`）はGit管理します。
- **管理対象外**: 
  - `wordpress/wp-content/uploads/` - メディアファイル
  - `wordpress/wp-config.php` - ローカル設定
  - データベース（Docker Volumeで管理）

### データの永続化

- データベースはDocker Volume（`db_data_*`）で永続化されます。
- 環境ごとに異なるVolume名を使用することで、環境を分離できます。
- Volumeを削除するとデータも削除されます：
  ```bash
  docker-compose down -v  # 注意: データが削除されます
  ```

### パフォーマンス

- 初回起動時はDockerイメージのダウンロードに時間がかかります。
- ボリュームマウントにより、ホスト側のファイル変更が即座に反映されます。

## 📚 参考リンク

- [Docker Compose公式ドキュメント](https://docs.docker.com/compose/)
- [WordPress公式ドキュメント](https://wordpress.org/support/)
- [WP-CLI公式ドキュメント](https://wp-cli.org/)

## 🔄 テンプレートとしての使い方

このリポジトリをテンプレートとして使用する方法：

### 方法1: GitHubの「Use this template」機能を使用

1. GitHubリポジトリページで「Use this template」ボタンをクリック
2. 新しいリポジトリ名を入力して作成
3. 作成したリポジトリをクローン
4. `setup.sh`（または`setup.bat`）を実行して初期設定

### 方法2: 直接クローン

```bash
# テンプレートをクローン
git clone https://github.com/YOUR_USERNAME/wordpress-docker-git-template.git my-project
cd my-project

# 既存のGit履歴を削除（新しいプロジェクトとして開始）
rm -rf .git
git init
git add .
git commit -m "Initial commit"

# セットアップスクリプトを実行
./setup.sh
```

### 方法3: フォークして使用

1. このリポジトリをフォーク
2. フォークしたリポジトリをクローン
3. 必要に応じてカスタマイズ
4. `setup.sh`を実行して初期設定

## 📝 ライセンス

このテンプレートは自由に使用・改変できます。

---

**問題が発生した場合や質問がある場合は、GitHubのIssuesでお知らせください。**
