@echo off
setlocal enabledelayedexpansion

echo ==========================================
echo WordPress Docker テンプレート セットアップ
echo ==========================================
echo.

REM 現在のディレクトリ名を取得
for %%I in (.) do set CURRENT_DIR=%%~nxI

REM プロジェクト名の入力
set /p PROJECT_NAME="プロジェクト名を入力してください（現在: %CURRENT_DIR%、Enterで現在の名前を使用）: "

REM プロジェクト名が空の場合は現在のディレクトリ名を使用
if "%PROJECT_NAME%"=="" (
    set PROJECT_NAME=%CURRENT_DIR%
    echo プロジェクト名を現在のディレクトリ名（!PROJECT_NAME!）に設定しました。
)

REM フォルダ名をプロジェクト名に変更（現在の名前と異なる場合）
if not "%CURRENT_DIR%"=="%PROJECT_NAME%" (
    echo.
    echo フォルダ名を '%CURRENT_DIR%' から '%PROJECT_NAME%' に変更します...
    
    REM 現在のディレクトリの絶対パスを取得
    set "CURRENT_PATH=%CD%"
    
    REM 親ディレクトリのパスを取得
    for %%I in ("%CURRENT_PATH%\..") do set "PARENT_PATH=%%~fI"
    
    REM 親ディレクトリに移動
    cd /d "%PARENT_PATH%"
    
    REM 既に同名のフォルダが存在するか確認
    if exist "%PROJECT_NAME%" (
        echo エラー: '%PROJECT_NAME%' という名前のフォルダが既に存在します。
        cd /d "%CURRENT_PATH%"
        exit /b 1
    )
    
    REM PowerShellを使用してリネーム（より確実）
    powershell -Command "Rename-Item -Path '%CURRENT_DIR%' -NewName '%PROJECT_NAME%' -ErrorAction Stop"
    if errorlevel 1 (
        echo エラー: フォルダ名の変更に失敗しました。
        cd /d "%CURRENT_PATH%"
        exit /b 1
    )
    
    REM 新しいディレクトリに移動
    cd /d "%PARENT_PATH%\%PROJECT_NAME%"
    echo フォルダ名を変更しました。
)

REM 環境名の選択
echo.
echo 環境を選択してください:
echo 1) dev (開発環境)
echo 2) stg (ステージング環境)
echo 3) prod (本番環境)
echo 4) カスタム
set /p ENV_CHOICE="選択 (1-4): "

if "%ENV_CHOICE%"=="1" set ENV_NAME=dev
if "%ENV_CHOICE%"=="2" set ENV_NAME=stg
if "%ENV_CHOICE%"=="3" set ENV_NAME=prod
if "%ENV_CHOICE%"=="4" (
    set /p ENV_NAME="環境名を入力してください: "
    if "!ENV_NAME!"=="" set ENV_NAME=dev
)
if "%ENV_NAME%"=="" set ENV_NAME=dev

REM 空いているポートを見つける関数（結果はFOUND_PORT変数に設定）
:find_free_port
set start_port=%1
set end_port=%2
set test_port=%start_port%

:check_port_loop
netstat -an | findstr ":!test_port! " >nul 2>&1
if !errorlevel! equ 0 (
    set /a test_port+=1
    if !test_port! leq %end_port% goto check_port_loop
    set FOUND_PORT=
    exit /b 1
) else (
    set FOUND_PORT=!test_port!
    exit /b 0
)

REM ポート番号の設定
echo.
echo ポート番号の設定方法を選択してください:
echo 1) 自動検出（推奨）
echo 2) 手動入力
set /p PORT_CHOICE="選択 (1-2、デフォルト: 1): "
if "%PORT_CHOICE%"=="" set PORT_CHOICE=1

if "%PORT_CHOICE%"=="2" (
    REM 手動入力
    set /p WP_PORT="WordPressポート番号（デフォルト: 8082）: "
    if "%WP_PORT%"=="" set WP_PORT=8082
    
    set /p PMA_PORT="phpMyAdminポート番号（デフォルト: 8083）: "
    if "%PMA_PORT%"=="" set PMA_PORT=8083
) else (
    REM 自動検出
    echo.
    echo 空いているポートを検索中...
    
    REM WordPressポートの検出
    set DEFAULT_WP_PORT=8082
    netstat -an | findstr ":%DEFAULT_WP_PORT% " >nul 2>&1
    if %errorlevel% equ 0 (
        call :find_free_port 8082 8090
        if errorlevel 1 (
            echo 警告: 8082-8090の範囲で空いているポートが見つかりませんでした。%DEFAULT_WP_PORT% を使用します。
            set WP_PORT=%DEFAULT_WP_PORT%
        ) else (
            set WP_PORT=!FOUND_PORT!
            echo WordPressポート %DEFAULT_WP_PORT% は使用中のため、!WP_PORT! に設定しました。
        )
    ) else (
        set WP_PORT=%DEFAULT_WP_PORT%
        echo WordPressポート: !WP_PORT!
    )
    
    REM phpMyAdminポートの検出（WordPressポートと重複しないように）
    set DEFAULT_PMA_PORT=8083
    if "!WP_PORT!"=="!DEFAULT_PMA_PORT!" (
        set /a DEFAULT_PMA_PORT=!WP_PORT!+1
    )
    
    netstat -an | findstr ":%DEFAULT_PMA_PORT% " >nul 2>&1
    if %errorlevel% equ 0 (
        call :find_free_port !DEFAULT_PMA_PORT! 8091
        if errorlevel 1 (
            echo 警告: !DEFAULT_PMA_PORT!-8091の範囲で空いているポートが見つかりませんでした。!DEFAULT_PMA_PORT! を使用します。
            set PMA_PORT=!DEFAULT_PMA_PORT!
        ) else (
            set PMA_PORT=!FOUND_PORT!
            echo phpMyAdminポート !DEFAULT_PMA_PORT! は使用中のため、!PMA_PORT! に設定しました。
        )
    ) else (
        set PMA_PORT=!DEFAULT_PMA_PORT!
        echo phpMyAdminポート: !PMA_PORT!
    )
)

REM .envファイルの作成
if not exist .env (
    if exist .env.example (
        copy .env.example .env >nul
        echo .envファイルを作成しました。
    ) else (
        REM .env.exampleが存在しない場合は新規作成
        (
            echo # WordPress Docker 環境変数設定
            echo WORDPRESS_PORT=%WP_PORT%
            echo PHPMYADMIN_PORT=%PMA_PORT%
            echo WORDPRESS_DB_HOST=db
            echo WORDPRESS_DB_USER=wordpress
            echo WORDPRESS_DB_PASSWORD=wordpress
            echo WORDPRESS_DB_NAME=wordpress
            echo MYSQL_DATABASE=wordpress
            echo MYSQL_USER=wordpress
            echo MYSQL_PASSWORD=wordpress
            echo MYSQL_ROOT_PASSWORD=root
            echo DB_VOLUME_NAME=%PROJECT_NAME%_db_data_%ENV_NAME%
        ) > .env
        echo .envファイルを新規作成しました。
    )
) else (
    echo 警告: .envファイルは既に存在します。更新します。
)

REM .envファイルの更新（PowerShellを使用）
if exist .env (
    powershell -Command "$content = Get-Content .env; $content = $content -replace '^WORDPRESS_PORT=.*', 'WORDPRESS_PORT=%WP_PORT%'; $content = $content -replace '^PHPMYADMIN_PORT=.*', 'PHPMYADMIN_PORT=%PMA_PORT%'; $content = $content -replace '^DB_VOLUME_NAME=.*', 'DB_VOLUME_NAME=%PROJECT_NAME%_db_data_%ENV_NAME%'; Set-Content .env $content"
    echo .envファイルを更新しました。
) else (
    echo エラー: .envファイルの作成に失敗しました。
    exit /b 1
)

REM docker-compose.ymlの更新
if exist docker-compose.yml (
    powershell -Command "(Get-Content docker-compose.yml) -replace 'name: db_data_dev', 'name: db_data_%ENV_NAME%' | Set-Content docker-compose.yml"
    echo docker-compose.ymlを更新しました。
)

echo.
echo ==========================================
echo セットアップ完了！
echo ==========================================
echo.
echo プロジェクト名: %PROJECT_NAME%
echo 環境: %ENV_NAME%
echo WordPressポート: %WP_PORT%
echo phpMyAdminポート: %PMA_PORT%
echo DB Volume名: %PROJECT_NAME%_db_data_%ENV_NAME%
echo.
echo 次のコマンドで起動できます:
echo   docker-compose-up.bat
echo   または
echo   docker-compose up -d
echo.
echo アクセスURL:
echo   WordPress: http://localhost:%WP_PORT%
echo   phpMyAdmin: http://localhost:%PMA_PORT%
echo.

endlocal

