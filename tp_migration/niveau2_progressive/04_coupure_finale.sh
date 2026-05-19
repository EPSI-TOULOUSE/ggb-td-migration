#!/bin/bash
echo '=== [NIVEAU 2] COUPURE – Synchronisation finale ==='
DEBUT=$(date)
echo "Debut de la fenetre de coupure : $DEBUT" | tee -a logs/coupure_n2.log

# 1. Source en lecture seule (connexion à postgres pour éviter le bug read-only)
docker exec pg_montpellier psql -U admin -d postgres -c \
  "ALTER DATABASE techcorp_db SET default_transaction_read_only = on;"
echo 'OK : Source en lecture seule'

# 2. Dernière sync fichiers avec --delete (supprime sur cible ce qui n'existe plus sur source)
rsync -avh --checksum --delete \
  ./data_montpellier/supports/ \
  ./data_toulouse/supports/
echo 'OK : Fichiers synchronises'

# 3. Dernier export
docker exec pg_montpellier pg_dump \
  -U admin -d techcorp_db \
  --format=custom -f /tmp/sync_finale.dump
docker cp pg_montpellier:/tmp/sync_finale.dump ./backups/sync_finale.dump
echo 'OK : Export final cree'

# 4. Restauration finale sur la cible
docker cp ./backups/sync_finale.dump pg_toulouse:/tmp/sync_finale.dump
docker exec pg_toulouse pg_restore \
  -U admin -d techcorp_db \
  --clean --if-exists -v \
  /tmp/sync_finale.dump
echo 'OK : Restauration finale terminee'

FIN=$(date)
echo "Fin de la synchronisation finale : $FIN" | tee -a logs/coupure_n2.log

# Vérification comptages avant bascule
echo '--- Verification comptages SOURCE = CIBLE ---'
for TABLE in utilisateurs formations progressions resultats_examens; do
  SRC=$(docker exec pg_montpellier psql -U admin -d techcorp_db -t -c "SELECT COUNT(*) FROM $TABLE;" | tr -d ' ')
  TGT=$(docker exec pg_toulouse  psql -U admin -d techcorp_db -t -c "SELECT COUNT(*) FROM $TABLE;" | tr -d ' ')
  if [ "$SRC" = "$TGT" ]; then
    echo "OK : $TABLE — source=$SRC cible=$TGT"
  else
    echo "ERREUR : $TABLE — source=$SRC cible=$TGT — ROLLBACK RECOMMANDE"
    exit 1
  fi
done
