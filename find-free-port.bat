@echo off
setlocal enabledelayedexpansion

REM 空いているポートを見つける関数
:find_free_port
set start_port=%1
set end_port=%2
set port=%start_port%

:check_port
netstat -an | findstr ":%port% " >nul 2>&1
if %errorlevel% equ 0 (
    set /a port+=1
    if !port! leq %end_port% goto check_port
    set port=
    exit /b 1
) else (
    set port=%port%
    exit /b 0
)

REM WordPressポートを検索（デフォルト: 8082-8090）
if "%WORDPRESS_PORT%"=="" set WORDPRESS_PORT=8082
netstat -an | findstr ":%WORDPRESS_PORT% " >nul 2>&1
if %errorlevel% equ 0 (
    echo ポート %WORDPRESS_PORT% は使用中です。空いているポートを検索中...
    call :find_free_port 8082 8090
    if errorlevel 1 (
        echo エラー: 8082-8090の範囲で空いているポートが見つかりませんでした。
        exit /b 1
    )
    set WORDPRESS_PORT=!port!
    echo WordPressポートを !WORDPRESS_PORT! に設定しました。
) else (
    echo WordPressポート: %WORDPRESS_PORT%
)

REM phpMyAdminポートを検索（デフォルト: 8083-8091）
if "%PHPMYADMIN_PORT%"=="" set PHPMYADMIN_PORT=8083
netstat -an | findstr ":%PHPMYADMIN_PORT% " >nul 2>&1
if %errorlevel% equ 0 (
    echo ポート %PHPMYADMIN_PORT% は使用中です。空いているポートを検索中...
    call :find_free_port 8083 8091
    if errorlevel 1 (
        echo エラー: 8083-8091の範囲で空いているポートが見つかりませんでした。
        exit /b 1
    )
    set PHPMYADMIN_PORT=!port!
    echo phpMyAdminポートを !PHPMYADMIN_PORT! に設定しました。
) else (
    echo phpMyAdminポート: %PHPMYADMIN_PORT%
)

echo.
echo 設定されたポート:
echo   WordPress: http://localhost:%WORDPRESS_PORT%
echo   phpMyAdmin: http://localhost:%PHPMYADMIN_PORT%
echo.

REM docker-composeを実行
docker-compose %*

endlocal

