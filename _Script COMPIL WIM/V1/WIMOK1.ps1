clear

# Efface l'affichage pour une vue propre
Clear-Host

# Obtient le chemin du dossier courant où le script est exécuté
$cheminDossierWIM = Get-Location

# Définit les chemins complets des fichiers WIM sources en utilisant le chemin du dossier courant
$cheminWim1 = Join-Path -Path $cheminDossierWIM -ChildPath "WIN10 OK.wim"
$cheminWim2 = Join-Path -Path $cheminDossierWIM -ChildPath "WIN10 TEST.wim"
$cheminWimFinal = Join-Path -Path $cheminDossierWIM -ChildPath "install.wim"

# Supprime le fichier WIM final s'il existe déjà pour éviter des erreurs lors de la création
If (Test-Path $cheminWimFinal) {
    Remove-Item $cheminWimFinal
}

# Exporte la première image de Wim1 vers le fichier WIM final à l'index 1
DISM /Export-Image /SourceImageFile:$cheminWim1 /SourceIndex:1 /DestinationImageFile:$cheminWimFinal /DestinationName:"Image de WIN10 OK"

# Exporte la première image de Wim2 vers le fichier WIM final, elle sera automatiquement ajoutée à l'index suivant disponible
DISM /Export-Image /SourceImageFile:$cheminWim2 /SourceIndex:1 /DestinationImageFile:$cheminWimFinal /DestinationName:"Image de WIN10 TEST"

# Affiche les informations du fichier WIM final pour vérification
DISM /Get-WimInfo /WimFile:$cheminWimFinal
