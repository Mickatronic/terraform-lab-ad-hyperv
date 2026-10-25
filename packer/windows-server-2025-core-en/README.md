# Windows Server 2025 Core — version anglaise, clavier français

Copie de `../windows-server-2025-core` pour obtenir un Windows **en anglais** (en-US) avec un **clavier AZERTY**.
Utile pour les scripts écrits pour un Windows anglais (noms de groupes `Domain Admins`, compte `Administrator`...).

| Fichier | Différence avec la version française |
|---------|--------------------------------------|
| `answer_files/Autounattend.xml` | langues `en-US`, clavier `040c:0000040c` (français), AutoLogon `Administrator` |
| `answer_files/sysprep-unattend.xml` | idem pour le premier démarrage des VMs déployées |
| `variables.pkr.hcl` | ISO `windows2025-en-noprompt.iso`, sortie `images\ws2025-core-en` |
| `windows-server-2025-core-en.pkr.hcl` | `winrm_username = "Administrator"` |

## Prérequis : un ISO ANGLAIS

L'ISO français ne contient que la langue française : on ne peut pas en tirer un Windows anglais.
Téléchargez l'ISO **Windows Server 2025 Evaluation, English (United States)** sur le Centre d'évaluation
Microsoft et enregistrez-le sous `C:\ISO\windows2025-en.iso`.

## Lancer le build

```powershell
.\scripts\01-build-image-core-en.ps1
```

Résultat : `C:\VMS\images\ws2025-core-en\Virtual Hard Disks\ws2025-core-en-golden.vhdx`
(les images françaises ne sont pas touchées). Utilisée par `terraform\05-ad-en`.

Vérifier dans une VM : `Get-WinSystemLocale`, `Get-WinUserLanguageList` (clavier fr-FR attendu),
`(Get-CimInstance Win32_OperatingSystem).MUILanguages` (en-US attendu).
