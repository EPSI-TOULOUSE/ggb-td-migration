#!/bin/bash
echo '=== [NIVEAU 3] Nettoyage post-migration ==='

docker exec pg_montpellier psql -U admin -d techcorp_db -c \
  "DROP PUBLICATION IF EXISTS pub_techcorp;"
echo 'OK : Publication supprimee sur la source'

echo '--- Etat final de la cible ---'
docker exec pg_toulouse psql -U admin -d techcorp_db -c \
  "SELECT 'utilisateurs', COUNT(*) FROM utilisateurs
   UNION ALL SELECT 'formations', COUNT(*) FROM formations
   UNION ALL SELECT 'progressions', COUNT(*) FROM progressions
   UNION ALL SELECT 'resultats_examens', COUNT(*) FROM resultats_examens;"

echo '--- Verification cles etrangeres sur la cible ---'
docker exec pg_toulouse psql -U admin -d techcorp_db -c \
  "SELECT tc.table_name, kcu.column_name, ccu.table_name AS table_referencee
   FROM information_schema.table_constraints AS tc
   JOIN information_schema.key_column_usage AS kcu ON tc.constraint_name = kcu.constraint_name
   JOIN information_schema.constraint_column_usage AS ccu ON ccu.constraint_name = tc.constraint_name
   WHERE tc.constraint_type = 'FOREIGN KEY';"
