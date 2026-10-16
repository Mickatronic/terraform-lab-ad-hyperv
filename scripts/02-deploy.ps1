#Requires -RunAsAdministrator
$ErrorActionPreference = 'Stop'
$dir = Join-Path $PSScriptRoot '..\terraform' | Resolve-Path
Push-Location $dir
try {
    terraform init
    terraform validate
    # parallelism=1 : une seule opération Hyper-V à la fois (évite les copies de VHDX simultanées)
    terraform plan -parallelism=1 -out tfplan
    $r = Read-Host 'Appliquer ce plan ? (o/N)'
    if ($r -eq 'o') { terraform apply -parallelism=1 tfplan }
}
finally { Pop-Location }
