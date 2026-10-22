# Variante 02 : un contrôleur de domaine Core + le modèle de tiering

On reprend la variante 01 et on va plus loin : le serveur devient **le premier contrôleur de domaine
d'une nouvelle forêt** `lab.local`, puis l'annuaire est **alimenté** par script selon le
**modèle d'administration en niveaux (tiering)**.

```
Windows 11 (hôte)
└── Hyper-V
    └── switch interne L02-Internal (192.168.102.0/24)
        └── L02-DC01  →  Windows : DC01, 192.168.102.10, AD DS + DNS, domaine lab.local
```

## Ce que vous apprenez ici

| Notion | Où la voir |
|--------|-----------|
| Promotion d'un DC en PowerShell (`Install-ADDSForest`) | `scripts/configure-dc01.ps1` |
| Changement d'identité après promotion (local → `LAB\Administrateur`) | `configure-dc01.ps1` |
| Modèle de tiering (Tier 0 / 1 / 2) | `scripts/New-LabTiering.ps1` (en-tête) |
| Création d'OU, groupes, comptes et ordinateurs en masse | `New-LabTiering.ps1` |
| Alimentation depuis un fichier CSV | `scripts/tiering-comptes.csv` |
| Retrouver un groupe intégré par son SID (Windows francisé) | `New-LabTiering.ps1`, partie 3 |

## Le déroulé automatique

`configuration.tf` lance `scripts/configure-dc01.ps1` sur l'hôte, qui pilote la VM par PowerShell Direct :

| Étape | Action | Compte utilisé |
|-------|--------|----------------|
| 1 | IP fixe 192.168.102.10, **DNS = 127.0.0.1**, nom DC01, redémarrage | `Administrateur` (local) |
| 2 | `Install-WindowsFeature AD-Domain-Services -IncludeManagementTools` | local |
| 3 | `Install-ADDSForest -DomainName lab.local -InstallDns` | local |
| 4 | Redémarrage, attente des Services Web AD (ADWS) | **`LAB\Administrateur`** |
| 5 | `New-LabTiering.ps1` : OU, groupes, comptes, ordinateurs | `LAB\Administrateur` |

Point à faire remarquer : lors de la création d'une forêt, le compte **local** `Administrateur` devient
l'administrateur **du domaine** (même mot de passe). Un contrôleur de domaine n'a plus de comptes locaux :
d'où le changement d'identifiant entre l'étape 3 et l'étape 4.

## Le modèle de tiering

Idée : ranger chaque ressource selon **ce qu'un attaquant gagnerait** s'il la compromettait.

| Tier | Contient | Exemples dans le LAB |
|------|----------|----------------------|
| **Tier 0** | Ce qui contrôle les identités de tout le SI | DC01, AD, PKI (`SRV-PKI01`) |
| **Tier 1** | Serveurs et applications | `SRV-FIC01`, `SRV-SQL01` |
| **Tier 2** | Postes de travail et utilisateurs | `PC-001`, `PC-002`, les utilisateurs |

**Règle d'or :** un compte d'un tier ne se connecte jamais sur une machine d'un tier inférieur.
Si un administrateur du domaine ouvre une session sur un poste infecté, l'attaquant récupère ses
identifiants (attaques *pass-the-hash*, Mimikatz...). Conséquence : **une personne = un compte par tier**.
Dans le CSV, Alice Martin a `t0-amartin` **et** `t1-amartin`.

### Arborescence créée

```
lab.local
├── Domain Controllers          (OU par défaut : DC01, Tier 0 de fait)
├── Tier 0
│   ├── Comptes admin           t0-amartin, t0-bleroy   (membres de Protected Users)
│   ├── Groupes                 GG_T0_Admins  →  membre de « Admins du domaine »
│   ├── Serveurs                SRV-PKI01
│   └── Comptes de service      svc-t0-sauvegarde
├── Tier 1
│   ├── Comptes admin           t1-amartin, t1-cdubois
│   ├── Groupes                 GG_T1_Admins_Serveurs
│   ├── Serveurs                SRV-FIC01, SRV-SQL01
│   └── Comptes de service      svc-t1-sql, svc-t1-web
└── Tier 2
    ├── Comptes admin           t2-cdubois, t2-dpetit
    ├── Groupes                 GG_T2_Admins_Postes, GG_T2_Support, GG_T2_Utilisateurs
    ├── Postes de travail       PC-001, PC-002
    ├── Comptes de service      svc-t2-deploiement
    └── Utilisateurs            ebernard, fmoreau, groux, hfournier
```

Les **OU** et les **groupes** sont décrits en tête de `New-LabTiering.ps1` ; les **comptes** viennent
de `tiering-comptes.csv` (séparateur `;`, ouvrable dans Excel, encodé en UTF-8). Le script est
**idempotent** : ajoutez une ligne au CSV, relancez `.\deploy.ps1`, seul le nouveau compte est créé
(la modification du CSV change son empreinte dans `triggers_replace`, ce qui relance la configuration).

> Tous les comptes ont le mot de passe du LAB `P@ssw0rd!`. Les OU sont protégées contre la
> suppression accidentelle (comportement par défaut, écrit explicitement dans le script).

## Déployer

Console PowerShell **en administrateur** :

```powershell
cd C:\VMS\terraform\02-ad-tiering
.\deploy.ps1
```

Durée indicative : 15 à 25 minutes (la promotion et le premier démarrage d'un DC sont longs).

## Vérifier

```powershell
Enter-PSSession -VMName L02-DC01 -Credential LAB\Administrateur
Get-ADDomain | Select-Object DNSRoot, NetBIOSName, DomainMode
Get-ADOrganizationalUnit -Filter * | Sort-Object DistinguishedName | Format-Table Name, DistinguishedName
Get-ADUser -Filter * -SearchBase 'OU=Tier 1,DC=lab,DC=local' | Format-Table Name, SamAccountName
Get-ADGroupMember GG_T0_Admins
Exit-PSSession
```

Le script peut aussi être relancé à la main dans le DC (après l'avoir copié) :
`.\New-LabTiering.ps1 -CsvPath .\tiering-comptes.csv -MotDePasse 'P@ssw0rd!'`.

## Ressources

| VM | vCPU | RAM démarrage / min / max | IP |
|----|------|----------------------------|----|
| DC01 | 2 | 1024 / 512 / 2048 Mo | 192.168.102.10 |

## Exercices possibles

- **Restreindre les connexions** (le cœur du tiering) : une GPO liée à `Tier 2\Postes de travail` qui
  **refuse l'ouverture de session** (« Interdire l'ouverture d'une session locale / par RDP ») à
  `GG_T0_Admins` et `GG_T1_Admins_Serveurs`. Même logique pour les serveurs Tier 1.
- **Déléguer** : donner à `GG_T2_Support` le droit de réinitialiser les mots de passe dans
  `Tier 2\Utilisateurs` (assistant de délégation, ou `dsacls`).
- **AGDLP** : ajouter des groupes de domaine local (`DL_...`) pour les droits sur les ressources.
- Remplacer les comptes de service par des **gMSA** (`New-ADServiceAccount`).
- Rediriger le conteneur par défaut des ordinateurs (`redircmp`) vers une OU dédiée.
