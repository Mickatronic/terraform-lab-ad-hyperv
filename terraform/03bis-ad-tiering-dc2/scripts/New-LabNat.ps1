<#
.SYNOPSIS
  Donne Internet aux VMs du switch interne : IP de passerelle sur l'hôte + NAT Windows.

.DESCRIPTION
  Exécuté SUR L'HÔTE par Terraform (terraform_data.nat), juste après la création du switch.

  Un switch INTERNE relie les VMs à l'hôte, mais pas au réseau physique. Pour sortir :
    1. l'hôte reçoit une adresse sur sa carte « vEthernet (<switch>) » : ce sera la
       PASSERELLE des VMs (ex. 192.168.101.1) ;
    2. une règle NAT (New-NetNat) traduit les adresses des VMs vers l'adresse de l'hôte,
       exactement comme une box Internet le fait pour les machines de la maison.

  Windows 10/11 n'accepte en pratique qu'UNE règle NAT. On en crée donc une seule, large,
  « LAB-NAT » sur 192.168.96.0/19 (de 192.168.96.0 à 192.168.127.255), qui couvre les
  sous-réseaux de toutes les variantes (192.168.100 à 104). Elle est partagée : la détruire
  avec une variante couperait Internet aux autres, donc on la laisse en place.

  Lancement manuel (console administrateur) :
    .\scripts\New-LabNat.ps1 -SwitchName L01-Internal -GatewayIP 192.168.101.1
#>
param(
    [Parameter(Mandatory)][string]$SwitchName,
    [Parameter(Mandatory)][string]$GatewayIP,
    [int]$PrefixLength = 24,
    [string]$NatName = 'LAB-NAT',
    [string]$NatPrefix = '192.168.96.0/19'
)
$ErrorActionPreference = 'Stop'
# Chemin écrit sans Join-Path : LabHelpers doit être chargé avant tout autre module (voir son en-tête).
Import-Module "$PSScriptRoot\LabHelpers.psm1" -Force

# 1. Adresse de passerelle sur la carte virtuelle de l'hôte.
$carte = Get-NetAdapter -Name "vEthernet ($SwitchName)"
if (-not (Get-NetIPAddress -InterfaceIndex $carte.ifIndex -IPAddress $GatewayIP -ErrorAction SilentlyContinue)) {
    New-NetIPAddress -InterfaceIndex $carte.ifIndex -IPAddress $GatewayIP -PrefixLength $PrefixLength | Out-Null
    Write-LabEtape "Hôte : $GatewayIP/$PrefixLength sur « vEthernet ($SwitchName) »"
}
else {
    Write-LabEtape "Hôte : $GatewayIP déjà présente sur « vEthernet ($SwitchName) »"
}

# 2. La règle NAT.
$nat = Get-NetNat -ErrorAction SilentlyContinue | Where-Object InternalIPInterfaceAddressPrefix -eq $NatPrefix
if (-not $nat) {
    $autres = @(Get-NetNat -ErrorAction SilentlyContinue)
    if ($autres) {
        Write-LabEtape "ATTENTION : NAT déjà présent(s) : $($autres.Name -join ', '). Si la création échoue, voir le README."
    }
    New-NetNat -Name $NatName -InternalIPInterfaceAddressPrefix $NatPrefix | Out-Null
    Write-LabEtape "Hôte : NAT $NatName créé pour $NatPrefix"
}
else {
    Write-LabEtape "Hôte : NAT $($nat.Name) déjà présent pour $NatPrefix"
}
