# Niveau 1 - Migration Big Bang

## Principe

La migration Big Bang consiste à arrêter le service source, exporter toutes les données, transférer les fichiers, restaurer la base sur la cible, puis vérifier l'intégrité.

Dans ce TP :

- Source : Montpellier avec le conteneur `pg_montpellier`
- Cible : Toulouse avec le conteneur `pg_toulouse`
- Base de données : PostgreSQL
- Fichiers source : `data_montpellier/supports/`
- Fichiers cible : `data_toulouse/supports/`

---

## Étapes de la migration

### 1. Arrêt du service source

Script utilisé :

```shell
./niveau1_bigbang/01_arret_source.sh
















