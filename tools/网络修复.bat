@echo off
chcp 65001 >nul
title Windows 网络修复工具箱 v1.0
color 0A

:: 检查管理员权限
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo 请以管理员身份运行此脚本！
    echo 右键点击脚本 - 以管理员身份运行
    pause >nul
    exit /b 1
)

:menu
cls
echo ==========================================
echo    Windows 网络修复工具箱 v1.0
echo ==========================================
echo.
echo    [1] 全面诊断并修复（推荐）
echo    [2] 诊断网络状态
echo    [3] 重置IP地址（DHCP）
echo    [4] 清除DNS缓存
echo    [5] 重置Winsock目录
echo    [6] 重置TCP/IP协议栈
echo    [7] 刷新ARP缓存
echo    [8] 重置防火墙规则
echo    [9] 修复网络适配器
echo    [10] 清除代理设置
echo    [11] 恢复Hosts文件
echo    [12] 一键修复所有问题
echo    [0] 退出
echo.
set /p choice=请输入选项编号: 

if "%choice%"=="1" goto full_diagnose
if "%choice%"=="2" goto diagnose
if "%choice%"=="3" goto reset_ip
if "%choice%"=="4" goto flush_dns
if "%choice%"=="5" goto reset_winsock
if "%choice%"=="6" goto reset_tcpip
if "%choice%"=="7" goto flush_arp
if "%choice%"=="8" goto reset_firewall
if "%choice%"=="9" goto fix_adapter
if "%choice%"=="10" goto clear_proxy
if "%choice%"=="11" goto restore_hosts
if "%choice%"=="12" goto fix_all
if "%choice%"=="0" exit /b 0
goto menu

:diagnose
cls
echo ==========================================
echo           正在诊断网络状态...
echo ==========================================
echo.

echo [1/7] 检查IP配置...
ipconfig /all | findstr /C:"IPv4" /C:"子网掩码" /C:"默认网关" /C:"DNS 服务器"
echo.

echo [2/7] 测试网关连通性...
for /f "tokens=2,3 delims={,}" %%a in ('"WMIC NICConfig where IPEnabled="True" get DefaultIPGateway /value"') do (
    if not "%%~b"=="" (
        set gateway=%%~b
        echo 网关地址: %%~b
        ping %%~b -n 2
    )
)
echo.

echo [3/7] 测试DNS解析...
ping www.baidu.com -n 2
echo.

echo [4/7] 检测DNS服务器...
nslookup www.baidu.com 2>nul | findstr /C:"Address" /C:"服务器"
echo.

echo [5/7] 检测网络适配器状态...
wmic nic where "NetEnabled=true" get Name,NetConnectionStatus | findstr /V "NetConnectionStatus"
echo.

echo [6/7] 检查路由表...
route print -4 | findstr /C:"0.0.0.0"
echo.

echo [7/7] 检测防火墙状态...
netsh advfirewall show currentprofile | findstr "状态"
echo.

echo ==========================================
echo           诊断完成！
echo ==========================================
pause
goto menu

:full_diagnose
call :diagnose
echo.
echo 是否开始修复？(Y/N)
set /p fix_choice=
if /i "%fix_choice%"=="Y" goto fix_all
goto menu

:reset_ip
cls
echo 正在释放当前IP地址...
ipconfig /release
echo.
echo 正在重新获取IP地址...
ipconfig /renew
echo.
echo IP地址重置完成！
pause
goto menu

:flush_dns
cls
echo 正在清除DNS缓存...
ipconfig /flushdns
echo.
echo DNS缓存清除完成！
pause
goto menu

:reset_winsock
cls
echo 正在重置Winsock目录...
netsh winsock reset
echo.
echo Winsock重置完成！需要重启计算机才能生效。
echo.
echo 是否立即重启？(Y/N)
set /p reboot_choice=
if /i "%reboot_choice%"=="Y" shutdown /r /t 30 /c "系统将在30秒后重启以完成网络修复"
pause
goto menu

:reset_tcpip
cls
echo 正在重置TCP/IP协议栈...
echo 这可能需要几分钟...
netsh int ip reset c:\resetlog.txt
netsh int ipv4 reset
netsh int ipv6 reset
echo.
echo TCP/IP协议栈重置完成！
pause
goto menu

:flush_arp
cls
echo 正在清除ARP缓存...
arp -d *
echo.
echo ARP缓存清除完成！
pause
goto menu

:reset_firewall
cls
echo 正在重置Windows防火墙...
netsh advfirewall reset
echo.
echo 防火墙已恢复默认设置！
pause
goto menu

:fix_adapter
cls
echo 正在修复网络适配器...
echo.
echo 禁用并重新启用网络适配器...
wmic path win32_networkadapter where "NetEnabled=true" call disable >nul 2>&1
timeout /t 3 /nobreak >nul
wmic path win32_networkadapter where "NetEnabled=false" call enable >nul 2>&1
echo.
echo 网络适配器修复完成！
pause
goto menu

:clear_proxy
cls
echo 正在清除代理设置...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer /t REG_SZ /d "" /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyOverride /t REG_SZ /d "" /f
netsh winhttp reset proxy
echo.
echo 代理设置已清除！
pause
goto menu

:restore_hosts
cls
echo 正在备份当前Hosts文件...
if exist "%windir%\System32\drivers\etc\hosts" (
    copy "%windir%\System32\drivers\etc\hosts" "%windir%\System32\drivers\etc\hosts.backup" >nul
    echo 已备份为 hosts.backup
)
echo.
echo 正在恢复默认Hosts文件...
(
echo # Copyright ^(c^) 1993-2009 Microsoft Corp.
echo #
echo # 这是 Windows TCP/IP 使用的 HOSTS 文件示例
echo #
echo # 该文件包含IP地址到主机名的映射。每一项
echo # 都应该单独占一行。IP地址应该
echo # 放在第一列，后跟相应的主机名。
echo # IP地址和主机名之间应至少用一个空格分隔。
echo #
echo # 此外，注释（如此处）可能会插入到个人
echo # 行上或跟用'#'符号表示的机器名称后面。
echo #
echo # 例如：
echo #
echo #      102.54.94.97     rhino.acme.com          # 源服务器
echo #      38.25.63.10     x.acme.com              # x 客户端主机
echo #
echo # localhost名称解析在DNS本身内部处理。
echo #      127.0.0.1       localhost
echo #      ::1             localhost
echo 127.0.0.1 localhost
echo ::1 localhost
) > "%windir%\System32\drivers\etc\hosts"
echo.
echo Hosts文件已恢复默认！
pause
goto menu

:fix_all
cls
echo ==========================================
echo        正在执行全面网络修复...
echo ==========================================
echo.

echo [1/10] 清除DNS缓存...
ipconfig /flushdns >nul 2>&1
echo ✓ DNS缓存已清除

echo [2/10] 释放并更新IP地址...
ipconfig /release >nul 2>&1
ipconfig /renew >nul 2>&1
echo ✓ IP地址已更新

echo [3/10] 重置Winsock...
netsh winsock reset >nul 2>&1
echo ✓ Winsock已重置

echo [4/10] 重置TCP/IP协议栈...
netsh int ip reset >nul 2>&1
netsh int ipv4 reset >nul 2>&1
netsh int ipv6 reset >nul 2>&1
echo ✓ TCP/IP协议栈已重置

echo [5/10] 清除ARP缓存...
arp -d * >nul 2>&1
echo ✓ ARP缓存已清除

echo [6/10] 重置Windows防火墙...
netsh advfirewall reset >nul 2>&1
echo ✓ 防火墙已重置

echo [7/10] 清除代理设置...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 0 /f >nul 2>&1
netsh winhttp reset proxy >nul 2>&1
echo ✓ 代理设置已清除

echo [8/10] 重置Internet选项...
rundll32.exe iedkcs32.dll,Clear >nul 2>&1
echo ✓ Internet选项已重置

echo [9/10] 修复网络服务...
sc config Dnscache start= auto >nul 2>&1
sc start Dnscache >nul 2>&1
sc config Dhcp start= auto >nul 2>&1
sc start Dhcp >nul 2>&1
sc config NlaSvc start= auto >nul 2>&1
sc start NlaSvc >nul 2>&1
echo ✓ 网络服务已修复

echo [10/10] 重启网络接口...
netsh interface set interface "以太网" admin=disable >nul 2>&1
timeout /t 3 /nobreak >nul
netsh interface set interface "以太网" admin=enable >nul 2>&1
echo ✓ 网络接口已重启

echo.
echo ==========================================
echo           全面修复完成！
echo ==========================================
echo.
echo 建议重启计算机以使所有更改生效。
echo.
echo 是否立即重启？(Y/N)
set /p reboot_choice=
if /i "%reboot_choice%"=="Y" shutdown /r /t 60 /c "系统将在60秒后重启以完成网络修复"
pause
goto menu