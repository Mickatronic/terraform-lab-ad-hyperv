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

function Write-LabEtape {
    # Affiche une étape lisible dans la sortie de « terraform apply ».
    param([Parameter(Mandatory)][string]$Message)
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
      Si -NotBootedAt est fourni, on attend en plus un démarrage PLUS RÉCENT que cette heure
      (utile après un redémarrage, pour ne pas parler à la VM « avant » qu'elle ne s'éteigne).
    #>
    param(
        [Parameter(Mandatory)][string]$VMName,
        [Parameter(Mandatory)][pscredential]$Credential,
        [Nullable[datetime]]$NotBootedAt = $null,
        [int]$TimeoutMinutes = 30
    )
    $limite = (Get-Date).AddMinutes($TimeoutMinutes)
    Write-LabEtape "Attente de $VMName (PowerShell Direct, compte $($Credential.UserName))..."
    while ((Get-Date) -lt $limite) {
        $boot = Get-LabBootTime -VMName $VMName -Credential $Credential
        if ($boot -and ((-not $NotBootedAt) -or ($boot -gt $NotBootedAt))) {
            Write-LabEtape "$VMName répond (démarrée à $boot)."
            return $boot
        }
        Start-Sleep -Seconds 10
    }
    throw "$VMName ne répond pas après $TimeoutMinutes minutes."
}

function Restart-LabVM {
    <#
      Redémarre proprement l'invité puis attend son retour.
      -CredentialAfter : compte à utiliser APRÈS le redémarrage. Exemple : après la promotion
      en contrôleur de domaine, les comptes locaux n'existent plus, il faut LAB\Administrateur.
    #>
    param(
        [Parameter(Mandatory)][string]$VMName,
        [Parameter(Mandatory)][pscredential]$Credential,
        [pscredential]$CredentialAfter
    )
    if (-not $CredentialAfter) { $CredentialAfter = $Credential }
    $avant = Get-LabBootTime -VMName $VMName -Credential $Credential
    Write-LabEtape "Redémarrage de $VMName..."
    # shutdown /t 5 : on laisse 5 s à la session PowerShell Direct pour se fermer proprement.
    Invoke-Command -VMName $VMName -Credential $Credential -ScriptBlock { shutdown.exe /r /t 5 /f } | Out-Null
    Start-Sleep -Seconds 15
    Wait-LabVM -VMName $VMName -Credential $CredentialAfter -NotBootedAt $avant | Out-Null
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
            $p = @{ InterfaceIndex = $nic.ifIndex; IPAddress = $ip; PrefixLength = $prefix }
            if ($gw) { $p.DefaultGateway = $gw }
            New-NetIPAddress @p | Out-Null
        }
        if ($dns) { Set-DnsClientServerAddress -InterfaceIndex $nic.ifIndex -ServerAddresses $dns }
        else      { Set-DnsClientServerAddress -InterfaceIndex $nic.ifIndex -ResetServerAddresses }
        # Les noms techniques (-Name) des règles ne sont pas traduits, contrairement aux DisplayName :
        # c'est plus fiable sur un Windows en français.
        Get-NetFirewallRule -Name 'FPS-ICMP4-ERQ-In*' | Enable-NetFirewallRule
    }

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

Export-ModuleMember -Function Write-LabEtape, New-LabCredential, Get-LabBootTime, Wait-LabVM, Restart-LabVM, Set-LabBaseConfig, Wait-LabADReady
