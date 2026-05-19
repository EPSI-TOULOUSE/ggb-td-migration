#!/bin/bash

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd -P)"
DATA_MONTPELLIER="$BASE_DIR/data_montpellier"
DATA_TOULOUSE="$BASE_DIR/data_toulouse"

# Injecter les donnees dans le container source
docker exec -i pg_montpellier psql \
	-U admin \
-d techcorp_db < "$BASE_DIR/init_source.sql"

# Verifier que les donnees sont bien presentes
docker exec -it pg_montpellier psql \
	-U admin \
	-d techcorp_db \
	-c '\dt'

docker exec -it pg_montpellier psql \
	-U admin \
	-d techcorp_db \
	-c 'SELECT COUNT(*) FROM utilisateurs;'



mkdir -p "$DATA_MONTPELLIER/supports" "$DATA_TOULOUSE/supports"
echo 'Support Excel avance - Module 1' > "$DATA_MONTPELLIER/supports/excel_module1.pdf"
echo 'Support Cybersecurite - Introduction' > "$DATA_MONTPELLIER/supports/cyber_intro.pdf"
echo 'Support Gestion de projet - Methodes' > "$DATA_MONTPELLIER/supports/gestion_methodes.pdf"
echo 'Video Linux debutants - Partie 1' > "$DATA_MONTPELLIER/supports/linux_video1.mp4"
echo 'Image logo TechCorp' > "$DATA_MONTPELLIER/supports/logo.png"
ls -lh $DATA_MONTPELLIER/supports
