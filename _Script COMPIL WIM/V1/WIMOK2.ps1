clear
cd "C:\Users\Fabien\_No Sync"


Clear-Host

# Obtient le chemin du dossier courant où le script est exécuté
$cheminDossierWIM = Get-Location

# Liste des noms de fichiers WIM sources
$nomsFichiersWIM = @("10no.wim", "10yes.wim", "11no.wim", "11yes.wim", "WIN10 LAST.wim")

# Chemin du fichier WIM final
$cheminWimFinal = Join-Path -Path $cheminDossierWIM -ChildPath "install.wim"

# Supprime le fichier WIM final s'il existe déjà pour éviter des erreurs lors de la création
If (Test-Path $cheminWimFinal) {
    Remove-Item $cheminWimFinal
}

# Itère sur chaque fichier WIM dans la liste
foreach ($nomFichier in $nomsFichiersWIM) {
    $cheminWimSource = Join-Path -Path $cheminDossierWIM -ChildPath $nomFichier
    
    # Vérifie si le fichier WIM source existe
    If (Test-Path $cheminWimSource) {
        # Extrait le nom sans extension pour l'utiliser comme nom de l'image
        $nomImage = [System.IO.Path]::GetFileNameWithoutExtension($nomFichier)

        # Exporte l'image du fichier WIM source vers le fichier WIM final avec son nom d'origine
        DISM /Export-Image /SourceImageFile:$cheminWimSource /SourceIndex:1 /DestinationImageFile:$cheminWimFinal /DestinationName:"Image de $nomImage"
    } else {
        # Affiche un message si le fichier WIM source n'existe pas
        Write-Host "Le fichier WIM $nomFichier n'existe pas, passage au suivant..."
    }
}

# Affiche les informations du fichier WIM final pour vérification
DISM /Get-WimInfo /WimFile:$cheminWimFinal
