### **Administration avancée des services d'infrastructure** Titre de la formation **Windows et** **~~auto~~ matisation** 

Page 1 

**V3.2 Novembre 2024** 

**Partie 1 : Introduction** Titre de la formation 

Page 2 

P01 

C01 

**Chapitre 1 : Introduction** Titre de la formation 

Page 3 

#### **L’administrateur système Windows: les missions** 

Administrer et assurer la Automatiser la disponibilité de configuration services des réseaux et environnement services s utilisateurs 

Titre de la formation 

Page 4 

Intégrer des éléments de Assurer la sécurité dans supervision les des serveurs et infrastructure des services s 

Titre de la formation 

## **Partie : Sécurisation des serveurs Windows** 

Page 7 

P02 

Titre de la formation 

## **Chapitre 2 : Surface d’attaque et hardening** 

Page 8 

C27 

#### **Un annuaire livré ouvert, pas fermé** 

Active Directory a été conçu en 1999 pour faire fonctionner ensemble des systèmes qui ne se ressemblaient pas. 

- Ses valeurs par défaut privilégient la compatibilité 

- Elles n'ont jamais été resserrées, pour ne rien casser 

Titre de la formation 

- Aucune des mesures de ce module ne corrige une faille : elles ferment des portes laissées ouvertes 

Page 9 

#### **Pourquoi durcir un environnement AD** 

Un domaine Active Directory est la cible n°1 d'un attaquant : compromettre un contrôleur de domaine, c'est compromettre tout le système d'information. 

- La plupart des attaques exploitent des réglages par défaut, pas des failles 0-day 

- Objectif : réduire la surface d'attaque et ralentir la latéralisation 

Titre de la formation 

- 13 mesures concrètes, rapides à mettre en œuvre et à démontrer en lab 

Page 10 

#### **Les 5+1 parties du module** 

##### Titre de la formation 

Page 11 

###### 1. Cloisonner 

- Comptes séparés, modèle en tiers, Windows LAPS 

   4. Refermer les défauts 

- Quota machine, Pré-Windows 2000, spouleur 

2. Protéger les secrets 

###### 3. Couper NTLM 

   - LLMNR, IPv6, LmCompatibilityLe vel, signature SMB 

- Mise en cache, NTLM, Kerberos, Protected Users 

6. Améliorer la 

5. Rester 

réversible disponibilité, la résilience et 

► Corbeille AD, l’auditabilité protection contre la suppression ► DNS, DHCP, DFS, 

   - DNS, DHCP, DFS, 

P01 

**Chapitre 1 — Sécuriser les comptes et l'administration -** Titre de **LAPS** la formation 

Page 13 

#### **Problème : La sécurité des comptes locaux** 

Mastering et sécurité des comptes 

- Un technicien connaît le mot de passe de tous les postes 

- Un attaquant récupère le mot de passe sur un poste 

- Mouvement latéral (Lateral Movement) 

- Pass-the-Hash 

- Compromission de tout le parc 

Titre de la formation 

Page 14 



P C - 0 1 

C o m p t e lo c a l : A d m i n M d p : W 2 k Q f M $ d H m 



P C - 0 2 

C o m p t e lo c a l : A d m i n M d p : W 2 k Q f M $ d H m 



P C - 0 3 C o m p t e lo c a l : A d m i n M d p : W 2 k Q f M $ d H m 

#### **Solution : Windows LAPS** 

- Gère automatiquement le mot de passe du compte administrateur local de chaque machine. 

- ► Mot de passe unique, complexe et renouvelé régulièrement, par machine 

- Stocké de façon chiffrée dans Active Directory (ou Entra ID) 

- Bloque la latéralisation par mot de passe admin local identique (Pass-the-Hash) 

Titre de la formation 

- Intégré nativement à Windows Server 2025 et Windows 11 

Page 15 

## **Démonstration** 

Titre de la formation 

Page 16 

#### **Ce qu’il faut retenir** 

- LAPS permets de gérer les mots de passe locaux; 



- LAPS dans windows serveur 2025 est presque natif. 

##### Titre de la formation 

- Les mots de passes des comptes locaux sont accessible et chiffrer dans Active Directory ou Entra ID 

Page 17 

P01 

**Chapitre 2 — Sécuriser les comptes et l'administration -** Titre de **Protecteduser** la formation 

Page 18 

#### **Le problème des comptes utilisateurs** 

   - La configuration classique des comptes utilisateurs lèves plusieurs problèmes : 

- Un compte à privilèges finit toujours par ouvrir une session quelque part 

- Dès cette seconde, son secret est déposé dans la mémoire de la machine 

- L’accès à un service peut également amener l’usage de protocole fragile (ex : NTLM Kerberos avec RC4/DES) 

##### Titre de la formation 

- Des autorisations Kerberos avec des tickets TGT de longue durée ; 

Page 20 

#### **Ce qu'impose Protected Users** 

Titre de la formation 

###### Côté machine 

- Plus de NTLM, de Digest ni de CredSSP 

- Aucune mise en cache hors connexion 

###### Côté contrôleur 

- Kerberos en AES uniquement 

- Ni RC4, ni DES 

###### Sur la durée 

- TGT limité à 4 heures 

- Non renouvelable, aucune délégation 

Page 21 

#### **Les précautions à prendre** 

Titre de la formation 

Page 22 

###### Ne jamais y mettre 

- Les comptes de service 

- krbtgt et les comptes d'ordinateur 

- Garder un compte administrateur hors protected 

###### Vérifier d'abord 

- Que Kerberos fonctionne partout 

- Les accès par adresse IP ou alias cassent 

###### Prérequis 

- Niveau fonctionnel de domaine 2012 R2 

- Clients Windows 8.1 ou 2012 R2 au minimum 

## **Démonstration** 

Titre de la formation 

Page 23 

#### **Ce qu’il faut retenir** 

- ProtectedUser n’empêche pas le vol des secrets : il réduit ce qu’il y a à voler et sa capacité d’exploitation 

##### Titre de la formation 

- Un compte ProtectedUser nécessite obligatoirement l’accès au domaine durant l’authentification 

- ProtectedUser est à réserver aux comptes utilisateurs à privilèges 

- Garder un compte break glass 

Page 24 

# **Chapitre 3 — Hardening : les** Titre de **indispensables** la formation Page 25 P01 

#### **Les blocs de sept** 

Titre de la formation 



<!-- Start of picture text -->
Page 26<br><!-- End of picture text -->

MachineAccountQuota = LLMNR et NBT-NS 0 Désactivé Groupe « Pré-Windows LmCompatibilitéLevel 5 2000 » Corbeille AD et Signature SMB et LDAP Protection contre la exigée suppression Gérer l’IPv6 

**Supprimer les droits d’un utilisateur d’ajouter des ordinateurs au domaine** 

Titre de la formation 

Page 27 



<!-- Start of picture text -->
WB Modification ADSI - a x<br>Fichier Action Affichage ? | Propriétésde : DC=demo,DC=lan ? x<br>‘oo aGixGGS . se<br>Yj Contexted’attributiondeno||  Atibuts:<br>> DCedemo,DC=lan)Fi true Valeur ;<br>modfiedCountAtLastProm =O tres actions » findows<br>msDS-AlUsers TrustQuota 1000<br>msDS-Behavior-Version 10 = (WIN2025)<br>msDS-CloudAnchor non défini><br>j mS-DSConsistencyGuid non défini> Editeur d’attributs de type Entier x<br>msDS-EnabledFeature non défini><br>msDS-ExpirePasswordsOnSm.... TRUE Attrbut : ms-DS-MachineAccountQuota<br>msDS-LastKnownRDN non défini> Valeur :<br>msDS-LogonTimeSyncinterval _<non défini> dq<br>ms-DS-MachineAccountQuota 10 ————<br>msDS-NeType 0<br>ree eeoa «ven défni> __ Bacer (0KJ ener<br><!-- End of picture text -->

#### **LmCompatibilitéLevel 5** 

Configuration ordinateur > Paramètres Windows > Paramètres de sécurité > Stratégies locales > Options de sécurité > Sécurité réseau : niveau d'authentification LAN Manager 

##### Titre de la formation 

Page 28 



<!-- Start of picture text -->
AZ} Editeur de gestion des stratégies de groupe - o x<br>eer Act = : Propriétésde : Sécurité réseau : niveau d'authentificati 2 x<br>¢9\ a) xO8/\a : : ion.<br>Uy Stratégie Sécurté-Authentification [AD.DEMO. || strategie * Paramétrede stratégie de sécurté Expliquer<br>Configuration. Oe ordinateurdu logiciel [DyDy  SécuritéSécurité desréseauréseaux:: conditions exigencesrequisesen matiérepour la de signature chiffrement de clientdu client LDAP 3 ‘Sécurté réseau : niveau d authenticationLAN Manager<br>a PoeveteeGulegice G Sécurité réseau : forcer la fermeture de session quand les horaires de<br>> [Gi Stratégiede résolution de noms (@ SécuritéréseauSturn:: niveau d'authentification LAN Manager @ Défini ce paramétre de stratégie<br>[B Scripts (démarrage/arrét) Q ut sen minal p ouror css bad<br>vy Paramétresde sécurité 2) Sécurité réseau : sécurité de session minimale pour les serveurs basés La modtication de ce XE doveckes<br>> Bi Strategiesde co (E) Sécurité réseau : Autoriser le retour & des sessions NULL avec Systéme dK. cers,les services et es applications. a<br>vj Stratégies locales Sécurité réseau : autoriser les demandes d’authentification PKU2U Fae ee Ne Oo<br>> Gl Stratégie d’audit [D) Sécurité réseau: Autoriser Systéme local 8 utiliser 'identité de l'ordin. :<br>> Gj Attributiondes droits uti | |} ij Sécurité réseau : Configurer les types de chiffrement autorisés pour:<br>> [Gj Options de sécurité] | Sécurité réseau : Restreindre NTLM : Ajouter des exceptions de ser<br><!-- End of picture text -->

Cette valeur permet d'indiquer des réponses _NTLMv2_ seulement et refuse _LM_ et _NTLM_ . 

**5** 

###### **LLMNR et NetBIOS (NBT-NS) les mécanismes de secours du DNS.** 

LLMNR et NetBIOS sont des mécanismes de secours du DNS 

- LLMNR et NetBIOS servent à retrouver une adresse IP lorsque le DNS échoue. 

- NetBIOS (NBT-NS) est l'ancien mécanisme historique de Windows (UDP 137). 

- LLMNR est son remplaçant plus récent, compatible IPv4 et IPv6 (UDP 5355). 

- Tous deux envoient une requête sur le réseau : « Qui s'appelle SERVEUR01 ? ». 

##### Titre de la formation 

- Un attaquant peut répondre à la place du vrai serveur et récupérer des authentifications NTLM. 

Page 29 

#### **LLMNR et NBT-NS Désactivé** 

Configuration ordinateur > Paramètres Windows > Paramètres de sécurité > Stratégies locales > Options de sécurité > Sécurité réseau : niveau d'authentification LAN Manager 

Titre de la formation 

Page 30 

#### **La corbeille AD** 

##### Titre de la formation 

Page 31 



<!-- Start of picture text -->
Bi Centre d’administration Active Directory<br>Recréer != restaurer © Desktop Experience ~ Centre d’administration Activ<br>Récupération d’un  ► GUI complète<br>By: Centre d’adminis.... < demo (local) (18)<br>utilisateur/objet<br>► Plus de composants =<br>Conservation des  EB Vue d’ensemble plus de failles<br>attributs et  Ill demo (ome rn y<br>appartenances lean: ► Utile en  Modifier le contréleurdedomaine<br>environnement de  Augmenter le niveau fonctionnel de la forét...<br>= |<br>Non activé par défaut Mm Authenti{ ——_ test Augmenter le niveau fonctionnel du domaine...<br>5) Recherch Activer la Corbeille...<br>N’est pas désactivable Nouveau L<br>Rechercher sous ce noeud<br>Po stes TACHES Vv SECTIONS ¥<br>Unité dorganisation Unité dorganisation D®A<br>Géréwoes Nom Postes Description<br>Extensions Adresse<br>“<br>| Protéger contre la suppression acciden...<br><!-- End of picture text -->



<!-- Start of picture text -->
Recréer != restaurer<br><!-- End of picture text -->

- Récupération d’un utilisateur/objet 

- ► Conservation des attributs et appartenances 

- Non activé par défaut 

- N’est pas désactivable 

**Groupe Pré-Version Windows 2000** **_Un groupe de compatibilité devenu une porte dérobée_** 

##### Titre de la formation 

###### Son rôle d'origine 

- Permettre à Windows NT 4.0 de lire l'annuaire 

- Créé à l'installation du domaine 

- Plus aucun usage légitime aujourd'hui 

###### Son contenu 

- Parfois « Tout le monde » ou « Connexion anonyme » 

- La lecture anonyme de l'annuaire redevient possible 

- Utilisateurs, groupes, descriptions : tout se lit 

Page 32 

## **Démonstration** 

Titre de la formation 

Page 33 

#### **Ce qu’il faut retenir** 



- Un utilisateur classique peut par défaut ajouter 10 ordinateurs dans le domaine. 

- NTLMv2 est à exiger ou à éviter. 

##### Titre de la formation 

- Désactiver les requêtes de multidiffusion LLMNR et NBT-NS ; 

- Limiter les groupes présents dans groupe preversion windows. 

Page 34 

**Chapitre 4 — Sécurité et IPv6** Titre de la formation 

Page 35 

P01 

#### **IPv6 est là, même si vous ne l'utilisez pas** 

Titre de la formation 

- Activé par défaut 

- ► Sur toutes les versions depuis Windows Vista 

- Et préféré à IPv4 pour toute résolution 

- Rarement configuré, jamais supervisé 

###### Personne ne le sert 

- Aucun serveur DHCPv6 légitime sur le réseau 

- ► Les postes sollicitent dans le vide, en permanence 

- La place est libre pour celui qui répond 

Page 36 

#### **MITM6 : du silence IPv6 à l'administrateur du domaine** 

##### Titre de la formation 



**5.  L'authentification NTLM part vers lui, puis est relayée vers LDAP** 

**1.  Les postes émettent des sollicitations DHCPv6 — personne n'y répond jamais** 



**2.  L'attaquant y répond et devient leur serveur DNS IPv6** 

Page 37 

**4. Il répond à la 3.  IPv6 étant requête WPAD : préféré à IPv4, le proxy du toute résolution poste, c'est lui passe par lui** 

###### **Pourquoi le MITM marche ici ?** 

- IPv6 est actif par défaut sur Windows 

- Il est préféré à IPv4 pour toute résolution 

- Aucun serveur DHCPv6 légitime ne répond 

- Personne ne surveille ce trafic 

Titre de la formation 

- **Désactiver IPv6 n'est pas la réponse préconisée par Microsoft.** 

Page 38 

#### **Maîtriser, pas désactiver** 

Titre de la formation 

- Ne pas désactiver 

- ► La pile Windows n'est pas prise en charge sans IPv6 

- Désactiver crée d'autres pannes 

Sur le réseau 

- RA Guard et DHCPv6 Guard sur les commutateurs 

- Filtrer UDP 546 et 547 entre postes 

Page 39 

#### **Protection contre les attaques MITM6** 

Comment empêcher un poste utilisateur de se faire passer pour un routeur ou un serveur DHCPv6 légitime ? 

Titre de la formation 

Page 40 

```
SW1(config)#ipv6 nd raguard policy RA-GUARD-HOST
SW1(config-nd-raguard)#device-role host
SW1(config-nd-raguard)#exit
```

```
SW1(config)#interface range GigabitEthernet0/1 - 20
SW1(config-if-range)#ipv6 nd raguard attach-policy
RA-GUARD-HOST
```

##### Titre de la formation 

Page 41 

#### **Ce qu’il faut retenir** 



- Microsoft recommande de laisser IPv6 activé. 

- IPv6 ne protège pas des attaques MITM par défaut 

- IPv6 est par défaut préféré par rapport à IPv4 même si aucune configuration n’est réalisée. 

- La sécurité d’IPv6 doit être prise en compte en partie par les commutateurs. 

**Chapitre 5 — Tiering Modele** Titre de la formation 

Page 42 

P01 

#### **Un compte, tous les pouvoirs** 

##### Titre de la formation 

Ce que l'on observe 

- Un seul compte pour le mail, le web et l'administration 

- Souvent membre d'« Admins du domaine » 

- Session ouverte en permanence sur le poste de travail 

Pourquoi c'est grave 

- Le poste bureautique est la cible la plus exposée 

- Une macro, un faux installeur, et le secret est volé 

- Aucun palier : on passe de rien à tout 

Page 43 

#### **Le chemin d'une seule erreur** 

Titre de la formation 

**m.dupont** 

un seul compte, membre de **« Admins du domaine »** 



**Messagerie et navigation web** ouverte toute la journée 

**Serveurs d'application** administration courante 

**Contrôleurs de domaine** le cœur de l'annuaire 

Page 44 

**Une seule pièce jointe ouverte sur ce poste, et les trois périmètres tombent ensemble.** 

#### **Le chemin d'une seule erreur** 

##### Titre de la formation 

Page 45 

**mdupont** 

compte bureautique 

**Peut ouvrir une session sur** 

- Poste de travail 

- Messagerie, Internet 

- Applications métier 

**Jamais** Aucun droit d'administration 

**admmdupont** administration des serveurs 

**Peut ouvrir une session sur** 

- Serveurs membres 

- Consoles administration 

- Jamais « admins du domaine » 

**Jamais** Jamais sur un poste ni sur un DC 

**da-mdupont** administration du domaine 

###### **Peut ouvrir une session sur** 

- Contrôleurs de domaine 

- Depuis un poste dédié 

- Usage exceptionnel **Jamais** Jamais de messagerie ni de web 

**Trois mots de passe, trois sessions : compromettre l'un ne donne pas les deux autres.** 

# **Partie 2 — Durcir l'annuaire** Titre de **Active Directory** la formation Page 47 P02 

#### **La surface d’attaque** 

La surface d’attaque / d’exposition désigne l’ensemble **<u>des points d’entrée</u>** potentiels par lesquels **<u>un attaquant</u>** pour accéder à un système, à un réseau ou même à des données afin de provoquer une ou plusieurs actions malveillantes. 

##### Titre de la formation 

Page 49 



<!-- Start of picture text -->
t=O<br><!-- End of picture text -->



<!-- Start of picture text -->
te<br><!-- End of picture text -->



<!-- Start of picture text -->
[<br><!-- End of picture text -->



<!-- Start of picture text -->
sg<br><!-- End of picture text -->

#### **Réduire la surface d'attaque** 

- Chaque service, port, rôle actif est un vecteur potentiel 

- ► Principe : n'installer que le strict nécessaire (Server Core) 

##### Titre de la formation 

Page 50 

#### **Server Core vs Desktop Experience** 

Titre de la formation 

- Server Core 

- ► Pas d'interface graphique 

- Surface d'attaque réduite 

- Administration à distance 

Desktop Experience 

- GUI complète 

- Plus de composants = plus de failles 

- Utile en environnement de test 

Page 51 

#### **PC** 

Titre de la formation 

Page 52 



<!-- Start of picture text -->
Bi] Policy Viewer- 390 items = Oo x<br>© Clipboard» View> ffyy Export> Options+<br>Policy Type Policy Group or Registry Key Policy Setting Baseline(s) Effective state<br>JAudit Policy __——|Accés al'obiet_ =| Audterle partacedefichiersdétallé<br>JAudit Policy _——|Accés al'obiet_ = |Auditerlepatacedefichies<br>JAudit Policy |Accés al'obiet_ =| Audterle stockage amovble<br>JAudt Policy |AccésDS_ | Asdterl'accés auserviced’anmuaire<br>|Audit Policy __(|Chanaement de stratéaie __—_| Auditerla modification de stratéaie d'authentfication = Succés = Succés<br>|Audt Policy _—(|Gestion ducomote | Audterla gestion des cometes d'ordinateur = Succes | Succes<br>|Audt Policy _—_—(|Gestionducompte =| Audterla gestion desqrounes desécuté = Succes | Succes<br>|Audt Policy _—_—‘|Ouvrirfemerla session _—_—| Audterouverture de session spécidle = Succes | Succes<br>Policy Path:<br>Configuration avancée de la stratégie d’audit<br>Stratégies d’audit du systéme\Accés 4 l'objet<br>Auditer d'autres événements d'accés 4 l'objet<br>Autres événements daccés 4 l objet<br>Ce paraméde s t ratégiere vous permet d auditer les événements générés par la gestion des travaux du Planificateur de taches ou des objets COM+.<br><!-- End of picture text -->

**Chapitre 1 : Fondamentaux et résolution DNS** Titre de la formation 

Page 53 

P01 

#### **Le rôle du DNS** 

Un annuaire distribué nom ↔ adresse 

- Traduit les noms de domaine (faciles à mémoriser) en adresses IP (utilisées par les machines) 

Titre de la formation 

- Objectif : découpler l'identité d'un service de sa localisation réseau (IP), qui peut changer 

- Hiérarchique et distribué : aucune base ne contient toutes les données mondiales 

Page 54 

#### **Quelques bonnes pratiques en matières de conception d’infrastructure DNS** 

Le Split-Brain DNS permet de fournir des réponses DNS différentes pour un même nom selon l'origine de la requête, tout en respectant le principe de cloisonnement recommandé par l'ANSSI entre les services DNS internes et externes 

- Séparer les services DNS internes et externes ; 

- Cloisonner les infrastructures DNS ; 

- Eviter les dépendances entre DNS internes et DNS exposés à Internet ; 

##### Titre de la formation 

Page 55 

- Obtenir des architectures distinctes pour la résolution interne et l'hébergement externe des zones DNS. 





#### **Les grandes parties des infrastructures DNS** 

Titre de la formation Page 56 

Le résolveur 

Le clients DNS 

Le forwardeur 

Le serveur de cache 

Les serveurs racines 

Les serveurs TLD 

Les serveurs autoritaires (primaire/secondaire) 

#### **Forwarders vs Root Hints** 

Titre de la formation 

Forwarder 

- Toutes les requêtes externes sont déléguées à un serveur unique 

- Simple à administrer, contrôle centralisé du flux sortant 

###### Root Hints 

- Le serveur explore lui-même la hiérarchie racine → TLD → autorité 

- ► Autonomie totale, aucune dépendance à un tiers 

Page 57 

#### **Forwarder conditionnel** 

Router la résolution selon le domaine demandé 

- Un domaine précis (ex. partenaire.fr) est envoyé vers un serveur DNS spécifique 

- Cas d'usage typique : relations B2B, environnements hybrides, domaines Azure/365 

- Les autres requêtes suivent le forwarder par défaut ou les Root Hints 

Titre de la formation 

Page 58 

#### **Schéma d’infrastructure globale** 

##### Titre de la formation 

Page 59 

C li e n t D N S 

D N S - 0 1 R é s o l v e u r I n t e r n e 

D N S - 0 2 R é s o l v e u r I n t e r n e R é p l ic a ti o n H A 

Résolutio n récursive 

U n b o u n d F o r w a r d e u r D N S p u b l i c C a c h e D N S 1 . 1 . 1 . 1 9 . 9 . 9 . 9 8 . 8 . 8 . 8 





S e r v e u r R a c in e a . r o o t - s e r v e r . n e t 



S e r v e u r T L D e . n i c . f r 



S e r v e u r a u t o r i t a ir e P r i m a i r e / S e c o n d a i r e 

#### **TTL et cache DNS** 

- Le cache existe à plusieurs niveaux 

- ► Cache client (résolveur du poste), cache du résolveur récursif, cache applicatif 

- Un TTL mal dimensionné retarde la propagation d'un changement (ex. bascule d'IP) 

Titre de la formation 

Page 61 

#### **Jeu de commandes — forwarders** 

Configuration des forwarders 

- Set-DnsServerForwarder -IPAddress 8.8.8.8,1.1.1.1 

- Get-DnsServerForwarder 

Titre de la formation 

- Add-DnsServerConditionalForwarderZone -Name partenaire.fr -MasterServers 198.51.100.10 

- Get-DnsServerZone | Where ZoneType -eq 'Forwarder' 

Page 62 

#### **Jeu de commandes — diagnostic de résolution** 

###### Commandes essentielles 

- Resolve-DnsName monsite.fr -Type A 

Titre de la formation 

- nslookup -debug monsite.fr 

- ipconfig /displaydns   |   ipconfig /flushdns 

- Clear-DnsClientCache 

Page 63 

#### **Mise à jour dynamique (Dynamic Update)** 

   - Trois modes possibles sur une zone intégrée à AD 

- Sécurisée uniquement : seuls les clients/ordinateurs authentifiés du domaine peuvent enregistrer 

- Non sécurisée et sécurisée : accepte aussi les mises à jour non authentifiées (déconseillé) 

- Aucune : les enregistrements doivent être créés manuellement 

##### Titre de la formation 

Page 64 



**Cycle de vieillissement et de nettoyage (Aging / Scavenging)** 

Titre de la formation 

Page 65 



<!-- Start of picture text -->
Enregistrement No eee y Fin du Eligible au<br>créé / actualisé Interval Refresh Interval scavenging<br>(timestamp posé) (7 j par défaut) (7 j par défaut) (supprimé)<br>No-Refresh Interval Refresh Interval<br>(les actualisations sont ignorées) (les actualisations sont acceptées)<br>Régle<br>Un enregistrement dynamique non réactualisé pendant No-Refresh + Refresh Interval devient éligible<br>au scavenging. Le nettoyage automatique doit étre activé sur le serveur ET sur la zone.<br><!-- End of picture text -->

#### **Jeu de commandes — aging & scavenging** 

###### Activation et pilotage 

- Set-DnsServerZoneAging -Name entreprise.fr -Aging $true -NoRefreshInterval 7.00:00:00 -RefreshInterval 7.00:00:00 

Titre de la formation 

- Set-DnsServerScavenging -ScavengingState $true -ScavengingInterval 7.00:00:00 

- Start-DnsServerScavenging 

Page 66 

- Get-DnsServerScavenging 

#### **Ce qu’il faut retenir** 

- Le DNS traduit des noms en adresses IP de façon hiérarchique et distribuée 

- Forwarder = simplicité et point de sortie unique ; Root Hints = autonomie complète 



- Le TTL pilote l'équilibre entre fraîcheur des données et charge réseau 

Le forwarder conditionnel route la résolution en fonction du domaine demandé 

##### Titre de la formation 

Page 68 

La mise à jour dynamique sécurisée est la configuration recommandée en environnement AD 

- Un enregistrement non réactualisé pendant NoRefresh + Refresh Interval devient éligible au scavenging 

# **Chapitre 3 : Zones,** Titre de **délégation et stub zones** la formation Page 69 P03 

#### **A / AAAA vs CNAME (Alias)** 

##### Titre de la formation 

A / AAAA 

- Pointe directement vers une adresse IPv4 / IPv6 

- Résolution en une seule étape 

###### CNAME (Alias) 

- Pointe vers un autre nom de domaine, qui est ensuite résolu 

- Pratique pour faire évoluer la cible sans toucher les clients 

Page 70 

srv-web01.entreprise.local rh.entreprise.local web01.entreprise.local site.entreprise.local web01.entreprise.local 

A 10.10.10.50 CNAME srvCNAME srv- 

#### **PTR, SOA/NS** 

Titre de la formation 

- PTR 

- ► Pointe une IPv4/v6 directement vers une adresse un FQDN. 

- Résolution en une seule étape mais inversée 

SOA/NS 

- Détermine le/les serveurs faisant autorité 

- Détermine les métadonnées 

Page 71 

#### **Types de zones DNS (par mécanisme)** 

Zone secondaire 

Titre de la formation 

Page 72 

- Zone primaire 

- ► Copie maîtresse, accepte les écritures 

- Zone intégrée à AD 

- ► Stockée dans Active Directory, réplication multimaître 

- Copie en lecture seule, mise à jour par transfert de zone (AXFR/IXFR) 

###### Zone stub 

- Ne contient que SOA, NS et les enregistrement s glue (A) 

#### **Types de zones DNS (par rôle)** 

Zone de recherche directe 

- Résout nom → adresse IP (A / AAAA) 

Zone de recherche inversée 

- Résout adresse IP → nom (PTR), zone inaddr.arpa 

Titre de la formation 

Page 73 

Zone GlobalNames 

- Alias courts à l'échelle de la forêt, sans suffixe 

###### Zone de stub 

- Copie légère des NS d'une zone hébergée ailleurs 

**La délégation de zone** **_entreprise.fr délègue lab.entreprise.fr_** 

##### Titre de la formation 

Page 75 



<!-- Start of picture text -->
délégue /'autorité s'appuie sur<br>Zone déléguée : lab.entreprise.fr Enregistrements NS + Glue (A)<br>pourServeurla sous-zone DNS 2 — uniquement fait autorité ne2entreprise.frapansla Zone parenteA 10.0.0.2:<br>Objectif : répartir l'administration et la charge — chaque service DNS gére uniquement sa portion de I'espace de noms.<br><!-- End of picture text -->

#### **Délégation classique VS Stub Zone** 

Titre de la formation 

Page 76 



<!-- Start of picture text -->
Délégation classique Stub zone<br>!<br>!<br>I!<br>I!<br>Il<br>!<br>1 Serveur avec<br>!<br>I<br>I! la stub zone e--<br>!<br>!<br>Le parent connait en 1 Copie automatique et légére :<br>permanence les NS a jour 1 uniquement SOA, NS et A (glue)<br>(maintenus manuellement) ! — pas les enregistrements complets<br>I!<br>!<br>!<br>!<br>!<br>!<br>!<br>!<br>Cas d'usage I Cas d'usage<br>!<br>!<br>!<br>Séparation administrative durable l pore Se ene on felis<br>entre deux zones distinctes ! ges Serveurs Taisant autorite dune zone<br>! hébergée ailleurs, sans copier toute la zone<br>!<br>I<br>!<br>!<br>1<br><!-- End of picture text -->

#### **Jeu de commandes — zones et délégation** 

###### Gestion des zones 

- Add-DnsServerPrimaryZone -Name lab.entreprise.fr -ZoneFile lab.entreprise.fr.dns 

- Add-DnsServerSecondaryZone -Name ... -MasterServers 10.0.0.2 

Titre de la formation 

- Add-DnsServerZoneDelegation -Name entreprise.fr -ChildZoneName lab -NameServer ns2.entreprise.fr -IPAddress 10.0.0.2 

- Add-DnsServerStubZone -Name partenaire.fr -MasterServers 203.0.113.5 

Page 77 

- Get-DnsServerZone 

**Démonstration — Délégation d'une sous-zone puis création d'une stub zone associée** 

Titre de la formation 

Page 78 

##### Titre de la formation 

Page 79 

#### **Ce qu’il faut retenir** 



- Les zones se distinguent par leur rôle (directe/inversée/GlobalNames) et leur mécanisme (primaire/secondaire/AD/stub) 

- La délégation répartit l'autorité entre plusieurs serveurs DNS 

- La stub zone maintient automatiquement la liste des NS d'une zone tierce, sans la copier intégralement 

**Chapitre 7 : Sécurisation du DNS : DNSSEC, DoH et DoT** Titre de la formation 

Page 101 

P07 

#### **Quels éléments de sécurité pour le service DNS** 

Trois mécanismes pour garantir la sécurité 

- **Authenticité** : Garantie que l'origine d'une information ou d'un utilisateur est bien celle qu'il prétend être. 

- **Intégrité** : Garantie que les données n'ont pas été altérées, modifiées ou détruites de manière non autorisée. 

##### Titre de la formation 

- **Confidentialité** : Garantie que l'information n'est accessible qu'aux personnes autorisées à la consulter. 

Page 102 

#### **Comment garantir l’authenticité et l’intégrité** 

   - DNSSEC utilise des **signatures** 

   - **numériques** et un mécanisme de **chaîne de confiance** , sans chiffrer les données. 

- **Intégrité** : RRSIG (signature des enregistrements) – prouver que les données n’ont pas été modifiées 

- **Authenticité** : KSK et ZSK – prouver que les données proviennent bien de l’autorité autoritaire de la zone. 

Titre de la formation 

Page 103 

#### **Fonctionnement du NSEC et RRSIG simplifié** 

##### Titre de la formation 

###### Page 104 



<!-- Start of picture text -->
Flfidentique au dossier parent) Source de nom (SOA) [8], ad.demo.lan., hostmaster.demo.lan,<br>liidentique au dossier parent) Serveur de noms (NS) ad.demo.lan.<br>Flidentique au dossier parent) RR Signature (RRSIG) [NS][Inception(UTC): 23/09/2026 10:18:47][Expiration(UTC): 03/10/2026 11:18:47][entreprise.lan.][RSA/SH...<br>[Alidentique au dossier parent) _RR Signature (RRSIG) [DNSKEY][Inception(UTC): 23/09/2026 10:18:47][Expiration(UTC): 30/09/2026 11:18:47]{entreprise.lan.][RS..<br>[Alidentique au dossier parent) RR Signature (RRSIG) [DNSKEY][Inception(UTC): 23/09/2026 10:18:47][Expiration(UTC): 30/09/2026 11:18:47]entreprise.lan.IRS...<br>Pilidentique au dossier parent) RR Signature (RRSIG) [NSEC3PARAM][Inception(UTC): 23/09/2026 10:18:47][Expiration(UTC): 03/10/2026 11:18:47][entreprise.la...<br>[Alidentique au dossier parent) RR Signature (RRSIG) [SOA][Inception(UTC): 23/09/2026 10:42:23]|Expiration(UTC): 03/10/2026 11:42:23] entreprise.lan.][RSA/S...<br>Flfidentique au dossier parent) DNS KEY (DNSKEY) [256][DNSSEC][RSA/SHA-256][57964]<br>FAlidentique au dossier parent) DNS KEY (DNSKEY) [256][DNSSEC][RSA/SHA-256]{59863]<br>[Alidentique au dossier parent) DNS KEY (DNSKEY) [257[DNSSEC][RSA/SHA-256][30406]<br>Flfidentique au dossier parent) DNS KEY (DNSKEY) [257][DNSSEC][RSA/SHA-256][55904]<br>[Alidentique au dossier parent) Next Secure 3 Parameters (NSEC3PARAM) —_[SHA-1][0][50][59F9BE3EC1D10CE8]<br>Pldstjzrbildbmo7ftp4dvghoSaf... RR Signature (RRSIG) [NSEC3][Inception(UTC): 23/09/2026 10:20:58][Expiration(UTC): 03/10/2026 11:20:58][entreprise.lan.][RSA...<br>asstjarbilobmo7ttpadvgho8q8...Prog9immcSsk7acbve3ms8segl... NextRR SignatureSecure 3(RRSIG)(NSEC3) [SHA-1][NO[NSEC3][Inception(UTC):Opt-Out][50][59F9BE3EC1D10CE8][roqlmmcsk7acbve3ms8seg1bvkgk4r][23/09/2026 10:42:23][Expiration(UTC): 03/10/2026 11:42:23] [entreprise.lan.][RSA..NS SOA RRSIG D . ..<br>EAroggimmcSsk7acbve3ms8segl.... Next Secure 3 (NSEC3) [SHA-1][NO Opt-Out][50][59F9BE3EC1D10CE8][s0grjfih4ju85k74a34t00361003n07¢][A RRSIG]<br>[s0qrjfingju8sk74034t00361003...__ RR Signature (RRSIG) [NSEC3]IInception(UTC): 23/09/2026 10:42:17][Expiration(UTC): 03/10/2026 11:42:17][entreprise.tan.][RSA...<br>Psogrifingju85k74234t00361003.... Next Secure 3 (NSEC3) [SHA-1][NO Opt-Out][50][59F9BE3EC1D10CE8][d5stj3rbilbmO07ftp4dvgho8q8oftvb][A RRSIG]<br>EAwebt Héte (A) 192.168.10.11<br>Fiweb1 RR Signature (RRSIG) [AllInception(UTC): 23/09/2026 10:42:17][Expiration(UTC): 03/10/2026 11:42:17][entreprise.lan.][RSA/SHA...<br>FAweb2 Héte (A) 192.168.10.12<br>EAweb2 RR Signature (RRSIG) [AllInception(UTC): 23/09/2026 10:42:23]| Expiration (UTC): 03/10/2026 11:42:23] entreprise.lan.][RSA/SHA...<br><!-- End of picture text -->

KSK(257) 



<!-- Start of picture text -->
RRSIG<br><!-- End of picture text -->



<!-- Start of picture text -->
NSEC3<br><!-- End of picture text -->



<!-- Start of picture text -->
DNSKEY<br><!-- End of picture text -->



<!-- Start of picture text -->
ZSK(256)<br><!-- End of picture text -->

#### **Fonctionnement du NSEC et RRSIG simplifié** 

##### Titre de la formation 

Page 107 



<!-- Start of picture text -->
@ Les enregistrements de la zone (extraits) @) Hashage NSEC3<br>SHA-1 + sel (salt) + itérations<br>bm Nom Type Données<br>“ On web1.demo.lan ane<br>web1.demo.lan A 10.10.10.10<br>sent Ne web2.demo.lan A 10.10.10.20 web2.demo.lan a<br>mail.demo.lan A 10.10.10.30<br>web1.demo.lan ' RRSIG ~ OSCi.<br><!-- End of picture text -->



<!-- Start of picture text -->
G) Chaine NSEC3 (triée et circulaire)<br>Chaque enregistrement est signé<br>8F3A2B7C... ---+ | Enregistrement NSEC3<br>C12D6E45... FO9AQCIB... "tanto cs<br>> C12D6E4S... — FOSASC1B... — 8F3A2B7C...<br>fo<br>= 7 ' RRSIG '<br>SignéZSK<br>Chaine circulaire<br><!-- End of picture text -->

#### **Preuve d’inéxistance et NSEC/NSEC3** 

##### Titre de la formation 

Page 108 



<!-- Start of picture text -->
(4) Preuve d'inexistence<br>Exemple : le client recherche<br>intranet.demo.lan<br>@) intranet.demo.lanLe serveur calcule le hash de<br>Il trouve dans la chaine les deux<br>@) hashs entre lesquels il se situe<br>NSEC3 correspondants + leurs RRSIG<br>@) Il renvoie les enregistrements<br>() etLe résolveurl'ordre lexicographique vérifie les signatures<br><!-- End of picture text -->



<!-- Start of picture text -->
4 io<br>Exemple de chaine (simplifiée)<br>8F3A2B7C... C12D6E45S... FOSA9C1B...<br>a anna<br>Tot 7<br>Hash recherché : B0000000...<br>1 intranet.demo.lan se situe entre ces deux hashs<br>SSSSSS,<br><!-- End of picture text -->



<!-- Start of picture text -->
Verification : 8F3A2B7C... < B0000000... < C12D6E45...<br>Donc intranet.demo.lan n’existe pas dans la zone.<br>Preuve cryptographiquement signée (RRSIG).<br><!-- End of picture text -->

#### **La confidentialité et le chiffrement DNS** 

###### DoT 

Titre de la formation 

Page 109 

DoH 

   - Chiffre les requêtes DNS dans une session TLS dédiée (port 853) 

- Chiffre les requêtes DNS dans une session HTTPS (port 443) 

- Facilement 

- ► Se fond dans le trafic identifiable et web, plus difficile à filtrable par port, administration 

- filtrer spécifiquement réseau plus simple 

#### **Ou et comment appliquer le DNSSEC et DOH/DOT** 

Traffic DNS Externe 

##### Titre de la formation 

Page 110 

- Traffic DNS Interne 

- ► Techno : DNSSec + DOH/DOT 

- Objectif : se protéger du MITM 

- Techno : DNSSec 

- Objectif : Se protéger d’un altération de la données durant le transit (WAN->LAN) 

- Pas besoin de DOH puisque la probabilité d’un MITM en externe est peu probable. 

DNS-LAN 

DNS-Internet 

Client externe 

#### **Jeu de commandes — DNSSEC** 

###### Signature de zone 

- Add-DnsServerSigningKey -ZoneName entreprise.fr -Type KSK|ZSK 

- Invoke-DnsServerZoneSign -ZoneName entreprise.fr 

Titre de la formation 

Page 114 

- Get-DnsServerSigningKey -ZoneName entreprise.fr 

- Get-DnsServerDsRecord -ZoneName entreprise.fr (à transmettre au parent) 

- Set-DnsServerDnsSecZoneSetting -ZoneName entreprise.fr -SignWithNSEC3 $true 

**Démonstration — Signature DNSSEC d'une zone et** Titre de **vérification de la chaîne de** la formation **confiance jusqu'au parent** Page 115 

#### **Ce qu’il faut retenir** 

- DNSSEC garantit l'intégrité et l'authenticité des réponses via la chaîne DS → DNSKEY → RRSIG 



- KSK et ZSK ont des rôles et des cycles de rollover distincts 

##### Titre de la formation 

- DoH et DoT chiffrent le transport DNS, avec des compromis différents en matière de filtrage 

Page 116 

P08 

**Chapitre 8 : Mise en pratique du DNSEC et DOH** Titre de la formation 

Page 117 

#### **Sommaire de la démonstration** 

###### **Partie 1 : Implémentation et Validation DNSSEC** 

- Mise en place : Déploiement d'un Windows Server (rôle DNS). 

Titre de la formation 

- Bac à sable : Création d'une zone primaire et activation DNSSEC (phase de test et découverte de NSEC3 et RRSIGN). 

- Déploiement AD : Application de DNSSEC sur la zone Active Directory principale. 

- Validation client : Analyse Wireshark (vérification des preuves d'authenticité et d'intégrité). 

Page 118 

**Démonstration — Signature DNSSEC d'une zone et** Titre de **vérification de la chaîne de** la formation **confiance jusqu'au parent** Page 119 

#### **Sommaire de la démonstration** 

###### **Partie 2 : Sécurisation des flux avec DoH** 

Titre de la formation 

- Configuration : Activation du service DNS over HTTPS (DoH) sur le serveur. 

- Contrôle : Analyse Wireshark pour confirmer le chiffrement de bout en bout des requêtes. 

Page 120 

**Démonstration — Signature DNSSEC d'une zone et** Titre de **vérification de la chaîne de** la formation **confiance jusqu'au parent** 

Page 121 

# **Chapitre 8 : DNS Policies et** Titre de **Split-Brain DNS** la formation Page 122 P08 

#### **Définition du Split Brain DNS / Split Horizon** 

Le **Split-Brain** est une architecture dans laquelle un même nom de domaine renvoie vers des adresses IP différentes en fonction de la provenance de la requête (le réseau du client qui interroge). 

##### Titre de la formation 

www.entreprise.fr ? 

www.entreprise.fr ? 

Page 123 

Client externe (WAN) 

**34.65.4.8** 

Serveur DNS 

**10.150.38.7** 

Client interne (LAN) 

#### **Comment appliquer le Split Brain DNS ?** 

Titre de la formation 

- Deux serveurs DNS 

- ► Un serveur pour la résolution interne 

- ► Un serveur pour la résolution externe 

DNS Policies / Politique DNS 

- Un serveur avec des politiques de réponse selon la provenance 

Page 124 

#### **Ce que permettent les DNS Policies** 

Titre de la formation 

Basées sur le Basées sur le serveur client 

   - Interface réseau ou adresse IP d'écoute du serveur DNS 

- Adresse IP / sous-réseau source de la requête 

Basées sur le temps 

- Jour et heure de la requête (bascule planifiée, maintenance) 

Page 125 

#### **Préconisation de l’ANSSI en mesure d’architecture DNS** 

Titre de la formation 

Page 126 



<!-- Start of picture text -->
——» Flux DNS client/serveur recommandé ——> Flux dacces a Internet<br>Clients / Ressources<br>spécifiques a<br>FE E r DMZ = C<br>= 4upe<br>Ne Li = i<br>_ LW 4 Que<br>& os NW<br>Relais Resolutions Intemet<br>LI Service DNS Service DNS Internet<br>Hébergement Intemet<br>| (5 Servicergement DNSInterne! ae<br>ResolutionsService InternesDNS LJ =J 4<br>Sl entité ElEcy<br>Infra. physique Infra. physique DMZ<br>«interne » «externe »<br><!-- End of picture text -->

#### **Jeu de commandes — policies et zone scopes** 

###### Mise en œuvre du split DNS 

- 1. Créer le sous-réseau client (Client Subnet) 

- 2. Créer une étendue de zone (Zone Scope) 

- 3. Ajouter les enregistrements DNS 

- 4. Créer la stratégie de résolution (DNS Policy) 

##### Titre de la formation 

- Add-DnsServerClientSubnet -Name "Interne" -IPv4Subnet "192.168.10.0/24" 

- Add-DnsServerZoneScope -ZoneName entreprise.fr -Name 'Externe' 

- Add-DnsServerResourceRecord -A -ZoneName entreprise.fr -Name www -IPv4Address 203.0.113.20 -ZoneScope 'Externe' 

Page 127 

- Add-DnsServerQueryResolutionPolicy -Name 'PolExterne' -Action ALLOW -ZoneScope 'Externe,1' -ZoneName entreprise.fr -ClientSubnet 'eq,Interne' 

**Démonstration — Mise en place d'un split-brain DNS avec zone scopes et une query resolution policy** 

Titre de la formation 

Page 128 

##### Titre de la formation 

Page 129 

#### **Ce qu’il faut retenir** 



- Le split-brain DNS combine zone scopes et policies pour donner deux vues d'une même zone 

- Le split-brain DNS combine zone scopes et policies pour donner deux vues d'une même zone L’ANSSI préconise de séparer les serveurs DNS pour la résolution interne et externe 

   - L’ANSSI préconise l’usage de service de relais DNS permettant de service de cache. 

**Chapitre 9 : Haute** Titre de **disponibilité DNS** la formation 

Page 130 

P09 

#### **Implémenter la réplication Active Directory** 

- 1) Installer un Windows Server 

► 2) Ajouter le serveur dans le domaine 

- 3) Installer le rôle AD DS 

Titre de la formation 

Page 131 

- 4) Ajouter le nouveau contrôleur au domaine 

- 5) Vérifier la réplication 

## **Démonstration** 

Titre de la formation 

Page 132 

## **Partie : DHCP** 

Titre de la formation 

Page 139 

P05 

**Chapitre 1 : Architecture** Titre de **DHCP et Active Directory** la formation 

Page 140 

C01 

#### **Objectif de ce chapitre** 

- À la fin de ce chapitre, vous saurez : 

- positionner serveur, relais, DNS et AD dans une architecture DHCP ; 

- choisir un modèle : site unique, multi-VLAN, multisites, hybride ; 

Titre de la formation 

- expliquer l'autorisation AD et ses limites, puis sauvegarder et migrer une base. 

Page 141 

#### **Qui fait quoi ?** 

###### **Serveur DHCP** 

Attribue les baux, porte la base des baux et les options par étendue. 

###### **Relais DHCP** 

###### **Routeur** 

Transforme le Sépare les domaines de broadcast client en broadcast et héberge le unicast vers le serveur relais (ip helperet renseigne giaddr. address). 

Titre de la formation 

Page 142 

###### **DNS** 

###### **Active Directory** 

Reçoit les mises à jour Autorise les serveurs dynamiques A et PTR DHCP et héberge les (client ou serveur zones DNS intégrées. DHCP). 

#### **Architecture de référence : relais + paire DHCP** 

Titre de la formation 

Page 143 



#### **Quatre architectures, quatre arbitrages** 

**Site unique** 

**Multi-VLAN** 

1 serveur ou 1 paire Paire centrale, un relais failover. Pas de relais si par SVI, une étendue un seul VLAN. Simple, par VLAN. Le cas mais à redonder. standard. 

Titre de la formation 

Page 144 

###### **Multi-sites** 

Paire locale par gros site, ou paire centrale via WAN : latence contre autonomie si le lien tombe. 

###### **Hybride** 

Le DHCP reste sur site ; un réseau virtuel cloud fournit son propre DHCP (pas de broadcast). On étend surtout DNS et AD. 

#### **Autorisation AD : ce qui se passe vraiment** 

- Un serveur DHCP joint au domaine doit être **autorisé** : son nom et son IP sont inscrits dans le conteneur `NetServices` de la partition Configuration. 

- Au démarrage, le service interroge l'AD. Non autorisé : il **cesse de répondre** (événement 1046). 

##### Titre de la formation 

- Droits requis : Enterprise Admins, ou délégation explicite sur le conteneur. 

- Un serveur Windows hors domaine détecte un DHCP autorisé (DHCPINFORM) et s'arrête aussi. 

Page 145 

#### **Rogue DHCP : ce que l'autorisation ne couvre pas** 

###### **Non couvert** 

###### **Couvert** 

- box, routeur, borne Wi-Fi 

##### Titre de la formation 

- serveur Windows du domaine non autorisé 

- serveur Windows hors domaine (détection DHCPINFORM) 

- Linux (dnsmasq, ISC), VM de labo 

- attaquant : rien n'authentifie les clients ni les serveurs. Réponse au rogue DHCP (DHCP Snooping) 

Page 146 

#### **Quatre architectures, quatre arbitrages** 

**Sauvegarde Base DHCP** Automatique toutes les Baux : `dhcp.mdb` . 60 min dans Configuration : registre. `dhcp\backup` . Ajouter Le backup couvre les `Backup-DhcpServer` deux. vers un stockage externe. 

Titre de la formation 

Page 147 

**Bonnes pratiques** 

**Bonnes pratiques Migration** Deux serveurs `Export-DhcpServer` minimum. Éviter DHCP `-Leases` , puis `Import-` sur un DC. Autorisation `DhcpServer` sur le déléguée. Liste `Get-` nouveau serveur. `DhcpServerInDC` Désautoriser l'ancien. auditée. 

**Chapitre 2 : Fonctionnement avancé des baux** Titre de la formation 

Page 149 

C02 

#### **Objectifs du chapitre** 

À la fin de ce chapitre, vous saurez : 

- calculer T1 et T2 et lire un renouvellement dans Wireshark ; 

- chiffrer l'impact d'une durée de bail : adresses et trafic ; 

- adapter la durée pour le Wi-Fi et le VPN. 

Titre de la formation 

Page 150 

#### **Cycle de vie d'un bail : T1, T2, expiration** 

Titre de la formation 

Page 151 



#### **Capture Wireshark : DORA, renouvellement, rebinding** 

Titre de la formation 

Page 152 



#### **Impact de la durée du bail** 

**Bail long : 8 jours** 

5 000 clients : ≈ 1 renouvellement par minute. Les adresses restent prises longtemps après le départ. 

**Bail court : 1 heure** 

5 000 clients : ≈ 167 renouvellements par minute. Réactif, mais charge et dépendance au serveur. 

Titre de la formation 

Page 153 

###### **Consommation** 

200 nouveaux appareils par heure : bail 8 h ≈ 1 600 adresses ≈ occupées ; bail 1 h 200. 

###### **Règle pratique** 

Bail ≈ durée de présence. Filaire : 8 j. Wi-Fi invité : 1 à 4 h. VPN : plus long que l'absence. 

#### **La consommation réseau du DHCP est neutre sur un réseau ?** 

La consommation du service DHCP est considéré comme neutre 

- 1 renouvellement DHCP =~ 1ko 

Attention tout de même 

- Hot Standby DHCP 

- Mise à jours DNS automatique  (A, PTR, réplication AD) 

Titre de la formation 

- Logs 

Page 154 

#### **Wi-Fi et VPN : deux pièges différents** 

###### **Wi-Fi** 

###### **VPN** 

Titre de la formation 

- MAC aléatoire par SSID : un même appareil peut prendre plusieurs baux 

- Changement de VLAN : l'ancien bail n'est jamais libéré 

- Pool /23 ou plus, bail de 1 à 4 h 

- Tunnel coupé à T1 : renouvellement impossible 

- Adresses du tunnel : pool de la passerelle ou DHCP relayé 

- Bail supérieur à l'absence probable 

Page 155 

#### **Les adresses matérielles aléatoires** 

- Les adresses matérielles aléatoires ont pour vocation à améliorer la confidentialité d’un utilisateur afin de camoufler l’ordinateur utilisé. 

##### Titre de la formation 

Page 156 



<!-- Start of picture text -->
— es<br>Feet peramecs Q_ Rechercher un paramatre<br>BSsoo + > Wi-Fi > Gérer les réseaux connus ><br>Connexion limitée<br>@ Accueil Certaines applications peuvent fonctionner différemment afin de réduire l'utilisation des données lorsque vous Désactive @_»)<br>étes connectés a ce réseau.<br>@ systeme . _ :<br>Définir une limite de données permettant de contréler la consommation des données sur ce réseau<br>© Bluetooth et appareils<br>1@ Réseau et Internet AdivousProtégezressesconnectez votrematériellesjatérielles vie privéealéatoires en rendantaléatoir  plus difficile le suivi de I'emplacementde votre appareil lorsque vous | 1 oes.<br>J Personnalisation réseau. 8 ce réseau. Le paramétre entre en vigueur la prochaine fois que vous vous connectez 4 ce | Busine<br>BZ Applications Les paramétres IP de tous les réseaux Wi-Fi ont été définis. Les paramétres ci-dessous ne seront pas _ Modifier tous lesjours<br>utilisés.<br>S& comptes Modifier les paramétres IP pour tous les réseaux Wi-Fi Modifier<br><!-- End of picture text -->

## **Démonstration** 

Titre de la formation 

Page 157 

#### **Ce qu’il faut retenir** 



- T1 = 50 %, T2 = 87,5 % : le client décide, pas le serveur. 

- Durée du bail : arbitrage entre adresses consommées et trafic de renouvellement. 

- Wi-Fi : bail court et pool large. VPN : bail supérieur à l'absence. 

##### Titre de la formation 

- Un client qui change de VLAN ne libère pas son ancien bail. 

Page 158 

Titre de la formation 

## **Chapitre 2 : Haute Disponibilité DHCP** 

Page 159 

C02 

#### **Objectifs du chapitre** 

À la fin de ce chapitre, vous saurez : 

- choisir entre Hot Standby et Load Balance ; 

- lire les états du failover et prévoir la bascule ; 

- situer le failover face au Split Scope et au cluster. 

Titre de la formation 

Page 160 

#### **Deux modes : Hot Standby ou Load Balance** 

Titre de la formation 

Page 161 



#### **Quel mode pour quel besoin ?** 

###### **Load Balance** 

###### **Hot Standby** 

- Site principal + site de secours 

- Deux serveurs au même endroit 

- 50 / 50 par défaut 

Titre de la formation 

- Actif à 100 % ; standby = 5 % de réserve 

- Agences : le standby est au siège 

- **Réseaux à forte densité** : pour des subnets avec de très nombreux clients avec renouvellent leurs baux simultanément 

Page 162 

#### **États et bascule** 

Titre de la formation 

Page 163 



#### **MCLT et bascule : ce qu'il faut savoir** 

- **MCLT** (Maximum Client Lead Time, 1 h par défaut) : avance maximale sur le bail connu du partenaire. 

- **Communication Interrupted** : chaque serveur continue ; les baux hors de sa part sont limités au MCLT. 

##### Titre de la formation 

Page 164 

- **Partner Down** : décidé par l'admin, ou automatique ( `AutoStateTransition` ). 

- Le survivant attend un MCLT avant de réutiliser les adresses du partenaire. 

- Réplication : baux en continu ; configuration à la demande. 

#### **Failover face aux solutions historiques** 

**Failover (2012+)** 

**Split Scope 80/20** 

Réplique baux et Deux serveurs, 80 % et configuration entre 20 % du pool, sans deux serveurs. Solution synchronisation des Microsoft de référence. baux. Obsolète. 

Titre de la formation 

Page 165 

**DHCP sur routeur ou box** 

###### **Cluster Windows** 

Une seule base sur stockage partagé. Plus Aucune HA, aucune lourd : à réserver aux intégration DNS. cas existants. Réservé à un petit site. 

#### **Bonnes pratiques de déploiement** 

- **Hot Standby** pour les agences, **Load Balance** pour un même site. 

- Horloges synchronisées (NTP) et **TCP 647** ouvert entre partenaires. 

Titre de la formation 

- **Secret partagé** fort ; réplication après chaque changement de configuration. 

- Les **deux** partenaires dans les `ip helper-address` . 

- Vérifier sur chaque partenaire les options de niveau serveur. 

Page 167 

#### **Ce qu’il faut retenir** 



- Hot Standby pour DR et agences, Load Balance pour un même site. 

- Le MCLT évite les doublons d'adresses pendant une coupure. 

- Le failover remplace Split Scope et cluster pour les étendues IPv4. 

##### Titre de la formation 

- Un Communication Interrupted durable est une panne à traiter. 

Page 168 

**Chapitre 6 : IPv6, SLAAC et DHCPv6** Titre de la formation 

Page 169 

C06 

#### **Objectifs du chapitre** 

À la fin de ce chapitre, vous saurez : 

- expliquer ce qui remplace broadcast, ARP et DHCP en IPv6 ; 

- lire un RA et ses flags M, O, A ; 

- choisir SLAAC, DHCPv6 ou un modèle mixte. 

Titre de la formation 

Page 170 

#### **Ce qui change en IPv6** 

**Broadcast** 

**ARP** 

Disparaît. Remplacé par Remplacé par Neighbor le multicast : `ff02::1` Discovery (ICMPv6) : NS (tous), `ff02::2` et NA pour la résolution (routeurs), `ff02::1:2` MAC/IP, RS et RA pour (serveurs DHCPv6). découvrir le routeur. 

Titre de la formation 

Page 171 

**Identité Configuration** Le routeur annonce Le client est identifié préfixe, passerelle et par un DUID (pas par flags par RA. Le sa MAC) ; ses adresses DHCPv6 est optionnel. par un IAID. 

#### **Les mode de DHCP** 

Titre de la formation 

###### **Pas de DHCP** 

Le poste génère l’adresse avec le préfix Aucun serveur DHCPv6 Pas de suivi centralisé 

###### **DHCP Stateless** 

Le poste génère l’adresse avec le préfix Des options complémentaires sont fournis par le DHCP Pas de suivi centralisé 

###### **DHCP Statefull** 

Le serveur DHCPv6 attribue les adresses; Le serveur conserve les baux; Administration centralisée; 

Page 172 

#### **SLAAC et DHCPv6 : usages** 

###### **SLAAC** 

###### **DHCPv6 stateful** 

Sans serveur, sans état, Adresses attribuées et rapide. Limites : peu de journalisées (IA_NA). traçabilité, options Utile pour l'audit ; réduites (RDNSS). Android ne le gère pas. 

Titre de la formation 

###### **DHCPv6 stateless** 

###### **Limite commune** 

Page 173 

L'adresse vient de SLAAC ; DHCPv6 ne donne que DNS et domaine (O=1). Utile là où RDNSS n'est pas géré. 

La passerelle vient toujours du RA. Un serveur DHCPv6 seul ne suffit jamais. 

**Les flags du RA (Router Advertisement)** 

Titre de la formation 

###### **A - Autonomous** 

Indique si le client peut construire son adresse IPv6 via SLAAC à partir du préfix réseau. 

###### **M - Managed** 

Indique si l’adresse IPv6 doit être obtenu via DHCP (statefull) 

**O – Other Configuration** 

Indique si les autres paramètres (DNS, suffixe DNS, NTP) sont disponible via DHCPv6 (stateless ou statefull) 

Page 174 

#### **Les combinaisons des Flags (A, M, O)** 

Titre de la formation 

Page 175 

|**A**|**M**|**O**|**Comportemen**<br>**t client**|**Méthode**|
|---|---|---|---|---|
|1|0|0|SLAAC<br>uniquement|Adresse via SLAAC aucune<br>option DHCPv6|
|1|0|1|SLAAC +<br>DHCPv6<br>stateless|Adresse via SLAAC et options<br>via DHCPv6|
|0|1|1|DHCPv6<br>statefull|Adresse et options via<br>DHCPv6|
|0|0|0|Aucune auto-<br>config utilisable|Le client ne peut pas obtenir<br>d’adresse ni d’options (sauf<br>configmanuelle)|



**Quels configurations pour quel cas ?** 

##### Titre de la formation 

**Serveurs PC-Wifi-Byod** M = 0 **Imprimantes,** M = 0  (filtrage by O = 0 **téléphones, AP, IOT** authentification) M = 1 A = 0 O = 1 Configuration statique, O = 0/1 A = 1 (compatibilité IPAM ou A = 0 android) provisionnement d’infrastructure 

Page 176 

#### **Configuration Cisco et RDNSS (Pas de DHCP)** 

```
interface GigabitEthernet0/1
```

- `! Add DNS servers to RA` 

```
 ipv6 nd ra dns server 2001:4860:4860::8888 1200 sequence 0
 ipv6 nd ra dns server 2001:4860:4860::8844 1200 sequence 1
```

##### Titre de la formation 

Page 178 

- `! Add DNS search domain` 

```
 ipv6 nd ra dns search-list corp.example.com 1200 sequence 1
```

```
! Verify RDNSS configuration
```

```
show ipv6 nd ra dns server
show ipv6 nd ra dns search-list
```

#### **Configuration Cisco et Statefull** 

```
interface GigabitEthernet0/0
ipv6 address 2001:DB8:ACAD:1::1/64
```

- `! 1. Gestion des flags Neighbor Discovery (ND)` 

- `! Indique aux clients d'interroger un DHCPv6 pour obtenir leur IP (Flag M) ipv6 nd managed-config-flag` 

- `! Indique aux clients d'interroger un DHCPv6 pour le DNS et le domaine (Flag O)` 

##### Titre de la formation 

Page 179 

```
 ipv6 nd other-config-flag
```

- `! 2. Désactivation de SLAAC (Flag A : Fortement recommandé en environnement Windows)` 

- `! Empêche les clients de générer une seconde adresse IP via autoconfiguration ipv6 nd prefix 2001:DB8:ACAD:1::/64 no-autoconfig` 

- `! 3. Configuration du Relais DHCPv6 ipv6 dhcp relay destination 2001:DB8:9999(SERVEURS)::10` 

#### **Échanges SLAAC et DHCPv6 sur le réseau** 

Titre de la formation 

Page 180 



## **Démonstration** 

Titre de la formation 

Page 182 

## **Partie : DFS/DFSR** 

Titre de la formation 

Page 183 

P05 

**Chapitre 1 : Architecture DFS** Titre de **Namespaces et DFSR** la formation 

Page 184 

C01 

#### **Objectifs du chapitre** 

À la fin de ce chapitre, vous saurez : 

- distinguer DFS Namespaces (l'espace de noms) et DFSR (la réplication) ; 

- choisir entre namespace autonome et namespace de domaine ; 

Titre de la formation 

- positionner DFSR par rapport à Storage Replica et au simple partage répliqué. 

Page 185 

#### **Présentation de DFS** 

DFS créé un point d'entrée unique et virtuel pour des dossiers partagés qui sont dispersés sur plusieurs serveurs physiques. 

Les objectifs de DFS sont multiples : 

- Masquer la complexité technique aux utilisateurs. 

##### Titre de la formation 

- Tolérance de panne et accès local plus rapide (coût du lien) 

\\entreprise.fr\partages 

Page 186 



DFS 

SRV-FS1 

**Réplication DFSR Bidirectionnel** 

Client interne 

SRV-FS2 

#### **Quand DFSR est la bonne réponse** 

Titre de la formation 

###### **Adapté** 

- Partages bureautiques consultés depuis plusieurs sites 

- Documents modifiés occasionnellement, pas en continu 

- SYSVOL et données de configuration répliquées par nature 

###### **Mal adapté** 

- Bases de données actives (SQL Server, etc.) 

- Fichiers verrouillés en continu (VHD en cours d'utilisation) 

- Besoin de cohérence transactionnelle stricte entre sites 

Page 187 

#### **Les environnements DFS avancées** 

##### Titre de la formation 

Page 188 



<!-- Start of picture text -->
Forét : entreprise.local<br>aTr<br>Domaine: Domaine: Domaine:<br>corp.entreprise.local agence.entreprise.local | | ressources.entreprise.local<br>DC1 DCc2 Dc3<br>SITES ACTIVE DIRECTORY<br>Les sites permettent d’associer des sous-réseaux IP<br>et de définir les codits des liens (topologie réseau)<br>Site Lille Site Paris Site Lyon<br><!-- End of picture text -->

#### **La gestion des sites et des coûts de lien** 

En exploitant les coûts de liens Active Directory, le DFS dirige l'utilisateur vers le site le plus proche : cela optimise les temps d'accès et évite de saturer les liens inter-sites, où la réplication est souvent bridée, voire différée la nuit. 

##### Titre de la formation 

Page 189 



<!-- Start of picture text -->
SITE LILLE<br>(10.1.0.0/16) Serveurs de fichiers<br>fc]F (DFSR)<br>FS-LILO1  FS-LIL-02 — FS-LIL-03 J<br>Coit : 100 Coit : 200<br>He SITE PARIS (10.2.0.0/16) i] Ej SITE LYON (10.3.0.0/16)<br>ElleAL ie Serveurs de fichiers; Coit : 50 ____ Serveurs de fichiers'<br>(DFSR) fi (DFSR)<br>FS-PAR-01 FS-PAR-02 \FS-LY0-01 FS-LYO-02 FS-LY0-03<br><!-- End of picture text -->

#### **Deux technologies, un seul nom** 

**DFS Namespaces** 

Un chemin virtuel unique ( `\ \corp.local\Partages` ) qui pointe vers une ou plusieurs cibles réelles. 

**DFSR** 

Le moteur qui réplique le contenu de dossiers entre plusieurs serveurs (les cibles). 

Titre de la formation 

Page 191 

###### **Ensemble** 

Le namespace masque l'emplacement réel ; DFSR fait en sorte que peu importe la cible choisie, le contenu est identique. 

###### **Seul, sans l'autre** 

Un namespace peut exister sans DFSR (une seule cible). DFSR peut répliquer sans namespace (SYSVOL). 

#### **Namespace autonome ou de domaine ?** 

###### **De domaine** 

Titre de la formation 

Page 194 

###### **Autonome** 

- Métadonnées stockées sur un seul serveur (registre) 

- Chemin `\ \serveur\namespace` 

- Pas de haute disponibilité du namespace lui-même 

- Utile hors domaine ou pour un cluster dédié 

- Métadonnées répliquées dans l'AD (ou dans SYSVOL en mode Windows Server 2008) 

- Chemin `\ \domaine\namespace` 

- Plusieurs serveurs de namespace : haute disponibilité native 

- Le choix par défaut en entreprise 

#### **3 systèmes de réplications possibles** 

Titre de la formation 

###### **Maillage complet** 

###### **Hub-and-spoke** 

Tous les sites Chaque agence répliquent entre eux. réplique avec le siège Résilient, coûteux à uniquement. Simple, administrer mais le siège est un manuellement au-delà point de passage obligé de quelques sites. 

###### **Personnalisée** 

Lors de la création vous choisissez aucune topologie et la réplication sera à gérer dans un second temps. 

Page 195 

#### **Installation des rôles** 

```
# Rôle DFS Namespaces et DFSR (sur chaque serveur membre)
Install-WindowsFeature FS-DFS-Namespace, FS-DFS-Replication `
  -IncludeManagementTools
```

```
# Vérification
Get-WindowsFeature FS-DFS*
```

```
# Outils en ligne de commande disponibles ensuite
Get-Command -Module DFSN, DFSR
```

Titre de la formation 

Page 196 

## **Démonstration** 

Titre de la formation 

Page 197 

#### **Démo : créer un namespace de domaine** 

- `New-DfsnRoot -TargetPath \\SRV-A\Partages -Type DomainV2 -Path \\corp.local\Partages` . 

- Ajouter une deuxième cible : `New-DfsnRootTarget` . 

##### Titre de la formation 

- Vérifier dans la console DFS Management : deux cibles, un seul chemin visible pour l'utilisateur. 

- `Get-DfsnRootTarget -Path \\corp.local\Partages` : lire l'état de chaque cible. 

Page 198 

#### **Ce qu’il faut retenir** 



- DFS Namespaces organise l'accès, DFSR réplique le contenu : deux rôles distincts. 

- Namespace de domaine = haute disponibilité native ; autonome = un seul serveur. 

- DFSR est multi-maître et pensé pour des fichiers de bureautique, pas pour des bases actives. 

##### Titre de la formation 

- Storage Replica répond à un besoin différent : la reprise après sinistre d'un volume. 

Page 199 

Titre de la formation 

## **Chapitre 2 : Espaces de noms : référencement et ciblage** 

Page 200 

C02 

#### **Objectifs du chapitre** 

- À la fin de ce chapitre, vous saurez : 

- expliquer le mécanisme de référence (referral) et son tri par coût de site ; 

- régler la priorité des cibles et le cache client ; 

- activer l'Access-Based Enumeration (ABE) sans surprise. 

Titre de la formation 

Page 201 



<!-- Start of picture text -->
Titre de<br>la formation<br>Page 202<br><!-- End of picture text -->

#### **Le mécanisme de référence pas à pas** 



<!-- Start of picture text -->
Client Contrôleur de domaine Namespace<br>(site B) (AD DS) \\entreprise.fr\Partages<br>①  Résolution du namespace + demande de coûts de site<br>②  Trie les cibles par coût de site<br>③  Liste ordonnée de référence<br>(referral) : SRV-B, puis SRV-A<br>④  Le client tente la 1re cible (SRV-B)<br><!-- End of picture text -->

#### **Coût de site : d'où viennent les priorités** 

- Le tri par défaut suit les **liens de site AD** (Sites et services Active Directory), pas une configuration DFS séparée. 

- **Cible dans le même site** que le client : toujours en tête, à égalité de priorité. 

##### Titre de la formation 

- Sans site AD correspondant : DFS retombe sur le coût des liens de site les plus proches. 

- On peut **forcer** une priorité par cible ( `Set-DfsnFolderTarget -TargetPriorityClass` ), utile pour désigner une cible de secours. 

Page 203 

#### **Access-Based Enumeration : effet et limites** 

Titre de la formation 

###### **Ce que ça change** 

- Un dossier sans droit de lecture n'apparaît plus dans l'explorateur 

- S'applique dossier par dossier sous la racine namespace 

- Nécessite le mode « Windows Server 2008 » du namespace 

###### **Ce que ça ne fait pas** 

- Ne remplace pas les permissions NTFS : c'est un affichage, pas une sécurité supplémentaire 

- Un chemin direct ( `\ \serveur\partage\dossier` ) reste accessible si les NTFS l'autorisent 

Page 205 

#### **Commandes : cibles, priorités, ABE** 

```
# Ajouter une cible et la classer en secours
New-DfsnFolderTarget -Path \\corp.local\Partages\RH `
  -TargetPath \\SRV-B\RH -ReferralPriorityClass "sites-costed"
Set-DfsnFolderTarget -Path \\corp.local\Partages\RH `
  -TargetPath \\SRV-C\RH -ReferralPriorityClass "sites-costed" `
  -ReferralPriorityRank 1
```

```
# Cache de référence
Set-DfsnFolder -Path \\corp.local\Partages\RH -ReferralTtl 900
```

Titre de la formation 

```
# Mettre une cible hors service pour maintenance
Set-DfsnFolderTarget -Path \\corp.local\Partages\RH `
  -TargetPath \\SRV-B\RH -State Offline
# Activer l'énumération basée sur l'accès (ABE)
Set-DfsnFolder -Path \\corp.local\Partages -EnableAccessBasedEnumeration $true
```

Page 206 

## **Démonstration** 

Titre de la formation 

Page 207 

#### **Démo : observer le referral changer** 

- `dfsutil /pktinfo` sur le client : lire le cache de référence actuel. 

- Modifier le coût du lien de site AD entre les deux sites du labo. 

Titre de la formation 

- `dfsutil /pktflush` pour vider le cache, puis ré-accéder au namespace. 

- Comparer l'ordre des cibles avant et après le changement de coût. 

Page 208 

#### **Panne n°2 · Le client utilise toujours la mauvaise cible** 

- **Symptôme** : un utilisateur du site B accède systématiquement au serveur du site A, plus lent. 

- **Diagnostic** : `dfsutil /pktinfo` (référence en cache), vérifier le site AD du poste ( `nltest /dsgetsite` ). 

##### Titre de la formation 

- **Journal** : aucun événement DFS pertinent ici : c'est une question de topologie AD, pas de panne DFS. 

- **Capture** : le poste n'a peut-être pas de sous-réseau AD associé à son site : vérifier `Get-ADReplicationSubnet` . 

- **Correction** : associer le sous-réseau du poste à son site AD, vider le cache client ( `dfsutil /pktflush` ). 

Page 209 

#### **Ce qu’il faut retenir** 



- Le tri des cibles suit le coût de site AD, pas une configuration DFS isolée. 

- Le cache client (300 / 1800 s) explique pourquoi un changement met du temps à être visible. 

- ABE masque l'affichage ; seules les permissions NTFS protègent réellement. 

##### Titre de la formation 

- Un poste mal rattaché à son site AD explique souvent un mauvais choix de cible. 

Page 210 

## **Chapitre 3 : Réplication DFSR : RDC, staging et** Titre de la formation **conflits** 

Page 211 

C03 

#### **Objectifs du chapitre** 

À la fin de ce chapitre, vous saurez : 

- expliquer le rôle du dossier de staging et de RDC ; 

- dimensionner les quotas de staging 

Titre de la formation 

Page 213 



<!-- Start of picture text -->
Titre de<br>la formation<br>Page 214<br><!-- End of picture text -->

#### **Quelques mots clés à connaitre** 

DFSR Journal USN Base DFSR RDC (Remote Zone de Staging Differential Compression) 

#### **Le circuit d'un fichier modifié** 

##### Titre de la formation 

Page 216 



###### **SERVEUR A · ÉMETTEUR** 



###### **Dossier répliqué** 

###### **Service DFSR** 

`D:\Data` Journal USN → nouvelle version en base DFSR 

- ① Fichier enregistré 







###### **Staging A** 

###### **RDC** 

   - ③ B compare les signatures avec sa graine et commande ses blocs 

- `DfsrPrivate\Staging` ② À la 1re demande : compressé + ACL + signatures 



**RPC** 

blocs manquants uniquement 



**× N partenaires** 

###### **SERVEUR B · PARTENAIRE** 

###### **Dossier répliqué** 

###### **Corbeille DFSR** 

`ConflictAndDeleted` Perdant d'un conflit 

`D:\Data` ⑥ Fichier remplacé 







###### **Installing** 

**Staging B** `DfsrPrivate\Stagin g` 

- `…\DfsrPrivate\ Installing` ⑤ Décompression 



- ④ Fichier reconstruit 

#### **Trois questions avant d'utiliser RDC** 



**Fichier modifié** 



<!-- Start of picture text -->
Titre de<br>la formation<br><!-- End of picture text -->

Page 222 



**oui oui Ancienne oui RDC activé ? Fichier ≥ 64 version chez RDC : blocs Ko ? B ? manquants seuls non non non Désactivé** : souvent voulu **Petit fichier** : l'envoyer **Rien à comparer** : sur un LAN rapide. entier va plus vite. nouveau fichier, nouveau membre. 









**Replication : le fichier entier, compressé, traverse le réseau** 

#### **Le cleanup, pas à pas** 

À la fin de ce chapitre, vous saurez : 

- expliquer le rôle du dossier de staging et de RDC ; 

- dimensionner les quotas de staging et de ConflictAndDeleted ; 

- prédire quel fichier « gagne » en cas de modification concurrente. 

Titre de la formation 

Page 225 

#### **Le cleanup, pas à pas** 

##### Titre de la formation 

Page 226 



<!-- Start of picture text -->
Le staging dépasse 90 % de son quota (high watermark).<br>DFSR supprime les fichiers stagés les plus anciens jusqu'à 60%.<br>Avant Après cleanup<br>90 %<br>suivi.xlsx<br>logo.png<br>export.csv<br>60 %<br>note.docx suivi.xlsx<br>photo.jpg logo.png<br>budget.xlsx export.csv<br>plan.vsdx note.docx<br>devis.docx photo.jpg<br>rapport.pptx budget.xlsx<br>Supprimés, les plus anciens :<br>rapport.pptx devis.docx plan.vsdx<br><!-- End of picture text -->

#### **Comment bien dimensionner la zone de staging ?** 

Une zone de staging mal calculer amène à 

- Plus de calcul CPU (recalcul des signatures rdc) 

- Plus d’E/S (IO) sur le disque (création fichier tmp, suppression) 

- Réplication plus lente car backlog en attente 

Titre de la formation 

Page 229 

- Staging churn, 

**32** 

#### **Le trajet d'un fichier modifié** 

Titre de la formation 

Page 232 



#### **Le dossier de staging : ce qu'il faut savoir** 

- Chaque membre a **son propre** dossier de staging par dossier répliqué (pas un dossier global). 

- Un fichier modifié y est copié **avant** transfert : c'est la zone de travail de RDC. 

##### Titre de la formation 

- **Quota trop petit** : DFSR doit nettoyer en continu, ce qui ralentit ou bloque la réplication (événement 4202). 

- ► Dimensionnement usuel : la taille des plus gros fichiers modifiés simultanément, avec de la marge. 

Page 233 

## **THE Démonstration** 

Titre de la formation 

Page 236 

#### **Ce qu’il faut retenir** 



- Le staging est local à chaque membre : RDC y prépare les blocs avant transfert. 

- Un staging sous-dimensionné est la première cause de réplication lente. 

- Dans un réseau rapide il n’est pas utile d’utiliser la fonctionnalité RDC. 

##### Titre de la formation 

- DFSR se base sur les informations du journal NTFS (usn) 

Page 237 

P05 

**Partie : Infrastructure as code (IAC)** Titre de la formation 

Page 238 

Titre de la formation 

## **Chapitre 27 : IAC - Introduction** 

Page 239 

C27 

#### **Les techniques de création de machines virtuelles** 

- Via GUI (Graphical User Interface) 

- Via Powershell 

Titre de la formation 

- Via un import / export 

► Template / Golden Image 

Page 240 

► Via IAC 

#### **Les typologies de déploiement** 

Déploiement via GUI 

Titre de la formation 

Page 241 

- Lent 

- ► Source d’erreurs humaines 

- Non documenté by design 

- Non reproductible 

- ► Deux admin != même configuration 

Déploiement via IAC 

- Déploiement rapide de dizaines de VM 

- Infrastructure toujours identique (dev / rec / prod) 

- Rebuild rapide après incident 

- Versionné, automatisable, reproductible, auditable 

#### **Les technologies du IAC** 

Titre de la formation Page 242 

Git (Versionning) Terraform Packer Vagrant Ansible SCVMM Powershell Container Windows Docker 

#### **Ce qu’il faut retenir** 

- L’infrastructure as code (IAC) permets de répondre à des enjeux  de versionning, d’automatisation, reproduction, audition et surtout d’isométrie. 

##### Titre de la formation 

- Les principales technologies de l’IAC dans le secteur de la virtualisation sont : 

   - Terraform 

   - Packer 

   - Ansible 

Page 243 

- Git 

- Docker 

**Chapitre 28 : IAC - Présentation de Terraform** Titre de la formation 

Page 244 

C28 

**Les trois notions clés autour de terraform** 

Titre de la formation 

Les connecteurs Le cœur de Rôle dans IAC de terraform : terraform : Les ressources Les providers 

Page 245 

#### **La notion de provider** 

Un provider est un plugin qui permet à Terraform de communiquer avec un environnement cloud. Les providers 

- Expose des API 

- Permet à terraform de créer/détruire des ressources 

##### Titre de la formation 

- Faire le lien entre votre code et l’hyperviseur 

Page 246 



<!-- Start of picture text -->
Titre de<br>la formation<br>Page 247<br><!-- End of picture text -->

#### **Les exemples de provider** 



<!-- Start of picture text -->
VMWare<br>Hyper-V Proxmox<br>Vsphere<br>Microsoft<br>AWS<br>Azure<br><!-- End of picture text -->

#### **Schéma d’explication de Terraform** 

##### Titre de la formation 

Page 248 



<!-- Start of picture text -->
LT HYPERVISEURS<br>Ng Terraform (Infrastructure cible)<br>vmwere =<br>terraform init terraform plan terraform apply terraform destroy — att<br>dl; & + vSphere ESXi<br>inane<br>wh b W Cia+ vCenter<br>XPRoxmox aa<br>PROVIDER Bao<br>+ ProxmoxVE ea<br>Le provider est le plugin qui permet a Terraform —--- * KVM/LXC<br>d'interagir avec une plateforme (hyperviseur, cloud, ...) via son API. oii =<br>BB Microsoft ea<br>vmware MIE Microsott | YK AN aws GB Hyper-v =<br>vvtrentcom MIE Hyper-V ppoxmox ei niesllr + Hyper-V Host<br>+ Failover Cluster<br>1 | A Microsoft<br>Une ressource représenteRESSOURCEun élément d'infrastructure + Azuread Compute cs<br>géré par Terraform * Azure Network<br>+ Azure Disk<br>a= cS ese @ peae<br>Virtual Machine Réseau Virtuel Disque Security Group : Hes<br>vm_resource network_resource disk_resource sg_resource EBS<br><!-- End of picture text -->

##### Titre de la formation 

Page 249 

#### **Ce qu’il faut retenir** 



- Terraform exploite de multiprovider 

- Terraform permet de provisionner des machines virtuelles au sein d’un cloud. 

- Terraform permet de définir la configuration d’une VM 

- Il existe 4 commandes grandes commande : Init, plan, apply, destroy 

Titre de la formation 

## **Chapitre 29 : IAC – Customiser des ISO de Windows** 

Page 250 

C29 

#### **Automatiser la configuration avec des fichiers de réponses** 

- Déployer Windows ou Linux à grande échelle (serveurs, poste de travail) 

- Avoir des images reproductibles, rapides et standardisées 

Titre de la formation 

- Éliminer la potentialité d’erreur humaine 

Page 251 

- Éviter la phase de questions interactives 



<!-- Start of picture text -->
Titre de<br>la formation<br>Page 252<br><!-- End of picture text -->

**Quels fichiers définir pour automatiser l’installation** 

**<u>Linux : Windows :</u>** Kickstart / Autounattend.xml Autoinstall Unattend.xml Cloud-init 

**Les différentes phases du fichier unattend.xml** 

Titre de la formation 

Page 253 

**<u>WindowsPE</u>** _langue, disques .._ 





**<u>Specialize</u>** _hostname, domaine, licence, réseau, parefeu,.._ 

**<u>OobeSystem</u>** _Compte utilisateur, configuration cortana, clavier_ , 



#### **OSCDimg** 

- Outil en ligne de commande fourni par Microsoft 

- Permets de **créer des images ISO bootables** à partir de fichiers ou de dossiers 

Titre de la formation 

Page 254 

- **OSDimg fait partie de l’ensemble d’outils ADK** (Assessment and Deployment Kit). 

- ► **ADK permet de déployer, personnaliser et tester** des images Windows 

##### **Téléchargez et installez ADK** _Assessment and Deployment Kit_ 

- Télécharger ADK 

<u>https://learn.microsoft.com/fr-fr/windows-hardwa re/get-started/adk-install#download-the-adk-1012 61009457-september-2026</u> 

Titre de la formation 

Page 255 

- Installer ADK (vérifier que la fonctionnalité outils de déploiement est bien activée) 

- Ajouter dans vos variables d’environnement OSCDimg 

C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg 

#### **Intégrer votre fichier de réponse dans l’image Windows** 

###### Protocole de création 

- Monter l’ISO originale de Windows 

- Copier tout le contenu de l’ISO dans un dossier de travail 

- Démonter l’ISO 

- Copier le fichier autounattend.xml à la racine du dossier 

Titre de la formation 

- Recréer l’ISO avec OSCDImg 

Page 256 

#### **Création de l’ISO Custom : phase 1 à 3** 

$isoOriginal = "C:\terraform\vms\vm1\windows2025.iso" $mount = Mount-DiskImage -ImagePath $isoOriginal -PassThru $lettre = ($mount | Get-Volume).DriveLetter 

Titre de la formation 

$dossierTravail = "C:\terraform\tmp\win2025" New-Item -ItemType Directory -Force $dossierTravail Copy-Item "${lettre}:\*" $dossierTravail -Recurse -Force Dismount-DiskImage -ImagePath $isoOriginal 

Page 257 

#### **Création de l’ISO Custom : phase 4 et 5** 

Copy-Item "C:\terraform\vms\vm2\unattend\autounattend.xml" "$dossierTravail\autounattend.xml" 

##### Titre de la formation 

Page 258 

$oscdimg   = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe" $isoFinale = "C:\terraform\vms\vm2\windows2025_unattend.iso" 

& $oscdimg  -m   -o   -u2   -udfver102   -l"WS2025_UNATTEND" -bootdata:"2#p0,e,b${dossierTravail}\boot\etfsboot.com#pEF,e,b$ {dossierTravail}\efi\microsoft\boot\efisys_noprompt.bin" ` $dossierTravail ` $isoFinale 

## **Démonstration** 

Titre de la formation 

Page 259 

#### **Ce qu’il faut retenir** 



► A FAIRE 

Titre de la formation 

Page 260 

## **Chapitre 29 : IAC - Installation de Terraform et** Titre de la formation **prérequis** 

Page 261 

C29 

#### **Listes des actions à réaliser avant de lancer son premier terraform sur Hyper-V** 

- Préparer le système 

- Configurer  WinRM 

- Créer un utilisateur dédié au déploiement 

- Customiser un ISO de Windows Serveur 

Titre de la formation 

- Déploiement de notre première machine 

Page 262 

#### **Installer Terraform** 

- Téléchargez terraform sur le site de Hashicorp 

- Décompresser le fichier dans votre répertoire 

##### Titre de la formation 

Page 264 

- Vérifier la version installée 

PS C:\terraform> .\terraform.exe --version Terraform v1.14.9 on windows_amd64 PS C:\terraform> 

#### **Ajouter Terraform dans nos variables d’environnement** 

- Windows+R et inscrire : sysdm.cpl 

- Accéder à l’onglet « Paramètre système avancé » 

- Cliquer sur le bouton « Variable d’environnement » 

- Sélectionner la ligne « Path » de votre utilisateur 

- Ajouter le chemin pour accéder à votre répertoire terraform 

Titre de la formation 

Page 265 

#### **Ajouter Terraform dans nos variables d’environnement** 



<!-- Start of picture text -->
Titre de  ets<br>see<br>la formation Prof des<br><!-- End of picture text -->



<!-- Start of picture text -->
Prof des lecteur<br>Peremitres Bureau és & vote cones<br><!-- End of picture text -->



<!-- Start of picture text -->
Viable environnement x<br>Variables_  uiiateur pour Micka! Modifierla variable d'environnement x<br>Vorable pane ValeurTras e=\User\ Mi im e eNien<br>ChocolateyToolsLocation _Ci\tools ‘C:\Program Files\Oracle\VirtualBox | Modifier<br>OneDrivePath C :\Users\Mickael\scoop\shims;C:\Users\Mickael\AppData\Local\M...\User\Mickaeh\OneDrive ‘ C :\wampé64\bin\php\AUsers\Mickael Ap p hp8.4.0Data\Reaming\Compozer\vendor\bin aParcourir...<br>TEMP (C\Users\Mickael\AppDatalLocah Temp ‘CA\Program Files 085)\Nmap oe<br>™P CAUsers\Mickael\AppData\Local\Temp ‘CA\Users\Mickaeh AppData\Reaming\npm Supprimer<br>7 [c\teraform| oO<br>Nowell... | Mesifie..._Supprimer Déptcervasteha]<br>Variables systeme Déplacerversle bas |<br>Vavabie Valeur<br><!-- End of picture text -->



<!-- Start of picture text -->
Page 266<br><!-- End of picture text -->

#### **Préparer le système Windows** 

Vérifier que votre réseau est en profil privé Get-NetConnectionProfile Name                     :  MonReseau (wifi ou ethernet) InterfaceAlias           : vEthernet (Test) InterfaceIndex           : 26 NetworkCategory          : Public Titre de DomainAuthenticationKind : None la formation IPv4Connectivity         : Internet IPv6Connectivity         : Internet Page 267 Set-NetConnectionProfile -InterfaceIndex 26 –NetworkCategory Private 

#### **Activer et vérifier le lancement de WinRM** 

##### Titre de la formation 

Page 268 

Activer le lancement de WinRM et vérifier les Listeners winrm quickconfig –force Get-Service WinRM winrm enumerate winrm/config/listener Listener Address = * Transport = HTTP Port = 5985 Hostname Enabled = true URLPrefix = wsman CertificateThumbprint ListeningOn = 127.0.0.1, 192.168.1.55,  …. 

#### **Configurer WinRM** 

- Activer l’envoi de commande Powershell à distance 

- Autoriser les connexions sans chiffrement 

- Autoriser les connexions avec une authentification utilisateur/mdp 

Titre de la formation 

Page 269 

Enable-PSRemoting –Force 

Set-Item WSMan:\localhost\Service\AllowUnencrypted -Value $true 

Set-ItemProperty -Path "HKLM: \SOFTWARE\Microsoft\Windows\CurrentVersion\WSMAN\Service" -Name "allow_unencrypted"  -Value 1 -Type DWord 

Set-Item WSMan:\localhost\Service\Auth\Basic -Value $true 

#### **Configurer WinRM** 

- Autoriser les connexions sans chiffrement 

- Autoriser les connexions avec une authentification utilisateur/mdp 

Titre de la formation 

Page 270 

winrm set winrm/config/service '@{AllowUnencrypted="true"}' winrm set winrm/config/client '@{AllowUnencrypted="true"}' winrm set winrm/config/service/auth '@{Basic="true"}' winrm set winrm/config/client/auth '@{Basic="true"}' 

###### **Créer un utilisateur dédié au déploiement** 

- Créer un utilisateur 

- Affecter les droits d’administrateur à l’utilisateur 

Titre de la formation 

Page 271 

New-LocalUser -Name "terraform" ` -Password (ConvertTo-SecureString "P@ssword/59" -AsPlainText -Force)  -PasswordNeverExpires 

Add-LocalGroupMember -Group "Administrateurs" -Member "terraform" 

#### **Vérifier la connectivité avec WinRM** 

- Utiliser les commandes Invoke-Command et TestWSMan 

$cred = Get-Credential 

Test-WSMan -ComputerName localhost -Authentication Basic -Credential $cred 

Titre de la formation 

Page 272 

Invoke-Command -ComputerName localhost ` -Credential $cred ` -Authentication Basic ` -ScriptBlock { whoami } ` -SessionOption (New-PSSessionOption -NoEncryption) 

**Les fichiers / répertoires principaux de Terraform** **<u>Variables.tf et Main.tf terraform.tfvar</u>** Ressources (VM, **<u>s</u>** disque…) Déclaration des Provider variables configuration Instanciation globale des variables Titre de la formation **<u>.terraform/ Outputs.tf</u>** Plugins (provider) Page 273 Afficher les Dépendance résultats après Les verrous exécution terraform.tfstate 

#### **Pré requis à la création de la VM** 

ISO de Windows Main.tf officielle 

Titre de la formation 

Page 274 

ISO de Windows Un fichier de custom avec le réponse fichier de réponse unattend.xml créé par oscdimg 

#### **Intégrer votre fichier de réponse dans l’image Windows** 

###### Protocole de création 

- Monter l’ISO originale de Windows 

- Copier tout le contenu de l’ISO dans un dossier de travail 

- Démonter l’ISO 

- Copier le fichier autounattend.xml à la racine du dossier 

Titre de la formation 

- Recréer l’ISO avec OSCDImg 

Page 275 

#### **Création de l’ISO Custom : phase 1 à 3** 

$isoOriginal = "C:\terraform\vms\vm1\windows2025.iso" $mount = Mount-DiskImage -ImagePath $isoOriginal -PassThru $lettre = ($mount | Get-Volume).DriveLetter 

Titre de la formation 

$dossierTravail = "C:\terraform\tmp\win2025" New-Item -ItemType Directory -Force $dossierTravail Copy-Item "${lettre}:\*" $dossierTravail -Recurse -Force Dismount-DiskImage -ImagePath $isoOriginal 

Page 276 

#### **Création de l’ISO Custom : phase 4 et 5** 

Copy-Item "C:\terraform\vms\vm2\unattend\autounattend.xml" "$dossierTravail\autounattend.xml" 

##### Titre de la formation 

Page 277 

$oscdimg   = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe" $isoFinale = "C:\terraform\vms\vm2\windows2025_unattend.iso" 

& $oscdimg  -m   -o   -u2   -udfver102   -l"WS2025_UNATTEND" -bootdata:"2#p0,e,b${dossierTravail}\boot\etfsboot.com#pEF,e,b$ {dossierTravail}\efi\microsoft\boot\efisys_noprompt.bin" ` $dossierTravail ` $isoFinale 

## **Démonstration** 

Titre de la formation 

Page 278 

#### **Ce qu’il faut retenir** 



- Terraform est un simple exécutable à ajouter dans son path. 

- Terraform nécessite plusieurs éléments de préconfiguration 

##### Titre de la formation 

Page 279 

- Plusieurs fichiers .tf permettent de s’interfacer avec terraform (main, variables, outputs ou encore le répertoire terraform) 

**Chapitre 30 : IAC - Définition de notre première machine** Titre de **via Terraform** la formation 

Page 280 

C30 

#### **Les éléments de mon premier main.tf** 

- Définition du provider 

- Information de connexion à l’API du provider 

Titre de la formation 

Page 281 

- Définir une ressource de disque dur 

- Définir la configuration de la VM 

#### **Définition du provider et des informations de connexion** 

terraform { required_providers { hyperv = { source  = "taliesins/hyperv" version = "> 1.0" } } } 

##### Titre de la formation 

Page 282 

provider "hyperv" { host     = "WIN2025-SRV2" port     = 5985 https    = false insecure = true user     = "terraform" password = "P@ssword59!" use_ntlm = false timeout  = "60s" } 

#### **Définition du disque dur** 

Une architecture réseau doit harmoniser : 

- Nom du disque 

- Emplacement du disque 

- Taille du disque 

Titre de la formation 

Page 283 

- Taille d’un bloc 

resource "hyperv_vhd" "disk_vm" { path       = "C:\\terraform\\vms\\vm_disk.vhdx" size       = 40 * 1024 * 1024 * 1024 block_size = 1048576 } 

#### **Définition de la séquence de démarrage (bootorder)** 

vm_firmware { enable_secure_boot    = "off" 

##### Titre de la formation 

Page 284 

boot_order { boot_type           = "DvdDrive" controller_number   = 0 controller_location = 1   # ISO Windows } boot_order { boot_type           = "HardDiskDrive" controller_number   = 0 controller_location = 0 } } 

#### **Attachement d’une carte réseau et des disques à la machine virtuelle** 

network_adaptors { 

name        = "eth0" switch_name = "Intel(R) 82574L Gigabit Network Connection - Virtual Switch" } 

##### Titre de la formation 

Page 285 

hard_disk_drives { path                = hyperv_vhd.disk_vm.path controller_number   = 0 controller_location = 0   # SCSI 0:0 } 

###### dvd_drives { 

path                = "C:\\terraform\\windows2025_unattend.iso" controller_number   = 0 → controller_location = 1  # SCSI 0:1 prioritaire dans le boot_order } 

} 

#### **Ajout d’une ressource complémentaire** 

resource "null_resource" "start_vm" { depends_on = [hyperv_machine_instance.vm, hyperv_vhd.disk_vm] 

Titre de la formation 

Page 286 

provisioner "local-exec" { interpreter = ["PowerShell", "-Command"] command     = <<-EOT Start-Sleep -Seconds 60 Start-VM -Name "VM_TERRAFORM_01" EOT } } 

#### **Ce qu’il faut retenir** 

- Le fichier main.tf permet de définir la machine virtuelle à créer dans l’hyperviseur 

- Le fichier main.tf doit contenir : 

Titre de la formation 

Page 287 

- Un provider 

- Des éléments de connexion vers l'hyperviseur 

- La définition de la machine virtuelle (cpu, ram, disque, réseau, ordre de boot, conf powershell) 

C31 

Titre de la formation 

## **Chapitre 31 : IAC - Les commandes Terraform** 

Page 288 



<!-- Start of picture text -->
Titre de<br>la formation<br>Page 289<br><!-- End of picture text -->

#### **Les différentes commandes Terraform** 



<!-- Start of picture text -->
Fmt Initialisation<br>Validate Plan<br>Apply State<br>Destroy<br><!-- End of picture text -->

#### **Utilisation de la commande Format** 

- Rôle : Formater le code 

- Objectif : Améliorer la lecture du code en utilisant l’indentation 

##### Titre de la formation 

PS C:\vm1> terraform.exe fmt 

Page 290 

#### **Terraform init** 

###### **Initialiser le projet Terraform.** 

- Télécharge les providers (ex : hyperv) 

- Crée le dossier .terraform 

Titre de la formation 

Page 291 

PS C:\vm1> terraform.exe init PS C:\vm1> terraform.exe init –reconfigure (après modif) 

#### **Terraform validate** 

**Vérifie la syntaxe et cohérence des fichiers .tf** 

- Détecter les fautes de frappe 

- Détecter les arguments invalides 

- Détecter les blocs incorrects 

Titre de la formation 

PS C:\vm1> terraform.exe validate 

Page 292 

#### **Terraform plan** 

**Simule ce que Terraform va réaliser comme action** 

- Compare état actuel et l’état attendu 

- Affiche les ressources à créer, modifier et supprimer 

Titre de la formation 

Page 293 

PS C:\vm1> terraform.exe plan (-json –nocolor) 

#### **Terraform apply** 

###### **Applique réellement les changements** 

- Crée la VM 

- Créer le disque 

Titre de la formation 

Page 294 

- Configure les ressources 

PS C:\vm1> terraform.exe apply (-autoapprove) 

#### **Terraform destroy** 

###### **Applique réellement les changements** 

- Supprime la VM 

- Supprime les disques 

Titre de la formation 

Page 295 

- Nettoie l’environnement 

PS C:\vm1> terraform.exe destroy (-autoapprove) 

#### **Terraform state** 

###### **Manipule l’état Terraform** 

► Affiche les ressources 

Titre de la formation 

PS C:\vm1> terraform.exe state list 

Page 296 

## **Démonstration** 

Titre de la formation 

Page 297 

##### Titre de la formation 

#### **Ce qu’il faut retenir** 



- Terraform init permet de télécharger le provider 

- Terraform apply permet d’appliquer les changements 

- ► Terraform destroy permet de supprimer les ressources créées 

Page 298 

C01 

**Chapitre 19 : Packer** Titre de la formation 

Page 299 

**Packer (Créer des images de VM standardisées, reproductibles et versionnées)** 

- Créer des images de VM 

- Terraform les implémente en usage multiple 

Titre de la formation 

Page 300 

**Chapitre 20 : Installation de** Titre de **Packer et prérequis** la formation 

Page 301 

C01 

#### **Installer Packer** 

- Télécharger Packer sur le site de Hashicorp 

- Décompresser le fichier dans votre répertoire 

- Vérifier la version installée 

- Ajouter Packer dans les variables d’environnement 

Titre de la formation 

Page 302 

C:\Program Files\Packer>packer.exe -version Packer v1.15.3 

C01 

**Chapitre 21 : Les commandes Packer** Titre de la formation 

Page 303 

#### **Les différentes commandes Packer** 

Titre de la formation 

Page 304 



<!-- Start of picture text -->
Fmt<br><!-- End of picture text -->

Build 

Init 



<!-- Start of picture text -->
Validate<br><!-- End of picture text -->

Inspect 

#### **Utilisation des commandes init, validate et format** 

- Nécessite de préciser le répertoire de localisation des fichiers. 

- Le symbole « . » Permet de préciser répertoire actuel. 

Titre de la formation 

PS C:\packer\vms\vm1> packer.exe init . PS C:\packer\vms\vm1> packer.exe validate . PS C:\packer\vms\vm1> packer.exe fmt . 

Page 305 

#### **Définition du provider et des informations de connexion** 

packer { required_plugins { hyperv = { version = ">= 1.1.0" source  = "github.com/hashicorp/hyperv" } } } 

##### Titre de la formation 

Page 306 

variable "admin_password" { type    = string default = "P@ssword59!" } 

#### **Définition du provider et des informations de connexion** 

source "hyperv-iso" "windowsserver2025" { # Configuration de l'ISO iso_url      = "C:\\Users\\Mickael\\Packer\\image3\ \windows2025_unattend.iso" iso_checksum = "sha256:56B76C6D7FDB0690BEC6CF860ED30225933523EF8DDE FC686FF2D8AD43D62B10" 

Titre de la formation 

Page 307 

vm_name            = "WinServer2025-HyperV-Template" generation         = 2 # Équivalent UEFI pour Hyper-V cpus               = 4 memory             = 8192 disk_size          = 61440 switch_name        = "Default Switch" enable_secure_boot = false headless           = false output_directory   = "output-hyperv" 

#### **Définition du provider et des informations de connexion** 

# Configuration du communicateur WinRM communicator   = "winrm" winrm_username = "Administrateur" winrm_password = var.admin_password winrm_timeout  = "2h" winrm_insecure = true winrm_use_ssl  = false 

Titre de la formation 

Page 308 

# Boot parameters boot_wait    = "5s" boot_command = ["<enter>"] 

- # On laisse cette commande pour que Packer sache quoi faire si le Sysprep ne coupe pas tout shutdown_command = "" shutdown_timeout = "30m" 

#### **Définition du provider et des informations de connexion** 

build { 

sources = ["source.hyperv-iso.windowsserver2025"] 

# Deuxième bloc : Validation de connexion provisionnée "powershell" { 

inline = ["Write-Output 'Connecté via WinRM sur Hyper-V ! '"] } 

##### Titre de la formation 

Page 309 

provisioner "powershell" { inline = [ 

"Write-Output 'Lancement du Sysprep en tâche de fond...'", "Remove-Item -Path C:\\Windows\\Panther\\Unattend.xml -ErrorAction SilentlyContinue", 

"Start-Sleep -Seconds 20", "Start-Process -FilePath C:\\Windows\\System32\\Sysprep\ \Sysprep.exe -ArgumentList '/oobe /generalize /shutdown'" ] } } 

## **Démonstration** 

Titre de la formation 

Page 310 

**Conclusion** Titre de la formation 

Page 311 

P05 

