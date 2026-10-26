<#
.SYNOPSIS
  Vérifie qu'un clone a bien appliqué l'Autounattend.xml du CD (variante 06).

.DESCRIPTION
  Lancé SUR L'HÔTE par Terraform (terraform_data.verification), une fois la VM créée.
  Contrairement à configure-serveur.ps1 de la variante 01, ce script NE CONFIGURE RIEN :
  il attend la fin du 1er démarrage, puis compare le nom et l'IP obtenus à ceux demandés.

  Si la VM ne répond jamais : ouvrir sa console dans le Gestionnaire Hyper-V.
  Un écran « Pays/région, clavier... » signifie que Windows n'a pas trouvé l'Autounattend.xml
  (CD absent, ou image construite AVEC un unattend : voir le README).

  Lancement manuel possible (console PowerShell administrateur, depuis ce dossier) :
    $env:LAB_ADMIN_PASSWORD = 'P@ssw0rd!'
    .\scripts\verifier-serveur.ps1 -VMName L06-SRV01 -ComputerName SRV01 -IPAddress 192.168.106.20
#>
param(
    [Parameter(Mandatory)][string]$VMName,
    [Parameter(Mandatory)][string]$ComputerName,
    [Parameter(Mandatory)][string]$IPAddress,
    [string]$AdminUser = 'Administrateur'
)
$ErrorActionPreference = 'Stop'
# Chemin écrit sans Join-Path : LabHelpers doit être chargé avant tout autre module (voir son en-tête).
Import-Module "$PSScriptRoot\LabHelpers.psm1" -Force

if (-not $env:LAB_ADMIN_PASSWORD) { throw 'Variable d''environnement LAB_ADMIN_PASSWORD absente.' }

# Le mot de passe a été posé par l'Autounattend du CD (passe oobeSystem).
$cred = New-LabCredential -UserName $AdminUser -Password $env:LAB_ADMIN_PASSWORD

# Le 1er démarrage (specialize, redémarrage, oobeSystem) prend quelques minutes.
Wait-LabVM -VMName $VMName -Credential $cred | Out-Null

$etat = Invoke-Command -VMName $VMName -Credential $cred -ScriptBlock {
    $os = Get-CimInstance Win32_OperatingSystem
    [pscustomobject]@{
        Nom     = $env:COMPUTERNAME
        Systeme = "$($os.Caption) (build $($os.BuildNumber))"
        IP      = @(Get-NetIPAddress -AddressFamily IPv4 | Where-Object IPAddress -notlike '127.*').IPAddress
        Route   = (Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue).NextHop
        DNS     = (Get-DnsClientServerAddress -AddressFamily IPv4 |
                   Where-Object ServerAddresses | Select-Object -First 1).ServerAddresses
    }
}

Write-LabEtape "Nom        : $($etat.Nom)"
Write-LabEtape "Système    : $($etat.Systeme)"
Write-LabEtape "Adresse(s) : $($etat.IP -join ', ')"
Write-LabEtape "Passerelle : $($etat.Route -join ', ')"
Write-LabEtape "DNS        : $($etat.DNS -join ', ')"

# Le nom et l'IP doivent venir de l'Autounattend : sinon, inutile d'aller plus loin.
$erreurs = @()
if ($etat.Nom -ne $ComputerName) { $erreurs += "nom $($etat.Nom) au lieu de $ComputerName" }
if ($etat.IP -notcontains $IPAddress) { $erreurs += "IP $($etat.IP -join ', ') au lieu de $IPAddress" }
if ($erreurs) {
    throw "L'Autounattend.xml du CD n'a pas été appliqué correctement : $($erreurs -join ' ; ')."
}

Test-LabInternet -VMName $VMName -Credential $cred

Write-LabEtape "Serveur $ComputerName prêt : nom et IP posés au 1er démarrage par le CD de réponse."
