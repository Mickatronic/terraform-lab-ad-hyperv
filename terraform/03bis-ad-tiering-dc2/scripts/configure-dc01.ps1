<#
.SYNOPSIS
  Transforme un Server Core neuf en premier contrôleur de domaine d'une NOUVELLE forêt,
  puis crée l'arborescence d'OU du modèle de tiering.

.DESCRIPTION
  Lancé SUR L'HÔTE par Terraform (terraform_data + local-exec). Étapes :
    1. configuration de base : IP fixe, DNS = soi-même, nom DC01 (LabHelpers.psm1) ;
    2. installation du rôle AD DS (le rôle DNS est ajouté par la promotion) ;
    3. promotion : Install-ADDSForest crée la forêt et le domaine ;
    4. redémarrage, puis attente des services AD ;
    5. alimentation de l'annuaire : New-LabTiering.ps1 + tiering-comptes.csv.

  Chaque étape vérifie d'abord si elle est déjà faite : le script peut être relancé.

  Lancement manuel (console PowerShell administrateur, depuis le dossier de la variante) :
    $env:LAB_ADMIN_PASSWORD = 'P@ssw0rd!'
    .\scripts\configure-dc01.ps1 -VMName L02-DC01 -ComputerName DC01 -IPAddress 192.168.102.10
#>
param(
    [Parameter(Mandatory)][string]$VMName,
    [Parameter(Mandatory)][string]$ComputerName,
    [Parameter(Mandatory)][string]$IPAddress,
    [int]$PrefixLength = 24,
    [string]$DomainName = 'lab.local',
    [string]$NetbiosName = 'LAB',
    [string]$AdminUser = 'Administrateur',
    [string]$Gateway = '',                 # IP de l'hôte sur le switch (accès Internet par NAT)
    [string[]]$DnsForwarders = @(),        # DNS publics vers lesquels le DC redirige les noms Internet
    [switch]$SkipTiering
)
$ErrorActionPreference = 'Stop'
# Chemin écrit sans Join-Path : LabHelpers doit être chargé avant tout autre module (voir son en-tête).
Import-Module "$PSScriptRoot\LabHelpers.psm1" -Force

if (-not $env:LAB_ADMIN_PASSWORD) { throw 'Variable d''environnement LAB_ADMIN_PASSWORD absente.' }
$motDePasse = $env:LAB_ADMIN_PASSWORD

# Deux identités pour la même personne :
#  - AVANT la promotion : le compte LOCAL « Administrateur » de l'image ;
#  - APRÈS la promotion : ce compte devient l'administrateur du DOMAINE (LAB\Administrateur),
#    avec le même mot de passe. Les comptes locaux n'existent pas sur un contrôleur de domaine.
$credLocal   = New-LabCredential -UserName $AdminUser -Password $motDePasse
$credDomaine = New-LabCredential -UserName "$NetbiosName\$AdminUser" -Password $motDePasse

# --- Est-ce déjà un contrôleur de domaine ? ------------------------------------------
# DomainRole (Win32_ComputerSystem) : 0-1 = poste, 2 = serveur autonome, 3 = serveur membre,
# 4 = contrôleur de domaine secondaire, 5 = contrôleur de domaine principal (émulateur PDC).
$dejaDC = $false
if (Get-LabBootTime -VMName $VMName -Credential $credDomaine) {
    $role = Invoke-Command -VMName $VMName -Credential $credDomaine -ScriptBlock { (Get-CimInstance Win32_ComputerSystem).DomainRole }
    $dejaDC = ($role -ge 4)
}

if (-not $dejaDC) {
    # --- 1. Configuration de base -------------------------------------------------------
    # Un DC est son propre serveur DNS : on pointe donc le DNS sur 127.0.0.1.
    Set-LabBaseConfig -VMName $VMName -Credential $credLocal -ComputerName $ComputerName `
        -IPAddress $IPAddress -PrefixLength $PrefixLength -Gateway $Gateway -DnsServers '127.0.0.1'

    # --- 2 et 3. Rôle AD DS puis création de la forêt -------------------------------------
    Write-LabEtape "Installation du rôle AD DS et création de la forêt $DomainName (plusieurs minutes)..."
    Invoke-Command -VMName $VMName -Credential $credLocal -ArgumentList $DomainName, $NetbiosName, $motDePasse -ScriptBlock {
        param($domaine, $netbios, $mdp)
        $ErrorActionPreference = 'Stop'

        # -IncludeManagementTools ajoute le module PowerShell ActiveDirectory (pas de console graphique en Core).
        Install-WindowsFeature AD-Domain-Services -IncludeManagementTools | Out-Null

        Import-Module ADDSDeployment
        # Le mot de passe DSRM (mode restauration des services d'annuaire) sert à démarrer le DC
        # « hors AD » pour une restauration. Dans le LAB, on prend le même que l'administrateur.
        $dsrm = ConvertTo-SecureString $mdp -AsPlainText -Force
        $r = Install-ADDSForest `
            -DomainName $domaine `
            -DomainNetbiosName $netbios `
            -SafeModeAdministratorPassword $dsrm `
            -InstallDns `
            -NoRebootOnCompletion `
            -Force `
            -WarningAction SilentlyContinue
        # -NoRebootOnCompletion : on redémarre nous-mêmes, pour garder la main et attendre proprement.
        "Résultat de la promotion : $($r.Status) $($r.Message)"
    } | ForEach-Object { Write-LabEtape $_ }

    # --- 4. Redémarrage : après, on se connecte avec le compte du DOMAINE ---------------------
    Restart-LabVM -VMName $VMName -Credential $credLocal -CredentialAfter $credDomaine
}
else {
    Write-LabEtape "$VMName est déjà contrôleur de domaine : configuration de base et promotion ignorées."
}

Wait-LabADReady -VMName $VMName -Credential $credDomaine

# --- Accès Internet (refait à chaque passage : idempotent, et utile pour un DC déjà promu) ----
if ($Gateway)       { Set-LabGateway -VMName $VMName -Credential $credDomaine -Gateway $Gateway }
if ($DnsForwarders) { Set-LabDnsForwarder -VMName $VMName -Credential $credDomaine -Forwarders $DnsForwarders }

# --- 5. Modèle de tiering -----------------------------------------------------------------
if (-not $SkipTiering) {
    # Le CSV est lu ICI, sur l'hôte, et ses lignes sont envoyées au script qui tourne dans la VM :
    # pas besoin de copier de fichier dans la VM.
    $comptes = Import-Csv -Path (Join-Path $PSScriptRoot 'tiering-comptes.csv') -Delimiter ';' -Encoding UTF8
    Write-LabEtape "Création du modèle de tiering ($($comptes.Count) comptes à vérifier)..."
    Invoke-Command -VMName $VMName -Credential $credDomaine `
        -FilePath (Join-Path $PSScriptRoot 'New-LabTiering.ps1') `
        -ArgumentList $comptes, $motDePasse |
        ForEach-Object { Write-LabEtape $_ }
}

if ($Gateway) { Test-LabInternet -VMName $VMName -Credential $credDomaine }

Write-LabEtape "Contrôleur de domaine $ComputerName ($DomainName) prêt."
