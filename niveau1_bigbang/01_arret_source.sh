#!/bin/bash
echo '=== [NIVEAU 1] Arret du service source ==='
echo "Heure de debut de coupure : $(date)" | tee logs/coupure_debut.log

docker exec pg_montpellier psql -U admin -d techcorp_db -c \
  "ALTER DATABASE techcorp_db SET default_transaction_read_only = on;"
echo 'OK : Base source passee en lecture seule'

# Vérification qu'aucune transaction n'est en cours
ACTIVE=$(docker exec pg_montpellier psql -U admin -d techcorp_db -t -c \
  "SELECT COUNT(*) FROM pg_stat_activity WHERE state = 'active' AND query NOT LIKE '%pg_stat_activity%';" | tr -d ' ')
echo "Transactions actives : $ACTIVE"
if [ "$ACTIVE" -gt 0 ]; then
  echo "AVERTISSEMENT : $ACTIVE transaction(s) en cours — attente recommandee"
else
  echo "OK : Aucune transaction active"
fi
