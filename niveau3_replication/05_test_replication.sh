#!/bin/bash
echo '=== [NIVEAU 3] Test de la replication en temps reel ==='

echo '--- Avant insertion ---'
echo -n 'Source : '
docker exec pg_montpellier psql -U admin -d techcorp_db -t -c \
  'SELECT COUNT(*) FROM utilisateurs;' | tr -d ' '
echo -n 'Cible  : '
docker exec pg_toulouse psql -U admin -d techcorp_db -t -c \
  'SELECT COUNT(*) FROM utilisateurs;' | tr -d ' '

docker exec pg_montpellier psql -U admin -d techcorp_db -c \
  "INSERT INTO utilisateurs (nom, email)
   VALUES ('Test Replication', 'test.replication@techcorp.fr');"

sleep 2

echo '--- Apres insertion (2s) ---'
echo -n 'Source : '
docker exec pg_montpellier psql -U admin -d techcorp_db -t -c \
  'SELECT COUNT(*) FROM utilisateurs;' | tr -d ' '
echo -n 'Cible  : '
docker exec pg_toulouse psql -U admin -d techcorp_db -t -c \
  'SELECT COUNT(*) FROM utilisateurs;' | tr -d ' '

echo ''
echo '--- Test UPDATE ---'
docker exec pg_montpellier psql -U admin -d techcorp_db -c \
  "UPDATE utilisateurs SET nom = 'Test Replication MAJ' WHERE email = 'test.replication@techcorp.fr';"
sleep 1
docker exec pg_toulouse psql -U admin -d techcorp_db -c \
  "SELECT nom, email FROM utilisateurs WHERE email = 'test.replication@techcorp.fr';"

echo '--- Test DELETE ---'
docker exec pg_montpellier psql -U admin -d techcorp_db -c \
  "DELETE FROM utilisateurs WHERE email = 'test.replication@techcorp.fr';"
sleep 1
echo -n 'Source apres DELETE : '
docker exec pg_montpellier psql -U admin -d techcorp_db -t -c \
  'SELECT COUNT(*) FROM utilisateurs;' | tr -d ' '
echo -n 'Cible apres DELETE  : '
docker exec pg_toulouse psql -U admin -d techcorp_db -t -c \
  'SELECT COUNT(*) FROM utilisateurs;' | tr -d ' '

echo ''
echo '--- Mesure du lag de replication (sur la source) ---'
docker exec pg_montpellier psql -U admin -d techcorp_db -c \
  "SELECT client_addr, state, sent_lsn, write_lsn, flush_lsn, replay_lsn,
          write_lag, flush_lag, replay_lag
   FROM pg_stat_replication;"
