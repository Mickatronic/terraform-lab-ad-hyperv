# Windows Server 2025 Core — sans fichier de réponse sysprep

Variante de `../windows-server-2025-core`, rangée dans son propre dossier : l'image d'origine
(`images\ws2025-core\...\ws2025-core-golden.vhdx`) et les variantes Terraform 01 à 05 ne sont pas touchées.

## L'idée

| | Image d'origine | Cette image |
|---|---|---|
| Fichier de réponse du 1er démarrage | **dans l'image** (`sysprep /unattend:...` le copie dans `C:\Windows\Panther`) | **absent** : fourni sur un CD par Terraform |
| Nom et IP des clones | nom aléatoire, puis renommage + IP par un script Terraform (redémarrage) | posés **dès le 1er démarrage** par l'unattend du CD |
| Clone démarré sans CD | démarre normalement | **s'arrête sur l'assistant OOBE** |

## Ce qui change par rapport à l'original

| Fichier | Différence |
|---------|-----------|
| `answer_files/sysprep-unattend.xml` | supprimé |
| `windows-server-2025-core-sans-unattend.pkr.hcl` | plus de provisioner `file` ; build `windows-server-2025-core-sans-unattend` |
| `scripts/03-register-sysprep-task.ps1` | sysprep **sans** `/unattend` ; efface d'abord `C:\Windows\Panther\unattend.xml` (copie de l'Autounattend de l'installation, qui sinon serait relue par les clones) |
| `scripts/99-sysprep.ps1` | supprimé (inutile ici) |
| `variables.pkr.hcl` | `vm_name` = `ws2025-core-sans-unattend`, `output_dir` = `C:/VMS/images/ws2025-core-sans-unattend` |

`Autounattend.xml`, `01-configure-winrm.ps1` et `02-updates-and-tools.ps1` sont identiques à l'original.

## Lancer le build

```powershell
.\scripts\01-build-image-core-sans-unattend.ps1
```

Résultat : `C:\VMS\images\ws2025-core-sans-unattend\Virtual Hard Disks\ws2025-core-sans-unattend.vhdx`

## Utiliser l'image

Avec `terraform\06-unattend-cdrom`, qui génère un `Autounattend.xml` par VM, le grave sur un ISO et
le monte dans le lecteur DVD de la VM avant son premier démarrage.
