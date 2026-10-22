# Variantes Terraform du LAB (images Server Core)

Trois dossiers indépendants, du plus simple au plus complet. Chacun est un projet Terraform
autonome (son état, ses VMs préfixées, son switch, son sous-réseau) : on peut les étudier dans l'ordre.
Le dossier `terraform\` d'origine (DC01 + SRV01, configuration manuelle) n'est pas modifié.

| Dossier | Contenu | VMs Hyper-V | Réseau | RAM au démarrage |
|---------|---------|-------------|--------|------------------|
| `01-serveur-seul` | 1 serveur Core configuré (IP, nom) | L01-SRV01 | 192.168.101.0/24 | 1 Go |
| `02-ad-tiering` | 1 DC, forêt lab.local, OU de tiering alimentées | L02-DC01 | 192.168.102.0/24 | 1 Go |
| `03-ad-tiering-dc2` | 02 + DC02 joint puis promu DC supplémentaire | L03-DC01, L03-DC02 | 192.168.103.0/24 | 2 Go |

Prérequis communs :
- l'image `C:\VMS\images\ws2025-core\Virtual Hard Disks\ws2025-core-golden.vhdx` (`scripts\01-build-image-core.ps1`) ;
- une console PowerShell **administrateur** (PowerShell Direct) ;
- `terraform.tfvars` dans chaque dossier (déjà copié depuis `terraform\terraform.tfvars`).

Lancement : `cd <dossier>` puis `.\deploy.ps1` ; destruction : `.\deploy.ps1 -Destroy`.
Avec ~2,4 Go de RAM libre sur l'hôte, **un seul LAB à la fois**.
