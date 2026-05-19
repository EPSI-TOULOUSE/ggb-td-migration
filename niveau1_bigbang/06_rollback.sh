#!/bin/bash
echo '=== [NIVEAU 1] ROLLBACK – Retour a Montpellier ==='
echo 'ATTENTION : Cette operation annule la migration !'
read -p 'Confirmer le rollback ? (oui/non) : ' CONFIRM

if [ "$CONFIRM" != 'oui' ]; then
  echo 'Rollback annule.'
  exit 0
fi

# Connexion à la base 'postgres' (pas techcorp_db) pour contourner le read-only
docker exec pg_montpellier psql -U admin -d postgres -c \
  "ALTER DATABASE techcorp_db SET default_transaction_read_only = off;"
echo 'OK : Base source remise en lecture/ecriture'

# Vider la base cible pour éviter toute confusion
docker exec pg_toulouse psql -U admin -d techcorp_db -c \
  "DROP TABLE IF EXISTS resultats_examens, progressions, formations, utilisateurs CASCADE;"
echo 'OK : Base cible videe'

echo "Rollback effectue le $(date) – raison : echec ou test" >> logs/coupure_debut.log
echo 'OK : Raison enregistree dans logs/coupure_debut.log'
echo 'OK : Le service peut reprendre sur Montpellier'
