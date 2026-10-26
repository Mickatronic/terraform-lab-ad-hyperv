# Prépare la tâche planifiée qui lancera sysprep (déclenchée ensuite par le shutdown_command).
# Pourquoi pas `schtasks /create` ? Ses réglages par défaut incluent « Ne pas lancer sur batterie ».
# Or Hyper-V expose la batterie de l'hôte aux VM : sur un PC portable débranché, la tâche reste
# « En file d'attente », sysprep ne démarre jamais et Packer attend l'arrêt indéfiniment.
$ErrorActionPreference = 'Stop'

# VARIANTE SANS UNATTEND : différences avec ../windows-server-2025-core
#
# 1. sysprep est lancé SANS /unattend. Au 1er démarrage d'un clone, Windows cherche donc un fichier
#    de réponse ailleurs, entre autres à la racine des CD/DVD (Autounattend.xml) : c'est Terraform qui
#    le fournit, avec le nom et l'IP propres à chaque VM.
#
# 2. On efface d'abord l'unattend mis en cache par l'INSTALLATION. Windows Setup a copié notre
#    Autounattend.xml dans C:\Windows\Panther\unattend.xml. Ce dossier est lu AVANT les CD/DVD :
#    s'il restait, le clone rejouerait les réglages de l'installation (AutoLogon, recherche de
#    01-configure-winrm.ps1...) et ignorerait le fichier fourni par Terraform.
#
# Le reste est identique : arrêt forcé (/f) seulement si sysprep a créé Sysprep_succeeded.tag.
$panther = "$env:SystemRoot\Panther"
$nettoyage = "del /f /q $panther\unattend.xml $panther\Unattend\unattend.xml 2>nul"
$sysprep = "$env:SystemRoot\System32\Sysprep\sysprep.exe /generalize /oobe /quit /quiet"
$action = New-ScheduledTaskAction -Execute "$env:SystemRoot\System32\cmd.exe" `
    -Argument "/c $nettoyage & $sysprep & if exist $env:SystemRoot\System32\Sysprep\Sysprep_succeeded.tag $env:SystemRoot\System32\shutdown.exe /s /t 0 /f"
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
    -ExecutionTimeLimit (New-TimeSpan -Hours 2)
$principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest

Register-ScheduledTask -TaskName PackerSysprep -Action $action -Settings $settings -Principal $principal -Force | Out-Null
Write-Host 'Tâche PackerSysprep enregistrée (sans /unattend, cache Panther effacé, arrêt forcé après sysprep).'
