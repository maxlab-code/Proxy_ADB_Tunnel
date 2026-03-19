# === AUTOMATIC ADMINISTRATOR PRIVILEGES REQUEST ===
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $argList = '-WindowStyle Hidden -ExecutionPolicy Bypass -File "' + $PSCommandPath + '"'
    Start-Process -FilePath powershell.exe -ArgumentList $argList -Verb RunAs
    Exit
}
# ================= SETTINGS =================

$BatPath = Join-Path $PSScriptRoot "Auto_Proxy.bat"
# Go up one level (..) and enter the adjacent nekoray folder
$NekoBoxPath = [System.IO.Path]::GetFullPath("$PSScriptRoot\..\nekoray\nekobox.exe") #"C:\...\nekoray\nekobox.exe" # <--- OR INSERT YOUR PATH HERE

# If the executable inside is named nekoray.exe instead of nekobox.exe, the script will correct the path itself:
if (-not (Test-Path $NekoBoxPath)) {
    $NekoBoxPath = [System.IO.Path]::GetFullPath("$PSScriptRoot\..\nekoray\nekoray.exe")
}
# =================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Import Windows API
Add-Type @"
using System;
using System.Text;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

    public static IntPtr FindWindowContains(string partialTitle) {
        IntPtr found = IntPtr.Zero;
        EnumWindows((wnd, param) => {
            StringBuilder sb = new StringBuilder(256);
            GetWindowText(wnd, sb, 256);
            if (sb.ToString().Contains(partialTitle)) {
                found = wnd;
                return false;
            }
            return true;
        }, IntPtr.Zero);
        return found;
    }
}
"@

# Hide the PowerShell window
$psWindow = [Win32]::GetConsoleWindow()
if ($psWindow -ne [IntPtr]::Zero) { [Win32]::ShowWindow($psWindow, 0) }

$script:consoleVisible = $false

# Configure the tray icon
$icon = New-Object System.Windows.Forms.NotifyIcon
$icon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon("$env:windir\system32\cmd.exe")
$icon.Text = "Proxy ADB Tunnel"
$icon.Visible = $true

# Create the menu
$menu = New-Object System.Windows.Forms.ContextMenu
$itemStart  = New-Object System.Windows.Forms.MenuItem("▶ Start auto-tunnel")
$itemToggle = New-Object System.Windows.Forms.MenuItem("👁 Show / Hide console")
$itemStop   = New-Object System.Windows.Forms.MenuItem("⏹ Stop")
$itemExit   = New-Object System.Windows.Forms.MenuItem("❌ Exit")

$menu.MenuItems.Add($itemStart) | Out-Null
$menu.MenuItems.Add($itemToggle) | Out-Null
$menu.MenuItems.Add($itemStop) | Out-Null
$menu.MenuItems.Add("-") | Out-Null
$menu.MenuItems.Add($itemExit) | Out-Null
$icon.ContextMenu = $menu

# Function to start ADB and NekoBox
function Start-Tunnel {
    $hwnd = [Win32]::FindWindowContains("Proxy_ADB_Loop")
    if ($hwnd -eq [IntPtr]::Zero) {
        # Start ADB tunnel
		Start-Process cmd.exe -ArgumentList "/c `"$BatPath`"" -WindowStyle Hidden
        
        # Start NekoBox minimized (if the path is correct and it's not already running)
        if (Test-Path $NekoBoxPath) {
            $nekoProc = Get-Process -Name "nekobox", "nekoray" -ErrorAction SilentlyContinue
            if (-not $nekoProc) {
                Start-Process -FilePath $NekoBoxPath -ArgumentList "-tray" -WorkingDirectory (Split-Path $NekoBoxPath)
            }
        }

        $script:consoleVisible = $false
        $icon.BalloonTipText = "Auto-tunnel and NekoBox started."
        $icon.ShowBalloonTip(2000)
    } else {
        $icon.BalloonTipText = "Tunnel is already running."
        $icon.ShowBalloonTip(2000)
    }
}

# Function to show/hide the console
function Toggle-Console {
    $hwnd = [Win32]::FindWindowContains("Proxy_ADB_Loop")
    if ($hwnd -ne [IntPtr]::Zero) {
        if ($script:consoleVisible) {
            [Win32]::ShowWindow($hwnd, 0) # 0 = Hide
            $script:consoleVisible = $false
        } else {
            [Win32]::ShowWindow($hwnd, 5) # 5 = Show
            $script:consoleVisible = $true
        }
    } else {
        $icon.BalloonTipText = "Console not found."
        $icon.ShowBalloonTip(2000)
    }
}

$itemStart.Add_Click({ Start-Tunnel })

$itemToggle.Add_Click({ Toggle-Console })

$icon.Add_DoubleClick({ Toggle-Console })

$itemStop.Add_Click({
    # Kill the waiting script
    Get-CimInstance Win32_Process -Filter "name='cmd.exe' and CommandLine like '%Auto_Proxy.bat%'" | ForEach-Object { 
        Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue 
    }
    # Kill ADB processes
    Stop-Process -Name "adb" -Force -ErrorAction SilentlyContinue
    
    # Close NekoBox
    Stop-Process -Name "nekobox", "nekoray" -Force -ErrorAction SilentlyContinue
    
    $script:consoleVisible = $false
    $icon.BalloonTipText = "Tunnel, ADB, and NekoBox stopped."
    $icon.ShowBalloonTip(2000)
})

$itemExit.Add_Click({
    Get-CimInstance Win32_Process -Filter "name='cmd.exe' and CommandLine like '%Auto_Proxy.bat%'" | ForEach-Object { 
        Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue 
    }
    Stop-Process -Name "adb", "nekobox", "nekoray" -Force -ErrorAction SilentlyContinue
    
    $icon.Visible = $false
    [System.Windows.Forms.Application]::Exit()
})

# AUTOSTART ON LAUNCH
Start-Tunnel

[System.Windows.Forms.Application]::Run()