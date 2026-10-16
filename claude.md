# CLAUDE.md

## Contexte

Je suis formateur en BTS SIO SISR et administrateur systèmes et réseaux.

Ce projet me sert à monter en compétence sur l'Infrastructure as Code autour de :

- Packer
- Terraform
- Hyper-V
- Windows Server
- Active Directory
- PowerShell

Mon environnement de LAB est un PC Windows 11 avec Hyper-V installé directement dessus.

## Objectif technique

Construire progressivement un LAB permettant de :

1. Créer une image Windows Server avec Packer
2. Déployer une VM Hyper-V avec Terraform
3. Configurer automatiquement Windows Server
4. Installer AD DS et DNS
5. Créer un domaine Active Directory
6. Ajouter ensuite d'autres serveurs ou clients au domaine

Architecture cible :

Windows 11
└── Hyper-V
    ├── DC01 - Windows Server + AD DS + DNS
    ├── SRV01 - Windows Server membre

## Méthode de travail

Je veux comprendre ce que je fais, pas seulement obtenir du code fonctionnel.