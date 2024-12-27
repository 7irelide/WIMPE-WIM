@echo off

:: Exécute le script PowerShell avec la politique d'exécution ByPass
powershell.exe -ExecutionPolicy Bypass -File "%~dp0WIMOK2.ps1"

:: Affiche un message invitant l'utilisateur à appuyer sur une touche pour continuer
pause