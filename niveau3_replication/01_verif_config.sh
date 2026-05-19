#!/bin/bash
echo '=== [NIVEAU 3] Verification de la configuration ==='

WAL_LEVEL=$(docker exec pg_montpellier psql -U admin -d postgres -t -c 'SHOW wal_level;' | tr -d ' \n')
echo "WAL level source : $WAL_LEVEL"

if [ "$WAL_LEVEL" != 'logical' ]; then
  echo 'ERREUR : wal_level doit etre logical pour la replication'
  exit 1
fi
echo 'OK : Configuration WAL correcte'

docker exec pg_montpellier psql -U admin -d postgres -c 'SELECT version();'
