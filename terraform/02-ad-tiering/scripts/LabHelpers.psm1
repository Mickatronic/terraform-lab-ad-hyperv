<#
.SYNOPSIS
  Fonctions communes utilisées par les scripts de configuration du LAB.

.DESCRIPTION
  Ces fonctions s'exécutent SUR L'HÔTE Hyper-V (lancées par Terraform via local-exec)
  et pilotent les VMs grâce à PowerShell Direct :

      Invoke-Command -VMName <VM> -Credential <compte> -ScriptBlock { ... }

  PowerShell Direct passe par le bus VMBus d'Hyper-V, PAS par le réseau. C'est ce qui
  permet de configurer une VM qui n'a encore ni adresse IP ni nom définitif (notre switch
  interne n'a pas de DHCP). Conditions : être administrateur sur l'hôte, VM démarrée,
  invité Windows 10 / Server 2016 ou plus récent.
#>

Set-StrictMode -Version Latest

# Une erreur dans une fonction du module doit ARRÊTER le script. Le $ErrorActionPreference du
# script appelant ne s'applique pas à l'intérieur d'un module : on le fixe donc ici aussi.
$ErrorActionPreference = 'Stop'

# --- Chemin des modules ---------------------------------------------------------------------
# Terraform lance « powershell.exe » (Windows PowerShell 5.1). Si TU as lancé Terraform depuis
# PowerShell 7 (pwsh), la variable PSModulePath héritée pointe d'abord vers les modules de
# PowerShell 7, que Windows PowerShell 5.1 ne sait pas charger. Erreur typique :
#   « ConvertTo-SecureString ... module Microsoft.PowerShell.Security n'a pas pu être chargé »
# On remet donc les dossiers de modules propres à Windows PowerShell 5.1.
if ($PSVersionTable.PSEdition -eq 'Desktop') {
    # Simple concaténation de chaînes : Join-Path vit lui-même dans un module (Management),
    # qui ne pourrait pas encore être chargé à ce stade.
    $env:PSModulePath = @(
        [Environment]::GetFolderPath('MyDocuments') + '\WindowsPowerShell\Modules'
        $env:ProgramFiles + '\WindowsPowerShell\Modules'
        $env:SystemRoot + '\System32\WindowsPowerShell\v1.0\Modules'
    ) -join ';'
}

function Write-LabEtape {
    # Affiche une étape lisible dans la sortie de « terraform apply ».
    # Les commandes comme repadmin renvoient aussi des lignes vides : on les accepte et on les ignore.
    param([Parameter(Mandatory)][AllowEmptyString()][AllowNull()][string]$Message)
    if ([string]::IsNullOrWhiteSpace($Message)) { return }
    Write-Host ("[{0:HH:mm:ss}] {1}" -f (Get-Date), $Message)
}

function New-LabCredential {
    <#
      Fabrique un objet PSCredential à partir d'un nom et d'un mot de passe en clair.
      Le mot de passe arrive par une variable d'environnement posée par Terraform
      (bloc « environment » du local-exec) : il n'apparaît donc pas dans la ligne de commande.
    #>
    param(
        [Parameter(Mandatory)][string]$UserName,
        [Parameter(Mandatory)][string]$Password
    )
    if (-not $Password) { throw "Mot de passe vide pour $UserName." }
    $secure = ConvertTo-SecureString $Password -AsPlainText -Force
    New-Object System.Management.Automation.PSCredential ($UserName, $secure)
}

function Get-LabBootTime {
    # Renvoie l'heure du dernier démarrage de l'invité (ou $null si la VM ne répond pas encore).
    param(
        [Parameter(Mandatory)][string]$VMName,
        [Parameter(Mandatory)][pscredential]$Credential
    )
    try {
        Invoke-Command -VMName $VMName -Credential $Credential -ErrorAction Stop -ScriptBlock {
            (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
        }
    }
    catch { $null }
}

function Wait-LabVM {
    <#
      Attend que la VM accepte une session PowerShell Direct avec ce compte.
      Juste après le déploiement, l'image « sysprepée » passe par les phases specialize
      puis OOBE (avec un redémarrage) : il faut plusieurs minutes avant que le compte
      Administrateur soit utilisable. On réessaie donc toutes les 10 secondes.
    #>
    param(
        [Parameter(Mandatory)][string]$VMName,
        [Parameter(Mandatory)][pscredential]$Credential,
        [int]$TimeoutMinutes = 30
    )
    $limite = (Get-Date).AddMinutes($TimeoutMinutes)
    Write-LabEtape "Attente de $VMName (PowerShell Direct, compte $($Credential.UserName))..."
    while ((Get-Date) -lt $limite) {
        $boot = Get-LabBootTime -VMName $VMName -Credential $Credential
        if ($boot) {
            Write-LabEtape "$VMName répond (démarrée à $boot)."
            return $boot
        }
        Start-Sleep -Seconds 10
    }
    throw "$VMName ne répond pas après $TimeoutMinutes minutes."
}

function Restart-LabVM {
    <#
      Redémarre l'invité puis attend son retour.
      Le redémarrage est demandé à Hyper-V (Stop-VM puis Start-VM), pas à Windows :
        - Stop-VM sans -TurnOff est un arrêt PROPRE (service d'intégration « Arrêt »),
          comme un clic sur « Arrêter » dans le Gestionnaire Hyper-V ;
        - il ne demande AUCUN identifiant. C'est important juste après une promotion en DC :
          le compte local n'existe plus, et le compte du domaine ne marche qu'après redémarrage.
      -CredentialAfter : compte à utiliser APRÈS le redémarrage (ex. LAB\Administrateur).
    #>
    param(
        [Parameter(Mandatory)][string]$VMName,
        [Parameter(Mandatory)][pscredential]$Credential,
        [pscredential]$CredentialAfter
    )
    # Sous Windows PowerShell 5.1, un paramètre [pscredential] non fourni vaut [pscredential]::Empty
    # (et non $null) : le tester avec « -not » ne suffit pas, et passer Empty à Invoke-Command
    # ouvre une fenêtre « Demande d'informations d'identification ». On regarde donc s'il a été fourni.
    if (-not $PSBoundParameters.ContainsKey('CredentialAfter') -or
        $CredentialAfter -eq [System.Management.Automation.PSCredential]::Empty) {
        $CredentialAfter = $Credential
    }
    Write-LabEtape "Redémarrage de $VMName (arrêt propre par Hyper-V)..."
    # -Force : pas de question de confirmation (le script tourne sans console interactive).
    Stop-VM -Name $VMName -Force
    Start-VM -Name $VMName
    Wait-LabVM -VMName $VMName -Credential $CredentialAfter | Out-Null
}

function Set-LabBaseConfig {
    <#
      Configuration de base commune à tous les serveurs du LAB, idempotente
      (on peut la relancer : elle ne refait que ce qui manque) :
        1. adresse IP fixe + serveurs DNS ;
        2. autorisation du ping (ICMPv4) dans le pare-feu ;
        3. renommage de l'ordinateur (le sysprep a donné un nom aléatoire WIN-XXXX) + redémarrage.
    #>
    param(
        [Parameter(Mandatory)][string]$VMName,
        [Parameter(Mandatory)][pscredential]$Credential,
        [Parameter(Mandatory)][string]$ComputerName,
        [Parameter(Mandatory)][string]$IPAddress,
        [int]$PrefixLength = 24,
        [string]$Gateway = '',
        [string[]]$DnsServers = @()
    )

    Wait-LabVM -VMName $VMName -Credential $Credential | Out-Null

    Write-LabEtape "Réseau de $VMName : $IPAddress/$PrefixLength, DNS $($DnsServers -join ', ')"
    Invoke-Command -VMName $VMName -Credential $Credential -ArgumentList $IPAddress, $PrefixLength, $Gateway, $DnsServers -ScriptBlock {
        param($ip, $prefix, $gw, $dns)
        $ErrorActionPreference = 'Stop'
        # Une seule carte réseau dans nos VMs : on prend la première carte active.
        $nic = Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1
        if (-not (Get-NetIPAddress -InterfaceIndex $nic.ifIndex -IPAddress $ip -ErrorAction SilentlyContinue)) {
            # On désactive le DHCP et on retire l'éventuelle adresse APIPA (169.254.x.x).
            Set-NetIPInterface -InterfaceIndex $nic.ifIndex -Dhcp Disabled
            Get-NetIPAddress -InterfaceIndex $nic.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
                Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue
            New-NetIPAddress -InterfaceIndex $nic.ifIndex -IPAddress $ip -PrefixLength $prefix | Out-Null
        }
        if ($dns) { Set-DnsClientServerAddress -InterfaceIndex $nic.ifIndex -ServerAddresses $dns }
        else      { Set-DnsClientServerAddress -InterfaceIndex $nic.ifIndex -ResetServerAddresses }
        # Les noms techniques (-Name) des règles ne sont pas traduits, contrairement aux DisplayName :
        # c'est plus fiable sur un Windows en français.
        Get-NetFirewallRule -Name 'FPS-ICMP4-ERQ-In*' | Enable-NetFirewallRule
    }
    if ($Gateway) { Set-LabGateway -VMName $VMName -Credential $Credential -Gateway $Gateway }

    $nomActuel = Invoke-Command -VMName $VMName -Credential $Credential -ScriptBlock { $env:COMPUTERNAME }
    if ($nomActuel -ne $ComputerName) {
        Write-LabEtape "Renommage $nomActuel -> $ComputerName"
        Invoke-Command -VMName $VMName -Credential $Credential -ArgumentList $ComputerName -ScriptBlock {
            param($n) Rename-Computer -NewName $n -Force -WarningAction SilentlyContinue
        }
        Restart-LabVM -VMName $VMName -Credential $Credential
    }
    else {
        Write-LabEtape "$VMName s'appelle déjà $ComputerName."
    }
}

function Set-LabGateway {
    <#
      Passerelle par défaut de la VM = adresse de l'hôte sur le switch (voir New-LabNat.ps1).
      C'est elle qui donne Internet à la VM, à travers le NAT de l'hôte. Idempotente.
      Bonus : avec une passerelle, Windows identifie mieux le réseau (profil « Domaine » sur un DC).
    #>
    param(
        [Parameter(Mandatory)][string]$VMName,
        [Parameter(Mandatory)][pscredential]$Credential,
        [Parameter(Mandatory)][string]$Gateway
    )
    Invoke-Command -VMName $VMName -Credential $Credential -ArgumentList $Gateway -ScriptBlock {
        param($gw)
        $nic = Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1
        # Route par défaut = 0.0.0.0/0 (« tout le reste ») vers la passerelle.
        $route = Get-NetRoute -InterfaceIndex $nic.ifIndex -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue
        if ($route.NextHop -ne $gw) {
            $route | Remove-NetRoute -Confirm:$false -ErrorAction SilentlyContinue
            New-NetRoute -InterfaceIndex $nic.ifIndex -DestinationPrefix '0.0.0.0/0' -NextHop $gw | Out-Null
        }
        "$env:COMPUTERNAME : passerelle $gw"
    } | ForEach-Object { Write-LabEtape $_ }
}

function Set-LabDnsForwarder {
    <#
      Sur un DC, le DNS de la machine reste le DC lui-même (127.0.0.1) : c'est lui qui connaît lab.local.
      Pour les noms Internet (microsoft.com...), le service DNS du DC les demande à des
      « redirecteurs » : ici des DNS publics, joints à travers le NAT de l'hôte.
    #>
    param(
        [Parameter(Mandatory)][string]$VMName,
        [Parameter(Mandatory)][pscredential]$Credential,
        [Parameter(Mandatory)][string[]]$Forwarders
    )
    Invoke-Command -VMName $VMName -Credential $Credential -ArgumentList (, $Forwarders) -ScriptBlock {
        param($fwd)
        Set-DnsServerForwarder -IPAddress $fwd
        "$env:COMPUTERNAME : redirecteurs DNS $($fwd -join ', ')"
    } | ForEach-Object { Write-LabEtape $_ }
}

function Test-LabInternet {
    # Petit test de sortie Internet depuis la VM, pour le bilan (n'arrête pas le script).
    param(
        [Parameter(Mandatory)][string]$VMName,
        [Parameter(Mandatory)][pscredential]$Credential
    )
    Invoke-Command -VMName $VMName -Credential $Credential -ScriptBlock {
        $dns = [bool](Resolve-DnsName www.microsoft.com -ErrorAction SilentlyContinue)
        $web = (Test-NetConnection www.microsoft.com -Port 443 -WarningAction SilentlyContinue).TcpTestSucceeded
        "$env:COMPUTERNAME : Internet -> résolution DNS $(if ($dns) {'OK'} else {'ÉCHEC'}), HTTPS $(if ($web) {'OK'} else {'ÉCHEC'})"
    } | ForEach-Object { Write-LabEtape $_ }
}

function Wait-LabADReady {
    <#
      Après la promotion d'un contrôleur de domaine, le service « Services Web Active Directory »
      (ADWS, utilisé par les cmdlets *-AD*) met quelques minutes à répondre.
      On attend qu'un Get-ADDomain fonctionne sur la VM.
    #>
    param(
        [Parameter(Mandatory)][string]$VMName,
        [Parameter(Mandatory)][pscredential]$Credential,
        [int]$TimeoutMinutes = 20
    )
    $limite = (Get-Date).AddMinutes($TimeoutMinutes)
    Write-LabEtape "Attente des services Active Directory sur $VMName..."
    while ((Get-Date) -lt $limite) {
        try {
            $d = Invoke-Command -VMName $VMName -Credential $Credential -ErrorAction Stop -ScriptBlock {
                Get-ADDomain -Server localhost -ErrorAction Stop | Select-Object -ExpandProperty DNSRoot
            }
            if ($d) { Write-LabEtape "Active Directory répond sur $VMName (domaine $d)."; return }
        }
        catch { }
        Start-Sleep -Seconds 15
    }
    throw "Active Directory ne répond pas sur $VMName après $TimeoutMinutes minutes."
}

Export-ModuleMember -Function Write-LabEtape, New-LabCredential, Get-LabBootTime, Wait-LabVM, Restart-LabVM, Set-LabBaseConfig, Set-LabGateway, Set-LabDnsForwarder, Test-LabInternet, Wait-LabADReady
