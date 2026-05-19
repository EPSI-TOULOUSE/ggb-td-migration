#!/bin/bash
echo '=== [NIVEAU 1] Export de la base source ==='
BACKUP_DIR='./backups'
BACKUP_FILE="$BACKUP_DIR/techcorp_bigbang_$(date +%Y%m%d_%H%M%S).dump"
mkdir -p $BACKUP_DIR

docker exec pg_montpellier pg_dump \
  -U admin -d techcorp_db \
  -F c -v \
  -f /tmp/techcorp_backup.dump

docker cp pg_montpellier:/tmp/techcorp_backup.dump $BACKUP_FILE
echo "OK : Sauvegarde creee : $BACKUP_FILE"
ls -lh $BACKUP_FILE

# Vérification fichier non vide
[ -s $BACKUP_FILE ] && echo 'OK : Fichier non vide' || { echo 'ERREUR : fichier vide'; exit 1; }
