# Niveau 3 — Migration avec « Réplication logique »

**Étudiants :**

- Lucas Baduel
- Quentin Grenier
- Valentin Gorrin

## Principe de la méthode

La migration avec réplication logique est une stratégie de migration continue.  
Elle consiste à maintenir la base cible synchronisée en temps réel avec la base source grâce au mécanisme `PUBLICATION / SUBSCRIPTION` de PostgreSQL.

Contrairement aux migrations « Big Bang » et « Progressive », la cible reçoit automatiquement les changements effectués sur la source. La coupure finale est donc très courte, voire quasi nulle.

## Contexte du TP

L'environnement de ce Travaux Pratiques simule une migration inter-régionale entre deux instances conteneurisées représentant deux sites géographiques :

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

Les volumes attendus dépendent de l'état de la base au moment du test. Si le niveau 3 est lancé après les données initiales et le test de réplication, on attend notamment :

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

## Conclusion

La migration avec réplication logique est la méthode la plus avancée du TP.

Elle permet de maintenir Toulouse synchronisé avec Montpellier avant la bascule finale.

Elle est recommandée lorsque la disponibilité du service est prioritaire et que l'on souhaite réduire au maximum la durée de coupure. En contrepartie, elle demande une configuration plus rigoureuse et une surveillance attentive de l'état de réplication.
