# Prépare la tâche planifiée qui lancera sysprep (déclenchée ensuite par le shutdown_command).
# Pourquoi pas `schtasks /create` ? Ses réglages par défaut incluent « Ne pas lancer sur batterie ».
# Or Hyper-V expose la batterie de l'hôte aux VM : sur un PC portable débranché, la tâche reste
# « En file d'attente », sysprep ne démarre jamais et Packer attend l'arrêt indéfiniment.
$ErrorActionPreference = 'Stop'

# Sysprep n'éteint pas la VM lui-même (/quit au lieu de /shutdown) : sur Windows Server (Core comme Desktop), son arrêt « poli »
# (InitiateSystemShutdownEx, sans forcer la fermeture des applications) reste bloqué indéfiniment,
# alors que sysprep a réussi (Sysprep_succeeded.tag). On enchaîne donc avec un arrêt forcé (/f).
# Le « && » garantit qu'on n'éteint QUE si sysprep a réussi : en cas d'échec, la VM reste allumée
# et les journaux restent lisibles (scripts\diag-sysprep-logs.ps1 côté hôte).
$sysprep = "$env:SystemRoot\System32\Sysprep\sysprep.exe /generalize /oobe /quit /quiet /unattend:C:\Windows\Temp\sysprep-unattend.xml"
$action = New-ScheduledTaskAction -Execute "$env:SystemRoot\System32\cmd.exe" `
    -Argument "/c $sysprep && $env:SystemRoot\System32\shutdown.exe /s /t 0 /f"
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
    -ExecutionTimeLimit (New-TimeSpan -Hours 2)
$principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest

Register-ScheduledTask -TaskName PackerSysprep -Action $action -Settings $settings -Principal $principal -Force | Out-Null
Write-Host 'Tâche PackerSysprep enregistrée (autorisée sur batterie, arrêt forcé après sysprep).'
