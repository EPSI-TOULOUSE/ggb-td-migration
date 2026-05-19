# Niveau 1 — Migration « Big Bang »

**Étudiants :**

- Lucas Baduel
- Quentin Grenier
- Valentin Gorrin

## Principe de la méthode

La migration « Big Bang » est une stratégie de bascule directe.  
Elle consiste à transférer l'intégralité du système d'un état source à un état cible en une seule opération planifiée.

Cette méthode est simple à mettre en place, mais elle nécessite une coupure complète du service pendant toute la durée de la migration.

## Contexte du TP

L'environnement de ce Travaux Pratiques simule une migration inter-régionale entre deux instances conteneurisées représentant deux sites géographiques :

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

## Conclusion

La migration « Big Bang » est la méthode la plus simple, mais aussi la plus risquée concernant la disponibilité du service.

Elle convient lorsque le volume de données est maîtrisé et qu'une coupure complète est acceptable. Dans ce TP, le niveau 1 est validé car les données et les fichiers sont identiques entre Montpellier et Toulouse après la migration.
