# Variante 04 : la 02 en version démo

Même résultat que la variante 02 (DC01 Core, forêt `lab.local`, OU Tier 0/1/2), écrit en version « rapide » :
un seul `main.tf`, un seul script `dc01.ps1`, tout en dur, pas de module, presque pas de commentaires.

```
04-ad-demo/
├── main.tf        # switch + disque + VM + terraform_data qui lance dc01.ps1
├── variables.tf   # seulement le compte de l'hôte (valeurs dans terraform.tfvars)
├── dc01.ps1       # IP, nom, AD DS, forêt, OU de tiering
└── versions.tf, providers.tf, terraform.tfvars
```

## Lancer

Console PowerShell **administrateur** :

```powershell
cd C:\VMS\terraform\04-ad-demo
terraform init
terraform apply
```

VM `L04-DC01`, IP `192.168.104.10`, connexion : `Enter-PSSession -VMName L04-DC01 -Credential LAB\Administrateur`.

## Ce qu'on a sacrifié par rapport à la 02

- **Pas relançable** : si le script échoue au milieu, on repart de zéro (`terraform destroy` puis `terraform apply`).
- Pas de CSV : les comptes sont dans le script.
- Valeurs en dur (nom, IP, mot de passe) au lieu de variables Terraform.
- Peu d'affichage : en cas de problème, la 02 est bien plus facile à déboguer.

C'est justement une bonne base de discussion avec les apprenants : comparer `04` et `02` pour voir ce que
coûtent (et rapportent) les variables, l'idempotence et les logs.
