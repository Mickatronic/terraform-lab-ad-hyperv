#Requires -RunAsAdministrator
<#
.SYNOPSIS
  À exécuter DANS DC01 : IP fixe, AD DS + DNS, création du domaine lab.local.
#>
param(
    [string]$DomainName = 'lab.local',
    [string]$NetbiosName = 'LAB',
    [string]$IpAddress = '192.168.100.10',
    [int]$PrefixLength = 24,
    [securestring]$SafeModePassword = (ConvertTo-SecureString 'P@ssw0rd!' -AsPlainText -Force)
)
$ErrorActionPreference = 'Stop'

# 1. Réseau : IP fixe, DNS = soi-même
$nic = Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1
New-NetIPAddress -InterfaceIndex $nic.ifIndex -IPAddress $IpAddress -PrefixLength $PrefixLength -ErrorAction SilentlyContinue
Set-DnsClientServerAddress -InterfaceIndex $nic.ifIndex -ServerAddresses '127.0.0.1'

# 2. Rôles
Install-WindowsFeature AD-Domain-Services, DNS -IncludeManagementTools

# 3. Promotion (la VM redémarre toute seule)
Import-Module ADDSDeployment
Install-ADDSForest `
    -DomainName $DomainName `
    -DomainNetbiosName $NetbiosName `
    -SafeModeAdministratorPassword $SafeModePassword `
    -InstallDns `
    -Force
