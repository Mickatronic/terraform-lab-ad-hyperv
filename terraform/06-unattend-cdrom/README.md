# Variante 06 : le fichier de réponse fourni par CD

Même résultat que la variante 01 (**un serveur Core** nommé `SRV01`, IP fixe, accès Internet),
mais obtenu autrement : Windows reçoit son nom et son IP **pendant son premier démarrage**, grâce à un
`Autounattend.xml` que Terraform génère, grave sur un ISO et met dans le lecteur DVD de la VM.

```
Windows 11 (hôte)
└── Hyper-V
    └── switch interne L06-Internal (192.168.106.0/24, pas de DHCP)
        └── L06-SRV01  →  Windows : SRV01, 192.168.106.20
              ├── disque : copie de ws2025-core-sans-unattend.vhdx
              └── DVD    : unattend.iso (Autounattend.xml propre à cette VM)
```

## Prérequis : une image SANS fichier de réponse

Cette variante utilise une image à part, construite par
`packer\windows-server-2025-core-sans-unattend` (`scripts\01-build-image-core-sans-unattend.ps1`) :

```
C:\VMS\images\ws2025-core-sans-unattend\Virtual Hard Disks\ws2025-core-sans-unattend.vhdx
```

Pourquoi ? Au 1er démarrage d'un clone, Windows cherche son fichier de réponse dans cet ordre :

1. `C:\Windows\Panther\Unattend\` puis `C:\Windows\Panther\` (dans le disque) ;
2. la racine des supports amovibles, clés USB puis CD/DVD (`Autounattend.xml`).

L'image habituelle (`ws2025-core-golden.vhdx`) contient déjà un fichier dans `C:\Windows\Panther`
(copié par `sysprep /unattend:...`) : le CD serait ignoré. L'image « sans unattend » n'en contient aucun.

## Comparaison avec la variante 01

| | 01-serveur-seul | 06-unattend-cdrom |
|---|---|---|
| Image | `ws2025-core-golden.vhdx` (unattend dans l'image) | `ws2025-core-sans-unattend.vhdx` |
| Nom et IP | posés **après** le démarrage par `configure-serveur.ps1` (PowerShell Direct), avec un redémarrage | posés **pendant** le 1er démarrage par l'Autounattend du CD |
| Script lancé par Terraform | configure | **vérifie** seulement (`verifier-serveur.ps1`) |
| Changer le nom ou l'IP | le script les modifie sur la VM existante | VM **recréée** (l'unattend n'est lu qu'une fois) |
| VM démarrée sans le CD | démarre normalement | bloquée sur l'assistant « Pays, clavier, mot de passe » |

## Ce que vous apprenez ici

| Notion | Où la voir |
|--------|-----------|
| Générer un fichier à partir d'un modèle | `templatefile()` dans `main.tf`, modèle `unattend/Autounattend.xml.tftpl` |
| Boucle dans un modèle (`%{ for }`) | serveurs DNS dans le modèle |
| Créer un ISO avec Terraform | `data.archive_file` + `hyperv_iso_image` dans `main.tf` |
| Lecteur DVD et ordre de démarrage d'une VM Gen 2 | `dvd_drives` et `vm_firmware.boot_order` |
| Adresse MAC fixe | `network_adaptors.static_mac_address` (l'unattend reconnaît la carte par sa MAC) |
| Forcer le remplacement d'une ressource | `lifecycle.replace_triggered_by` sur le disque et la VM |
| Paramétrer Windows au 1er démarrage | passes `specialize` et `oobeSystem` de l'Autounattend |

## Les fichiers

```
06-unattend-cdrom/
├── versions.tf               # providers hyperv + archive (nouveau)
├── providers.tf              # identique à la 01
├── variables.tf              # + mac_address, time_zone, dns_servers
├── main.tf                   # switch, CD de réponse, disque, VM
├── configuration.tf          # NAT + vérification
├── outputs.tf
├── unattend/
│   └── Autounattend.xml.tftpl  # MODÈLE du fichier de réponse (les ${...} sont remplacés)
├── terraform.tfvars          # VOS valeurs : compte de l'hôte
├── terraform.tfvars.example
├── deploy.ps1                # identique à la 01
└── scripts/
    ├── LabHelpers.psm1       # identique à la 01
    ├── New-LabNat.ps1        # identique à la 01
    └── verifier-serveur.ps1  # attend la VM et vérifie nom + IP
```

Le dossier `build\` (créé au premier `plan`) contient le zip intermédiaire : il est ignoré par Git
car l'Autounattend y contient le mot de passe en clair.

## Comment ça marche

1. `templatefile()` complète le modèle avec les valeurs de la VM (nom, IP, MAC, passerelle, DNS, mot de passe).
2. `data.archive_file` met ce texte dans un zip sous le nom `Autounattend.xml`.
3. `hyperv_iso_image` transforme le zip en `unattend.iso`, dans le dossier de la VM.
4. La VM est créée avec ce CD dans son lecteur DVD, une **MAC fixe**, et démarre sur son disque.
5. Windows (image « sans unattend ») ne trouve rien dans `C:\Windows\Panther`, lit l'`Autounattend.xml` du CD :
   - passe *specialize* : nom `SRV01`, fuseau, IP `192.168.106.20/24`, passerelle `.1`, DNS ;
   - passe *oobeSystem* : langue, clavier, mot de passe Administrateur, assistant sauté.
6. `verifier-serveur.ps1` attend que la VM réponde en PowerShell Direct, compare le nom et l'IP, teste Internet.

## Déployer

Console PowerShell **en administrateur** :

```powershell
cd C:\VMS\terraform\06-unattend-cdrom
.\deploy.ps1           # le 1er init télécharge aussi le provider hashicorp/archive
```

## Vérifier

```powershell
Enter-PSSession -VMName L06-SRV01 -Credential Administrateur
hostname                                   # SRV01, sans aucun Rename-Computer
Get-NetIPAddress -AddressFamily IPv4       # 192.168.106.20
Get-Content D:\Autounattend.xml            # le fichier lu au démarrage (lettre du CD à adapter)
Exit-PSSession
```

## Si ça ne marche pas

| Symptôme | Cause probable |
|----------|---------------|
| Console Hyper-V bloquée sur « Pays/région » | Windows n'a pas trouvé l'Autounattend : mauvaise image (celle avec unattend) ou CD absent |
| Nom correct mais pas d'IP fixe | la MAC de l'unattend ne correspond pas à la carte : vérifier `Get-VMNetworkAdapter L06-SRV01` |
| Erreur `hyperv_iso_image` | le provider crée l'ISO avec IMAPI2 sur l'hôte : vérifier que le dossier `C:\VMS\vms\06-unattend-cdrom` est accessible |

Le journal du 1er démarrage est dans la VM : `C:\Windows\Panther\setupact.log` (chercher « unattend »).

## Détruire

```powershell
.\deploy.ps1 -Destroy
```

## Exercices possibles

- Changer `computer_name` puis `.\deploy.ps1` : lire le plan, expliquer pourquoi le disque et la VM sont remplacés.
- Démarrer une VM à la main depuis l'image sans unattend, sans CD : observer l'assistant OOBE.
- Ajouter la jonction à un domaine dans l'Autounattend (composant `Microsoft-Windows-UnattendedJoin`).
