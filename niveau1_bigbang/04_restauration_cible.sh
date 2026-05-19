#!/bin/bash
echo '=== [NIVEAU 1] Restauration sur la cible (Toulouse) ==='
BACKUP_FILE=$(ls -t ./backups/techcorp_bigbang_*.dump | head -1)

if [ -z "$BACKUP_FILE" ]; then
  echo 'ERREUR : Aucun fichier de sauvegarde trouve !'
  exit 1
fi
echo "Fichier utilise : $BACKUP_FILE"

docker cp $BACKUP_FILE pg_toulouse:/tmp/techcorp_backup.dump

docker exec pg_toulouse pg_restore \
  -U admin -d techcorp_db \
  -v --clean --if-exists \
  /tmp/techcorp_backup.dump

echo 'OK : Restauration terminee'

# Vérification tables restaurées
echo '--- Tables presentes sur la cible ---'
docker exec pg_toulouse psql -U admin -d techcorp_db -c '\dt'
