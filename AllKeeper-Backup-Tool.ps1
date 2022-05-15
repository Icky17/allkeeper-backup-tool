#------------- Programmkopf ---------------#
# Autor: Jairo Morales
# Version: 1.0.0
# Datum: 13.05.2022
# Titel: AllKeeper (Backup-Tool, Shell)
# PSVersion: 5.1.19041.1320
# Beschreibung:
# Mit der Auswahl von verschiedenen Optionen
# kann man einen schnellen, automatisierten 
# Backup erstellen.
#
# GitHub: https://github.com/Icky17/AllKeeper-Backup-Tool
#------------------------------------------#

# LogFile und Write-Host habe ich getrennt, weil ich mit der LogFile Funktion nicht färben konnte

# Hier werden alle Variablen deklariert (Mit Kommentar)

$logPath = "C:\temp\AllKeeper_Backup" # Hier wird der LogFile gespeichert
$LogfileName = "AllKeeper-Log" # LogFile Name
$LoggingLevel = "1" # Hier kann man entscheiden, ob man auch die Log Messages vom LogFile in der PowerShell sehen will. 1=kein Text in der Shell, 3=Text in der Shell (Default = 1)

$FolderToSave = # Welche Dateien / Ordner Du sichern willst
$BackupFolder = "C:\temp\AllKeeper_Backup" # (Default) Wo die Dateien / Ordner gesichert werden
$NewName = # Hier wird der Name des Backup Ordners gespeichert

$ZIP = $true # Backup wird im Zielpfad komprimiert und Staging Ordner wird im C: Laufwerk \temp erstellt
$StagingPath = "C:\temp\AllKeeper_Staging" # (Default) Hier werden die Dateien / Ordner gespeichert und komprimiert um diese danach ins Ziel Ordner zu kopieren.

$ZIPCheck = $true # Falls der ZIPCheck am Schluss $false ist, wurde sich der ZIP Vorgang wiederholen (Default = $true)

#--------------------------------------------------##--------------------------------------------------#
#--------------------------------------------------##--------------------------------------------------#
# Mit dieser Funktion, kann man alles was beim Backup-Prozess passiert, in einen Logfile speichern.    #
#--------------------------------------------------##--------------------------------------------------#
#--------------------------------------------------##--------------------------------------------------#


function Write-Logfile { # Hier wird eine neue Funktion erstellt, die mir das erstellen des LogFiles und der LogNachrichten vereinfacht
    [CmdletBinding()]
    param
    (
        [ValidateSet('DEBUG', 'INFO', 'WARNING', 'ERROR')] # Das sind die verschiedenen Optionen die man nehmen kann, um den Prozess zu beschreiben.
        [string]$Type,
        [string]$Text
    )
       
    if (!(Test-Path -Path $logPath)) { # LogFile Pfad erstellen und kontrollieren
        try {
            $logPath = New-Item -Path $logPath -ItemType Directory
            Write-Verbose ("Path: ""{0}"" was created." -f $logPath)
        }
        catch {
            Write-Verbose ("Path: ""{0}"" couldn't be created." -f $logPath)
        }
    }
    else {
        Write-Verbose ("Path: ""{0}"" already exists." -f $logPath)
    }
    [string]$logFile = '{0}\{1}_{2}.log' -f $logPath, $(Get-Date -Format 'yyyy-MM-dd'), $LogfileName # LogFile Name wird erstellt
    $logEntry = '{0}: <{1}> <{2}> {3}' -f $(Get-Date -Format dd.MM.yyyy-HH:mm:ss), $Type, $PID, $Text # Info von Uhrzeit, Datum, Fehler werden vor der Ausgabe des Status, in das LogFile hinein kopiert
    
    try { Add-Content -Path $logFile -Value $logEntry } # Log Nachrichten werden ins LogFile kopiert
    catch {
        Start-sleep -Milliseconds 50
        Add-Content -Path $logFile -Value $logEntry
    }
    if ($LoggingLevel -eq "3") { Write-Host $Text } # Hier kann man entscheiden, ob man auch die Nachrichten des LogFiles sehen will
}


#--------------------------------------------------#
#--------------------------------------------------#
# Titel, Willkommen und Warnungen
#--------------------------------------------------#
#--------------------------------------------------#


$AllKeeper = @"
░█████╗░██╗░░░░░██╗░░░░░██╗░░██╗███████╗███████╗██████╗░███████╗██████╗░
██╔══██╗██║░░░░░██║░░░░░██║░██╔╝██╔════╝██╔════╝██╔══██╗██╔════╝██╔══██╗
███████║██║░░░░░██║░░░░░█████═╝░█████╗░░█████╗░░██████╔╝█████╗░░██████╔╝    (Autor: Jairo Morales)
██╔══██║██║░░░░░██║░░░░░██╔═██╗░██╔══╝░░██╔══╝░░██╔═══╝░██╔══╝░░██╔══██╗
██║░░██║███████╗███████╗██║░╚██╗███████╗███████╗██║░░░░░███████╗██║░░██║
╚═╝░░╚═╝╚══════╝╚══════╝╚═╝░░╚═╝╚══════╝╚══════╝╚═╝░░░░░╚══════╝╚═╝░░╚═╝
"@
Write-Host $AllKeeper -ForegroundColor blue


Write-Logfile -Type Info -Text "Starte den Skript"
Write-Host "Willkommen zum Backup-Tool AllKeeper!"

Start-Sleep -Seconds 1 # Mit folgenden Befehl pausiert man für 1 Sekunde den Prozess / Ablauf

Write-Host "`n" # Mit folgenden Befehl erstellt man einen Zeilenabstand

Write-Warning "Bei Ordner die Adminrechte benötigen, wird der Backup nicht durchgeführt, ausser man führt den Skript als Administrator aus."

Start-Sleep -Seconds 4

Write-Host "`n"

#--------------------------------------------------#
#--------------------------------------------------#
# Welche Datei / Ordner gesichert werden soll
#--------------------------------------------------#
#--------------------------------------------------#


Do 
{
    $i = $false
    try {
        
        Write-Host "Welche Datei / Ordner soll gesichert werden?: [Pfad eingeben]"
        $FolderToSave = Read-Host
        "Der Pfad [$FolderToSave] wird gesucht."
        Write-host "`n"
        if (Test-Path -Path $FolderToSave) { # Mit dem Befehl wird kontrolliert, ob der Pfad existiert oder nicht
        Write-Host "Pfad existiert!" -ForegroundColor Green 

        $i = $true
        } else {
        Write-Host "Pfad existiert nicht." -ForegroundColor red
        Write-Host ""

        $i = $false
        }
    }
    catch {
        Write-Host "ERROR: Ein Fehler wurde entdeckt, bitte geben sie einen gültigen Pfad ein." -ForegroundColor red
        Write-host "`n"

        $i = $false
    }
} While ($i -eq $false)

Start-Sleep -Seconds 1.5

Write-Host "`n"


#--------------------------------------------------#
#--------------------------------------------------#
# Wo der Backup gesichert werden soll
#--------------------------------------------------#
#--------------------------------------------------#


Do 
{
    $i = $false

    Write-Host "Wo soll die Datei / Ordner gesichert werden?: [Pfad eingeben]"
    $BackupFolder = Read-Host
    "Der Pfad [$BackupFolder] wird gesucht."
        Write-Host "`n"
    try {
        if (Test-Path -Path $BackupFolder) {
        Write-Host "Pfad existiert!" -ForegroundColor Green 

        $i = $true
        } else {
        Write-Host "Pfad existiert nicht." -ForegroundColor red

        $BackupFolder = New-Item -Path $BackupFolder -ItemType Directory # Mit dem Befehl wird ein neuer Ordner / Pfad erstellt

        Write-Host "Pfad wurde erstellt." -ForegroundColor orange
        Write-Host "`n"

        $i = $true
        }
    }
    catch {
        Write-Host "ERROR: Ein Fehler wurde entdeckt, bitte geben sie einen gültigen Pfad ein." -ForegroundColor red 
        Write-Host "`n"

        $i = $false
    }
} While ($i -eq $false)

Start-Sleep -Seconds 1.5

Write-Host "`n"


#--------------------------------------------------#
#--------------------------------------------------#
# Name des Ordners benennen / umbenennen
#--------------------------------------------------#
#--------------------------------------------------#


Do {
    Write-Host "Geben Sie einen Namen für die Datei / Ordner ein: [Default = 'Backup' + Datum + Zeit]"
    $NewName = Read-Host
    try {
        if ($NewName -eq "") {
            Write-Host "Die Datei / Ordner bekommt den (Default) Namen" -ForegroundColor cyan
            Write-Host ""

            $NewName = "Backup-" + (Get-Date -format yyyy-MM-dd) + "_" + (Get-Date -format HH-mm-ss) # Hier wird der Name eines Files erstellt
        
            $BackupDestination = $BackupFolder + "\" + $NewName # Hier werden mehrere Variable in eine einzige zusammen getan und es entsteht eine neue Variable
            Write-Host "Der Ordner wurde mit dem Namen [$BackupDestination] erfolgreich erstellt" -ForegroundColor cyan
            
            $i = $true
        
        } else {
            $BackupDestination = $BackupFolder + "\" + $NewName

            Write-Host ""
            Write-Host "Der Ordner wird mit dem Namen [$BackupDestination] gespeichert" -ForegroundColor cyan

            $i = $true

        } 
    }
    catch {
        Write-Warning "Der Pfad / Ordner existiert schon oder es hat einen ungültigen Zeichen."
        Write-Host ""
        
        $i = $false

    }

} While ($i -eq $false)

Write-Host ""


#--------------------------------------------------#
#--------------------------------------------------#
# ZIP Alternation / Auswahl
#--------------------------------------------------#
#--------------------------------------------------#


Do {
    try {
        Write-Host "Soll die Datei mit ZIP gesichert werden?"
    
        $ZipOption = Read-Host
    
        if ($ZipOption -eq "j") {
            Write-Host "Die Datei wird mit ZIP komprimiert."
            $ZIP = $true
            $i = $true
            Write-Host ""
    
        } elseif ($ZipOption -eq "n") {
            Write-Host "Die Datei wird nicht mit ZIP komprimiert."
            $ZIP = $false
            $i = $true
            Write-Host ""
        } else {
            Write-Logfile -Type ERROR -Text "Fehleingabe bei. 'J' oder 'N'"
            Write-Host "Bitte geben Sie 'J' oder 'N' ein." -ForegroundColor red
            -ErrorAction Stop # Mit dem Befehl, geht es direkt ins Catch hinein obwohl der Code keinen "Fehler" ausgibt. Man provoziert sozu sagen den Fehler
        }
    
    } catch {
        Write-Logfile -Type ERROR -Text "Die Datei konnte nicht richtig konfiguriert werden."
        Write-Host ""
        $i = $false

    }
} While ($i -eq $false)

#--------------------------------------------------#
#--------------------------------------------------#
# Backup Vorgang und ZIP Check
#--------------------------------------------------#
#--------------------------------------------------#


Do {
    if ($ZIP) {
        Write-Logfile -Type INFO -Text "ZIP wurde ausgewählt"
        
        try {
            $ZipFile = $StagingPath + "\" + $NewName + ".zip"
            
            Write-Logfile -Type Info -Text "Datei wird komprimiert"
                      
            Compress-Archive -Path $FolderToSave -Update -DestinationPath $ZipFile # Mit dem Befehl, können wir einen Ordner / Pfad komprimieren (ZIP) und mit dem Update Befehl können wir im verschieben
    
            Write-Logfile -Type Info -Text "ZIP wird ins Zielpfad verschoben"
    
            Move-Item -Path $ZipFile -Destination $BackupFolder # Hier wird das $ZipFile ins $BackupFolder verschoben
    
            $ZIPCheck = $true
        } catch {
            Write-Logfile -Type ERROR -Text "Error bei der Komprimierung"
            Write-Logfile -Type ERROR -Text $Error
            $ZIPCheck = $false
        }
    } else {
        Write-Logfile -Type INFO -Text "ZIP wurde nicht ausgewählt. Das Backup wird ohne ZIP durchgeführt."
        Write-Logfile -Type INFO -Text "Die Daten werden gesichert, bitte warten...."
        #--------------------------------------------------------------------------------------#
        Write-Host "ZIP wurde nicht ausgewählt. Das Backup wird ohne ZIP durchgeführt."
        Write-Host "Die Daten werden gesichert, bitte warten...."

        $BackupDestination = New-Item -Path $BackupDestination -ItemType Directory -ErrorAction Stop
        
        Copy-Item -Path $FolderToSave -Destination $BackupDestination -recurse -Force # Hier wird der Ordner nur kopiert, weil die Nicht komprimierte Datei verbraucht gleich viel Platz beim verschieben in ein anderes Laufwerk
    }
} While ($ZIPCheck -eq $false)

Write-Host "Das Backup von [$FolderToSave] wurde erfolgreich im folgendem Pfad gespeichert: [$BackupDestination]" -ForegroundColor Green
Write-Host ""
Write-Host "Das LogFile wurde im Ordner [$logPath] gespeichert."
Write-Host ""
Write-Host "Drücke Enter, um das Skript zu beenden.." -ForegroundColor Blue

$End = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

#--------------------------------------------------#
#--------------------------------------------------#
# Skript Ende
#--------------------------------------------------#
#--------------------------------------------------#