# Variante 01 : un serveur Windows Server Core seul

Le point de départ : **une seule VM** Windows Server 2025 Core, configurée automatiquement
(nom, adresse IP, ping autorisé), sans aucun rôle. C'est la brique que les variantes 02 et 03 réutilisent.

```
Windows 11 (hôte)
└── Hyper-V
    └── switch interne L01-Internal (192.168.101.0/24, pas de DHCP)
        └── L01-SRV01  →  Windows : SRV01, 192.168.101.20
```

## Ce que vous apprenez ici

| Notion | Où la voir |
|--------|-----------|
| Séparer infrastructure et configuration | `main.tf` (Hyper-V) / `configuration.tf` (Windows) |
| Ressources simples reliées par des références (pas de boucle) | `main.tf` |
| Copier une image Packer « golden » en disque de VM | `hyperv_vhd.os` dans `main.tf` |
| Mémoire dynamique Hyper-V | `hyperv_machine_instance.vm` dans `main.tf` |
| Lancer un script après la création d'une VM | `terraform_data` + `local-exec` dans `configuration.tf` |
| Configurer une VM **sans réseau** : PowerShell Direct | `scripts/LabHelpers.psm1` |
| Écrire un script **idempotent** (relançable sans casse) | `Set-LabBaseConfig` dans `LabHelpers.psm1` |

## Les fichiers

```
01-serveur-seul/
├── versions.tf               # version de Terraform et du provider taliesins/hyperv
├── providers.tf              # connexion du provider à Hyper-V (WinRM sur 127.0.0.1)
├── variables.tf              # toutes les valeurs modifiables (image, RAM, IP...)
├── main.tf                   # switch + disque + VM
├── configuration.tf          # lance scripts/configure-serveur.ps1 après la création
├── outputs.tf                # ce qu'affiche Terraform à la fin
├── moved.tf                  # transition depuis l'ancienne version (avec for_each), supprimable ensuite
├── terraform.tfvars          # VOS valeurs : compte de l'hôte (copie de terraform\terraform.tfvars)
├── terraform.tfvars.example
├── deploy.ps1                # init + validate + plan + apply (ou -Destroy)
└── scripts/                  # PowerShell exécuté SUR L'HÔTE
    ├── LabHelpers.psm1       # fonctions communes (attente, redémarrage, config de base)
    └── configure-serveur.ps1 # IP + nom pour ce serveur
```

## Comment ça marche

1. **Terraform crée l'infrastructure** : le switch interne, une copie complète du VHDX
   `images\ws2025-core\...\ws2025-core-golden.vhdx`, puis la VM génération 2 (Secure Boot) qu'il démarre.
2. Au premier démarrage, Windows applique le **sysprep** de l'image (phases *specialize* puis *OOBE*) :
   il reçoit un nom aléatoire `WIN-XXXX` et le mot de passe `P@ssw0rd!` du compte `Administrateur`.
3. **Terraform lance `configure-serveur.ps1`** (ressource `terraform_data`). Ce script, qui tourne sur
   l'hôte, attend que la VM accepte une session **PowerShell Direct**, puis fixe l'IP, autorise le ping
   et renomme la machine en `SRV01` (avec redémarrage).

### Pourquoi PowerShell Direct ?

Le switch interne n'a pas de DHCP : au démarrage, la VM **n'a pas d'adresse IP**, donc ni WinRM ni RDP
ne peuvent l'atteindre. PowerShell Direct (`Invoke-Command -VMName ...`) passe par le bus interne
d'Hyper-V (VMBus), pas par le réseau. Seules conditions : être **administrateur de l'hôte** et que la VM
soit démarrée.

### Pourquoi un `terraform_data` ?

Terraform décrit un **état** (« il existe une VM SRV01 »), il ne sait pas « faire des actions ».
`terraform_data` est une ressource vide qui sert de support au provisioner `local-exec`. Le provisioner
ne s'exécute qu'à la **création** de la ressource ; `triggers_replace` la recrée (et relance donc le
script) si la VM est recréée ou si un script est modifié.

> Pour aller plus loin : en entreprise, cette partie « configuration » est souvent confiée à un outil
> dédié (Ansible, DSC). Terraform reste alors centré sur l'infrastructure.

## Déployer

Console PowerShell **en administrateur** (obligatoire pour PowerShell Direct) :

```powershell
cd C:\VMS\terraform\01-serveur-seul
.\deploy.ps1           # répondre « o » pour appliquer
```

Durée indicative : 5 à 10 minutes (copie du disque, sysprep, redémarrage).

## Vérifier

```powershell
Enter-PSSession -VMName L01-SRV01 -Credential Administrateur
hostname                        # SRV01
Get-NetIPAddress -AddressFamily IPv4
sconfig                         # le menu texte de configuration de Server Core
Exit-PSSession
```

## Détruire

```powershell
.\deploy.ps1 -Destroy
```

## Ressources

| VM | vCPU | RAM démarrage / min / max | IP |
|----|------|----------------------------|----|
| SRV01 | 2 | 1024 / 512 / 2048 Mo | 192.168.101.20 |

L'hôte n'a qu'environ 2,4 Go de RAM libre : la mémoire dynamique permet à la VM de ne consommer
que ce dont elle a besoin. Ces valeurs se changent dans `variables.tf` (`memory_startup_mb`, `memory_min_mb`, `memory_max_mb`).

## Exercices possibles

- Ajouter un deuxième serveur en copiant les ressources `hyperv_vhd` et `hyperv_machine_instance`, puis
  comparer avec la variante 03, qui fait la même chose avec une boucle `for_each` sur une map de VMs.
- Ajouter le rôle serveur de fichiers (`Install-WindowsFeature FS-FileServer`) dans `configure-serveur.ps1`.
- Donner une IP à l'hôte sur le switch (`New-NetIPAddress` sur la carte `vEthernet (L01-Internal)`)
  pour joindre la VM par le réseau (ping, WinRM).

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
