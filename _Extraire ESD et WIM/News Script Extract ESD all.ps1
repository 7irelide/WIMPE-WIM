#requires -RunAsAdministrator
#requires -Version 5.1

<#
.SYNOPSIS
    Extrait les indices de fichiers ESD et WIM avec options de menu.

.DESCRIPTION
    Ce script offre un menu interactif pour extraire des indices spécifiques ou tous les indices
    de fichiers ESD et WIM. Il utilise DISM pour l'extraction et permet une gestion flexible
    des fichiers d'entrée et de sortie.

.NOTES
    Nom du fichier : ESD-WIM-Extractor-Complete.ps1
    Auteur        : [Votre nom]
    Date          : [Date de création/modification]
    Version       : 8.0
    
    Assurez-vous d'exécuter ce script avec des privilèges administratifs.
#>

# Configuration des couleurs
$ColorScheme = @{
    Info    = 'Cyan'
    Success = 'Green'
    Warning = 'Yellow'
    Error   = 'Red'
    Debug   = 'Magenta'
    Header  = 'Yellow'
}

# Fonction pour afficher du texte coloré
function Write-ColoredOutput {
    param (
        [string]$Message,
        [string]$Color,
        [switch]$NoNewline
    )
    if ($NoNewline) {
        Write-Host $Message -ForegroundColor $Color -NoNewline
    } else {
        Write-Host $Message -ForegroundColor $Color
    }
}

# Fonction pour afficher un en-tête
function Show-Header {
    param (
        [string]$Title
    )
    $width = 80
    $padding = [math]::Max(0, ($width - $Title.Length) / 2)
    $line = "-" * $width
    Write-Host ""
    Write-Host $line -ForegroundColor Magenta
    Write-Host (" " * [math]::Floor($padding) + $Title + " " * [math]::Ceiling($padding)) -ForegroundColor $ColorScheme.Header -BackgroundColor DarkBlue
    Write-Host $line -ForegroundColor Magenta
    Write-Host ""
}

# Fonction pour initialiser les dossiers
function Initialize-Directory {
    param (
        [string]$Path,
        [string]$Name
    )
    if (-not (Test-Path -Path $Path)) {
        New-Item -Path $Path -ItemType Directory | Out-Null
        Write-ColoredOutput "Dossier $Name créé à l'emplacement: $Path" $ColorScheme.Info
    } else {
        Write-ColoredOutput "Le dossier $Name existe déjà à l'emplacement: $Path" $ColorScheme.Debug
    }
}

# Fonction pour exécuter les commandes DISM
function Invoke-DismCommand {
    param (
        [string]$Arguments
    )
    Write-ColoredOutput "Exécution de la commande DISM : dism.exe $Arguments" $ColorScheme.Debug
    $dismProcess = Start-Process -FilePath "dism.exe" -ArgumentList $Arguments -NoNewWindow -PassThru -Wait
    return $dismProcess.ExitCode
}

# Fonction pour afficher le menu
function Show-Menu {
    Clear-Host
    Show-Header "Menu d'Extraction ESD/WIM"
    Write-Host "  [1] Extraire un index spécifique" -ForegroundColor $ColorScheme.Info
    Write-Host "  [2] Extraire tous les fichiers du dossier" -ForegroundColor $ColorScheme.Info
    Write-Host "  [3] Quitter" -ForegroundColor $ColorScheme.Info
    Write-Host ""
    Write-Host "Choisissez une option (1-3): " -ForegroundColor $ColorScheme.Warning -NoNewline
}

# Fonction pour obtenir les fichiers ESD et WIM
function Get-ImageFiles {
    param (
        [string]$FolderPath
    )
    Write-ColoredOutput "Recherche de fichiers dans : $FolderPath" $ColorScheme.Debug
    $files = Get-ChildItem -Path $FolderPath -Include @("*.esd", "*.wim") -File -Recurse
    Write-ColoredOutput "Nombre de fichiers trouvés : $($files.Count)" $ColorScheme.Debug
    return $files
}

# Fonction pour sélectionner un fichier spécifique
function Get-SpecificFile {
    $files = Get-ImageFiles -FolderPath $depotFolder
    if ($files.Count -eq 0) {
        Write-ColoredOutput "Aucun fichier ESD ou WIM trouvé dans le dossier DEPOT." $ColorScheme.Error
        Write-ColoredOutput "Contenu du dossier DEPOT :" $ColorScheme.Debug
        Get-ChildItem -Path $depotFolder -Recurse | ForEach-Object { Write-ColoredOutput $_.FullName $ColorScheme.Debug }
        return $null
    }
    Write-ColoredOutput "Fichiers disponibles:" $ColorScheme.Info
    for ($i = 0; $i -lt $files.Count; $i++) {
        Write-ColoredOutput "$($i+1): $($files[$i].FullName)" $ColorScheme.Info
    }
    $choice = Read-Host "Sélectionnez le numéro du fichier"
    $index = [int]$choice - 1
    if ($index -ge 0 -and $index -lt $files.Count) {
        return $files[$index]
    } else {
        Write-ColoredOutput "Sélection invalide." $ColorScheme.Error
        return $null
    }
}

# Fonction pour afficher les détails d'extraction
function Show-ExtractionDetails {
    param (
        [string]$ImageIndex,
        [string]$ImageName,
        [string]$SourceFile,
        [string]$DestinationFile
    )
    Write-Host "+- Image $ImageIndex : $ImageName -" -ForegroundColor $ColorScheme.Success
    Write-Host "¦ Source      : $SourceFile" -ForegroundColor $ColorScheme.Info
    Write-Host "¦ Destination : $DestinationFile" -ForegroundColor $ColorScheme.Info
    Write-Host "+- Extraction de l'image..." -ForegroundColor $ColorScheme.Warning
}

# Fonction pour extraire un index spécifique
function Extract-SpecificIndex {
    Show-Header "Extraction d'un index spécifique"
    Write-ColoredOutput "Démarrage de l'extraction d'un index spécifique" $ColorScheme.Debug
    $file = Get-SpecificFile
    if ($null -eq $file) { 
        Write-ColoredOutput "Aucun fichier sélectionné ou trouvé." $ColorScheme.Error
        return 
    }

    $wimInfoOutput = & dism /Get-WimInfo /WimFile:"$($file.FullName)"
    $indices = @()
    $names = @()
    foreach ($line in $wimInfoOutput) {
        if ($line -match "^Index\s+:\s+(\d+)$") { $indices += $Matches[1] }
        elseif ($line -match "^Nom\s+:\s+(.+)$") { $names += $Matches[1] }
    }

    Write-ColoredOutput "Indices disponibles:" $ColorScheme.Info
    for ($i = 0; $i -lt $indices.Count; $i++) {
        Write-ColoredOutput "$($indices[$i]): $($names[$i])" $ColorScheme.Info
    }

    $indexChoice = Read-Host "Entrez le numéro de l'index à extraire"
    if ($indices -contains $indexChoice) {
        $name = $names[$indices.IndexOf($indexChoice)]
        $outputName = "$($file.BaseName) - $name.wim"
        $outputPath = Join-Path -Path $finalFolder -ChildPath $outputName
        Show-ExtractionDetails -ImageIndex $indexChoice -ImageName $name -SourceFile $file.FullName -DestinationFile $outputPath
        $dismArgs = "/Export-Image /SourceImageFile:`"$($file.FullName)`" /SourceIndex:$indexChoice /DestinationImageFile:`"$outputPath`" /Compress:max /CheckIntegrity"
        Write-ColoredOutput "Extraction en cours..." $ColorScheme.Warning
        $exitCode = Invoke-DismCommand -Arguments $dismArgs
        if ($exitCode -eq 0) {
            Write-ColoredOutput "Extraction réussie : $outputPath" $ColorScheme.Success
        } else {
            Write-ColoredOutput "Échec de l'extraction : $outputPath (Code de sortie: $exitCode)" $ColorScheme.Error
        }
    } else {
        Write-ColoredOutput "Index invalide." $ColorScheme.Error
    }
}

# Fonction pour extraire tous les fichiers
function Extract-AllFiles {
    Show-Header "Extraction de tous les fichiers"
    Write-ColoredOutput "Démarrage de l'extraction de tous les fichiers" $ColorScheme.Debug
    $files = Get-ImageFiles -FolderPath $depotFolder
    if ($files.Count -eq 0) {
        Write-ColoredOutput "Aucun fichier ESD ou WIM trouvé dans le dossier DEPOT." $ColorScheme.Error
        return
    }

    foreach ($file in $files) {
        Write-ColoredOutput "Traitement du fichier : $($file.FullName)" $ColorScheme.Info
        $wimInfoOutput = & dism /Get-WimInfo /WimFile:"$($file.FullName)"
        $indices = @()
        $names = @()
        foreach ($line in $wimInfoOutput) {
            if ($line -match "^Index\s+:\s+(\d+)$") { $indices += $Matches[1] }
            elseif ($line -match "^Nom\s+:\s+(.+)$") { $names += $Matches[1] }
        }

        for ($i = 0; $i -lt $indices.Count; $i++) {
            $index = $indices[$i]
            $name = $names[$i]
            $outputName = "$($file.BaseName) - $name.wim"
            $outputPath = Join-Path -Path $finalFolder -ChildPath $outputName
            Show-ExtractionDetails -ImageIndex $index -ImageName $name -SourceFile $file.FullName -DestinationFile $outputPath
            $dismArgs = "/Export-Image /SourceImageFile:`"$($file.FullName)`" /SourceIndex:$index /DestinationImageFile:`"$outputPath`" /Compress:max /CheckIntegrity"
            Write-ColoredOutput "Extraction de l'index $index ($name)..." $ColorScheme.Warning
            $exitCode = Invoke-DismCommand -Arguments $dismArgs
            if ($exitCode -eq 0) {
                Write-ColoredOutput "Extraction réussie : $outputPath" $ColorScheme.Success
            } else {
                Write-ColoredOutput "Échec de l'extraction : $outputPath (Code de sortie: $exitCode)" $ColorScheme.Error
            }
        }
    }
}

# Configuration initiale
$currentPath = Get-Location
$depotFolder = Join-Path -Path $currentPath -ChildPath "DEPOT"
$finalFolder = Join-Path -Path $currentPath -ChildPath "FINAL"

# Création des dossiers nécessaires
Initialize-Directory -Path $depotFolder -Name "DEPOT"
Initialize-Directory -Path $finalFolder -Name "FINAL"

# Vérification initiale des fichiers
Write-ColoredOutput "Vérification initiale des fichiers dans le dossier DEPOT" $ColorScheme.Debug
$initialFiles = Get-ImageFiles -FolderPath $depotFolder
Write-ColoredOutput "Nombre de fichiers ESD/WIM trouvés initialement : $($initialFiles.Count)" $ColorScheme.Debug

# Message de bienvenue
Clear-Host
Show-Header "Bienvenue dans le programme d'extraction ESD/WIM"
Write-Host @"

Pour commencer, assurez-vous d'avoir placé vos fichiers ESD et WIM dans le dossier 'DEPOT'.
Les fichiers extraits seront créés dans le dossier 'FINAL'.
"@ -ForegroundColor $ColorScheme.Info
Write-Host ""
Read-Host "Appuyez sur Entrée pour continuer"

# Boucle principale du menu
do {
    Show-Menu
    $input = Read-Host
    switch ($input) {
        '1' {
            Extract-SpecificIndex
            pause
        }
        '2' {
            Extract-AllFiles
            pause
        }
        '3' {
            Show-Header "Merci d'avoir utilisé l'ESD-WIM-Extractor!"
            return
        }
        default {
            Write-ColoredOutput "Option invalide. Veuillez réessayer." $ColorScheme.Error
            pause
        }
    }
} while ($true)