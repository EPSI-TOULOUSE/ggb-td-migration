# Niveau 2 — Migration « Progressive »

**Étudiants :**

- Lucas Baduel
- Quentin Grenier
- Valentin Gorrin

## Principe de la méthode

La migration « Progressive » est une stratégie de migration par étapes.  
Elle consiste à synchroniser une première fois les données avant la coupure, puis à transférer uniquement les changements restants lors d'une courte fenêtre de bascule.

Contrairement à la migration « Big Bang », le service source reste disponible pendant une grande partie de la migration. La coupure finale est donc plus courte.

## Contexte du TP

L'environnement de ce Travaux Pratiques simule une migration inter-régionale entre deux instances conteneurisées représentant deux sites géographiques :

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

## Conclusion

La migration « Progressive » est un bon compromis entre simplicité et disponibilité.

Elle réduit fortement la durée de coupure par rapport à une migration « Big Bang », car la majorité du transfert est réalisée avant l'arrêt du service.

Cette méthode est recommandée lorsque la fenêtre de coupure est limitée, mais que la mise en place d'une réplication continue n'est pas nécessaire ou trop complexe.
