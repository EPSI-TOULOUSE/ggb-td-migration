#!/bin/bash
echo '=== [NIVEAU 1] Transfert des fichiers ==='
SOURCE='./data_montpellier/supports/'
CIBLE='./data_toulouse/supports/'

rsync -avh --progress --checksum $SOURCE $CIBLE

echo ''
echo '=== Verification du transfert ==='
NB_SOURCE=$(find $SOURCE -type f | wc -l | tr -d ' ')
NB_CIBLE=$(find $CIBLE -type f | wc -l | tr -d ' ')
echo "Fichiers source : $NB_SOURCE"
echo "Fichiers cible  : $NB_CIBLE"

if [ "$NB_SOURCE" -eq "$NB_CIBLE" ]; then
  echo 'OK : Meme nombre de fichiers'
else
  echo 'ERREUR : Nombre de fichiers different !'
  exit 1
fi

# Comparaison MD5
echo ''
echo '=== Verification MD5 ==='
md5 $SOURCE* 2>/dev/null | awk '{print $NF, $4}' | sort > /tmp/checksums_source.txt
md5 $CIBLE*  2>/dev/null | awk '{print $NF, $4}' | sort > /tmp/checksums_cible.txt
if diff /tmp/checksums_source.txt /tmp/checksums_cible.txt > /dev/null; then
  echo 'OK : Checksums MD5 identiques'
else
  echo 'ERREUR : Differences detectees dans les checksums'
  diff /tmp/checksums_source.txt /tmp/checksums_cible.txt
  exit 1
fi
