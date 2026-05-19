#!/bin/bash
echo '=== [NIVEAU 3] Creation de la SUBSCRIPTION sur la cible ==='

# Supprimer si elle existe déjà
docker exec pg_toulouse psql -U admin -d techcorp_db -c \
  "DROP SUBSCRIPTION IF EXISTS sub_techcorp;"

SOURCE_IP=$(docker inspect pg_montpellier \
  --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
echo "IP du container source : $SOURCE_IP"

docker exec pg_toulouse psql -U admin -d techcorp_db -c \
  "CREATE SUBSCRIPTION sub_techcorp
   CONNECTION 'host=$SOURCE_IP port=5432 dbname=techcorp_db user=admin password=admin123'
   PUBLICATION pub_techcorp;"

echo 'OK : Subscription creee — replication en cours...'
sleep 5

echo '--- Etat de la subscription ---'
docker exec pg_toulouse psql -U admin -d techcorp_db -c \
  "SELECT subname, subenabled FROM pg_subscription;"

echo '--- Etat detaille de la replication ---'
docker exec pg_toulouse psql -U admin -d techcorp_db -c \
  "SELECT * FROM pg_stat_subscription;"

echo '--- Donnees arrivees sur la cible ---'
docker exec pg_toulouse psql -U admin -d techcorp_db -c \
  "SELECT 'utilisateurs', COUNT(*) FROM utilisateurs
   UNION ALL SELECT 'formations', COUNT(*) FROM formations
   UNION ALL SELECT 'progressions', COUNT(*) FROM progressions
   UNION ALL SELECT 'resultats_examens', COUNT(*) FROM resultats_examens;"
