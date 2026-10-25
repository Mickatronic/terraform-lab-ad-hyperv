# Variante 05 : contrôleur de domaine Core en anglais (clavier français)

La variante 02, mais sur un Windows Server **en anglais** (en-US) avec un **clavier AZERTY**.
Objectif : faire tourner des scripts écrits pour un Windows anglais, comme le script de tiering
Microsoft publié sur GitHub, qui attend `Administrator`, `Domain Admins`, `Enterprise Admins`...

```
Windows 11 (hôte)
└── Hyper-V
    └── switch interne L05-Internal (192.168.105.0/24, NAT vers Internet par 192.168.105.1)
        └── L05-DC01  →  Windows (en-US) : DC01, 192.168.105.10, AD DS + DNS, domaine lab.local
```

## Différences avec la 02

| Élément | 02 | 05 |
|---------|----|----|
| Image | `images\ws2025-core` (français) | `images\ws2025-core-en` (anglais, clavier FR) |
| Compte | `Administrateur` / `LAB\Administrateur` | `Administrator` / `LAB\Administrator` |
| Groupes intégrés | `Admins du domaine`... | `Domain Admins`... |
| Notre tiering (`New-LabTiering.ps1`) | créé | **désactivé par défaut** (`create_tiering = false`) |
| Réseau | 192.168.102.0/24 | 192.168.105.0/24 |

Le tiering maison est désactivé pour laisser une forêt « propre » au script Microsoft (les deux créeraient
des OU « Tier 0/1/2 » concurrentes). Pour l'activer quand même : `create_tiering = true` dans `terraform.tfvars`.

## Étape 1 : construire l'image anglaise (une seule fois)

1. Télécharger l'ISO **Windows Server 2025 Evaluation, English (United States)** sur le Centre
   d'évaluation Microsoft, l'enregistrer sous `C:\ISO\windows2025-en.iso`.
2. Console administrateur :
   ```powershell
   C:\VMS\scripts\01-build-image-core-en.ps1
   ```
   Résultat : `C:\VMS\images\ws2025-core-en\Virtual Hard Disks\ws2025-core-en-golden.vhdx`.
   Le template est dans `C:\VMS\packer\windows-server-2025-core-en` (voir son README).

## Étape 2 : déployer

```powershell
cd C:\VMS\terraform\05-ad-en
.\deploy.ps1
```

## Vérifier

```powershell
Enter-PSSession -VMName L05-DC01 -Credential LAB\Administrator
(Get-CimInstance Win32_OperatingSystem).MUILanguages   # en-US
Get-WinUserLanguageList                                # clavier fr-FR (040C:0000040C)
Get-ADGroup 'Domain Admins'                            # nom anglais
```

## Étape 3 : lancer le script de tiering Microsoft

Copier le script dans la VM depuis l'hôte, puis l'exécuter dans la session :

```powershell
$s = New-PSSession -VMName L05-DC01 -Credential LAB\Administrator
Copy-Item .\<script-tiering>.ps1 -Destination C:\ -ToSession $s
Enter-PSSession $s
C:\<script-tiering>.ps1
```

Avec le NAT, la VM a Internet : on peut aussi télécharger le script directement depuis GitHub dans la VM.
