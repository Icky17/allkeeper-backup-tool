#------------- Programmkopf ---------------#
# Autor: Jairo Morales (Original), Refactored Version
# Version: 2.0.0
# Datum: 24.12.2024
# Titel: AllKeeper (Backup-Tool, Shell)
# PSVersion: 5.1+
# Beschreibung:
# Automatisiertes Backup-Tool mit verschiedenen Optionen
# zur Datei- und Ordnersicherung
#
# Original: https://github.com/Icky17/allkeeper-backup-tool
#------------------------------------------#

# Parameter und Konfiguration
[CmdletBinding()]
param (
    [string]$LogPath = "C:\temp\AllKeeper_Backup",
    [string]$LogFileName = "AllKeeper-Log",
    [ValidateSet(1, 3)]
    [int]$LoggingLevel = 1,
    [string]$BackupFolder = "C:\temp\AllKeeper_Backup",
    [string]$StagingPath = "C:\temp\AllKeeper_Staging"
)

# Fehlerbehandlung aktivieren
$ErrorActionPreference = "Stop"

# Funktion für Logging
function Write-LogMessage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateSet('DEBUG', 'INFO', 'WARNING', 'ERROR')]
        [string]$Type,
        
        [Parameter(Mandatory)]
        [string]$Message
    )
    
    # Ensure log directory exists
    if (!(Test-Path -Path $LogPath)) {
        try {
            $null = New-Item -Path $LogPath -ItemType Directory -Force
            Write-Verbose "Log path created: $LogPath"
        }
        catch {
            throw "Failed to create log directory: $_"
        }
    }
    
    $logFile = Join-Path $LogPath "$((Get-Date).ToString('yyyy-MM-dd'))_$LogFileName.log"
    $timeStamp = (Get-Date).ToString('dd.MM.yyyy-HH:mm:ss')
    $logEntry = "{0}: <{1}> <{2}> {3}" -f $timeStamp, $Type, $PID, $Message
    
    try {
        Add-Content -Path $logFile -Value $logEntry
        if ($LoggingLevel -eq 3) {
            switch ($Type) {
                'ERROR'   { Write-Host $Message -ForegroundColor Red }
                'WARNING' { Write-Host $Message -ForegroundColor Yellow }
                'INFO'    { Write-Host $Message -ForegroundColor White }
                'DEBUG'   { Write-Host $Message -ForegroundColor Gray }
            }
        }
    }
    catch {
        Write-Warning "Failed to write to log file: $_"
    }
}

# Banner anzeigen
function Show-Banner {
    $banner = @"
░█████╗░██╗░░░░░██╗░░░░░██╗░░██╗███████╗███████╗██████╗░███████╗██████╗░
██╔══██╗██║░░░░░██║░░░░░██║░██╔╝██╔════╝██╔════╝██╔══██╗██╔════╝██╔══██╗
███████║██║░░░░░██║░░░░░█████═╝░█████╗░░█████╗░░██████╔╝█████╗░░██████╔╝    (Version 2.0.0)
██╔══██║██║░░░░░██║░░░░░██╔═██╗░██╔══╝░░██╔══╝░░██╔═══╝░██╔══╝░░██╔══██╗
██║░░██║███████╗███████╗██║░╚██╗███████╗███████╗██║░░░░░███████╗██║░░██║
╚═╝░░╚═╝╚══════╝╚══════╝╚═╝░░╚═╝╚══════╝╚══════╝╚═╝░░░░░╚══════╝╚═╝░░╚═╝
"@
    Write-Host $banner -ForegroundColor Blue
    Write-Host "`nWillkommen zum Backup-Tool AllKeeper!`n" -ForegroundColor Cyan
    Write-Warning "Für Ordner mit erforderlichen Administratorrechten muss das Skript als Administrator ausgeführt werden.`n"
}

# Funktion zur Pfadvalidierung
function Test-ValidPath {
    param (
        [string]$Path,
        [string]$PathType,
        [switch]$CreateIfNotExists
    )
    
    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw "Pfad darf nicht leer sein."
    }
    
    if (Test-Path -Path $Path) {
        Write-Host "Pfad existiert!" -ForegroundColor Green
        return $true
    }
    
    if ($CreateIfNotExists) {
        try {
            $null = New-Item -Path $Path -ItemType Directory -Force
            Write-Host "Pfad wurde erstellt." -ForegroundColor Yellow
            return $true
        }
        catch {
            Write-Host "Fehler beim Erstellen des Pfads: $_" -ForegroundColor Red
            return $false
        }
    }
    
    Write-Host "Pfad existiert nicht." -ForegroundColor Red
    return $false
}

# Hauptfunktion für den Backup-Prozess
function Start-Backup {
    param (
        [string]$SourcePath,
        [string]$DestinationPath,
        [string]$BackupName,
        [bool]$UseZip
    )
    
    try {
        if ($UseZip) {
            Write-LogMessage -Type INFO -Message "Starte ZIP-Backup"
            $zipPath = Join-Path $StagingPath "$BackupName.zip"
            
            # Ensure staging directory exists
            if (!(Test-Path $StagingPath)) {
                $null = New-Item -Path $StagingPath -ItemType Directory -Force
            }
            
            # Create ZIP
            Compress-Archive -Path $SourcePath -DestinationPath $zipPath -Force
            
            # Move ZIP to destination
            Move-Item -Path $zipPath -Destination $DestinationPath -Force
            
            Write-LogMessage -Type INFO -Message "ZIP-Backup erfolgreich erstellt"
        }
        else {
            Write-LogMessage -Type INFO -Message "Starte normales Backup"
            $destinationFullPath = Join-Path $DestinationPath $BackupName
            
            # Create destination directory
            $null = New-Item -Path $destinationFullPath -ItemType Directory -Force
            
            # Copy items
            Copy-Item -Path $SourcePath -Destination $destinationFullPath -Recurse -Force
            
            Write-LogMessage -Type INFO -Message "Normales Backup erfolgreich erstellt"
        }
        return $true
    }
    catch {
        Write-LogMessage -Type ERROR -Message "Backup-Fehler: $_"
        return $false
    }
}

# Hauptprogramm
function Start-AllKeeper {
    try {
        Show-Banner
        Write-LogMessage -Type INFO -Message "Starte AllKeeper Backup Tool"
        
        # Quellpfad abfragen
        do {
            Write-Host "Welche Datei/Ordner soll gesichert werden? [Pfad eingeben]"
            $sourcePath = Read-Host
        } while (!(Test-ValidPath -Path $sourcePath -PathType "Quelle"))
        
        # Zielpfad abfragen
        do {
            Write-Host "`nWo soll die Datei/Ordner gesichert werden? [Pfad eingeben]"
            $destPath = Read-Host
            if ([string]::IsNullOrWhiteSpace($destPath)) { $destPath = $BackupFolder }
        } while (!(Test-ValidPath -Path $destPath -PathType "Ziel" -CreateIfNotExists))
        
        # Backup-Namen festlegen
        Write-Host "`nGeben Sie einen Namen für das Backup ein [Enter für Standardname]:"
        $backupName = Read-Host
        if ([string]::IsNullOrWhiteSpace($backupName)) {
            $backupName = "Backup-" + (Get-Date -Format "yyyy-MM-dd_HH-mm-ss")
        }
        
        # ZIP-Option abfragen
        do {
            Write-Host "`nSoll das Backup als ZIP erstellt werden? (J/N)"
            $zipResponse = Read-Host
            $useZip = $zipResponse -eq "J"
        } while ($zipResponse -notin @("J", "N"))
        
        # Backup durchführen
        $success = Start-Backup -SourcePath $sourcePath -DestinationPath $destPath `
                              -BackupName $backupName -UseZip $useZip
        
        if ($success) {
            Write-Host "`nBackup erfolgreich erstellt!" -ForegroundColor Green
            Write-Host "Backup-Pfad: $destPath\$backupName" -ForegroundColor Cyan
            Write-Host "Log-Datei: $LogPath" -ForegroundColor Cyan
        }
        else {
            Write-Host "`nBackup fehlgeschlagen. Siehe Log-Datei für Details." -ForegroundColor Red
        }
    }
    catch {
        Write-LogMessage -Type ERROR -Message "Kritischer Fehler: $_"
        Write-Host "`nEin kritischer Fehler ist aufgetreten. Siehe Log-Datei für Details." -ForegroundColor Red
    }
    finally {
        Write-Host "`nDrücken Sie eine beliebige Taste zum Beenden..." -ForegroundColor Blue
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

# Skript starten
Start-AllKeeper