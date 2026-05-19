--
-- PostgreSQL database dump
--

\restrict wHyFSotZznUgWkKB3EHeVn6EL4LdRl4ehwzyTuaV97NxbJAZ8bEhhDQEDuTASt0

-- Dumped from database version 15.18 (Debian 15.18-1.pgdg13+1)
-- Dumped by pg_dump version 15.18 (Debian 15.18-1.pgdg13+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: formations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.formations (
    id integer NOT NULL,
    titre character varying(200) NOT NULL,
    categorie character varying(100),
    duree_heures integer
);


--
-- Name: formations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.formations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: formations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.formations_id_seq OWNED BY public.formations.id;


--
-- Name: progressions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.progressions (
    id integer NOT NULL,
    utilisateur_id integer,
    formation_id integer,
    pourcentage integer DEFAULT 0,
    derniere_activite timestamp without time zone DEFAULT now()
);


--
-- Name: progressions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.progressions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: progressions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.progressions_id_seq OWNED BY public.progressions.id;


--
-- Name: resultats_examens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.resultats_examens (
    id integer NOT NULL,
    utilisateur_id integer,
    formation_id integer,
    note numeric(5,2),
    date_examen date DEFAULT CURRENT_DATE
);


--
-- Name: resultats_examens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.resultats_examens_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: resultats_examens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.resultats_examens_id_seq OWNED BY public.resultats_examens.id;


--
-- Name: utilisateurs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.utilisateurs (
    id integer NOT NULL,
    nom character varying(100) NOT NULL,
    email character varying(150) NOT NULL,
    date_inscription date DEFAULT CURRENT_DATE
);


--
-- Name: utilisateurs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.utilisateurs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: utilisateurs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.utilisateurs_id_seq OWNED BY public.utilisateurs.id;


--
-- Name: formations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.formations ALTER COLUMN id SET DEFAULT nextval('public.formations_id_seq'::regclass);


--
-- Name: progressions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.progressions ALTER COLUMN id SET DEFAULT nextval('public.progressions_id_seq'::regclass);


--
-- Name: resultats_examens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resultats_examens ALTER COLUMN id SET DEFAULT nextval('public.resultats_examens_id_seq'::regclass);


--
-- Name: utilisateurs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.utilisateurs ALTER COLUMN id SET DEFAULT nextval('public.utilisateurs_id_seq'::regclass);


--
-- Data for Name: formations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.formations (id, titre, categorie, duree_heures) FROM stdin;
1	Excel avance	Bureautique	14
2	Cybersecurite bases	Numerique	21
3	Gestion de projet	Gestion	28
4	Linux pour debutants	Technique	35
\.


--
-- Data for Name: progressions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.progressions (id, utilisateur_id, formation_id, pourcentage, derniere_activite) FROM stdin;
1	1	1	75	2026-05-19 08:50:04.425922
2	1	2	30	2026-05-19 08:50:04.425922
3	2	3	100	2026-05-19 08:50:04.425922
4	3	1	50	2026-05-19 08:50:04.425922
5	4	4	20	2026-05-19 08:50:04.425922
6	5	2	90	2026-05-19 08:50:04.425922
\.


--
-- Data for Name: resultats_examens; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.resultats_examens (id, utilisateur_id, formation_id, note, date_examen) FROM stdin;
1	2	3	17.50	2026-05-19
2	5	2	14.00	2026-05-19
3	1	1	18.00	2026-05-19
\.


--
-- Data for Name: utilisateurs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.utilisateurs (id, nom, email, date_inscription) FROM stdin;
1	Alice Martin	alice@techcorp.fr	2026-05-19
2	Bob Dupont	bob@techcorp.fr	2026-05-19
3	Claire Moreau	claire@techcorp.fr	2026-05-19
4	David Leroy	david@techcorp.fr	2026-05-19
5	Emma Bernard	emma@techcorp.fr	2026-05-19
\.


--
-- Name: formations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.formations_id_seq', 4, true);


--
-- Name: progressions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.progressions_id_seq', 6, true);


--
-- Name: resultats_examens_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.resultats_examens_id_seq', 3, true);


--
-- Name: utilisateurs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.utilisateurs_id_seq', 6, true);


--
-- Name: formations formations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.formations
    ADD CONSTRAINT formations_pkey PRIMARY KEY (id);


--
-- Name: progressions progressions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.progressions
    ADD CONSTRAINT progressions_pkey PRIMARY KEY (id);


--
-- Name: resultats_examens resultats_examens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resultats_examens
    ADD CONSTRAINT resultats_examens_pkey PRIMARY KEY (id);


--
-- Name: utilisateurs utilisateurs_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.utilisateurs
    ADD CONSTRAINT utilisateurs_email_key UNIQUE (email);


--
-- Name: utilisateurs utilisateurs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.utilisateurs
    ADD CONSTRAINT utilisateurs_pkey PRIMARY KEY (id);


--
-- Name: progressions progressions_formation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.progressions
    ADD CONSTRAINT progressions_formation_id_fkey FOREIGN KEY (formation_id) REFERENCES public.formations(id);


--
-- Name: progressions progressions_utilisateur_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.progressions
    ADD CONSTRAINT progressions_utilisateur_id_fkey FOREIGN KEY (utilisateur_id) REFERENCES public.utilisateurs(id);


--
-- Name: resultats_examens resultats_examens_formation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resultats_examens
    ADD CONSTRAINT resultats_examens_formation_id_fkey FOREIGN KEY (formation_id) REFERENCES public.formations(id);


--
-- Name: resultats_examens resultats_examens_utilisateur_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resultats_examens
    ADD CONSTRAINT resultats_examens_utilisateur_id_fkey FOREIGN KEY (utilisateur_id) REFERENCES public.utilisateurs(id);


--
-- PostgreSQL database dump complete
--

\unrestrict wHyFSotZznUgWkKB3EHeVn6EL4LdRl4ehwzyTuaV97NxbJAZ8bEhhDQEDuTASt0

