#!/bin/bash
echo '=== [NIVEAU 2] Simulation d activite utilisateur ==='

docker exec pg_montpellier psql -U admin -d techcorp_db -c \
  "INSERT INTO utilisateurs (nom, email) VALUES
   ('Francois Petit', 'francois@techcorp.fr'),
   ('Gaelle Simon', 'gaelle@techcorp.fr');"

docker exec pg_montpellier psql -U admin -d techcorp_db -c \
  "UPDATE progressions SET pourcentage = 100, derniere_activite = NOW()
   WHERE utilisateur_id = 1 AND formation_id = 2;"

docker exec pg_montpellier psql -U admin -d techcorp_db -c \
  "INSERT INTO resultats_examens (utilisateur_id, formation_id, note)
   VALUES (3, 1, 16.5);"

echo 'Nouveau support Python debutants' > data_montpellier/supports/python_intro.pdf

echo "OK : Nouvelles donnees ajoutees sur la source"
echo "  2 nouveaux utilisateurs, 1 progression mise a jour"
echo "  1 nouveau resultat d examen, 1 nouveau fichier support"

echo '--- Etat source apres activite ---'
docker exec pg_montpellier psql -U admin -d techcorp_db -t -c \
  "SELECT 'utilisateurs', COUNT(*) FROM utilisateurs
   UNION ALL SELECT 'formations', COUNT(*) FROM formations
   UNION ALL SELECT 'progressions', COUNT(*) FROM progressions
   UNION ALL SELECT 'resultats_examens', COUNT(*) FROM resultats_examens;"
