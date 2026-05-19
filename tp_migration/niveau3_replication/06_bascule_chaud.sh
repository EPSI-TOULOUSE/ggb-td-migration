#!/bin/bash
echo '=== [NIVEAU 3] Bascule a chaud ==='
DEBUT=$(date +%s)
echo "Debut : $(date)"

echo '--- Verification du lag de replication ---'
docker exec pg_montpellier psql -U admin -d techcorp_db -c \
  "SELECT client_addr, state, sent_lsn, write_lsn, flush_lsn, replay_lsn
   FROM pg_stat_replication;"

# Passer la source en lecture seule (coupure minimale)
docker exec pg_montpellier psql -U admin -d postgres -c \
  "ALTER DATABASE techcorp_db SET default_transaction_read_only = on;"
echo 'OK : Source en lecture seule'

# Attendre que la replication soit à jour
sleep 3

# Supprimer la subscription sur la cible
docker exec pg_toulouse psql -U admin -d techcorp_db -c \
  "DROP SUBSCRIPTION sub_techcorp;"
echo 'OK : Subscription supprimee'

# Activer la cible en lecture/écriture
docker exec pg_toulouse psql -U admin -d postgres -c \
  "ALTER DATABASE techcorp_db SET default_transaction_read_only = off;"
echo 'OK : Cible activee'

FIN=$(date +%s)
DUREE=$((FIN - DEBUT))
echo "Fin de la bascule : $(date)"
echo "Duree de la coupure : ${DUREE} secondes"
echo 'OK : Migration avec replication terminee'
