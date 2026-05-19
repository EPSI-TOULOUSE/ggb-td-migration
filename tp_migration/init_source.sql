-- init_source.sql
CREATE TABLE IF NOT EXISTS utilisateurs (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    date_inscription DATE DEFAULT CURRENT_DATE
);

CREATE TABLE IF NOT EXISTS formations (
    id SERIAL PRIMARY KEY,
    titre VARCHAR(200) NOT NULL,
    categorie VARCHAR(100),
    duree_heures INT
);

CREATE TABLE IF NOT EXISTS progressions (
    id SERIAL PRIMARY KEY,
    utilisateur_id INT REFERENCES utilisateurs(id),
    formation_id INT REFERENCES formations(id),
    pourcentage INT DEFAULT 0,
    derniere_activite TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS resultats_examens (
    id SERIAL PRIMARY KEY,
    utilisateur_id INT REFERENCES utilisateurs(id),
    formation_id INT REFERENCES formations(id),
    note NUMERIC(5,2),
    date_examen DATE DEFAULT CURRENT_DATE
);

INSERT INTO utilisateurs (nom, email) VALUES
    ('Alice Martin', 'alice@techcorp.fr'),
    ('Bob Dupont', 'bob@techcorp.fr'),
    ('Claire Moreau', 'claire@techcorp.fr'),
    ('David Leroy', 'david@techcorp.fr'),
    ('Emma Bernard', 'emma@techcorp.fr');

INSERT INTO formations (titre, categorie, duree_heures) VALUES
    ('Excel avance', 'Bureautique', 14),
    ('Cybersecurite bases', 'Numerique', 21),
    ('Gestion de projet', 'Gestion', 28),
    ('Linux pour debutants', 'Technique', 35);

INSERT INTO progressions (utilisateur_id, formation_id, pourcentage) VALUES
    (1,1,75),(1,2,30),(2,3,100),(3,1,50),(4,4,20),(5,2,90);

INSERT INTO resultats_examens (utilisateur_id, formation_id, note) VALUES
    (2,3,17.5),(5,2,14.0),(1,1,18.0);
