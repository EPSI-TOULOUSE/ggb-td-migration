#!/bin/bash
echo '=== [NIVEAU 3] Creation de la structure sur la cible ==='

docker exec pg_montpellier pg_dump \
  -U admin -d techcorp_db \
  --schema-only --no-owner \
  -f /tmp/schema_only.sql

docker cp pg_montpellier:/tmp/schema_only.sql ./backups/schema_only.sql
docker cp ./backups/schema_only.sql pg_toulouse:/tmp/schema_only.sql

docker exec pg_toulouse psql -U admin -d techcorp_db -f /tmp/schema_only.sql

echo 'OK : Structure creee sur la cible'
echo '--- Tables presentes sur la cible ---'
docker exec pg_toulouse psql -U admin -d techcorp_db -c '\dt'

echo '--- Verification que les tables sont vides ---'
docker exec pg_toulouse psql -U admin -d techcorp_db -c \
  "SELECT 'utilisateurs', COUNT(*) FROM utilisateurs
   UNION ALL SELECT 'formations', COUNT(*) FROM formations
   UNION ALL SELECT 'progressions', COUNT(*) FROM progressions
   UNION ALL SELECT 'resultats_examens', COUNT(*) FROM resultats_examens;"
