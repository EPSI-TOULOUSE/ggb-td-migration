#!/bin/bash
echo '=== [NIVEAU 2] Synchronisation differentielle ==='

echo '--- Fichiers : rsync differentiel ---'
rsync -avh --progress --checksum \
  ./data_montpellier/supports/ \
  ./data_toulouse/supports/

echo ''
echo '--- Comparaison comptages source vs cible ---'
echo 'SOURCE :'
docker exec pg_montpellier psql -U admin -d techcorp_db -t -c \
  "SELECT 'utilisateurs', COUNT(*) FROM utilisateurs
   UNION ALL SELECT 'formations', COUNT(*) FROM formations
   UNION ALL SELECT 'progressions', COUNT(*) FROM progressions
   UNION ALL SELECT 'resultats_examens', COUNT(*) FROM resultats_examens;"

echo 'CIBLE :'
docker exec pg_toulouse psql -U admin -d techcorp_db -t -c \
  "SELECT 'utilisateurs', COUNT(*) FROM utilisateurs
   UNION ALL SELECT 'formations', COUNT(*) FROM formations
   UNION ALL SELECT 'progressions', COUNT(*) FROM progressions
   UNION ALL SELECT 'resultats_examens', COUNT(*) FROM resultats_examens;"

echo 'OK : Synchronisation differentielle terminee — differences restantes visibles ci-dessus'
