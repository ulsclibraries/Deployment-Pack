# Windows 11 Pro - Disable LibUser Autologin
# This script disables automatic login (login screen will be shown on startup)
# Requires Administrator privileges

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Write-LogEntry {
    param([string]$Message)
    
    $logFile = "C:\applications\LibUserSetup.log"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] $Message"
    
    $logDir = Split-Path -Parent $logFile
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    $logEntry | Out-File $logFile -Append -Force
}

function Get-AutoLoginStatus {
    $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
    $autoAdminLogon = Get-ItemProperty -Path $registryPath -Name "AutoAdminLogon" -ErrorAction SilentlyContinue
    $defaultUserName = Get-ItemProperty -Path $registryPath -Name "DefaultUserName" -ErrorAction SilentlyContinue
    return @{
        Enabled  = ($autoAdminLogon.AutoAdminLogon -eq "1")
        Username = $defaultUserName.DefaultUserName
    }
}

function Disable-AutoLogin {
    try {
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
        
        if (-not (Test-Path $registryPath)) {
            Write-LogEntry "Error: Registry path not found: $registryPath"
            return $false
        }
        
        Set-ItemProperty -Path $registryPath -Name "AutoAdminLogon" -Value "0" -Type String -ErrorAction Stop
        Remove-ItemProperty -Path $registryPath -Name "DefaultUserName"   -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $registryPath -Name "DefaultPassword"   -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $registryPath -Name "DefaultDomainName" -ErrorAction SilentlyContinue
        
        Write-LogEntry "Autologin disabled"
        return $true
    }
    catch {
        Write-LogEntry "Error disabling autologin: $($_.Exception.Message)"
        return $false
    }
}

# ============================================
# MAIN
# ============================================

Write-LogEntry "========================================================"
Write-LogEntry "Windows 11 Pro - Disable LibUser Autologin"
Write-LogEntry "========================================================"

if (-not (Test-Administrator)) {
    Write-LogEntry "ERROR: This script requires Administrator privileges."
    exit 1
}

try {
    $status = Get-AutoLoginStatus
    
    if (-not $status.Enabled) {
        Write-LogEntry "Autologin already disabled - no action taken."
        exit 0
    }
    
    Write-LogEntry "Autologin is currently enabled for: $($status.Username)"

    Write-LogEntry "Disabling autologin..."
    if (Disable-AutoLogin) {
        Write-LogEntry "[OK] Autologin disabled. Login screen will appear on next restart."
    }
    else {
        Write-LogEntry "Failed to disable autologin."
        exit 1
    }
}
catch {
    Write-LogEntry "Error during disable autologin: $($_.Exception.Message)"
    exit 1
}