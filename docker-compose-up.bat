@echo off

REM find-free-port.batを実行してからdocker-compose upを実行
call find-free-port.bat up -d

