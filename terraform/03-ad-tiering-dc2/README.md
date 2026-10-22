# Variante 03 : deux contrôleurs de domaine Core dans la même forêt

On reprend **toute la variante 02** (DC01, forêt `lab.local`, modèle de tiering) et on ajoute un
deuxième serveur Core, **DC02**, qui :

1. rejoint le domaine comme **serveur membre** ;
2. reçoit le rôle AD DS ;
3. est **promu contrôleur de domaine supplémentaire** du domaine `lab.local` (même forêt).

```
Windows 11 (hôte)
└── Hyper-V
    └── switch interne L03-Internal (192.168.103.0/24)
        ├── L03-DC01  →  DC01, 192.168.103.10, AD DS + DNS + GC, crée la forêt lab.local
        └── L03-DC02  →  DC02, 192.168.103.11, AD DS + DNS + GC, réplique depuis DC01
```

## Ce que vous apprenez ici

| Notion | Où la voir |
|--------|-----------|
| Ordonner des étapes dépendantes (`depends_on`) | `configuration.tf` |
| Jonction au domaine en PowerShell (`Add-Computer`) | `scripts/configure-dc02.ps1`, étape 2 |
| Rôle du DNS pour trouver un DC (enregistrements SRV) | `configure-dc02.ps1`, étape 2 |
| Ajout d'un DC à un domaine existant (`Install-ADDSDomainController`) | `configure-dc02.ps1`, étape 3 |
| DNS croisé entre deux DC | `configure-dc02.ps1`, étape 5 |
| Contrôle de la réplication (`repadmin`) | `configure-dc02.ps1`, étape 6 |

## Le déroulé automatique

Terraform crée les deux VMs, puis :

| Ordre | Ressource | Script | Ce qui se passe |
|-------|-----------|--------|-----------------|
| 1 | `terraform_data.dc01` | `configure-dc01.ps1` | Identique à la variante 02 : forêt + tiering |
| 2 | `terraform_data.dc02` | `configure-dc02.ps1` | Jonction, promotion, DNS croisé, vérification |

`depends_on = [terraform_data.dc01]` est indispensable : Terraform voit que les deux VMs existent,
mais il ne peut pas deviner que DC02 a besoin d'un **domaine qui fonctionne**. On lui impose l'ordre.
Pendant que DC01 se promeut, DC02 est déjà démarrée et attend.

### Les trois commandes de promotion, pour comparer

| Cmdlet | Usage |
|--------|-------|
| `Install-ADDSForest` | Premier DC d'une **nouvelle forêt** (DC01) |
| `Install-ADDSDomain` | Premier DC d'un **nouveau domaine** dans une forêt existante (domaine enfant) |
| `Install-ADDSDomainController` | DC **supplémentaire** dans un domaine existant (DC02) |

### Le DNS, toujours le DNS

- Avant la jonction, DC02 a pour DNS **l'IP de DC01** : c'est en interrogeant le DNS
  (`_ldap._tcp.dc._msdcs.lab.local`) que Windows trouve un contrôleur de domaine. Le script le teste
  avec `Resolve-DnsName` avant d'appeler `Add-Computer`.
- À la fin, **DNS croisé** : DC01 interroge d'abord DC02 puis lui-même, et inversement. Si un DC
  redémarre seul, il trouve tout de suite son partenaire.

### Et le tiering ?

Les deux DC sont dans l'OU **Domain Controllers** : ils sont Tier 0 par nature. Le script ne les
déplace pas (une GPO par défaut, « Default Domain Controllers Policy », y est liée). Le compte
ordinateur de DC02 est créé dans `Computers` lors de la jonction, puis déplacé automatiquement dans
`Domain Controllers` par la promotion.

## ⚠ Mémoire de l'hôte

L'hôte n'a qu'environ **2,4 Go de RAM libre**. Les deux VMs démarrent à **1 Go chacune** (mémoire
dynamique, 512 Mo minimum, 1,5 Go maximum) : cela passe tout juste. Avant de lancer :

- arrêtez les autres VMs (variantes 01/02, LAB d'origine) et fermez les applications gourmandes ;
- si Hyper-V refuse de démarrer une VM faute de mémoire, baissez `memory_startup_mb` à `768` dans
  `variables.tf` (la promotion sera plus lente, mais fonctionne).

## Déployer

Console PowerShell **en administrateur** :

```powershell
cd C:\VMS\terraform\03-ad-tiering-dc2
.\deploy.ps1
```

Durée indicative : 30 à 45 minutes.

## Vérifier

```powershell
Enter-PSSession -VMName L03-DC02 -Credential LAB\Administrateur
Get-ADDomainController -Filter * | Format-Table HostName, IPv4Address, IsGlobalCatalog
repadmin /replsummary            # 0 échec attendu
netdom query fsmo                # les 5 rôles FSMO sont restés sur DC01
Get-ADOrganizationalUnit -Filter "Name -like 'Tier *'" -Server DC02   # répliquées depuis DC01
Exit-PSSession
```

Test de réplication en direct : créez un utilisateur sur DC01, puis cherchez-le sur DC02
(`Get-ADUser test -Server DC02`) quelques secondes plus tard (`repadmin /syncall /AdeP` pour forcer).

## Ressources

| VM | vCPU | RAM démarrage / min / max | IP |
|----|------|----------------------------|----|
| DC01 | 2 | 1024 / 512 / 1536 Mo | 192.168.103.10 |
| DC02 | 2 | 1024 / 512 / 1536 Mo | 192.168.103.11 |

## Exercices possibles

- **Transférer un rôle FSMO** vers DC02 (`Move-ADDirectoryServerOperationMasterRole`), puis le récupérer.
- **Simuler une panne** : éteindre DC01 (`Stop-VM L03-DC01`) et vérifier qu'on s'authentifie toujours.
- Créer un **deuxième site AD** (`New-ADReplicationSite`) et y placer DC02.
- Rétrograder DC02 (`Uninstall-ADDSDomainController`) et observer le nettoyage des métadonnées.
