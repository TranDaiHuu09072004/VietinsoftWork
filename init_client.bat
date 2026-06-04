@echo off
echo ======================================================
echo KHOI TAO KHONG GIAN LAM VIEC KHACH HANG (WORKSPACES)
echo ======================================================
echo.

set ClientName=%~1

if "%ClientName%" == "" (
    set /p ClientName="Nhap ten khach hang (Vi du: Cuong): "
)

if "%ClientName%" == "" (
    echo [ERROR] Ten khach hang khong duoc de trong!
    pause
    exit /b
)

python init_client.py %ClientName%
pause
