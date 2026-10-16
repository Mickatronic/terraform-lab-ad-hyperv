# Exécuté par Packer dans la VM, via WinRM.
$ErrorActionPreference = 'Stop'

Write-Host '== Désactivation de l''écran Gestionnaire de serveur au démarrage =='
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\ServerManager' -Name DoNotOpenServerManagerAtLogon -PropertyType DWord -Value 1 -Force | Out-Null

Write-Host '== Activation du Bureau à distance (RDP) =='
Set-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Value 0
Enable-NetFirewallRule -DisplayGroup 'Bureau à distance' -ErrorAction SilentlyContinue
Enable-NetFirewallRule -DisplayGroup 'Remote Desktop' -ErrorAction SilentlyContinue

Write-Host '== Autoriser le ping =='
Enable-NetFirewallRule -Name 'FPS-ICMP4-ERQ-In' -ErrorAction SilentlyContinue

Write-Host '== Mots de passe qui n''expirent pas (LAB) =='
# Le compte s'appelle « Administrateur » en français : on le retrouve par son SID (se termine par -500).
Get-LocalUser | Where-Object { $_.SID.Value -like '*-500' } | Set-LocalUser -PasswordNeverExpires $true

# Windows Update : décommenter pour un build complet (long : 30 min et plus)
# Install-Module PSWindowsUpdate -Force -Confirm:$false
# Install-WindowsUpdate -AcceptAll -IgnoreReboot

Write-Host 'Terminé.'
