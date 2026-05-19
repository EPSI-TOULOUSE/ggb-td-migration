#!/bin/bash
echo '=== [NIVEAU 2] Synchronisation initiale (hors coupure) ==='
echo "Debut : $(date)" | tee logs/coupure_n2.log

BACKUP_DIR='./backups'
mkdir -p $BACKUP_DIR

docker exec pg_montpellier pg_dump \
  -U admin -d techcorp_db \
  --format=plain --no-owner --no-acl \
  -f /tmp/sync_initiale.sql

docker cp pg_montpellier:/tmp/sync_initiale.sql $BACKUP_DIR/sync_initiale.sql
docker cp $BACKUP_DIR/sync_initiale.sql pg_toulouse:/tmp/sync_initiale.sql
docker exec pg_toulouse psql -U admin -d techcorp_db -f /tmp/sync_initiale.sql

rsync -avh --progress \
  ./data_montpellier/supports/ \
  ./data_toulouse/supports/

echo "OK : Synchronisation initiale terminee : $(date)" | tee -a logs/coupure_n2.log

# Checksum de l'état de la base à cet instant
docker exec pg_montpellier psql -U admin -d techcorp_db -t -c \
  "SELECT 'utilisateurs', COUNT(*) FROM utilisateurs
   UNION ALL SELECT 'formations', COUNT(*) FROM formations
   UNION ALL SELECT 'progressions', COUNT(*) FROM progressions
   UNION ALL SELECT 'resultats_examens', COUNT(*) FROM resultats_examens;" \
  > logs/checksum_sync_initiale.txt
echo "OK : Etat de la base enregistre dans logs/checksum_sync_initiale.txt"
cat logs/checksum_sync_initiale.txt
