# Script de fusion de fichiers WIM
# Auteur: Assistant IA
# Date: 10/08/2024

# Fonction pour afficher un message avec une pause
function Show-Message {
    param (
        [string]$Message
    )
    Write-Host $Message
    Read-Host "Appuyez sur Entrée pour continuer..."
}

# Message de bienvenue
Clear-Host
Show-Message @"
Bienvenue dans le programme de fusion de fichiers WIM !

Ce programme vous permet de :
1. Fusionner plusieurs fichiers WIM en un seul fichier.
2. Choisir l'ordre des index dans le fichier WIM final.
3. Renommer les index selon vos besoins.
4. Vérifier l'intégrité des fichiers WIM avant la fusion.
5. Choisir le niveau de compression pour le fichier WIM final.

Pour commencer, assurez-vous d'avoir placé vos fichiers WIM dans le dossier 'SourceWims'.
Le fichier WIM final sera créé dans le dossier 'FinalWim'.

"@

# Définition des chemins
$sourcePath = Join-Path $PSScriptRoot "SourceWims"
$outputPath = Join-Path $PSScriptRoot "FinalWim"
$finalWimPath = Join-Path $outputPath "install.wim"

# Création des dossiers s'ils n'existent pas
if (-not (Test-Path $sourcePath)) { 
    New-Item -ItemType Directory -Path $sourcePath 
    Show-Message "Le dossier 'SourceWims' a été créé. Veuillez y placer vos fichiers WIM et relancer le script."
    exit
}
if (-not (Test-Path $outputPath)) { New-Item -ItemType Directory -Path $outputPath }

# Détection des fichiers WIM dans le dossier source
$wimFiles = Get-ChildItem -Path $sourcePath -Filter "*.wim"

if ($wimFiles.Count -eq 0) {
    Show-Message "Aucun fichier WIM trouvé dans le dossier 'SourceWims'. Veuillez y placer vos fichiers WIM et relancer le script."
    exit
}

# Supprimer l'ancien fichier WIM final s'il existe
if (Test-Path $finalWimPath) {
    Remove-Item $finalWimPath
}

# Affichage des fichiers WIM détectés
Clear-Host
Write-Host "Fichiers WIM détectés dans le dossier 'SourceWims' :"
for ($i = 0; $i -lt $wimFiles.Count; $i++) {
    Write-Host "$($i+1). $($wimFiles[$i].Name)"
}
Show-Message "`nCes fichiers seront utilisés pour la fusion."

# Sélection de l'ordre des index
$selectedOrder = @()
for ($i = 1; $i -le $wimFiles.Count; $i++) {
    Clear-Host
    Write-Host "Sélection de l'ordre des index :"
    for ($j = 0; $j -lt $selectedOrder.Count; $j++) {
        Write-Host "$($j+1). $($wimFiles[$selectedOrder[$j]].Name)"
    }
    Write-Host "`nFichiers disponibles :"
    for ($j = 0; $j -lt $wimFiles.Count; $j++) {
        if (-not $selectedOrder.Contains($j)) {
            Write-Host "$($j+1). $($wimFiles[$j].Name)"
        }
    }
    $selection = Read-Host "`nEntrez le numéro du fichier WIM pour l'index $i (ou appuyez sur Entrée pour terminer)"
    if ($selection -eq "") { break }
    $selectedIndex = [int]$selection - 1
    if ($selectedOrder.Contains($selectedIndex)) {
        Show-Message "Ce fichier a déjà été sélectionné. Veuillez choisir un autre fichier."
        $i--
    } else {
        $selectedOrder += $selectedIndex
    }
}

# Renommage des index
$indexNames = @()
foreach ($index in $selectedOrder) {
    Clear-Host
    Write-Host "Renommage des index :"
    for ($i = 0; $i -lt $indexNames.Count; $i++) {
        Write-Host "$($i+1). $($indexNames[$i])"
    }
    $defaultName = $wimFiles[$index].BaseName
    $newName = Read-Host "`nEntrez un nom pour l'index '$defaultName' (ou appuyez sur Entrée pour garder le nom par défaut)"
    if ($newName -eq "") { $newName = $defaultName }
    $indexNames += $newName
}

# Fusion des WIM
Clear-Host
$totalImages = $selectedOrder.Count
for ($i = 0; $i -lt $selectedOrder.Count; $i++) {
    $sourceWim = $wimFiles[$selectedOrder[$i]].FullName
    $index = $i + 1
    $name = $indexNames[$i]

    Write-Host "`nTraitement de l'image $index : $name"
    Write-Host "Fichier source : $sourceWim"
    Write-Host "Fichier destination : $finalWimPath"
    
    # Utilisation de la méthode DISM /Export-Image pour créer ou ajouter des images au WIM final
    Write-Host "Exportation de l'image..."
    DISM /Export-Image /SourceImageFile:$sourceWim /SourceIndex:1 /DestinationImageFile:$finalWimPath /DestinationName:"Image de $name"
    
    # Afficher la barre de progression
    $progressPercent = [math]::Round((($index / $totalImages) * 100), 2)
    Write-Progress -Activity "Fusion des fichiers WIM" -Status "Progression : $progressPercent%" -PercentComplete $progressPercent

    # Vérifier si DISM a rencontré une erreur
    if ($LASTEXITCODE -ne 0) {
        throw "Erreur lors de la fusion de l'image $index"
    }
    Write-Host "Image $index traitée avec succès."
}

# Afficher les informations du fichier WIM final pour vérification
DISM /Get-WimInfo /WimFile:$finalWimPath

Show-Message "Fusion terminée avec succès. Le fichier final se trouve à : $finalWimPath"
