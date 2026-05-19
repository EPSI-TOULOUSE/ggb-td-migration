#!/bin/bash
echo '=== [NIVEAU 3] Creation de la PUBLICATION sur la source ==='

# Supprimer si elle existe déjà (idempotence)
docker exec pg_montpellier psql -U admin -d techcorp_db -c \
  "DROP PUBLICATION IF EXISTS pub_techcorp;"

docker exec pg_montpellier psql -U admin -d techcorp_db -c \
  "CREATE PUBLICATION pub_techcorp FOR ALL TABLES;"

echo '--- Publications actives ---'
docker exec pg_montpellier psql -U admin -d techcorp_db -c \
  "SELECT pubname, puballtables FROM pg_publication;"

echo '--- Tables publiees ---'
docker exec pg_montpellier psql -U admin -d techcorp_db -c \
  "SELECT * FROM pg_publication_tables;"

echo 'OK : Publication creee sur la source'
