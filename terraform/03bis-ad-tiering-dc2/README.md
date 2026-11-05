# Variante 03 bis : deux contrôleurs de domaine, SANS boucle

**Exactement le même LAB que la variante 03** (DC01 crée la forêt `lab.local` + le tiering, DC02 la
rejoint puis devient DC supplémentaire), mais **sans `for_each`** : les deux VMs sont écrites
en entier, l'une après l'autre, dans `main.tf`. Plus long, mais chaque bloc se lit seul.

```
Windows 11 (hôte)
└── Hyper-V
    └── switch interne L03B-Internal (192.168.113.0/24, NAT vers Internet par 192.168.113.1)
        ├── L03B-DC01  →  DC01, 192.168.113.10, AD DS + DNS + GC, crée la forêt lab.local
        └── L03B-DC02  →  DC02, 192.168.113.11, AD DS + DNS + GC, réplique depuis DC01
```

Préfixe, switch et sous-réseau sont différents de la 03 (`L03B`, `192.168.113.x`) : les deux
dossiers ne se marchent pas dessus. Les scripts PowerShell sont **identiques** à la 03.

## 03 ou 03 bis : comparer les deux écritures

| | 03 (avec boucle) | 03 bis (sans boucle) |
|---|---|---|
| Description des VMs | une map `vms` dans `variables.tf` | **la même map `vms`** |
| Ressources dans `main.tf` | `hyperv_vhd.os` et `hyperv_machine_instance.vm`, avec `for_each = var.vms` | `hyperv_vhd.dc01`, `hyperv_vhd.dc02`, `hyperv_machine_instance.dc01`, `hyperv_machine_instance.dc02` |
| Valeurs d'une VM | `each.value.cpus` (la boucle passe sur chaque clé) | `var.vms["DC01"].cpus` (on lit la clé à la main) |
| Nom de la VM | `local.vm_names[each.key]` (préfixe + clé) | `var.vms["DC01"].id` (écrit dans la map) |
| Switch et dossier | `hyperv_network_switch.lab.name`, `var.vm_root_path` | `var.vms["DC01"].switch`, `var.vms["DC01"].path` (+ `depends_on` vers le switch) |
| Référence dans `configuration.tf` | `hyperv_machine_instance.vm["DC01"].id` | `hyperv_machine_instance.dc01.id` |
| IP | `var.vms["DC01"].ip` | `var.vms["DC01"].ip` (identique) |
| Ajouter une 3e VM | une ligne dans la map | une ligne dans la map **et** un bloc de ~40 lignes dans `main.tf` |

À retenir pour les apprenants : **sans boucle**, c'est plus simple à lire et à modifier VM par VM ;
**avec boucle**, on évite la répétition dès qu'il y a plusieurs machines identiques.
Terraform crée exactement les mêmes objets dans Hyper-V dans les deux cas.

## Les fichiers

```
03bis-ad-tiering-dc2/
├── main.tf               # switch, puis DC01 (disque + VM), puis DC02 (disque + VM)
├── variables.tf          # valeurs communes + la map vms (id, nom, switch, dossier, CPU, RAM, IP)
├── configuration.tf      # nat → dc01 (forêt + tiering) → dc02 (jonction + promotion)
├── outputs.tf
├── versions.tf, providers.tf, terraform.tfvars, deploy.ps1
└── scripts/              # identiques à la variante 03
```

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
cd C:\VMS\terraform\03bis-ad-tiering-dc2
.\deploy.ps1
```

Durée indicative : 30 à 45 minutes.

## Vérifier

```powershell
Enter-PSSession -VMName L03B-DC02 -Credential LAB\Administrateur
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
| DC01 | 2 | 1024 / 512 / 1536 Mo | 192.168.113.10 |
| DC02 | 2 | 1024 / 512 / 1536 Mo | 192.168.113.11 |

## Exercices possibles

- **Transférer un rôle FSMO** vers DC02 (`Move-ADDirectoryServerOperationMasterRole`), puis le récupérer.
- **Simuler une panne** : éteindre DC01 (`Stop-VM L03B-DC01`) et vérifier qu'on s'authentifie toujours.
- Créer un **deuxième site AD** (`New-ADReplicationSite`) et y placer DC02.
- Rétrograder DC02 (`Uninstall-ADDSDomainController`) et observer le nettoyage des métadonnées.

## Accès Internet des VMs (NAT sur l'hôte)

Le switch est **interne** : seul, il ne relie les VMs qu'à l'hôte. Pour leur donner Internet,
`terraform_data.nat` lance `scripts/New-LabNat.ps1` sur l'hôte, qui :

1. donne à la carte `vEthernet (<switch>)` de l'hôte l'adresse `.1` du sous-réseau : c'est la **passerelle** des VMs ;
2. crée (une seule fois) la règle NAT `LAB-NAT` sur `192.168.96.0/19`, qui couvre toutes les variantes.
   Windows 10/11 n'accepte qu'une règle NAT : elle est partagée et n'est pas supprimée au `destroy`.

Côté VM, le script de configuration ajoute la route par défaut vers cette passerelle. Sur un DC, le DNS
de la machine reste lui-même (il connaît `lab.local`) et les noms Internet sont demandés à des
**redirecteurs** (`dns_forwarders`, par défaut 1.1.1.1 et 8.8.8.8, à remplacer par le DNS de
l'établissement si les DNS publics sont filtrés). Le bilan final affiche un test DNS + HTTPS.

Vérifier côté hôte : `Get-NetNat` et `Get-NetIPAddress -InterfaceAlias 'vEthernet (*'`.
Si `New-NetNat` échoue, un autre NAT existe déjà sur une plage qui chevauche : `Get-NetNat` le montre
(on peut le supprimer avec `Remove-NetNat` s'il ne sert plus).
