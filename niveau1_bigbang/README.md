### Niveau 1 — Migration « Big Bang »

Principe de la méthode:
La migration « Big Bang » est une stratégie de bascule directe. Elle consiste à transférer l'intégralité du système d'un état source à un état cible en une seule opération planifiée.


## Contexte du TP
L'environnement de ce Travaux Pratiques simule une migration inter-régionale entre deux instances conteneurisées représentant deux sites géographiques :

Source : Montpellier (Conteneur Docker pg_montpellier)

Cible : Toulouse (Conteneur Docker pg_toulouse)

Moteur de Base de Données : PostgreSQL

Fichiers Source : data_montpellier/supports/

Fichiers Cible : data_toulouse/supports/

## Étapes de la migration

### 1) Arrêt du service source
Script associé : ./niveau1_bigbang/01_arret_source.sh

Objectifs :

Passer la base source en mode lecture seule (read-only).

Simuler l'arrêt complet des écritures applicatives.

Enregistrer l'heure exacte du début de la coupure de service.

Vérifier et auditer les transactions actives.

Commande principale :
ALTER DATABASE techcorp_db SET default_transaction_read_only = on;

Résultat attendu :
ALTER DATABASE
OK : Base source passée en lecture seule

### 2) Export complet de la base source
Script associé : ./niveau1_bigbang/02_export_source.sh

Objectifs :

Exporter l'intégralité de la base PostgreSQL source.

Créer une sauvegarde compressée au format .dump.

Copier automatiquement la sauvegarde dans le dossier backups/.

Vérifier que le fichier de sauvegarde généré n'est pas vide.

Commande principale :
docker exec pg_montpellier pg_dump -U admin -d techcorp_db -F c -v -f /tmp/techcorp_backup.dump

Résultat attendu :
OK : Sauvegarde créée
OK : le fichier de sauvegarde existe et n’est pas vide

Exemple de fichier généré : backups/techcorp_bigbang_20260519_112816.dump

### 3) Transfert des fichiers avec rsync
Script associé : ./niveau1_bigbang/03_transfert_fichiers.sh

Objectifs :

Copier les fichiers de support pédagogiques de Montpellier vers Toulouse.

Vérifier que le nombre de fichiers à la cible est identique à la source.

Valider l'intégrité des fichiers transférés à l'aide de sommes de contrôle (checksums MD5).

Commande principale :
rsync -avh --progress --checksum ./data_montpellier/supports/ ./data_toulouse/supports/

Résultat attendu :
Fichiers source : 5
Fichiers cible : 5
OK : même nombre de fichiers
OK : checksums identiques

### 4) Restauration sur la cible (Toulouse)
Script associé : ./niveau1_bigbang/04_restauration_cible.sh

Objectifs :

Récupérer le dernier fichier .dump généré.

Copier le fichier de dump dans le conteneur cible pg_toulouse.

Restaurer entièrement la base sur la cible.

Vérifier la bonne présence de toutes les tables.

Commande principale :
docker exec pg_toulouse pg_restore -U admin -d techcorp_db -v --clean --if-exists /tmp/techcorp_backup.dump

Tables attendues :

formations

progressions

resultats_examens

utilisateurs

### 5) Vérification de l’intégrité
Script associé : ./niveau1_bigbang/05_verification.sh

Objectifs :

Comparer précisément le volume de données entre Montpellier et Toulouse.

Vérifier la cohérence des contraintes de clés étrangères.

Contrôler la conformité des fichiers physiques transférés.

### Avantages
Méthode simple : Un processus linéaire, facile à comprendre et à documenter.

Mise en place rapide : Demande peu de configuration et s'appuie sur des outils natifs éprouvés (pg_dump, rsync).

Intégrité forte : L'absence d'écritures concurrentes élimine les risques de désynchronisation des données durant l'opération.

Idéal petits volumes : Parfaitement adaptée aux bases de données légères ou aux environnements hors production.

### Inconvénients
Coupure totale (Downtime) : Interruption complète du service pour les utilisateurs pendant toute la durée du traitement.

Risque élevé en fin de parcours : Si la restauration échoue sur la cible, la durée de la coupure est prolongée le temps du diagnostic.

Pas de scalabilité : Inadaptée aux bases de production volumineuses car le temps d'export/transfert devient critique.

Rollback nécessaire : Oblige à prévoir un plan de retour en arrière (réouverture des accès de la source) en cas d'échec critique.

### Conclusion
La migration « Big Bang » est la méthode la plus simple, mais aussi la plus risquée concernant la disponibilité du service. Elle convient idéalement lorsque le volume de données est maîtrisé et qu'une fenêtre de coupure complète est acceptable pour les utilisateurs.



