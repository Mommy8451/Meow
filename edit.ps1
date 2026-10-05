$ErrorActionPreference = 'Continue'
$Host.UI.RawUI.WindowTitle = 'Windows Setup Script'

function Warn($e) { Write-Host "   WARNING: $($e.Exception.Message)" -ForegroundColor Yellow }

Write-Host '============================================'
Write-Host ' Windows Setup Script'
Write-Host '============================================'
Write-Host ''

# ------------------------------------------------------------
# [1/5] Wallpaper
# ------------------------------------------------------------
Write-Host '[1/5] Downloading and setting wallpaper...'
try {
    $url = 'https://4kwallpapers.com/images/walls/thumbs_3t/26545.png'
    $img = Join-Path $env:USERPROFILE 'wallpaper.png'
    Invoke-WebRequest -Uri $url -OutFile $img -UseBasicParsing

    $reg = 'HKCU:\Control Panel\Desktop'
    Set-ItemProperty -Path $reg -Name Wallpaper      -Value $img -Force
    Set-ItemProperty -Path $reg -Name WallpaperStyle -Value '10' -Force
    Set-ItemProperty -Path $reg -Name TileWallpaper  -Value '0'  -Force

    if (-not ('WP' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class WP {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int a, int b, string c, int d);
}
'@
    }
    [void][WP]::SystemParametersInfo(20, 0, $img, 3)
    Write-Host '   Wallpaper set successfully.'
} catch { Warn $_ }

# ------------------------------------------------------------
# [2/5] Enable "End Task" in taskbar right-click menu
# (Windows 11 23H2+ only)
# ------------------------------------------------------------
Write-Host '[2/5] Enabling End Task in Developer Settings...'
try {
    $p = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings'
    if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
    New-ItemProperty -Path $p -Name 'TaskbarEndTask' -PropertyType DWord -Value 1 -Force | Out-Null
    $v = (Get-ItemProperty -Path $p -Name 'TaskbarEndTask').TaskbarEndTask
    if ($v -eq 1) { Write-Host '   End Task enabled.' }
    else { Write-Host '   Failed to verify registry value.' -ForegroundColor Yellow }
} catch { Warn $_ }

# ------------------------------------------------------------
# [3/5] Unpin Microsoft Edge from taskbar
# ------------------------------------------------------------
Write-Host '[3/4] Unpinning Microsoft Edge from taskbar...'
try {
    $pinDir = Join-Path $env:APPDATA 'Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar'
    $edge = @()
    if (Test-Path $pinDir) {
        $edge = Get-ChildItem -Path $pinDir -Filter '*.lnk' -ErrorAction SilentlyContinue |
                Where-Object { $_.BaseName -like '*Edge*' }
    }
    if ($edge.Count -gt 0) {
        $edge | Remove-Item -Force
        $tb = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband'
        foreach ($n in 'Favorites','FavoritesResolve','FavoritesChanges','FavoritesRemovedChanges','FavoritesVersion') {
            Remove-ItemProperty -Path $tb -Name $n -ErrorAction SilentlyContinue
        }
        Write-Host '   Edge shortcut removed.'
    } else {
        Write-Host '   Microsoft Edge pin not found.'
    }
} catch { Warn $_ }

# Restart Explorer so the taskbar reloads before pinning
Write-Host 'Restarting Explorer...'
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) { Start-Process explorer }
Start-Sleep -Seconds 4

# ------------------------------------------------------------
# [4/5] Open Task Manager
# ------------------------------------------------------------
Write-Host '[4/5] Opening Task Manager...'
try {
    Start-Process -FilePath (Join-Path $env:WINDIR 'System32\Taskmgr.exe')
    Start-Sleep -Seconds 3
    Write-Host '   Task Manager opened.'
} catch { Warn $_ }

# ------------------------------------------------------------
# [5/5] Pin Task Manager to taskbar
# Method A: custom verb (reuses system pin handler) on Taskmgr.exe
# Method B: same verb on a .lnk in %TEMP%
# Method C: drop the .lnk directly in User Pinned\TaskBar + restart Explorer
# Each method is verified before moving to the next.
# ------------------------------------------------------------
Write-Host '[5/5] Pinning Task Manager to taskbar...'

$taskmgr = Join-Path $env:WINDIR 'System32\Taskmgr.exe'
$tmpLnk  = Join-Path $env:TEMP 'Task Manager.lnk'
$verb    = '{:}'
$verbKey = "Software\Classes\*\shell\$verb"

function Test-TaskMgrPinned {
    if (-not (Test-Path $pinDir)) { return $false }
    $ws = New-Object -ComObject WScript.Shell
    foreach ($f in Get-ChildItem -Path $pinDir -Filter '*.lnk' -ErrorAction SilentlyContinue) {
        try {
            if ($ws.CreateShortcut($f.FullName).TargetPath -like '*\Taskmgr.exe') { return $true }
        } catch {}
    }
    return $false
}

function Invoke-PinVerb([string]$path) {
    $shell  = New-Object -ComObject Shell.Application
    $folder = $shell.Namespace((Split-Path $path))
    $item   = $folder.ParseName((Split-Path $path -Leaf))
    if (-not $item) { throw "ParseName failed for $path" }
    $item.InvokeVerb($verb)
    Start-Sleep -Seconds 3
}

try {
    $handler = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\Windows.taskbarpin' -ErrorAction Stop).ExplorerCommandHandler
    if (-not $handler) { throw 'Windows.taskbarpin handler not found.' }

    $k = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey($verbKey)
    $k.SetValue('ExplorerCommandHandler', $handler)
    $k.Close()

    $pinned = Test-TaskMgrPinned

    # Method A
    if (-not $pinned) {
        try { Invoke-PinVerb $taskmgr } catch { Warn $_ }
        $pinned = Test-TaskMgrPinned
        if ($pinned) { Write-Host '   Pinned (method A).' }
    }

    # Method B
    if (-not $pinned) {
        try {
            $ws = New-Object -ComObject WScript.Shell
            $sc = $ws.CreateShortcut($tmpLnk)
            $sc.TargetPath = $taskmgr
            $sc.Save()
            Invoke-PinVerb $tmpLnk
        } catch { Warn $_ }
        $pinned = Test-TaskMgrPinned
        if ($pinned) { Write-Host '   Pinned (method B).' }
    }

    # Method C
    if (-not $pinned) {
        try {
            if (-not (Test-Path $pinDir)) { New-Item -ItemType Directory -Path $pinDir -Force | Out-Null }
            $ws = New-Object -ComObject WScript.Shell
            $sc = $ws.CreateShortcut((Join-Path $pinDir 'Task Manager.lnk'))
            $sc.TargetPath = $taskmgr
            $sc.Save()
            Restart-Explorer
        } catch { Warn $_ }
        $pinned = Test-TaskMgrPinned
        if ($pinned) { Write-Host '   Pinned (method C - shortcut in pinned folder).' }
    }

    if (-not $pinned) { Write-Host '   Task Manager pin FAILED (all methods).' -ForegroundColor Yellow }
} catch { Warn $_ }
finally {
    try { [Microsoft.Win32.Registry]::CurrentUser.DeleteSubKeyTree($verbKey, $false) } catch {}
    Remove-Item $tmpLnk -Force -ErrorAction SilentlyContinue
}

Write-Host ''
Write-Host 'All tasks completed.'

# ------------------------------------------------------------
# Install menu (skipped automatically inside GitHub Actions)
# ------------------------------------------------------------
if (-not $env:GITHUB_ACTIONS) {

    Write-Host ''
    Write-Host '============================================'
    Write-Host ' Setup finished! What would you like to install?'
    Write-Host '============================================'
    Write-Host ''
    Write-Host '  [1] opencode Desktop + opencode Terminal'
    Write-Host '  [2] Ollama'
    Write-Host '  [3] Both (opencode + Ollama)'
    Write-Host '  [4] Nothing (Skip)'
    Write-Host ''

    function Install-Winget([string]$id) {
        winget install --id $id --exact --silent --accept-source-agreements --accept-package-agreements --disable-interactivity
    }

    $choice = Read-Host 'Enter your choice (1-4)'
    switch ($choice) {
        '1' { Install-Winget 'SST.opencode'; Install-Winget 'SST.OpenCodeDesktop'; Write-Host 'opencode installation finished.' }
        '2' { Install-Winget 'Ollama.Ollama'; Write-Host 'Ollama installation finished.' }
        '3' { Install-Winget 'SST.opencode'; Install-Winget 'SST.OpenCodeDesktop'; Install-Winget 'Ollama.Ollama'; Write-Host 'All installations finished.' }
        '4' { Write-Host 'Skipping installations.' }
        default { Write-Host 'Invalid choice! No installations performed.' }
    }

    Write-Host ''
    Write-Host '============================================'
    Write-Host ' All done!'
    Write-Host '============================================'
    Read-Host 'Press Enter to exit'
}
