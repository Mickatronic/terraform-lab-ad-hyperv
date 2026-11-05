<#
.SYNOPSIS
  Crée l'arborescence d'OU du modèle de tiering et l'alimente (groupes, comptes, ordinateurs).

.DESCRIPTION
  Ce script s'exécute DANS le contrôleur de domaine.
  - Lancé par configure-dc01.ps1 (depuis l'hôte, via Invoke-Command -FilePath) : les comptes
    lui sont passés en paramètre (-Comptes), lus depuis tiering-comptes.csv.
  - Lancé à la main sur le DC : .\New-LabTiering.ps1 -CsvPath .\tiering-comptes.csv -MotDePasse 'P@ssw0rd!'

  LE MODÈLE DE TIERING (modèle d'administration en niveaux de Microsoft)
  -----------------------------------------------------------------------
  On range les ressources selon ce qu'un attaquant gagnerait à les compromettre :
    Tier 0 : ce qui contrôle l'identité de tout le SI (contrôleurs de domaine, AD, PKI...).
    Tier 1 : les serveurs et applications de l'entreprise (fichiers, SQL, web...).
    Tier 2 : les postes de travail et les utilisateurs.
  Règle d'or : un compte d'un tier ne se connecte JAMAIS sur une machine d'un tier inférieur
  (un admin Tier 0 ne tape pas son mot de passe sur un poste Tier 2 qui pourrait être compromis).
  Conséquence : une personne qui administre plusieurs tiers a UN COMPTE PAR TIER
  (ex. t0-amartin, t1-amartin), d'où plusieurs lignes pour la même personne dans le CSV.

  Arborescence créée (à la racine du domaine) :
    Tier 0 / Comptes admin | Groupes | Serveurs           | Comptes de service
    Tier 1 / Comptes admin | Groupes | Serveurs           | Comptes de service
    Tier 2 / Comptes admin | Groupes | Postes de travail  | Comptes de service | Utilisateurs

  Le script est IDEMPOTENT : il ne crée que ce qui n'existe pas encore. On peut donc ajouter
  des lignes au CSV et le relancer.
#>
param(
    [object[]]$Comptes,
    [Parameter(Mandatory)][string]$MotDePasse,
    [string]$CsvPath
)
$ErrorActionPreference = 'Stop'

# Juste après la promotion, le DC répond déjà en local, mais il n'est pas encore « trouvable »
# par le localisateur de DC (enregistrements DNS en cours, service Netlogon qui démarre).
# Sans -Server, une cmdlet AD cherche un DC via ce localisateur et peut échouer avec
# « Impossible de trouver un serveur par défaut avec les services Web Active Directory ».
# On dit donc à TOUTES les cmdlets *-AD* de ce script d'interroger le DC local :
$PSDefaultParameterValues['*-AD*:Server'] = $env:COMPUTERNAME
# Pas de lecteur « AD: » automatique (il cherche lui aussi un DC par défaut et affiche un avertissement).
$env:ADPS_LoadDefaultDrive = 0
Import-Module ActiveDirectory

if ($CsvPath) { $Comptes = Import-Csv -Path $CsvPath -Delimiter ';' -Encoding UTF8 }
if (-not $Comptes) { throw 'Aucun compte fourni (paramètre -Comptes ou -CsvPath).' }

$domaine  = Get-ADDomain
$racineDN = $domaine.DistinguishedName      # ex. DC=lab,DC=local
$suffixe  = $domaine.DNSRoot                # ex. lab.local
$mdp      = ConvertTo-SecureString $MotDePasse -AsPlainText -Force

# -----------------------------------------------------------------------------------------
# 1. Description de l'arborescence : un tier -> ses sous-OU.
#    (Modifier ici pour faire évoluer le modèle.)
# -----------------------------------------------------------------------------------------
$arborescence = [ordered]@{
    'Tier 0' = 'Comptes admin', 'Groupes', 'Serveurs', 'Comptes de service'
    'Tier 1' = 'Comptes admin', 'Groupes', 'Serveurs', 'Comptes de service'
    'Tier 2' = 'Comptes admin', 'Groupes', 'Postes de travail', 'Comptes de service', 'Utilisateurs'
}

# Colonne « Type » du CSV -> sous-OU de destination.
$ouParType = @{
    'Admin'       = 'Comptes admin'
    'Service'     = 'Comptes de service'
    'Utilisateur' = 'Utilisateurs'
}

# Groupes globaux de sécurité, un jeu par tier. Convention de nommage : GG_<tier>_<rôle>.
$groupes = @(
    @{ Nom = 'GG_T0_Admins';          Tier = 'Tier 0'; Description = 'Administrateurs Tier 0 (AD, contrôleurs de domaine)' }
    @{ Nom = 'GG_T1_Admins_Serveurs'; Tier = 'Tier 1'; Description = 'Administrateurs des serveurs Tier 1' }
    @{ Nom = 'GG_T2_Admins_Postes';   Tier = 'Tier 2'; Description = 'Administrateurs des postes de travail' }
    @{ Nom = 'GG_T2_Support';         Tier = 'Tier 2'; Description = 'Support de proximité (helpdesk)' }
    @{ Nom = 'GG_T2_Utilisateurs';    Tier = 'Tier 2'; Description = 'Utilisateurs standard du LAB' }
)

# Comptes d'ordinateurs « pré-créés » pour montrer où ranger serveurs et postes.
# (Les contrôleurs de domaine, eux, restent dans l'OU par défaut « Domain Controllers » : ils sont Tier 0.)
$ordinateurs = @(
    @{ Nom = 'SRV-PKI01'; Tier = 'Tier 0'; OU = 'Serveurs';          Description = 'Autorité de certification (Tier 0)' }
    @{ Nom = 'SRV-FIC01'; Tier = 'Tier 1'; OU = 'Serveurs';          Description = 'Serveur de fichiers' }
    @{ Nom = 'SRV-SQL01'; Tier = 'Tier 1'; OU = 'Serveurs';          Description = 'Serveur SQL' }
    @{ Nom = 'PC-001';    Tier = 'Tier 2'; OU = 'Postes de travail'; Description = 'Poste utilisateur' }
    @{ Nom = 'PC-002';    Tier = 'Tier 2'; OU = 'Postes de travail'; Description = 'Poste utilisateur' }
)

# -----------------------------------------------------------------------------------------
# Fonctions utilitaires
# -----------------------------------------------------------------------------------------
function Get-DNTier([string]$tier, [string]$sousOU) {
    # Construit le DistinguishedName d'une OU, ex. OU=Groupes,OU=Tier 1,DC=lab,DC=local
    if ($sousOU) { "OU=$sousOU,OU=$tier,$racineDN" } else { "OU=$tier,$racineDN" }
}

function New-OUSiAbsente([string]$nom, [string]$parentDN) {
    $dn = "OU=$nom,$parentDN"
    # -Filter plutôt que -Identity : pas d'exception quand l'objet n'existe pas.
    if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$dn'")) {
        # ProtectedFromAccidentalDeletion : l'OU ne peut pas être supprimée par erreur
        # (il faut d'abord décocher la protection). C'est le comportement par défaut, on l'écrit pour le montrer.
        New-ADOrganizationalUnit -Name $nom -Path $parentDN -ProtectedFromAccidentalDeletion $true
        "  + OU      $dn"
    }
}

# -----------------------------------------------------------------------------------------
# 2. Les OU
# -----------------------------------------------------------------------------------------
"Unités d'organisation :"
foreach ($tier in $arborescence.Keys) {
    New-OUSiAbsente $tier $racineDN
    foreach ($sous in $arborescence[$tier]) { New-OUSiAbsente $sous (Get-DNTier $tier) }
}

# -----------------------------------------------------------------------------------------
# 3. Les groupes
# -----------------------------------------------------------------------------------------
"Groupes :"
foreach ($g in $groupes) {
    if (-not (Get-ADGroup -Filter "SamAccountName -eq '$($g.Nom)'")) {
        New-ADGroup -Name $g.Nom -SamAccountName $g.Nom -GroupScope Global -GroupCategory Security `
            -Path (Get-DNTier $g.Tier 'Groupes') -Description $g.Description
        "  + groupe  $($g.Nom)"
    }
}

# Les groupes intégrés ont des noms TRADUITS (« Admins du domaine » sur un Windows français,
# « Domain Admins » en anglais). On les retrouve donc par leur SID, qui lui ne change jamais :
#   <SID du domaine>-512 = Admins du domaine
#   <SID du domaine>-525 = Protected Users (protections renforcées : pas de NTLM, pas de délégation,
#                          tickets Kerberos courts... recommandé pour les comptes Tier 0)
$sid = $domaine.DomainSID.Value
$adminsDuDomaine = Get-ADGroup -Identity "$sid-512"
$protectedUsers  = Get-ADGroup -Identity "$sid-525"

# Le groupe Tier 0 devient membre des Admins du domaine : on donne les droits à un GROUPE, pas à des personnes.
if (-not (Get-ADGroupMember $adminsDuDomaine | Where-Object SamAccountName -eq 'GG_T0_Admins')) {
    Add-ADGroupMember -Identity $adminsDuDomaine -Members 'GG_T0_Admins'
    "  + GG_T0_Admins membre de « $($adminsDuDomaine.Name) »"
}

# -----------------------------------------------------------------------------------------
# 4. Les comptes (depuis le CSV)
# -----------------------------------------------------------------------------------------
"Comptes :"
foreach ($c in $Comptes) {
    $tier  = "Tier $($c.Tier)"
    $ou    = Get-DNTier $tier $ouParType[$c.Type]
    $login = $c.Login

    if (-not (Get-ADUser -Filter "SamAccountName -eq '$login'")) {
        # Nom affiché : « Prénom Nom (T1) » pour une personne, le login pour un compte de service.
        if ($c.Prenom) { $nom = "$($c.Prenom) $($c.Nom)"; if ($c.Type -eq 'Admin') { $nom += " (T$($c.Tier))" } }
        else           { $nom = $login }

        $p = @{
            Name                  = $nom
            DisplayName           = $nom
            SamAccountName        = $login
            UserPrincipalName     = "$login@$suffixe"
            Path                  = $ou
            Description           = $c.Description
            AccountPassword       = $mdp
            Enabled               = $true
            ChangePasswordAtLogon = $false    # LAB : en production, $true pour les utilisateurs.
        }
        if ($c.Prenom) { $p.GivenName = $c.Prenom; $p.Surname = $c.Nom }
        # Compte de service : mot de passe qui n'expire pas (sinon l'application tombe en panne).
        # En production, on préférerait un gMSA (compte de service géré, mot de passe changé automatiquement).
        if ($c.Type -eq 'Service') { $p.PasswordNeverExpires = $true }

        New-ADUser @p
        "  + compte  $login -> $ou"
    }

    if ($c.Groupe) {
        if (-not (Get-ADGroupMember $c.Groupe | Where-Object SamAccountName -eq $login)) {
            Add-ADGroupMember -Identity $c.Groupe -Members $login
            "  + $login membre de $($c.Groupe)"
        }
    }
    # Comptes administrateurs Tier 0 : dans Protected Users.
    if ($c.Tier -eq '0' -and $c.Type -eq 'Admin') {
        if (-not (Get-ADGroupMember $protectedUsers | Where-Object SamAccountName -eq $login)) {
            Add-ADGroupMember -Identity $protectedUsers -Members $login
            "  + $login membre de Protected Users"
        }
    }
}

# -----------------------------------------------------------------------------------------
# 5. Les comptes d'ordinateurs pré-créés
# -----------------------------------------------------------------------------------------
"Ordinateurs :"
foreach ($o in $ordinateurs) {
    if (-not (Get-ADComputer -Filter "Name -eq '$($o.Nom)'")) {
        New-ADComputer -Name $o.Nom -Path (Get-DNTier $o.Tier $o.OU) -Description $o.Description
        "  + ordi    $($o.Nom) -> $(Get-DNTier $o.Tier $o.OU)"
    }
}

# -----------------------------------------------------------------------------------------
# 6. Bilan : nombre d'objets par OU
# -----------------------------------------------------------------------------------------
"Bilan :"
foreach ($tier in $arborescence.Keys) {
    foreach ($sous in $arborescence[$tier]) {
        $dn = Get-DNTier $tier $sous
        $n  = @(Get-ADObject -SearchBase $dn -SearchScope OneLevel -Filter *).Count
        "  {0,-35} {1,3} objet(s)" -f "$tier\$sous", $n
    }
}
