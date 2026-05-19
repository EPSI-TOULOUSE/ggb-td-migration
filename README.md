# TD Pratique — Migration de données

**EPSI — ASRBD / STESE636**

Tests d'intégration & Migration de données

## Étudiants

- Lucas Baduel
- Quentin Grenier
- Valentin Gorrin

---

# Contexte général du TP

Ce TP consiste à simuler une migration de données entre deux data centers.

L'environnement est reproduit localement avec Docker et deux instances PostgreSQL distinctes.

Source : Montpellier avec le conteneur Docker `pg_montpellier`

Cible : Toulouse avec le conteneur Docker `pg_toulouse`

Moteur de base de données : PostgreSQL

Fichiers source : `data_montpellier/supports/`

Fichiers cible : `data_toulouse/supports/`

Réseau Docker : `migration_net`

---

# Étape 0 — Préparation de l'environnement local

## 1) Démarrer les services

```shell
docker compose up -d
```

## 2) Vérifier que les conteneurs sont démarrés

```shell
docker ps
```

Résultat attendu :

```text
pg_montpellier
pg_toulouse
```

## 3) Injecter les données de base

```shell
docker exec -i pg_montpellier psql -U admin -d techcorp_db < init_source.sql
```

## 4) Vérifier les tables

```shell
docker exec -it pg_montpellier psql -U admin -d techcorp_db -c '\dt'
```

Tables attendues :

```text
formations
progressions
resultats_examens
utilisateurs
```

---

# Niveau 1 — Migration « Big Bang »

## Principe de la méthode

La migration « Big Bang » est une stratégie de bascule directe.

Elle consiste à transférer l'intégralité du système d'un état source à un état cible en une seule opération planifiée.

Cette méthode est simple à mettre en place, mais elle nécessite une coupure complète du service pendant toute la durée de la migration.

## Contexte du niveau 1

Source : Montpellier avec le conteneur Docker `pg_montpellier`

Cible : Toulouse avec le conteneur Docker `pg_toulouse`

Moteur de base de données : PostgreSQL

Fichiers source : `data_montpellier/supports/`

Fichiers cible : `data_toulouse/supports/`

## Étapes de la migration

### 1) Arrêt du service source

Script associé :

```shell
./niveau1_bigbang/01_arret_source.sh
```

Objectifs :

Passer la base source en mode lecture seule.

Simuler l'arrêt complet des écritures applicatives.

Enregistrer l'heure exacte du début de la coupure de service.

Vérifier les transactions actives.

Commande principale :

```sql
ALTER DATABASE techcorp_db SET default_transaction_read_only = on;
```

Résultat attendu :

```text
ALTER DATABASE
OK : Base source passée en lecture seule
```

### 2) Export complet de la base source

Script associé :

```shell
./niveau1_bigbang/02_export_source.sh
```

Objectifs :

Exporter l'intégralité de la base PostgreSQL source.

Créer une sauvegarde compressée au format `.dump`.

Copier automatiquement la sauvegarde dans le dossier `backups/`.

Vérifier que le fichier de sauvegarde généré n'est pas vide.

Commande principale :

```shell
docker exec pg_montpellier pg_dump -U admin -d techcorp_db -F c -v -f /tmp/techcorp_backup.dump
```

Résultat attendu :

```text
OK : Sauvegarde créée
OK : le fichier de sauvegarde existe et n’est pas vide
```

Exemple de fichier généré :

```text
backups/techcorp_bigbang_20260519_112816.dump
```

### 3) Transfert des fichiers avec rsync

Script associé :

```shell
./niveau1_bigbang/03_transfert_fichiers.sh
```

Objectifs :

Copier les fichiers de support pédagogiques de Montpellier vers Toulouse.

Vérifier que le nombre de fichiers sur la cible est identique à la source.

Valider l'intégrité des fichiers transférés avec des checksums MD5.

Commande principale :

```shell
rsync -avh --progress --checksum ./data_montpellier/supports/ ./data_toulouse/supports/
```

Résultat attendu :

```text
Fichiers source : 5
Fichiers cible : 5
OK : même nombre de fichiers
OK : checksums identiques
```

### 4) Restauration sur la cible Toulouse

Script associé :

```shell
./niveau1_bigbang/04_restauration_cible.sh
```

Objectifs :

Récupérer le dernier fichier `.dump` généré.

Copier le fichier de dump dans le conteneur cible `pg_toulouse`.

Restaurer entièrement la base sur la cible.

Vérifier la présence de toutes les tables.

Commande principale :

```shell
docker exec pg_toulouse pg_restore -U admin -d techcorp_db -v --clean --if-exists /tmp/techcorp_backup.dump
```

Tables attendues :

```text
formations
progressions
resultats_examens
utilisateurs
```

### 5) Vérification de l’intégrité

Script associé :

```shell
./niveau1_bigbang/05_verification.sh
```

Objectifs :

Comparer le volume de données entre Montpellier et Toulouse.

Vérifier la cohérence des contraintes de clés étrangères.

Contrôler la conformité des fichiers transférés.

Résultat obtenu :

| Table | Montpellier | Toulouse |
|---|---:|---:|
| utilisateurs | 5 | 5 |
| formations | 4 | 4 |
| progressions | 6 | 6 |
| resultats_examens | 3 | 3 |

Fichiers vérifiés :

| Dossier | Nombre de fichiers |
|---|---:|
| `data_montpellier/supports/` | 5 |
| `data_toulouse/supports/` | 5 |

## Avantages

Méthode simple : processus linéaire, facile à comprendre et à documenter.

Mise en place rapide : peu de configuration nécessaire.

Intégrité forte : l'arrêt des écritures limite les risques de désynchronisation.

Adaptée aux petits volumes : efficace pour une base légère ou un environnement de test.

## Inconvénients

Coupure totale : le service est indisponible pendant toute la migration.

Risque élevé : si la restauration échoue, la coupure est prolongée.

Peu adaptée aux gros volumes : le temps d'export et de restauration peut devenir trop long.

Rollback nécessaire : il faut prévoir un retour arrière en cas d'échec.

## Conclusion du niveau 1

La migration « Big Bang » est la méthode la plus simple, mais aussi la plus risquée concernant la disponibilité du service.

Elle convient lorsque le volume de données est maîtrisé et qu'une coupure complète est acceptable.

Dans ce TP, le niveau 1 est validé car les données et les fichiers sont identiques entre Montpellier et Toulouse après la migration.

---

# Niveau 2 — Migration « Progressive »

## Principe de la méthode

La migration « Progressive » est une stratégie de migration par étapes.

Elle consiste à synchroniser une première fois les données avant la coupure, puis à transférer uniquement les changements restants lors d'une courte fenêtre de bascule.

Contrairement à la migration « Big Bang », le service source reste disponible pendant une grande partie de la migration. La coupure finale est donc plus courte.

## Contexte du niveau 2

Source : Montpellier avec le conteneur Docker `pg_montpellier`

Cible : Toulouse avec le conteneur Docker `pg_toulouse`

Moteur de base de données : PostgreSQL

Fichiers source : `data_montpellier/supports/`

Fichiers cible : `data_toulouse/supports/`

## Étapes de la migration

### 1) Synchronisation initiale complète

Script associé :

```shell
./niveau2_progressive/01_sync_initiale.sh
```

Objectifs :

Exporter une première copie complète de la base PostgreSQL source.

Restaurer cette copie initiale sur la cible Toulouse.

Copier une première fois les fichiers de support pédagogiques.

Réaliser cette étape hors fenêtre de coupure, sans arrêter le service source.

Commande principale :

```shell
docker exec pg_montpellier pg_dump -U admin -d techcorp_db --format=plain --no-owner --no-acl -f /tmp/sync_initiale.sql
```

Commande de synchronisation des fichiers :

```shell
rsync -avh --progress ./data_montpellier/supports/ ./data_toulouse/supports/
```

Résultat attendu :

```text
OK : Synchronisation initiale terminée
```

À cette étape, Toulouse possède une première copie des données et des fichiers de Montpellier.

### 2) Simulation d’activité utilisateur

Script associé :

```shell
./niveau2_progressive/02_simulation_activite.sh
```

Objectifs :

Simuler l'activité normale des utilisateurs après la synchronisation initiale.

Ajouter deux nouveaux utilisateurs dans la base source.

Mettre à jour une progression existante.

Ajouter un nouveau résultat d'examen.

Ajouter un nouveau fichier support dans le dossier source.

Commande principale :

```sql
INSERT INTO utilisateurs (nom, email) VALUES
('Francois Petit', 'francois@techcorp.fr'),
('Gaelle Simon', 'gaelle@techcorp.fr');
```

Commande de mise à jour :

```sql
UPDATE progressions
SET pourcentage = 100, derniere_activite = NOW()
WHERE utilisateur_id = 1 AND formation_id = 2;
```

Fichier ajouté :

```text
data_montpellier/supports/python_intro.pdf
```

Résultat attendu :

```text
2 nouveaux utilisateurs
1 progression mise à jour
1 nouveau résultat d'examen
1 nouveau fichier support
```

Après cette étape, la source Montpellier contient des données plus récentes que la cible Toulouse.

### 3) Synchronisation différentielle

Script associé :

```shell
./niveau2_progressive/03_sync_differentielle.sh
```

Objectifs :

Synchroniser les fichiers nouveaux ou modifiés depuis la dernière synchronisation.

Réduire le volume de données à transférer lors de la coupure finale.

Préparer la cible Toulouse avec les dernières modifications disponibles.

Commande principale :

```shell
rsync -avh --progress --checksum ./data_montpellier/supports/ ./data_toulouse/supports/
```

Résultat attendu :

```text
OK : Synchronisation différentielle terminée
```

L'intérêt de cette étape est d'éviter de retransférer tous les fichiers. Seuls les fichiers nouveaux ou modifiés sont copiés.

### 4) Coupure et synchronisation finale

Script associé :

```shell
./niveau2_progressive/04_coupure_finale.sh
```

Objectifs :

Démarrer la fenêtre de coupure.

Passer la base source Montpellier en mode lecture seule.

Effectuer la dernière synchronisation des fichiers.

Exporter l'état final de la base source.

Restaurer l'état final sur la cible Toulouse.

Commande principale :

```sql
ALTER DATABASE techcorp_db SET default_transaction_read_only = on;
```

Commande de synchronisation finale des fichiers :

```shell
rsync -avh --checksum --delete ./data_montpellier/supports/ ./data_toulouse/supports/
```

Commande d'export final :

```shell
docker exec pg_montpellier pg_dump -U admin -d techcorp_db --format=custom -f /tmp/sync_finale.dump
```

Commande de restauration finale :

```shell
docker exec pg_toulouse pg_restore -U admin -d techcorp_db --clean --if-exists -v /tmp/sync_finale.dump
```

Résultat attendu :

```text
OK : Source en lecture seule
OK : Fichiers synchronisés
OK : Export final créé
OK : Restauration finale terminée
```

L'option `--delete` de `rsync` permet de supprimer sur Toulouse les fichiers qui auraient été supprimés sur Montpellier. Elle garantit que le dossier cible est identique au dossier source.

### 5) Bascule et validation

Script associé :

```shell
./niveau2_progressive/05_bascule_validation.sh
```

Objectifs :

Comparer les comptages entre la source Montpellier et la cible Toulouse.

Vérifier que les données principales sont cohérentes avant la bascule.

Activer la cible Toulouse en lecture/écriture.

Valider la fin de la migration progressive.

Commande principale :

```sql
SELECT COUNT(*) FROM utilisateurs;
```

Résultat attendu :

```text
Utilisateurs source : 7
Utilisateurs cible : 7
OK : Comptages identiques – bascule autorisée
OK : Cible activée en lecture/écriture
OK : Migration progressive terminée avec succès
```

## Résultat attendu après migration

Après la simulation d'activité et la synchronisation finale, les volumes attendus sont :

| Élément | Résultat attendu |
|---|---:|
| Utilisateurs | 7 |
| Formations | 4 |
| Progressions | 6 |
| Résultats d'examens | 4 |
| Fichiers supports | 6 |

Les utilisateurs passent de 5 à 7 car deux utilisateurs sont ajoutés pendant la simulation d'activité.

Les résultats d'examens passent de 3 à 4 car un nouveau résultat est ajouté.

Les fichiers supports passent de 5 à 6 grâce à l'ajout du fichier `python_intro.pdf`.

## Avantages

Réduction de la coupure : une grande partie des données est transférée avant la fenêtre de coupure.

Méthode plus sûre que le Big Bang : la bascule finale traite moins de données.

Meilleure disponibilité : le service source continue à fonctionner pendant la synchronisation initiale.

Adaptée aux volumes moyens : permet de limiter le temps d'indisponibilité.

Contrôle progressif : les synchronisations successives permettent de vérifier l'état de la cible avant la bascule.

## Inconvénients

Complexité supérieure : la méthode nécessite plusieurs étapes et plusieurs scripts.

Risque de décalage temporaire : la source continue d'évoluer après la synchronisation initiale.

Vérifications nécessaires : il faut comparer les données avant la bascule.

Coupure toujours nécessaire : même réduite, une interruption reste nécessaire pour figer la source.

Gestion des suppressions : l'option `--delete` doit être utilisée avec prudence.

## Conclusion du niveau 2

La migration « Progressive » est un bon compromis entre simplicité et disponibilité.

Elle réduit fortement la durée de coupure par rapport à une migration « Big Bang », car la majorité du transfert est réalisée avant l'arrêt du service.

Cette méthode est recommandée lorsque la fenêtre de coupure est limitée, mais que la mise en place d'une réplication continue n'est pas nécessaire ou trop complexe.

---

# Niveau 3 — Migration avec « Réplication logique »

## Principe de la méthode

La migration avec réplication logique est une stratégie de migration continue.

Elle consiste à maintenir la base cible synchronisée en temps réel avec la base source grâce au mécanisme `PUBLICATION / SUBSCRIPTION` de PostgreSQL.

Contrairement aux migrations « Big Bang » et « Progressive », la cible reçoit automatiquement les changements effectués sur la source. La coupure finale est donc très courte, voire quasi nulle.

## Contexte du niveau 3

Source : Montpellier avec le conteneur Docker `pg_montpellier`

Cible : Toulouse avec le conteneur Docker `pg_toulouse`

Moteur de base de données : PostgreSQL

Mécanisme utilisé : réplication logique PostgreSQL

Publication source : `pub_techcorp`

Subscription cible : `sub_techcorp`

## Étapes de la migration

### 1) Vérification de la configuration

Script associé :

```shell
./niveau3_replication/01_verif_config.sh
```

Objectifs :

Vérifier que PostgreSQL est configuré avec le niveau WAL adapté à la réplication logique.

Contrôler que la valeur de `wal_level` est bien `logical`.

Afficher la version de PostgreSQL utilisée dans le conteneur source.

Commande principale :

```shell
docker exec pg_montpellier psql -U admin -c 'SHOW wal_level;'
```

Résultat attendu :

```text
logical
OK : Configuration WAL correcte
```

Cette vérification est indispensable car la réplication logique PostgreSQL nécessite `wal_level = logical`.

### 2) Création de la PUBLICATION sur la source

Script associé :

```shell
./niveau3_replication/02_publication.sh
```

Objectifs :

Créer une publication PostgreSQL sur la base source Montpellier.

Déclarer les tables qui seront répliquées vers la cible.

Vérifier que la publication est bien créée.

Afficher la liste des tables publiées.

Commande principale :

```sql
CREATE PUBLICATION pub_techcorp FOR ALL TABLES;
```

Commande de vérification :

```sql
SELECT pubname, puballtables FROM pg_publication;
```

Résultat attendu :

```text
pub_techcorp | true
OK : Publication créée sur la source
```

La publication permet à PostgreSQL de savoir quelles tables de la source doivent être rendues disponibles pour la réplication.

### 3) Préparation de la structure sur la cible

Script associé :

```shell
./niveau3_replication/03_structure_cible.sh
```

Objectifs :

Exporter uniquement le schéma de la base source, sans les données.

Créer la structure des tables sur la cible Toulouse.

Préparer la base cible avant de créer la subscription.

Vérifier que les tables sont bien présentes sur Toulouse.

Commande principale :

```shell
docker exec pg_montpellier pg_dump -U admin -d techcorp_db --schema-only --no-owner -f /tmp/schema_only.sql
```

Commande d'import du schéma :

```shell
docker exec pg_toulouse psql -U admin -d techcorp_db -f /tmp/schema_only.sql
```

Tables attendues :

```text
formations
progressions
resultats_examens
utilisateurs
```

Important : la réplication logique PostgreSQL ne crée pas automatiquement les tables sur la cible. Il faut donc créer le schéma manuellement avant de démarrer la subscription.

### 4) Création de la SUBSCRIPTION sur la cible

Script associé :

```shell
./niveau3_replication/04_subscription.sh
```

Objectifs :

Récupérer l'adresse IP du conteneur source `pg_montpellier`.

Créer une subscription sur la cible Toulouse.

Connecter la cible à la publication de la source.

Démarrer automatiquement la synchronisation des données.

Commande principale :

```sql
CREATE SUBSCRIPTION sub_techcorp
CONNECTION 'host=<IP_SOURCE> port=5432 dbname=techcorp_db user=admin password=admin123'
PUBLICATION pub_techcorp;
```

Commande de vérification :

```sql
SELECT subname, subenabled FROM pg_subscription;
```

Résultat attendu :

```text
sub_techcorp | true
```

Après cette étape, Toulouse commence à recevoir les données publiées par Montpellier.

### 5) Test de la réplication en temps réel

Script associé :

```shell
./niveau3_replication/05_test_replication.sh
```

Objectifs :

Comparer le nombre d'utilisateurs sur la source et la cible avant modification.

Insérer un nouvel utilisateur sur la source Montpellier.

Attendre quelques secondes pour laisser la réplication se faire.

Vérifier que la nouvelle donnée apparaît automatiquement sur Toulouse.

Commande principale :

```sql
INSERT INTO utilisateurs (nom, email)
VALUES ('Test Replication', 'test.replication@techcorp.fr');
```

Résultat attendu :

```text
Source : nombre d'utilisateurs augmenté
Cible : même nombre après quelques secondes
```

Si les deux comptages sont identiques après l'insertion, la réplication logique fonctionne correctement.

### 6) Bascule à chaud

Script associé :

```shell
./niveau3_replication/06_bascule_chaud.sh
```

Objectifs :

Vérifier que la réplication est à jour.

Passer la source Montpellier en lecture seule pour empêcher de nouvelles écritures.

Attendre la synchronisation finale.

Supprimer la subscription côté Toulouse.

Activer la cible Toulouse en lecture/écriture.

Commande principale :

```sql
ALTER DATABASE techcorp_db SET default_transaction_read_only = on;
```

Commande de suppression de la subscription :

```sql
DROP SUBSCRIPTION sub_techcorp;
```

Commande d'activation de la cible :

```sql
ALTER DATABASE techcorp_db SET default_transaction_read_only = off;
```

Résultat attendu :

```text
OK : Source en lecture seule
OK : Subscription supprimée
OK : Cible activée
OK : Migration avec réplication terminée
```

La bascule à chaud permet de réduire fortement la durée d'interruption du service.

### 7) Nettoyage post-migration

Script associé :

```shell
./niveau3_replication/07_nettoyage.sh
```

Objectifs :

Supprimer la publication côté source Montpellier.

Nettoyer les éléments de réplication devenus inutiles.

Vérifier l'état final de la cible Toulouse.

Commande principale :

```sql
DROP PUBLICATION IF EXISTS pub_techcorp;
```

Commande de vérification finale :

```sql
SELECT 'utilisateurs', COUNT(*) FROM utilisateurs
UNION ALL SELECT 'formations', COUNT(*) FROM formations
UNION ALL SELECT 'progressions', COUNT(*) FROM progressions
UNION ALL SELECT 'resultats_examens', COUNT(*) FROM resultats_examens;
```

Résultat attendu :

```text
OK : Publication supprimée sur la source
Etat final de la cible affiché correctement
```

## Résultat attendu après migration

Après le test de réplication et la bascule à chaud, les données doivent être identiques entre Montpellier et Toulouse.

Les volumes attendus dépendent de l'état de la base au moment du test.

| Élément | Résultat attendu |
|---|---:|
| Utilisateurs | 6 ou plus |
| Formations | 4 |
| Progressions | 6 |
| Résultats d'examens | 3 ou plus |

La valeur importante n'est pas seulement le nombre final, mais surtout l'égalité entre la source et la cible avant la bascule.

## Avantages

Coupure minimale : la cible est synchronisée en continu avec la source.

Risque de perte de données faible : les modifications sont répliquées automatiquement.

Méthode adaptée aux environnements critiques : elle convient aux services qui doivent rester disponibles.

Synchronisation en temps réel : les insertions, mises à jour et suppressions peuvent être propagées.

Bascule plus sécurisée : la cible est déjà prête au moment de la coupure finale.

## Inconvénients

Complexité élevée : la configuration est plus avancée que pour les autres méthodes.

Préparation obligatoire du schéma : les tables doivent exister sur la cible avant la subscription.

Surveillance nécessaire : il faut contrôler l'état de la réplication.

Risque de conflits : il ne faut pas écrire sur la cible pendant que la réplication est active.

Limites PostgreSQL : certaines opérations de structure ne sont pas répliquées automatiquement.

## Conclusion du niveau 3

La migration avec réplication logique est la méthode la plus avancée du TP.

Elle permet de maintenir Toulouse synchronisé avec Montpellier avant la bascule finale.

Elle est recommandée lorsque la disponibilité du service est prioritaire et que l'on souhaite réduire au maximum la durée de coupure.

En contrepartie, elle demande une configuration plus rigoureuse et une surveillance attentive de l'état de réplication.

---

# Synthèse comparative

| Critère | Big Bang | Progressive | Réplication logique |
|---|---|---|---|
| Coupure | Longue | Courte | Très courte |
| Complexité | Faible | Moyenne | Élevée |
| Risque de perte de données | Élevé | Moyen | Faible |
| Préparation avant bascule | Faible | Oui | Oui, en continu |
| Outils principaux | `pg_dump`, `pg_restore`, `rsync` | `pg_dump`, `pg_restore`, `rsync` | `PUBLICATION`, `SUBSCRIPTION` |
| Adapté aux gros volumes | Non | Moyen | Oui |
| Disponibilité du service | Faible | Moyenne | Élevée |

---

# Conclusion générale

Les trois méthodes permettent de migrer les données de Montpellier vers Toulouse, mais elles ne répondent pas au même besoin.

La migration « Big Bang » est simple, mais impose une coupure complète.

La migration « Progressive » réduit la durée de coupure en préparant une partie du transfert à l'avance.

La migration avec « Réplication logique » est la plus avancée et la plus adaptée lorsque la disponibilité du service est prioritaire.

Pour le contexte TechCorp Formation, la méthode recommandée est la réplication logique, car elle permet de réduire fortement le temps d'interruption et de sécuriser la bascule vers Toulouse.




