# Exécuté par Packer dans la VM, via WinRM.
# Version Server Core : pas de Gestionnaire de serveur local à désactiver (il n'existe pas sur Core),
# on prépare plutôt la machine à être administrée À DISTANCE (RSAT, Gestionnaire de serveur de l'hôte, WAC).
$ErrorActionPreference = 'Stop'

Write-Host '== Vérification : installation Server Core =='
$type = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').InstallationType
Write-Host "InstallationType = $type"
if ($type -ne 'Server Core') { throw "Attendu 'Server Core', obtenu '$type' : vérifiez le nom d'image dans Autounattend.xml" }

Write-Host '== Activation du Bureau à distance (RDP) =='
# Sur Core, RDP ouvre une session avec sconfig / PowerShell : pratique pour dépanner.
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
# Le compte s'appelle « Administrateur » en français : on le retrouve par son SID (se termine par -500).
Get-LocalUser | Where-Object { $_.SID.Value -like '*-500' } | Set-LocalUser -PasswordNeverExpires $true

# Optionnel : ouvrir PowerShell au lieu de sconfig à l'ouverture de session (Core lance sconfig par défaut).
# Set-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name Shell -Value 'powershell.exe -NoExit'

# Windows Update : décommenter pour un build complet (long : 30 min et plus)
# Install-Module PSWindowsUpdate -Force -Confirm:$false
# Install-WindowsUpdate -AcceptAll -IgnoreReboot

Write-Host 'Terminé.'
