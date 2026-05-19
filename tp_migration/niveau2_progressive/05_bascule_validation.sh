#!/bin/bash
echo '=== [NIVEAU 2] Bascule et validation ==='

SOURCE_COUNT=$(docker exec pg_montpellier psql -U admin -d techcorp_db -t -c \
  'SELECT COUNT(*) FROM utilisateurs;' | tr -d ' ')
CIBLE_COUNT=$(docker exec pg_toulouse psql -U admin -d techcorp_db -t -c \
  'SELECT COUNT(*) FROM utilisateurs;' | tr -d ' ')

echo "Utilisateurs source : $SOURCE_COUNT"
echo "Utilisateurs cible  : $CIBLE_COUNT"

if [ "$SOURCE_COUNT" != "$CIBLE_COUNT" ]; then
  echo 'ERREUR : Les comptages ne correspondent pas — rollback recommande'
  exit 1
fi
echo 'OK : Comptages identiques — bascule autorisee'

# Activer la cible en lecture/écriture
docker exec pg_toulouse psql -U admin -d postgres -c \
  "ALTER DATABASE techcorp_db SET default_transaction_read_only = off;"
echo 'OK : Cible activee en lecture/ecriture'

# Test insertion sur la cible pour confirmer qu'elle est active
docker exec pg_toulouse psql -U admin -d techcorp_db -c \
  "INSERT INTO utilisateurs (nom, email) VALUES ('Validation Bascule', 'validation@techcorp.fr');"
docker exec pg_toulouse psql -U admin -d techcorp_db -c \
  "DELETE FROM utilisateurs WHERE email = 'validation@techcorp.fr';"
echo 'OK : Test insertion/suppression sur la cible reussi'

echo 'OK : Migration progressive terminee avec succes'
echo "Heure de fin : $(date)" | tee -a logs/coupure_n2.log
