<#
.SYNOPSIS
  Joint un Server Core neuf au domaine, puis le promeut contrôleur de domaine SUPPLÉMENTAIRE
  du domaine existant (même forêt).

.DESCRIPTION
  Lancé SUR L'HÔTE par Terraform, APRÈS la configuration complète de DC01 (depends_on).
  Étapes :
    1. configuration de base : IP fixe, DNS = DC01, nom DC02 ;
    2. jonction au domaine (le serveur devient « serveur membre ») + redémarrage ;
    3. rôle AD DS + promotion : Install-ADDSDomainController (réplique l'annuaire depuis DC01) ;
    4. redémarrage, attente des services AD ;
    5. DNS croisé : chaque DC interroge d'abord son partenaire, puis lui-même ;
    6. vérification de la réplication.

  Lancement manuel (console PowerShell administrateur, depuis le dossier de la variante) :
    $env:LAB_ADMIN_PASSWORD = 'P@ssw0rd!'
    .\scripts\configure-dc02.ps1 -VMName L03-DC02 -ComputerName DC02 -IPAddress 192.168.103.11 `
        -PartnerVMName L03-DC01 -PartnerIPAddress 192.168.103.10
#>
param(
    [Parameter(Mandatory)][string]$VMName,
    [Parameter(Mandatory)][string]$ComputerName,
    [Parameter(Mandatory)][string]$IPAddress,
    [Parameter(Mandatory)][string]$PartnerVMName,      # VM Hyper-V du premier DC (L03-DC01)
    [Parameter(Mandatory)][string]$PartnerIPAddress,   # son adresse IP (= DNS du domaine)
    [int]$PrefixLength = 24,
    [string]$DomainName = 'lab.local',
    [string]$NetbiosName = 'LAB',
    [string]$AdminUser = 'Administrateur'
)
$ErrorActionPreference = 'Stop'
# Chemin écrit sans Join-Path : LabHelpers doit être chargé avant tout autre module (voir son en-tête).
Import-Module "$PSScriptRoot\LabHelpers.psm1" -Force

if (-not $env:LAB_ADMIN_PASSWORD) { throw 'Variable d''environnement LAB_ADMIN_PASSWORD absente.' }
$motDePasse = $env:LAB_ADMIN_PASSWORD

$credLocal   = New-LabCredential -UserName $AdminUser -Password $motDePasse
$credDomaine = New-LabCredential -UserName "$NetbiosName\$AdminUser" -Password $motDePasse

# Où en est la machine ? (DomainRole : 2 = autonome, 3 = membre, 4/5 = contrôleur de domaine)
$role = 0
if (Get-LabBootTime -VMName $VMName -Credential $credDomaine) {
    $role = Invoke-Command -VMName $VMName -Credential $credDomaine -ScriptBlock { (Get-CimInstance Win32_ComputerSystem).DomainRole }
}

# --- 1 et 2. Configuration de base puis jonction au domaine ---------------------------------
if ($role -lt 3) {
    # Le DNS du serveur DOIT être un DC du domaine : c'est par le DNS (enregistrements SRV)
    # que Windows trouve un contrôleur de domaine pour la jonction.
    Set-LabBaseConfig -VMName $VMName -Credential $credLocal -ComputerName $ComputerName `
        -IPAddress $IPAddress -PrefixLength $PrefixLength -DnsServers $PartnerIPAddress

    # --- DC01 est-il joignable ? Profil réseau ---------------------------------------------
    # Le switch interne n'a pas de passerelle : au démarrage, le service « Connaissance des
    # emplacements réseau » (NlaSvc) de DC01 peut classer la carte en réseau PUBLIC au lieu de
    # DOMAINE, et le pare-feu bloque alors les ports AD. Le redémarrer refait la détection.
    Write-LabEtape "Vérification du profil réseau de DC01..."
    Invoke-Command -VMName $PartnerVMName -Credential $credDomaine -ScriptBlock {
        if (Get-NetConnectionProfile | Where-Object NetworkCategory -ne 'DomainAuthenticated') {
            Restart-Service NlaSvc -Force
            Start-Sleep -Seconds 20
        }
        Get-NetConnectionProfile | ForEach-Object { "$env:COMPUTERNAME : carte « $($_.InterfaceAlias) » en profil $($_.NetworkCategory)" }
    } | ForEach-Object { Write-LabEtape $_ }

    Write-LabEtape "Jonction de $ComputerName au domaine $DomainName..."
    Invoke-Command -VMName $VMName -Credential $credLocal -ArgumentList $DomainName, "$NetbiosName\$AdminUser", $motDePasse, $PartnerIPAddress -ScriptBlock {
        param($domaine, $user, $mdp, $ipDC)
        $ErrorActionPreference = 'Stop'
        $cred = New-Object System.Management.Automation.PSCredential ($user, (ConvertTo-SecureString $mdp -AsPlainText -Force))

        # Juste après la création du domaine, DC01 peut mettre quelques minutes à être
        # pleinement joignable (DNS, Netlogon, pare-feu) : on réessaie pendant 10 minutes.
        $limite = (Get-Date).AddMinutes(10)
        while ($true) {
            try {
                # Sans -OUPath, le compte ordinateur est créé dans le conteneur par défaut « Computers ».
                # Ce n'est pas grave ici : la promotion le déplacera dans l'OU « Domain Controllers ».
                Add-Computer -DomainName $domaine -Credential $cred -Force -WarningAction SilentlyContinue
                "Jonction réussie."
                break
            }
            catch {
                # Diagnostic affiché dans la sortie de Terraform : ce que la jonction utilise réellement.
                "Échec de la jonction : $($_.Exception.Message)"
                $srv = Resolve-DnsName "_ldap._tcp.dc._msdcs.$domaine" -Type SRV -ErrorAction SilentlyContinue
                "  DNS  : enregistrement SRV des DC $(if ($srv) { 'trouvé' } else { 'ABSENT' })"
                # nltest /dsgetdc : la recherche de DC exactement comme la fait Windows (DNS + ping LDAP).
                "  nltest /dsgetdc : " + ((nltest /dsgetdc:$domaine 2>&1 | Select-Object -First 2) -join ' | ')
                foreach ($port in 53, 88, 135, 389, 445) {
                    $ok = (Test-NetConnection $ipDC -Port $port -WarningAction SilentlyContinue).TcpTestSucceeded
                    "  port $port vers $ipDC : $(if ($ok) { 'ouvert' } else { 'FERMÉ' })"
                }
                if ((Get-Date) -gt $limite) { throw "Jonction impossible après 10 minutes : voir le diagnostic ci-dessus." }
                "  Nouvel essai dans 30 s..."
                Start-Sleep -Seconds 30
            }
        }
    } | ForEach-Object { Write-LabEtape $_ }
    # Après la jonction, LAB\Administrateur (membre des Admins du domaine) est administrateur local.
    Restart-LabVM -VMName $VMName -Credential $credLocal -CredentialAfter $credDomaine
    $role = 3
}

# --- 3 et 4. Promotion en contrôleur de domaine supplémentaire --------------------------------
if ($role -lt 4) {
    Write-LabEtape "Installation du rôle AD DS et promotion de $ComputerName (réplication depuis DC01, plusieurs minutes)..."
    Invoke-Command -VMName $VMName -Credential $credDomaine -ArgumentList $DomainName, "$NetbiosName\$AdminUser", $motDePasse -ScriptBlock {
        param($domaine, $user, $mdp)
        $ErrorActionPreference = 'Stop'
        Install-WindowsFeature AD-Domain-Services -IncludeManagementTools | Out-Null

        Import-Module ADDSDeployment
        $secure = ConvertTo-SecureString $mdp -AsPlainText -Force
        $cred   = New-Object System.Management.Automation.PSCredential ($user, $secure)
        # Install-ADDSDomainController : ajoute un DC à un domaine EXISTANT
        # (Install-ADDSForest créait une nouvelle forêt, Install-ADDSDomain un nouveau domaine dans une forêt).
        #   -InstallDns          : DC02 sera aussi serveur DNS (zones intégrées à AD, répliquées).
        #   -NoGlobalCatalog:$false : DC02 est aussi catalogue global (recommandé avec un seul site).
        $r = Install-ADDSDomainController `
            -DomainName $domaine `
            -Credential $cred `
            -SafeModeAdministratorPassword $secure `
            -InstallDns `
            -NoGlobalCatalog:$false `
            -NoRebootOnCompletion `
            -Force `
            -WarningAction SilentlyContinue
        "Résultat de la promotion : $($r.Status) $($r.Message)"
    } | ForEach-Object { Write-LabEtape $_ }

    Restart-LabVM -VMName $VMName -Credential $credDomaine
}
else {
    Write-LabEtape "$VMName est déjà contrôleur de domaine : promotion ignorée."
}

Wait-LabADReady -VMName $VMName -Credential $credDomaine

# --- 5. DNS croisé ------------------------------------------------------------------------------
# Bonne pratique avec deux DC : DNS préféré = l'AUTRE DC, DNS auxiliaire = soi-même (127.0.0.1).
# Si un DC redémarre seul, il trouve tout de suite son partenaire ; s'il est seul, il se trouve lui-même.
Write-LabEtape 'DNS croisé entre les deux contrôleurs de domaine'
$dnsCroise = @(
    @{ VM = $VMName;        Dns = @($PartnerIPAddress, '127.0.0.1') }
    @{ VM = $PartnerVMName; Dns = @($IPAddress, '127.0.0.1') }
)
foreach ($d in $dnsCroise) {
    Invoke-Command -VMName $d.VM -Credential $credDomaine -ArgumentList (, $d.Dns) -ScriptBlock {
        param($dns)
        $nic = Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1
        Set-DnsClientServerAddress -InterfaceIndex $nic.ifIndex -ServerAddresses $dns
        "$env:COMPUTERNAME : DNS = $($dns -join ', ')"
    } | ForEach-Object { Write-LabEtape $_ }
}

# --- 6. Vérification --------------------------------------------------------------------------
Write-LabEtape 'Réplication et liste des contrôleurs de domaine'
Invoke-Command -VMName $VMName -Credential $credDomaine -ScriptBlock {
    # On demande une réplication immédiate de toutes les partitions, dans les deux sens.
    # (/A toutes les partitions, /e tous les sites, /d noms complets, /P réplication « poussée »)
    repadmin /syncall /AdeP | Out-Null
    Get-ADDomainController -Filter * -Server localhost | ForEach-Object { "DC : $($_.HostName)  GC=$($_.IsGlobalCatalog)  site=$($_.Site)" }
    # Preuve que l'annuaire a été répliqué : les OU de tiering créées sur DC01 sont visibles ici.
    $ou = @(Get-ADOrganizationalUnit -Filter "Name -like 'Tier *'" -Server localhost).Count
    "OU 'Tier *' visibles sur $env:COMPUTERNAME : $ou"
    repadmin /replsummary
} | ForEach-Object { Write-LabEtape $_ }

Write-LabEtape "Contrôleur de domaine supplémentaire $ComputerName prêt."
