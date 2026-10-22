# Windows Server 2025 — Server Core (sans interface graphique)

Variante de `../windows-server-2025` (Desktop Experience). Même hyperviseur (Hyper-V Gen 2), même ISO,
même logique : `Autounattend.xml` → WinRM → provisioners → sysprep → VHDX « golden ».

## Lancer le build

```powershell
.\scripts\01-build-image-core.ps1
```

Résultat : `C:\VMS\images\ws2025-core\Virtual Hard Disks\ws2025-core-golden.vhdx`
(l'image Desktop Experience dans `images\ws2025` n'est pas touchée).

## Ce qui change par rapport à la version graphique

| Fichier | Différence |
|---------|-----------|
| `answer_files/Autounattend.xml` | `/IMAGE/NAME` = `Windows Server 2025 Datacenter` (sans « (expérience utilisateur) ») |
| `variables.pkr.hcl` | `vm_name`, `output_dir` distincts ; 2 Go de RAM et 40 Go de disque suffisent |
| `windows-server-2025-core.pkr.hcl` | source `ws2025core`, build `windows-server-2025-core` ; le reste est identique |
| `scripts/02-updates-and-tools.ps1` | vérifie que l'installation est bien `Server Core` ; plus de clé Gestionnaire de serveur ; ouverture des règles pare-feu d'administration à distance (MMC, WMI, disques) |

Si l'installation s'arrête sur « impossible de trouver l'image », listez les noms exacts de votre ISO :

```powershell
dism /Get-WimInfo /WimFile:D:\sources\install.wim
```

Pour Standard Core : `Windows Server 2025 Standard`.

## Déployer avec Terraform

Pointez la variable `golden_image_vhdx` vers l'image Core, par exemple dans `terraform.tfvars` :

```hcl
golden_image_vhdx = "C:\\VMS\\images\\ws2025-core\\Virtual Hard Disks\\ws2025-core-golden.vhdx"
```

Les `guest-scripts` (AD DS, jonction au domaine) fonctionnent tels quels sur Core : ce sont des cmdlets PowerShell.

## Administrer un Server Core

- Console / RDP : `sconfig` s'ouvre à la connexion (nom, réseau, domaine, mises à jour).
- Depuis l'hôte : `Enter-PSSession -ComputerName <IP> -Credential Administrateur`, RSAT, Gestionnaire de serveur, ou Windows Admin Center.
