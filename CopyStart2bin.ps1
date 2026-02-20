function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to write log entries
function Write-LogEntry {
    param([string]$Message)
    
    $logFile = "C:\applications\copyStart2bin.log"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] $Message"
    # Validate log file path exists and is writable
    $logDir = Split-Path -Parent $logFile
    if (-not (Test-Path $logDir)) {
        throw "Log directory does not exist: $logDir"
    }
    
    if (-not ([System.IO.Directory]::GetAccessControl($logDir).Access)) {
        throw "No write permission to log directory: $logDir"
    }
    
    # Write to log file
    $logEntry | Out-File $logFile -Append -Force
    
}

# Check if running as Administrator
if (-not (Test-Administrator)) {
    Write-LogEntry "This script requires Administrator privileges. Please run as Administrator."
    exit 1
}

# Define paths for start2.bin
$start2Url = "https://raw.githubusercontent.com/ulsclibraries/Deployment-Pack/d592d8988289999a429894435ef9a4dbbda2c23a/start2.bin"
$start2SourceFile = Join-Path $env:TEMP "start2.bin"
$start2Destination = "C:\Users\LibUser\AppData\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState\start2.bin"
$start2DestinationFolder = Split-Path -Parent $start2Destination
$start2Backup = "C:\Users\LibUser\AppData\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState\start2.bin.old"

$successCount = 0
$totalCopies = 1

    # ===== COPY START2.BIN =====

    # Download start2.bin from GitHub
    Write-LogEntry "Downloading start2.bin from: $start2Url"
    try {
        Invoke-WebRequest -Uri $start2Url -OutFile $start2SourceFile -UseBasicParsing -ErrorAction Stop
        Write-LogEntry "Downloaded start2.bin to: $start2SourceFile"
    }
    catch {
        Write-LogEntry "Error downloading start2.bin: $($_.Exception.Message)"
        Write-LogEntry "Skipping Start Menu layout copy."
    }

    if (-not (Test-Path $start2SourceFile)) {
        Write-LogEntry "Warning: start2.bin not found after download attempt - skipping copy"
    }
    else {
        Write-LogEntry "start2.bin ready: $start2SourceFile"
        
        # Create destination folder if it doesn't exist
        if (-not (Test-Path $start2DestinationFolder)) {
            Write-LogEntry "Creating destination folder: $start2DestinationFolder"
            try {
                New-Item -Path $start2DestinationFolder -ItemType Directory -Force -ErrorAction Stop | Out-Null
                Write-LogEntry "Folder created successfully."
                Write-LogEntry "Created folder: $start2DestinationFolder"
            }
            catch {
                Write-LogEntry "Failed to create folder: $($_.Exception.Message)"
                Write-LogEntry "Error creating folder: $($_.Exception.Message)"
            }
        }
        
        # Check if destination start2.bin already exists and backup if needed
        if (Test-Path $start2Destination) {
            Write-LogEntry "Existing start2.bin found. Creating backup..."
            try {
                # Remove old backup if it exists
                if (Test-Path $start2Backup) {
                    Remove-Item -Path $start2Backup -Force -ErrorAction Stop
                    Write-LogEntry "Removed old backup: $start2Backup"
                }
                
                # Rename current file to .old
                Rename-Item -Path $start2Destination -NewName "start2.bin.old" -Force -ErrorAction Stop
                Write-LogEntry "Backed up existing file to: start2.bin.old"
                Write-LogEntry "Backed up existing start2.bin to start2.bin.old"
            }
            catch {
                Write-LogEntry "Warning: Could not backup existing file: $($_.Exception.Message)"
                Write-LogEntry "Warning: Could not backup start2.bin - $($_.Exception.Message)"
            }
        }
        
        # Copy start2.bin to destination
        Write-LogEntry "Copying start2.bin to LibUser Start Menu folder..."
        try {
            Copy-Item -Path $start2SourceFile -Destination $start2Destination -Force -ErrorAction Stop
            Write-LogEntry "Copied start2.bin to: $start2Destination"
            $successCount++
        }
        catch {
            Write-LogEntry "Error copying start2.bin: $($_.Exception.Message)"
        }
        finally {
            # Clean up temp file
            if (Test-Path $start2SourceFile) {
                Remove-Item -Path $start2SourceFile -Force -ErrorAction SilentlyContinue
                Write-LogEntry "Removed temp file: $start2SourceFile"
            }
        }
    }


        # ===== SUMMARY =====
    
    Write-LogEntry "`n========================================================================"
    if ($successCount -eq $totalCopies) {
        Write-LogEntry "Operation completed successfully - $successCount/$totalCopies copies made"
    }
    elseif ($successCount -gt 0) {
        Write-LogEntry "Operation completed with warnings - $successCount/$totalCopies copies made"
    }
    else {
        Write-LogEntry "Operation failed - no files copied"
        exit 1
    }
    
