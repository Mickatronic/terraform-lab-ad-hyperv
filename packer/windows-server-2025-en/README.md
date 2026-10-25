# Windows Server 2025 Desktop Experience — version anglaise, clavier français

Image **avec interface graphique** (Desktop Experience), Windows **en anglais** (en-US) avec un **clavier AZERTY**.
Basée sur `../windows-server-2025-core-en` : utile pour les scripts écrits pour un Windows anglais
(noms de groupes `Domain Admins`, compte `Administrator`...), avec les consoles graphiques (ADUC, DNS, Gestionnaire de serveur).

| Fichier | Différence avec la version Core anglaise |
|---------|------------------------------------------|
| `answer_files/Autounattend.xml` | `/IMAGE/INDEX` = `4` (Datacenter Desktop Experience) au lieu de `3` (Core) |
| `scripts/02-updates-and-tools.ps1` | vérifie `InstallationType = Server` ; désactive l'ouverture auto du Gestionnaire de serveur |
| `variables.pkr.hcl` | `vm_name = ws2025-en-golden`, sortie `images\ws2025-en` |

Clavier : `InputLocale 040c:0000040c` (français AZERTY) dans `Autounattend.xml` (windowsPE + oobeSystem)
et dans `sysprep-unattend.xml` (premier démarrage des VMs déployées). Interface, formats et comptes restent en-US.

## Prérequis : un ISO ANGLAIS

Téléchargez l'ISO **Windows Server 2025 Evaluation, English (United States)** sur le Centre d'évaluation
Microsoft et enregistrez-le sous `C:\ISO\windows2025-en.iso` (le même que pour la version Core anglaise).

## Lancer le build

Console PowerShell **en administrateur** :

```powershell
C:\VMS\scripts\01-build-image-en.ps1
```

Résultat : `C:\VMS\images\ws2025-en\Virtual Hard Disks\ws2025-en-golden.vhdx`. Durée : 20 à 40 minutes.

Vérifier dans une VM : `(Get-CimInstance Win32_OperatingSystem).MUILanguages` (en-US attendu),
`Get-WinUserLanguageList` (clavier fr-FR attendu),
`(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').InstallationType` (`Server` attendu).
