# Windows 11 Pro - Enable LibUser Autologin
# This script enables automatic login for LibUser (blank password)
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

function Enable-AutoLogin {
    try {
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
        
        if (-not (Test-Path $registryPath)) {
            Write-LogEntry "Error: Registry path not found: $registryPath"
            return $false
        }
        
        Set-ItemProperty -Path $registryPath -Name "AutoAdminLogon"   -Value "1"            -Type String -ErrorAction Stop
        Set-ItemProperty -Path $registryPath -Name "DefaultUserName"   -Value "LibUser"      -Type String -ErrorAction Stop
        Set-ItemProperty -Path $registryPath -Name "DefaultPassword"   -Value ""             -Type String -ErrorAction Stop
        Set-ItemProperty -Path $registryPath -Name "DefaultDomainName" -Value $env:COMPUTERNAME -Type String -ErrorAction Stop
        
        Write-LogEntry "Autologin enabled for LibUser"
        return $true
    }
    catch {
        Write-LogEntry "Error enabling autologin: $($_.Exception.Message)"
        return $false
    }
}

# ============================================
# MAIN
# ============================================

Write-LogEntry "========================================================"
Write-LogEntry "Windows 11 Pro - Enable LibUser Autologin"
Write-LogEntry "========================================================"

if (-not (Test-Administrator)) {
    Write-LogEntry "ERROR: This script requires Administrator privileges."
    exit 1
}

# Verify LibUser exists
$libUser = Get-LocalUser -Name "LibUser" -ErrorAction SilentlyContinue
if (-not $libUser) {
    Write-LogEntry "ERROR: LibUser account does not exist. Run 2_CreateLibUser.ps1 first."
    exit 1
}

try {
    $status = Get-AutoLoginStatus
    
    if ($status.Enabled) {
        if ($status.Username -eq "LibUser") {
            Write-LogEntry "Autologin already enabled for LibUser - no action taken."
            exit 0
        }
        Write-LogEntry "Autologin currently enabled for: $($status.Username) - re-configuring for LibUser..."
    }
    else {
        Write-LogEntry "Autologin is currently disabled."
    }

    Write-LogEntry "Enabling autologin for LibUser..."
    if (Enable-AutoLogin) {
        Write-LogEntry "[OK] Autologin enabled. System will auto-login as LibUser on next restart."
    }
    else {
        Write-LogEntry "Failed to enable autologin."
        exit 1
    }
}
catch {
    Write-LogEntry "Error during enable autologin: $($_.Exception.Message)"
    exit 1
}
