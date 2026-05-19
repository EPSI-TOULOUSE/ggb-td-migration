--
-- PostgreSQL database dump
--

\restrict Q42JwLU30RD64IV0DN4tJocvxJBE7BjdBZLeoCiQaOLX8sVR85CvD41dhhiEf1y

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
-- Name: pub_techcorp; Type: PUBLICATION; Schema: -; Owner: -
--

CREATE PUBLICATION pub_techcorp FOR ALL TABLES WITH (publish = 'insert, update, delete, truncate');


--
-- PostgreSQL database dump complete
--

\unrestrict Q42JwLU30RD64IV0DN4tJocvxJBE7BjdBZLeoCiQaOLX8sVR85CvD41dhhiEf1y

