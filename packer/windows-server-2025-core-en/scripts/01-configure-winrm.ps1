# Exécuté au premier logon par Autounattend.xml : permet à Packer de se connecter en WinRM.
# LAB uniquement : HTTP + Basic non chiffré.
$ErrorActionPreference = 'Stop'

# Les réseaux « publics » bloquent WinRM : on force le profil privé.
Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private

Enable-PSRemoting -Force -SkipNetworkProfileCheck
Set-Item WSMan:\localhost\Service\AllowUnencrypted $true
Set-Item WSMan:\localhost\Service\Auth\Basic $true
Set-Item WSMan:\localhost\MaxTimeoutms 1800000

netsh advfirewall firewall add rule name="WinRM-HTTP-Packer" dir=in action=allow protocol=TCP localport=5985
Set-Service WinRM -StartupType Automatic
Restart-Service WinRM
