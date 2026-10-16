#Requires -RunAsAdministrator
<#
.SYNOPSIS
  À exécuter DANS SRV01 : IP fixe, DNS = DC01, jonction au domaine.
#>
param(
    [string]$DomainName = 'lab.local',
    [string]$IpAddress = '192.168.100.11',
    [string]$DnsServer = '192.168.100.10',
    [int]$PrefixLength = 24,
    [pscredential]$DomainCredential = (Get-Credential -Message 'Compte admin du domaine (LAB\Administrator)')
)
$ErrorActionPreference = 'Stop'

$nic = Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1
New-NetIPAddress -InterfaceIndex $nic.ifIndex -IPAddress $IpAddress -PrefixLength $PrefixLength -ErrorAction SilentlyContinue
Set-DnsClientServerAddress -InterfaceIndex $nic.ifIndex -ServerAddresses $DnsServer

Add-Computer -DomainName $DomainName -Credential $DomainCredential -Restart -Force
