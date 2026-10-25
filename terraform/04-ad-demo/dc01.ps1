# Configure L04-DC01 depuis l'hôte, par PowerShell Direct (Invoke-Command -VMName).
$ErrorActionPreference = 'Stop'
$env:PSModulePath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\Modules"

$vm  = 'L04-DC01'
$mdp = 'P@ssw0rd!'
$secu = ConvertTo-SecureString $mdp -AsPlainText -Force
$local   = New-Object PSCredential ('Administrateur', $secu)
$domaine = New-Object PSCredential ('LAB\Administrateur', $secu)

function Attendre($cred, $test = { $true }) {
    do {
        Start-Sleep 10
        $ok = try { Invoke-Command -VMName $vm -Credential $cred -ScriptBlock $test -ErrorAction Stop } catch { $false }
    } until ($ok)
}

"NAT sur l'hôte (accès Internet des VMs)..."
New-NetIPAddress -InterfaceAlias 'vEthernet (L04-Internal)' -IPAddress 192.168.104.1 -PrefixLength 24 -ErrorAction SilentlyContinue | Out-Null
if (-not (Get-NetNat -ErrorAction SilentlyContinue | Where-Object InternalIPInterfaceAddressPrefix -eq '192.168.96.0/19')) {
    New-NetNat -Name LAB-NAT -InternalIPInterfaceAddressPrefix 192.168.96.0/19 | Out-Null
}

"Attente de la VM..."
Attendre $local

"IP, nom, redémarrage..."
Invoke-Command -VMName $vm -Credential $local -ScriptBlock {
    $nic = (Get-NetAdapter)[0]
    New-NetIPAddress -InterfaceIndex $nic.ifIndex -IPAddress 192.168.104.10 -PrefixLength 24 -DefaultGateway 192.168.104.1 | Out-Null
    Set-DnsClientServerAddress -InterfaceIndex $nic.ifIndex -ServerAddresses 127.0.0.1
    Rename-Computer -NewName DC01 -Force -WarningAction SilentlyContinue
}
Stop-VM $vm -Force; Start-VM $vm
Attendre $local

"AD DS + création de la forêt lab.local..."
Invoke-Command -VMName $vm -Credential $local -ArgumentList $mdp -ScriptBlock {
    param($mdp)
    Install-WindowsFeature AD-Domain-Services -IncludeManagementTools | Out-Null
    Install-ADDSForest -DomainName lab.local -DomainNetbiosName LAB -InstallDns -Force -NoRebootOnCompletion `
        -SafeModeAdministratorPassword (ConvertTo-SecureString $mdp -AsPlainText -Force) -WarningAction SilentlyContinue | Out-Null
}
Stop-VM $vm -Force; Start-VM $vm
Attendre $domaine { Get-ADDomain -Server localhost }

"Tiering : OU, groupes, comptes..."
Invoke-Command -VMName $vm -Credential $domaine -ArgumentList $mdp -ScriptBlock {
    param($mdp)
    Set-DnsServerForwarder -IPAddress 1.1.1.1, 8.8.8.8
    $PSDefaultParameterValues['*-AD*:Server'] = 'localhost'
    $racine = 'DC=lab,DC=local'
    $secu = ConvertTo-SecureString $mdp -AsPlainText -Force

    foreach ($t in 0, 1, 2) {
        New-ADOrganizationalUnit -Name "Tier $t" -Path $racine
        foreach ($ou in 'Comptes admin', 'Groupes', 'Serveurs', 'Comptes de service') {
            New-ADOrganizationalUnit -Name $ou -Path "OU=Tier $t,$racine"
        }
        New-ADGroup -Name "GG_T$($t)_Admins" -GroupScope Global -Path "OU=Groupes,OU=Tier $t,$racine"
    }

    $comptes = @(
        @('t0-amartin', 0), @('t0-bleroy', 0),
        @('t1-amartin', 1), @('t1-cdubois', 1),
        @('t2-cdubois', 2), @('t2-dpetit', 2)
    )
    foreach ($c in $comptes) {
        New-ADUser -Name $c[0] -Path "OU=Comptes admin,OU=Tier $($c[1]),$racine" -AccountPassword $secu -Enabled $true
        Add-ADGroupMember "GG_T$($c[1])_Admins" -Members $c[0]
    }
    New-ADUser -Name 'svc-t1-sql' -Path "OU=Comptes de service,OU=Tier 1,$racine" -AccountPassword $secu -Enabled $true

    # Le groupe Tier 0 devient Admins du domaine (SID -512, le nom est traduit).
    Add-ADGroupMember "$((Get-ADDomain).DomainSID)-512" -Members 'GG_T0_Admins'

    Get-ADOrganizationalUnit -Filter * | Select-Object -ExpandProperty DistinguishedName
}
"Terminé."
