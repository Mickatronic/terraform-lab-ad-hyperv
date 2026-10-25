# Exécuté par Packer dans la VM, via WinRM.
# Version Desktop Experience (interface graphique) : on désactive l'ouverture automatique du
# Gestionnaire de serveur et on prépare aussi l'administration À DISTANCE (MMC, Gestionnaire de serveur de l'hôte).
$ErrorActionPreference = 'Stop'

Write-Host '== Vérification : installation Desktop Experience =='
$type = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').InstallationType
Write-Host "InstallationType = $type"
# 'Server' = avec interface graphique, 'Server Core' = sans.
if ($type -ne 'Server') { throw "Attendu 'Server' (Desktop Experience), obtenu '$type' : vérifiez /IMAGE/INDEX dans Autounattend.xml" }

Write-Host '== Gestionnaire de serveur : pas d''ouverture automatique =='
Get-ScheduledTask -TaskName ServerManager -ErrorAction SilentlyContinue | Disable-ScheduledTask | Out-Null
Set-ItemProperty 'HKLM:\SOFTWARE\Microsoft\ServerManager' -Name DoNotOpenServerManagerAtLogon -Value 1

Write-Host '== Activation du Bureau à distance (RDP) =='
# RDP ouvre le bureau Windows complet.
Set-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Value 0
Enable-NetFirewallRule -DisplayGroup 'Bureau à distance' -ErrorAction SilentlyContinue
Enable-NetFirewallRule -DisplayGroup 'Remote Desktop' -ErrorAction SilentlyContinue

Write-Host '== Autoriser le ping =='
Enable-NetFirewallRule -Name 'FPS-ICMP4-ERQ-In' -ErrorAction SilentlyContinue

Write-Host '== Administration à distance (MMC / Gestionnaire de serveur depuis un autre poste) =='
# Observateur d'événements, Gestion de l'ordinateur, Services, disques... ouverts depuis l'hôte.
Enable-NetFirewallRule -Name 'RemoteEventLogSvc-In-TCP', 'RemoteEventLogSvc-NP-In-TCP', 'RemoteEventLogSvc-RPCSS-In-TCP' -ErrorAction SilentlyContinue
Enable-NetFirewallRule -Name 'RemoteSvcAdmin-In-TCP', 'RemoteSvcAdmin-NP-In-TCP', 'RemoteSvcAdmin-RPCSS-In-TCP' -ErrorAction SilentlyContinue
Enable-NetFirewallRule -Name 'RVM-VDS-In-TCP', 'RVM-VDSLDR-In-TCP', 'RVM-RPCSS-In-TCP' -ErrorAction SilentlyContinue
Enable-NetFirewallRule -Name 'WMI-WINMGMT-In-TCP', 'WMI-RPCSS-In-TCP' -ErrorAction SilentlyContinue

Write-Host '== Mots de passe qui n''expirent pas (LAB) =='
# Le compte s'appelle « Administrator » ici, « Administrateur » en français : on le retrouve par son SID (-500).
Get-LocalUser | Where-Object { $_.SID.Value -like '*-500' } | Set-LocalUser -PasswordNeverExpires $true

# Windows Update : décommenter pour un build complet (long : 30 min et plus)
# Install-Module PSWindowsUpdate -Force -Confirm:$false
# Install-WindowsUpdate -AcceptAll -IgnoreReboot

Write-Host 'Terminé.'
