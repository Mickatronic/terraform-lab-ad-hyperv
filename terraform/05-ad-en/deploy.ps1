#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Déploie (ou détruit avec -Destroy) la variante du LAB contenue dans CE dossier.

.DESCRIPTION
  Console PowerShell lancée EN ADMINISTRATEUR : obligatoire pour PowerShell Direct
  (Invoke-Command -VMName), utilisé par les scripts de configuration des VMs.
    .\deploy.ps1            # init, validate, plan, puis apply après confirmation
    .\deploy.ps1 -Destroy   # supprime les VMs, les disques et le switch de cette variante
#>
param([switch]$Destroy)
$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
    if (-not (Test-Path .\terraform.tfvars)) {
        throw 'terraform.tfvars absent : copiez terraform.tfvars.example en terraform.tfvars et complétez-le.'
    }
    terraform init -input=false
    if ($LASTEXITCODE) { throw 'terraform init a échoué.' }

    if ($Destroy) {
        terraform destroy -parallelism=1
        return
    }

    terraform validate
    if ($LASTEXITCODE) { throw 'terraform validate a échoué.' }
    # parallelism=1 : une seule opération Hyper-V à la fois (évite les copies de VHDX simultanées).
    terraform plan -parallelism=1 -out tfplan
    if ($LASTEXITCODE) { throw 'terraform plan a échoué.' }
    $r = Read-Host 'Appliquer ce plan ? (o/N)'
    if ($r -eq 'o') { terraform apply -parallelism=1 tfplan }
}
finally { Pop-Location }
