# LAB IaC : Packer + Terraform + Hyper-V

Objectif : construire un LAB Active Directory (DC01 + SRV01) sur Hyper-V, de façon reproductible.

```
Windows 11 (hôte)
└── Hyper-V
    ├── DC01  - Windows Server 2025 + AD DS + DNS
    └── SRV01 - Windows Server 2025 membre du domaine
```

## Arborescence

```
C:\VMS
├── claude.md
├── README.md
├── .gitignore
├── scripts/                      # scripts PowerShell côté hôte
│   ├── 00-prereq-host.ps1        # vérifie/prépare l'hôte (Hyper-V, WinRM, outils)
│   ├── 01-build-image.ps1        # lance packer
│   └── 02-deploy.ps1             # lance terraform
├── packer/
│   └── windows-server-2025/
│       ├── windows-server-2025.pkr.hcl
│       ├── variables.pkr.hcl
│       ├── lab.auto.pkrvars.hcl.example
│       ├── answer_files/Autounattend.xml
│       └── scripts/              # scripts exécutés DANS la VM pendant le build
│           ├── 01-configure-winrm.ps1
│           ├── 02-updates-and-tools.ps1
│           └── 99-sysprep.ps1
├── terraform/
│   ├── versions.tf
│   ├── providers.tf
│   ├── variables.tf
│   ├── main.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
├── guest-scripts/                # configuration DANS les VMs déployées (étapes 3 à 6)
│   ├── dc01-install-adds.ps1
│   └── srv01-join-domain.ps1
└── images/                       # VHDX produits par Packer (ignorés par git)
```

## Le flux, étape par étape

| Étape | Outil | Ce qui se passe |
|-------|-------|-----------------|
| 1 | Packer | Boot sur l'ISO, `Autounattend.xml` installe Windows, scripts, sysprep, sortie : un VHDX « golden image » dans `images/` |
| 2 | Terraform | Crée le switch, copie le VHDX en un disque par VM, crée les VMs DC01 et SRV01 et les démarre |
| 3-4 | PowerShell | `dc01-install-adds.ps1` : renomme, installe AD DS + DNS, promeut le DC |
| 5 | PowerShell | Le domaine `lab.local` est créé par la promotion |
| 6 | PowerShell | `srv01-join-domain.ps1` : DNS vers DC01, jonction au domaine |

Pourquoi deux outils : **Packer fabrique l'image** (le « quoi installer »), **Terraform déploie les machines** (le « combien, avec quelles ressources »). Une image se construit une fois, on déploie ensuite autant de fois qu'on veut.

## Prérequis (hôte Windows 11)

1. Hyper-V activé, et votre session PowerShell lancée **en administrateur** (ou compte dans « Administrateurs Hyper-V »).
2. [Packer](https://developer.hashicorp.com/packer/install) et [Terraform](https://developer.hashicorp.com/terraform/install) dans le PATH (`winget install Hashicorp.Packer Hashicorp.Terraform`).
3. **Windows ADK (Deployment Tools)** : Packer a besoin de `oscdimg.exe` pour fabriquer le CD contenant `Autounattend.xml` (`cd_files`).
4. ISO Windows Server 2025 Evaluation (180 jours) téléchargée depuis le Centre d'évaluation Microsoft, à déposer dans `C:\ISO\`.
5. WinRM activé sur l'hôte pour le provider Terraform : `.\scripts\00-prereq-host.ps1`.

## Démarrage rapide

```powershell
# 1. Préparer l'hôte
.\scripts\00-prereq-host.ps1

# 2. Configurer les variables (copier les .example puis éditer)
Copy-Item packer\windows-server-2025\lab.auto.pkrvars.hcl.example packer\windows-server-2025\lab.auto.pkrvars.hcl
Copy-Item terraform\terraform.tfvars.example terraform\terraform.tfvars

# 3. Construire l'image
.\scripts\01-build-image.ps1

# 4. Déployer les VMs
.\scripts\02-deploy.ps1

# 5. Détruire le LAB quand on a fini
cd terraform; terraform destroy
```

## Sécurité (LAB uniquement)

Les mots de passe par défaut, WinRM en HTTP/Basic non chiffré et l'évaluation Windows sont acceptables pour un LAB isolé. Les `*.tfvars`, `*.pkrvars.hcl` et le state Terraform sont dans `.gitignore` : ils contiennent des secrets.

## Pistes de progression

- Remplacer WinRM HTTP par HTTPS + certificat.
- Faire exécuter `guest-scripts/` par Terraform (`provisioner "remote-exec"` / `winrm`) ou par un second build Packer.
- Passer à un module Terraform `vm` réutilisable.
- Ajouter un client Windows 11 joint au domaine, GPO, OUs via PowerShell/DSC.
