--
-- PostgreSQL database dump
--

-- Dumped from database version 16.0
-- Dumped by pg_dump version 16.0

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

--
-- Name: changepublicname(integer, character varying); Type: FUNCTION; Schema: public; Owner: komilakurbanova
--

CREATE FUNCTION public.changepublicname(p_user_id integer, p_new_public_name character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE Users
    SET public_name = p_new_public_name
    WHERE user_id = p_user_id;
END;
$$;


ALTER FUNCTION public.changepublicname(p_user_id integer, p_new_public_name character varying) OWNER TO komilakurbanova;

--
-- Name: getmediabycollection(character varying, integer); Type: FUNCTION; Schema: public; Owner: komilakurbanova
--

CREATE FUNCTION public.getmediabycollection(p_collection_name character varying, p_user_id integer) RETURNS TABLE(title character varying, media_type character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT Media_Content.title, Media_Content.media_type
    FROM Media_Content
    JOIN Media_Collection_Relation ON Media_Content.media_id = Media_Collection_Relation.media_id
    JOIN Collections ON Media_Collection_Relation.collection_id = Collections.collection_id
    WHERE Collections.collection_name = p_collection_name AND Collections.user_id = p_user_id;
END;
$$;


ALTER FUNCTION public.getmediabycollection(p_collection_name character varying, p_user_id integer) OWNER TO komilakurbanova;

--
-- Name: getmediabygenre(character varying); Type: FUNCTION; Schema: public; Owner: komilakurbanova
--

CREATE FUNCTION public.getmediabygenre(p_genre character varying) RETURNS TABLE(media_id integer, media_type character varying, title character varying, description text, rating numeric, genre character varying, country character varying, release_year integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM Media_Content
    WHERE LOWER(Media_Content.genre) LIKE '%' || LOWER(p_genre) || '%';
END;
$$;


ALTER FUNCTION public.getmediabygenre(p_genre character varying) OWNER TO komilakurbanova;

--
-- Name: trg_update_media_rating(); Type: FUNCTION; Schema: public; Owner: komilakurbanova
--

CREATE FUNCTION public.trg_update_media_rating() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Обновляем рейтинг в Media_Content при добавлении новой оценки
    UPDATE Media_Content
    SET rating = (
        SELECT AVG(rating) FROM Ratings WHERE media_id = NEW.media_id
    )
    WHERE media_id = NEW.media_id;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.trg_update_media_rating() OWNER TO komilakurbanova;

--
-- Name: update_episode_count_function(); Type: FUNCTION; Schema: public; Owner: komilakurbanova
--

CREATE FUNCTION public.update_episode_count_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NEW.episode_number > (
    SELECT MAX(episodes_count)
    FROM Series
    WHERE media_id = NEW.media_id
  ) THEN
    UPDATE Series
    SET episodes_count = NEW.episode_number
    WHERE media_id = NEW.media_id;
  END IF;
  IF NEW.season_number > (
    SELECT MAX(season_count)
    FROM Series
    WHERE media_id = NEW.media_id
  ) THEN
    UPDATE Series
    SET season_count = NEW.season_number
    WHERE media_id = NEW.media_id;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_episode_count_function() OWNER TO komilakurbanova;

--
-- Name: update_rating_function(); Type: FUNCTION; Schema: public; Owner: komilakurbanova
--

CREATE FUNCTION public.update_rating_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NEW.rating < 0 OR NEW.rating > 10 THEN
    RAISE EXCEPTION 'Оценка должна быть в диапазоне от 0 до 10.';
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_rating_function() OWNER TO komilakurbanova;

--
-- Name: validateusercredentials(character varying, character varying); Type: FUNCTION; Schema: public; Owner: komilakurbanova
--

CREATE FUNCTION public.validateusercredentials(p_username character varying, p_password_hash character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_count INT;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM Users
    WHERE username = p_username AND password_hash = p_password_hash;
    RETURN v_count > 0;
END;
$$;


ALTER FUNCTION public.validateusercredentials(p_username character varying, p_password_hash character varying) OWNER TO komilakurbanova;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: actors; Type: TABLE; Schema: public; Owner: komilakurbanova
--

CREATE TABLE public.actors (
    actor_id integer NOT NULL,
    actor_name character varying(100) NOT NULL,
    filmography text
);


ALTER TABLE public.actors OWNER TO komilakurbanova;

--
-- Name: collections; Type: TABLE; Schema: public; Owner: komilakurbanova
--

CREATE TABLE public.collections (
    collection_id integer NOT NULL,
    user_id integer,
    collection_name character varying(100) NOT NULL,
    is_public boolean NOT NULL
);


ALTER TABLE public.collections OWNER TO komilakurbanova;

--
-- Name: directors; Type: TABLE; Schema: public; Owner: komilakurbanova
--

CREATE TABLE public.directors (
    director_id integer NOT NULL,
    director_name character varying(100) NOT NULL,
    filmography text
);


ALTER TABLE public.directors OWNER TO komilakurbanova;

--
-- Name: media_actor_relation; Type: TABLE; Schema: public; Owner: komilakurbanova
--

CREATE TABLE public.media_actor_relation (
    media_id integer NOT NULL,
    actor_id integer NOT NULL
);


ALTER TABLE public.media_actor_relation OWNER TO komilakurbanova;

--
-- Name: media_collection_relation; Type: TABLE; Schema: public; Owner: komilakurbanova
--

CREATE TABLE public.media_collection_relation (
    media_id integer NOT NULL,
    collection_id integer NOT NULL
);


ALTER TABLE public.media_collection_relation OWNER TO komilakurbanova;

--
-- Name: media_content; Type: TABLE; Schema: public; Owner: komilakurbanova
--

CREATE TABLE public.media_content (
    media_id integer NOT NULL,
    media_type character varying(10) NOT NULL,
    title character varying(100) NOT NULL,
    description text NOT NULL,
    rating numeric(2,1) DEFAULT 0.0,
    genre character varying(255),
    country character varying(50),
    release_year integer,
    CONSTRAINT media_content_release_year_check CHECK (((release_year >= 1000) AND (release_year <= 9999)))
);


ALTER TABLE public.media_content OWNER TO komilakurbanova;

--
-- Name: media_director_relation; Type: TABLE; Schema: public; Owner: komilakurbanova
--

CREATE TABLE public.media_director_relation (
    media_id integer NOT NULL,
    director_id integer NOT NULL
);


ALTER TABLE public.media_director_relation OWNER TO komilakurbanova;

--
-- Name: movie; Type: TABLE; Schema: public; Owner: komilakurbanova
--

CREATE TABLE public.movie (
    media_id integer NOT NULL,
    watch_link character varying(255)
);


ALTER TABLE public.movie OWNER TO komilakurbanova;

--
-- Name: ratings; Type: TABLE; Schema: public; Owner: komilakurbanova
--

CREATE TABLE public.ratings (
    rating_id integer NOT NULL,
    user_id integer,
    media_id integer,
    rating integer NOT NULL,
    CONSTRAINT ratings_rating_check CHECK (((rating >= 0) AND (rating <= 10)))
);


ALTER TABLE public.ratings OWNER TO komilakurbanova;

--
-- Name: series; Type: TABLE; Schema: public; Owner: komilakurbanova
--

CREATE TABLE public.series (
    media_id integer NOT NULL,
    season_count integer NOT NULL,
    episodes_count integer NOT NULL,
    CONSTRAINT series_episodes_count_check CHECK ((episodes_count >= 0)),
    CONSTRAINT series_season_count_check CHECK ((season_count >= 0))
);


ALTER TABLE public.series OWNER TO komilakurbanova;

--
-- Name: series_episodes; Type: TABLE; Schema: public; Owner: komilakurbanova
--

CREATE TABLE public.series_episodes (
    episode_id integer NOT NULL,
    media_id integer,
    season_number integer NOT NULL,
    episode_number integer NOT NULL,
    title character varying(100),
    description text,
    watch_link character varying(255),
    CONSTRAINT series_episodes_episode_number_check CHECK ((episode_number >= 0)),
    CONSTRAINT series_episodes_season_number_check CHECK ((season_number >= 0))
);


ALTER TABLE public.series_episodes OWNER TO komilakurbanova;

--
-- Name: users; Type: TABLE; Schema: public; Owner: komilakurbanova
--

CREATE TABLE public.users (
    user_id integer NOT NULL,
    username character varying(50) NOT NULL,
    password_hash character varying(100) NOT NULL,
    public_name character varying(50) NOT NULL
);


ALTER TABLE public.users OWNER TO komilakurbanova;

--
-- Data for Name: actors; Type: TABLE DATA; Schema: public; Owner: komilakurbanova
--

COPY public.actors (actor_id, actor_name, filmography) FROM stdin;
1	Тим Роббинс	Побег из Шоушенка, Зеленая миля, Мистическая река
2	Мэттью Макконахи	Во все тяжкие, Интерстеллар, Загадочная река
3	Том Хэнкс	Форрест Гамп, Побег из Шоушенка, Спасение Райана
4	Морган Фримен	Побег из Шоушенка, Зеленая миля, Семь
5	Киану Ривз	Матрица, Джон Уик, Константин
\.


--
-- Data for Name: collections; Type: TABLE DATA; Schema: public; Owner: komilakurbanova
--

COPY public.collections (collection_id, user_id, collection_name, is_public) FROM stdin;
1	1	Избранное	t
2	1	Смотреть позже	f
3	2	Избранное	t
\.


--
-- Data for Name: directors; Type: TABLE DATA; Schema: public; Owner: komilakurbanova
--

COPY public.directors (director_id, director_name, filmography) FROM stdin;
1	Фрэнк Дарабонт	Побег из Шоушенка, Зеленая миля, Мистическая река
2	Кристофер Нолан	Мemento, The Dark Knight, Интерстеллар
3	Роберт Земекис	Форрест Гамп, Назад в будущее, Каст away
\.


--
-- Data for Name: media_actor_relation; Type: TABLE DATA; Schema: public; Owner: komilakurbanova
--

COPY public.media_actor_relation (media_id, actor_id) FROM stdin;
1	1
1	4
2	2
2	5
3	3
3	1
\.


--
-- Data for Name: media_collection_relation; Type: TABLE DATA; Schema: public; Owner: komilakurbanova
--

COPY public.media_collection_relation (media_id, collection_id) FROM stdin;
1	1
2	1
3	2
4	3
\.


--
-- Data for Name: media_content; Type: TABLE DATA; Schema: public; Owner: komilakurbanova
--

COPY public.media_content (media_id, media_type, title, description, rating, genre, country, release_year) FROM stdin;
6	Series	Во все тяжкие	Учитель химии из старшей школы становится производителем метамфетамина и заключает сделку с бывшим учеником для обеспечения будущего своей семьи.	0.0	Криминал, Драма, Триллер	США	2008
7	Series	Игра престолов	Эпическая сага о борьбе за власть в вымышленном мире Вестерос.	0.0	Драма, Фэнтези, Приключения	США	2011
8	Series	Черное зеркало	Каждая серия представляет собой отдельную историю, исследующую темы технологии и ее воздействия на общество.	0.0	Драма, Научная фантастика, Триллер	Великобритания	2011
1	Movie	Побег из Шоушенка	Двое заключенных находят общий язык на протяжении многих лет, находя утешение и окончательное искупление через акты добродетели.	9.0	Драма	США	1994
2	Movie	Интерстеллар	Группа исследователей использует проход в пространстве-времени, чтобы обеспечить выживание человечества на новой планете.	8.0	Научная фантастика, Драма	США	2014
3	Movie	Форрест Гамп	Жизнь обычного человека, который случайно участвует в ряде исторических событий в течение нескольких десятилетий.	7.0	Драма, Романтика	США	1994
4	Movie	Зеленая миля	Смотритель тюрьмы обнаруживает, что один из заключенных обладает невероятным даром.	8.0	Драма, Фэнтези	США	1999
5	Movie	Матрица	Программист Нео обнаруживает, что мир, в котором он живет, на самом деле является компьютерной симуляцией.	9.5	Экшн, Научная фантастика	США	1999
\.


--
-- Data for Name: media_director_relation; Type: TABLE DATA; Schema: public; Owner: komilakurbanova
--

COPY public.media_director_relation (media_id, director_id) FROM stdin;
1	1
1	3
2	2
3	3
\.


--
-- Data for Name: movie; Type: TABLE DATA; Schema: public; Owner: komilakurbanova
--

COPY public.movie (media_id, watch_link) FROM stdin;
1	https://example.com/watch/1
2	https://example.com/watch/2
3	https://example.com/watch/3
4	https://example.com/watch/4
5	https://example.com/watch/5
\.


--
-- Data for Name: ratings; Type: TABLE DATA; Schema: public; Owner: komilakurbanova
--

COPY public.ratings (rating_id, user_id, media_id, rating) FROM stdin;
1	1	1	9
2	2	2	8
3	3	3	7
4	1	4	8
5	2	5	9
6	1	5	10
\.


--
-- Data for Name: series; Type: TABLE DATA; Schema: public; Owner: komilakurbanova
--

COPY public.series (media_id, season_count, episodes_count) FROM stdin;
6	1	1
8	1	2
7	2	3
\.


--
-- Data for Name: series_episodes; Type: TABLE DATA; Schema: public; Owner: komilakurbanova
--

COPY public.series_episodes (episode_id, media_id, season_number, episode_number, title, description, watch_link) FROM stdin;
1	6	1	1	Пилотный эпизод	Первый эпизод сериала "Во все тяжкие". Учитель химии превращается в производителя метамфетамина.	https://example.com/series/6/season/1/episode/1
2	7	1	1	Зима близко	Первый эпизод сериала "Игра престолов". Вступление в мир интриг и политических борьб.	https://example.com/series/7/season/1/episode/1
3	8	1	1	Первый эпизод	Первый эпизод сериала "Черное зеркало". Исследование тем технологии и ее воздействия на общество.	https://example.com/series/8/season/1/episode/1
4	8	1	2	Второй эпизод	Второй эпизод сериала "Черное зеркало". Еще одна увлекательная история о технологиях.	https://example.com/series/8/season/1/episode/2
5	7	2	3	Загадочный эпизод	Третий эпизод второго сезона сериала "Игра престолов". Новые повороты в сюжете.	https://example.com/series/7/season/2/episode/3
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: komilakurbanova
--

COPY public.users (user_id, username, password_hash, public_name) FROM stdin;
1	user1	hashed_password1	Кисуня1998
2	user2	hashed_password2	Звездный Путник
3	user3	hashed_password3	Смотритель
\.


--
-- Name: actors actors_pkey; Type: CONSTRAINT; Schema: public; Owner: komilakurbanova
--

ALTER TABLE ONLY public.actors
    ADD CONSTRAINT actors_pkey PRIMARY KEY (actor_id);


--
-- Name: collections collections_pkey; Type: CONSTRAINT; Schema: public; Owner: komilakurbanova
--

ALTER TABLE ONLY public.collections
    ADD CONSTRAINT collections_pkey PRIMARY KEY (collection_id);


--
-- Name: directors directors_pkey; Type: CONSTRAINT; Schema: public; Owner: komilakurbanova
--

ALTER TABLE ONLY public.directors
    ADD CONSTRAINT directors_pkey PRIMARY KEY (director_id);


--
-- Name: media_actor_relation media_actor_relation_pkey; Type: CONSTRAINT; Schema: public; Owner: komilakurbanova
--

ALTER TABLE ONLY public.media_actor_relation
    ADD CONSTRAINT media_actor_relation_pkey PRIMARY KEY (media_id, actor_id);


--
-- Name: media_collection_relation media_collection_relation_pkey; Type: CONSTRAINT; Schema: public; Owner: komilakurbanova
--

ALTER TABLE ONLY public.media_collection_relation
    ADD CONSTRAINT media_collection_relation_pkey PRIMARY KEY (media_id, collection_id);


--
-- Name: media_content media_content_pkey; Type: CONSTRAINT; Schema: public; Owner: komilakurbanova
--

ALTER TABLE ONLY public.media_content
    ADD CONSTRAINT media_content_pkey PRIMARY KEY (media_id);


--
-- Name: media_director_relation media_director_relation_pkey; Type: CONSTRAINT; Schema: public; Owner: komilakurbanova
--

ALTER TABLE ONLY public.media_director_relation
    ADD CONSTRAINT media_director_relation_pkey PRIMARY KEY (media_id, director_id);


--
-- Name: movie movie_pkey; Type: CONSTRAINT; Schema: public; Owner: komilakurbanova
--

ALTER TABLE ONLY public.movie
    ADD CONSTRAINT movie_pkey PRIMARY KEY (media_id);


--
-- Name: ratings ratings_pkey; Type: CONSTRAINT; Schema: public; Owner: komilakurbanova
--

ALTER TABLE ONLY public.ratings
    ADD CONSTRAINT ratings_pkey PRIMARY KEY (rating_id);


--
-- Name: series_episodes series_episodes_pkey; Type: CONSTRAINT; Schema: public; Owner: komilakurbanova
--

ALTER TABLE ONLY public.series_episodes
    ADD CONSTRAINT series_episodes_pkey PRIMARY KEY (episode_id);


--
-- Name: series series_pkey; Type: CONSTRAINT; Schema: public; Owner: komilakurbanova
--

ALTER TABLE ONLY public.series
    ADD CONSTRAINT series_pkey PRIMARY KEY (media_id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: komilakurbanova
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: komilakurbanova
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: ratings trg_ratings_insert; Type: TRIGGER; Schema: public; Owner: komilakurbanova
--

CREATE TRIGGER trg_ratings_insert AFTER INSERT ON public.ratings FOR EACH ROW EXECUTE FUNCTION public.trg_update_media_rating();


--
-- Name: series_episodes update_episode_count; Type: TRIGGER; Schema: public; Owner: komilakurbanova
--

CREATE TRIGGER update_episode_count AFTER INSERT ON public.series_episodes FOR EACH ROW EXECUTE FUNCTION public.update_episode_count_function();


--
-- Name: ratings update_rating_trigger; Type: TRIGGER; Schema: public; Owner: komilakurbanova
--

CREATE TRIGGER update_rating_trigger BEFORE INSERT ON public.ratings FOR EACH ROW EXECUTE FUNCTION public.update_rating_function();


--
-- Name: collections collections_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: komilakurbanova
--

ALTER TABLE ONLY public.collections
    ADD CONSTRAINT collections_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- Name: media_actor_relation media_actor_relation_actor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: komilakurbanova
--

ALTER TABLE ONLY public.media_actor_relation
    ADD CONSTRAINT media_actor_relation_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES public.actors(actor_id);


--
-- Name: media_actor_relation media_actor_relation_media_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: komilakurbanova
--

ALTER TABLE ONLY public.media_actor_relation
    ADD CONSTRAINT media_actor_relation_media_id_fkey FOREIGN KEY (media_id) REFERENCES public.media_content(media_id);


--
-- Name: media_collection_relation media_collection_relation_collection_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: komilakurbanova
--

ALTER TABLE ONLY public.media_collection_relation
    ADD CONSTRAINT media_collection_relation_collection_id_fkey FOREIGN KEY (collection_id) REFERENCES public.collections(collection_id);


--
-- Name: media_collection_relation media_collection_relation_media_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: komilakurbanova
--

ALTER TABLE ONLY public.media_collection_relation
    ADD CONSTRAINT media_collection_relation_media_id_fkey FOREIGN KEY (media_id) REFERENCES public.media_content(media_id);


--
-- Name: media_director_relation media_director_relation_director_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: komilakurbanova
--

ALTER TABLE ONLY public.media_director_relation
    ADD CONSTRAINT media_director_relation_director_id_fkey FOREIGN KEY (director_id) REFERENCES public.directors(director_id);


--
-- Name: media_director_relation media_director_relation_media_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: komilakurbanova
--

ALTER TABLE ONLY public.media_director_relation
    ADD CONSTRAINT media_director_relation_media_id_fkey FOREIGN KEY (media_id) REFERENCES public.media_content(media_id);


--
-- Name: movie movie_media_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: komilakurbanova
--

ALTER TABLE ONLY public.movie
    ADD CONSTRAINT movie_media_id_fkey FOREIGN KEY (media_id) REFERENCES public.media_content(media_id);


--
-- Name: ratings ratings_media_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: komilakurbanova
--

ALTER TABLE ONLY public.ratings
    ADD CONSTRAINT ratings_media_id_fkey FOREIGN KEY (media_id) REFERENCES public.media_content(media_id);


--
-- Name: ratings ratings_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: komilakurbanova
--

ALTER TABLE ONLY public.ratings
    ADD CONSTRAINT ratings_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- Name: series_episodes series_episodes_media_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: komilakurbanova
--

ALTER TABLE ONLY public.series_episodes
    ADD CONSTRAINT series_episodes_media_id_fkey FOREIGN KEY (media_id) REFERENCES public.series(media_id);


--
-- Name: series series_media_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: komilakurbanova
--

ALTER TABLE ONLY public.series
    ADD CONSTRAINT series_media_id_fkey FOREIGN KEY (media_id) REFERENCES public.media_content(media_id);


--
-- PostgreSQL database dump complete
--

