@echo off
setlocal
title Windows Setup Script

echo ============================================
echo  Windows Setup Script
echo ============================================
echo.

set "PS1=%TEMP%\setup_windows_%RANDOM%.ps1"
if exist "%PS1%" del "%PS1%" >nul 2>&1

REM ============================================
REM  Generate PowerShell script
REM ============================================
echo $ErrorActionPreference = 'Continue' >> "%PS1%"
echo. >> "%PS1%"
echo Write-Host '[1/4] Downloading and setting wallpaper...' >> "%PS1%"
echo try { >> "%PS1%"
echo     $url = 'https://4kwallpapers.com/images/walls/thumbs_3t/26545.png' >> "%PS1%"
echo     $img = Join-Path $env:USERPROFILE 'wallpaper.png' >> "%PS1%"
echo     Invoke-WebRequest -Uri $url -OutFile $img -UseBasicParsing >> "%PS1%"
echo     Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'Wallpaper' -Value $img -Force >> "%PS1%"
echo     Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'WallpaperStyle' -Value '10' -Force >> "%PS1%"
echo     Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'TileWallpaper' -Value '0' -Force >> "%PS1%"
echo     Add-Type -TypeDefinition 'using System;using System.Runtime.InteropServices;public class WP{[DllImport("user32.dll",CharSet=CharSet.Auto)]public static extern int SystemParametersInfo(int a,int b,string c,int d);}' >> "%PS1%"
echo     [WP]::SystemParametersInfo(20, 0, $img, 3) ^| Out-Null >> "%PS1%"
echo     Write-Host '   Wallpaper set successfully.' >> "%PS1%"
echo } catch { >> "%PS1%"
echo     Write-Host "   WARNING: $($_.Exception.Message)" >> "%PS1%"
echo } >> "%PS1%"
echo. >> "%PS1%"
echo Write-Host '[2/4] Enabling End Task in Developer Settings...' >> "%PS1%"
echo try { >> "%PS1%"
echo     $regPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' >> "%PS1%"
echo     New-Item -Path $regPath -Force -ErrorAction SilentlyContinue ^| Out-Null >> "%PS1%"
echo     Set-ItemProperty -Path $regPath -Name 'TaskbarEndTask' -Value 1 -Type DWord -Force >> "%PS1%"
echo     Write-Host '   End Task enabled.' >> "%PS1%"
echo } catch { >> "%PS1%"
echo     Write-Host "   WARNING: $($_.Exception.Message)" >> "%PS1%"
echo } >> "%PS1%"
echo. >> "%PS1%"
echo Write-Host '[3/4] Unpinning Microsoft Edge from taskbar...' >> "%PS1%"
echo try { >> "%PS1%"
echo     $pinnedFolder = Join-Path $env:APPDATA 'Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar' >> "%PS1%"
echo     if (Test-Path $pinnedFolder) { >> "%PS1%"
echo         Get-ChildItem -Path $pinnedFolder -Filter '*Edge*.lnk' -ErrorAction SilentlyContinue ^| Remove-Item -Force -ErrorAction SilentlyContinue >> "%PS1%"
echo         Write-Host '   Edge unpinned.' >> "%PS1%"
echo     } else { >> "%PS1%"
echo         Write-Host '   Pinned taskbar folder not found.' >> "%PS1%"
echo     } >> "%PS1%"
echo } catch { >> "%PS1%"
echo     Write-Host "   WARNING: $($_.Exception.Message)" >> "%PS1%"
echo } >> "%PS1%"
echo. >> "%PS1%"
echo Write-Host '[4/4] Opening Task Manager and pinning to taskbar...' >> "%PS1%"
echo try { >> "%PS1%"
echo     $tm = Join-Path $env:WINDIR 'System32\Taskmgr.exe' >> "%PS1%"
echo     Start-Process $tm >> "%PS1%"
echo     Start-Sleep -Seconds 3 >> "%PS1%"
echo     $shell = New-Object -ComObject Shell.Application >> "%PS1%"
echo     $folder = $shell.Namespace((Split-Path $tm)) >> "%PS1%"
echo     $item = $folder.ParseName((Split-Path $tm -Leaf)) >> "%PS1%"
echo     $item.InvokeVerb('taskbarpin') >> "%PS1%"
echo     Write-Host '   Task Manager pinned.' >> "%PS1%"
echo } catch { >> "%PS1%"
echo     Write-Host "   WARNING: $($_.Exception.Message)" >> "%PS1%"
echo } >> "%PS1%"
echo. >> "%PS1%"
echo Write-Host 'Restarting Explorer to apply changes...' >> "%PS1%"
echo Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue >> "%PS1%"
echo Start-Sleep -Seconds 2 >> "%PS1%"
echo Start-Process explorer >> "%PS1%"
echo Write-Host '' >> "%PS1%"
echo Write-Host 'All tasks completed.' >> "%PS1%"

REM ============================================
REM  Run the script
REM ============================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%"

del "%PS1%" >nul 2>&1

echo.
echo ============================================
echo  All done!
echo ============================================
echo.
pause