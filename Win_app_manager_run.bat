@echo off
:: 获取当前脚本所在目录
cd /d "%~dp0"

:: 检查是否具有管理员权限
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

:: 如果没有管理员权限，则通过 PowerShell 重新发起提权请求
if '%errorlevel%' NEQ '0' (
    echo Requesting Admin Privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
    pushd "%CD%"
    CD /D "%~dp0"

:: 核心逻辑：以 Bypass 策略运行 PowerShell 脚本，且执行完后暂停
echo Starting Maintenance System...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "Win_app_manager.ps1"

echo.
echo ==========================================================
echo  Script Execution Finished.
echo ==========================================================
pause