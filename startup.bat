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
echo     $regPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings' >> "%PS1%"
echo     New-Item -Path $regPath -Force -ErrorAction SilentlyContinue ^| Out-Null >> "%PS1%"
echo     Set-ItemProperty -Path $regPath -Name 'TaskbarEndTask' -Value 1 -Type DWord -Force >> "%PS1%"
echo     Write-Host '   End Task enabled.' >> "%PS1%"
echo } catch { >> "%PS1%"
echo     Write-Host "   WARNING: $($_.Exception.Message)" >> "%PS1%"
echo } >> "%PS1%"
echo. >> "%PS1%"

echo Write-Host '[3/4] Unpinning Microsoft Edge from taskbar...' >> "%PS1%"
echo try { >> "%PS1%"
echo     $shell = New-Object -ComObject Shell.Application >> "%PS1%"
echo     $edgeItem = $shell.NameSpace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}').Items() ^| Where-Object { $_.Name -eq 'Microsoft Edge' } >> "%PS1%"
echo     if ($edgeItem) { >> "%PS1%"
echo         $edgeItem.Verbs() ^| Where-Object { $_.Name.replace('&','') -match 'Unpin from taskbar' } ^| ForEach-Object { $_.DoIt() } >> "%PS1%"
echo         Write-Host '   Edge unpinned.' >> "%PS1%"
echo     } else { >> "%PS1%"
echo         Write-Host '   Microsoft Edge not found on taskbar.' >> "%PS1%"
echo     } >> "%PS1%"
echo } catch { >> "%PS1%"
echo     Write-Host "   WARNING: $($_.Exception.Message)" >> "%PS1%"
echo } >> "%PS1%"
echo. >> "%PS1%"

echo Write-Host '[4/4] Opening Task Manager and pinning to taskbar...' >> "%PS1%"
echo try { >> "%PS1%"
echo     $shortcutPath = Join-Path $env:USERPROFILE 'Desktop\Task Manager.lnk' >> "%PS1%"
echo     $taskmgrPath = Join-Path $env:WINDIR 'System32\Taskmgr.exe' >> "%PS1%"
echo     $WshShell = New-Object -ComObject WScript.Shell >> "%PS1%"
echo     $Shortcut = $WshShell.CreateShortcut($shortcutPath) >> "%PS1%"
echo     $Shortcut.TargetPath = $taskmgrPath >> "%PS1%"
echo     $Shortcut.Save() >> "%PS1%"
echo     $shell = New-Object -ComObject Shell.Application >> "%PS1%"
echo     $item = $shell.NameSpace((Split-Path $shortcutPath)).ParseName((Split-Path $shortcutPath -Leaf)) >> "%PS1%"
echo     $item.InvokeVerb('taskbarpin') >> "%PS1%"
echo     Start-Sleep -Seconds 2 >> "%PS1%"
echo     Remove-Item $shortcutPath -Force -ErrorAction SilentlyContinue >> "%PS1%"
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
REM  Run the setup script
REM ============================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
del "%PS1%" >nul 2>&1

echo.
echo ============================================
echo  Setup finished! What would you like to install?
echo ============================================
echo.
echo   [1] opencode Desktop + opencode Terminal
echo   [2] Ollama
echo   [3] Both (opencode + Ollama)
echo   [4] Nothing (Skip)
echo.

set /p choice="Enter your choice (1-4): "

if "%choice%"=="1" goto :install_opencode
if "%choice%"=="2" goto :install_ollama
if "%choice%"=="3" goto :install_both
if "%choice%"=="4" goto :skip_all
goto :invalid_choice

REM ============================================
REM  Install opencode (Desktop + Terminal)
REM ============================================
:install_opencode
echo.
echo ============================================
echo  Installing opencode Desktop + Terminal...
echo ============================================
echo.
winget install --id SST.opencode --exact --silent --accept-source-agreements --accept-package-agreements --disable-interactivity
winget install --id SST.OpenCodeDesktop --exact --silent --accept-source-agreements --accept-package-agreements --disable-interactivity
echo.
echo opencode installation finished.
goto :end

REM ============================================
REM  Install Ollama
REM ============================================
:install_ollama
echo.
echo ============================================
echo  Installing Ollama...
echo ============================================
echo.
winget install --id Ollama.Ollama --exact --silent --accept-source-agreements --accept-package-agreements --disable-interactivity
echo.
echo Ollama installation finished.
goto :end

REM ============================================
REM  Install Both
REM ============================================
:install_both
echo.
echo ============================================
echo  Installing opencode + Ollama...
echo ============================================
echo.
winget install --id SST.opencode --exact --silent --accept-source-agreements --accept-package-agreements --disable-interactivity
winget install --id SST.OpenCodeDesktop --exact --silent --accept-source-agreements --accept-package-agreements --disable-interactivity
winget install --id Ollama.Ollama --exact --silent --accept-source-agreements --accept-package-agreements --disable-interactivity
echo.
echo All installations finished.
goto :end

REM ============================================
REM  Skip everything
REM ============================================
:skip_all
echo.
echo Skipping installations.
goto :end

REM ============================================
REM  Invalid input
REM ============================================
:invalid_choice
echo.
echo Invalid choice! No installations performed.
goto :end

REM ============================================
REM  End
REM ============================================
:end
echo.
echo ============================================
echo  All done!
echo ============================================
echo.
pause
endlocal
