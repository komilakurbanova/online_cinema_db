-- Создание таблицы "Медиа"
CREATE TABLE Media_Content (
    media_id INT PRIMARY KEY,
    media_type VARCHAR(10) NOT NULL,
    title VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    rating DECIMAL(2, 1) DEFAULT 0.0,
    genre VARCHAR(255),
    country VARCHAR(50),
    release_year INT CHECK (release_year >= 1000 AND release_year <= 9999)
);

-- Создание таблицы "Фильмы"
CREATE TABLE Movie (
    media_id INT PRIMARY KEY,
    watch_link VARCHAR(255),
    FOREIGN KEY (media_id) REFERENCES Media_Content(media_id)
);

-- Создание таблицы "Сериалы"
CREATE TABLE Series (
    media_id INT PRIMARY KEY,
    season_count INT CHECK (season_count >= 0) NOT NULL,
    episodes_count INT CHECK (episodes_count >= 0) NOT NULL,
    FOREIGN KEY (media_id) REFERENCES Media_Content(media_id)
);

-- Создание таблицы "Серии"
CREATE TABLE Series_Episodes (
    episode_id INT PRIMARY KEY,
    media_id INT,
    season_number INT CHECK (season_number >= 0) NOT NULL,
    episode_number INT CHECK (episode_number >= 0) NOT NULL,
    title VARCHAR(100),
    description TEXT,
    watch_link VARCHAR(255),
    FOREIGN KEY (media_id) REFERENCES Series(media_id)
);

-- Создание таблицы "Пользователи"
CREATE TABLE Users (
    user_id INT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(100) NOT NULL,
    public_name VARCHAR(50) NOT NULL
);

-- Создание таблицы "Коллекции"
CREATE TABLE Collections (
    collection_id INT PRIMARY KEY,
    user_id INT,
    collection_name VARCHAR(100) NOT NULL,
    is_public BOOLEAN NOT NULL,
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

-- Создание таблицы "Оценки"
CREATE TABLE Ratings (
    rating_id INT PRIMARY KEY,
    user_id INT,
    media_id INT,
    rating INT CHECK (rating >= 0 AND rating <= 10) NOT NULL,
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (media_id) REFERENCES Media_Content(media_id)
);

-- Создание таблицы "Режиссеры"
CREATE TABLE Directors (
    director_id INT PRIMARY KEY,
    director_name VARCHAR(100) NOT NULL,
    filmography TEXT
);

-- Создание таблицы "Актеры"
CREATE TABLE Actors (
    actor_id INT PRIMARY KEY,
    actor_name VARCHAR(100) NOT NULL,
    filmography TEXT
);

-- Создание таблицы "Связь медиа-режиссер"
CREATE TABLE Media_Director_Relation (
    media_id INT,
    director_id INT,
    PRIMARY KEY (media_id, director_id),
    FOREIGN KEY (media_id) REFERENCES Media_Content(media_id),
    FOREIGN KEY (director_id) REFERENCES Directors(director_id)
);

-- Создание таблицы "Связь медиа-актер"
CREATE TABLE Media_Actor_Relation (
    media_id INT,
    actor_id INT,
    PRIMARY KEY (media_id, actor_id),
    FOREIGN KEY (media_id) REFERENCES Media_Content(media_id),
    FOREIGN KEY (actor_id) REFERENCES Actors(actor_id)
);

-- Создание таблицы "Связь медиа-коллекция"
CREATE TABLE Media_Collection_Relation (
    media_id INT,
    collection_id INT,
    PRIMARY KEY (media_id, collection_id),
    FOREIGN KEY (media_id) REFERENCES Media_Content(media_id),
    FOREIGN KEY (collection_id) REFERENCES Collections(collection_id)
);


------------------------------------------------Триггеры-----------------------------------------


-- Триггерная функция для обновления рейтинга в MediaContent
CREATE OR REPLACE FUNCTION trg_Update_Media_Rating()
RETURNS TRIGGER AS $$
BEGIN
    -- Обновляем рейтинг в Media_Content при добавлении новой оценки
    UPDATE Media_Content
    SET rating = (
        SELECT AVG(rating) FROM Ratings WHERE media_id = NEW.media_id
    )
    WHERE media_id = NEW.media_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Триггер для Ratings
CREATE TRIGGER trg_Ratings_Insert
AFTER INSERT ON Ratings
FOR EACH ROW
EXECUTE FUNCTION trg_Update_Media_Rating();



-- Триггерная функция для выставления оценки
CREATE OR REPLACE FUNCTION update_rating_function()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.rating < 0 OR NEW.rating > 10 THEN
    RAISE EXCEPTION 'Оценка должна быть в диапазоне от 0 до 10.';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Триггер для выставления оценки
CREATE TRIGGER update_rating_trigger
BEFORE INSERT ON Ratings
FOR EACH ROW
EXECUTE FUNCTION update_rating_function();



-- Триггерная функция для обновления количества серий и сезонов
-- Здесь считаем, что мы увеличиваем число, если в базу добавляется новый сезон/серия (максимальное значение), о которых мы раньше не знали.
-- То есть это предположение о том, сколько сезонов и серий в этом сериале, а не о том, сколько эпизодов есть в нашей базе
CREATE OR REPLACE FUNCTION update_episode_count_function()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;

-- Триггер для обновления количества серий
CREATE TRIGGER update_episode_count
AFTER INSERT ON Series_Episodes
FOR EACH ROW
EXECUTE FUNCTION update_episode_count_function();



-----------------------------------------------------Добавление данных---------------------------------------------

INSERT INTO Media_Content (media_id, media_type, title, description, genre, country, release_year)
VALUES (1, 'Movie', 'Побег из Шоушенка', 'Двое заключенных находят общий язык на протяжении многих лет, находя утешение и окончательное искупление через акты добродетели.', 'Драма', 'США', 1994);

INSERT INTO Media_Content (media_id, media_type, title, description, genre, country, release_year)
VALUES (2, 'Movie', 'Интерстеллар', 'Группа исследователей использует проход в пространстве-времени, чтобы обеспечить выживание человечества на новой планете.', 'Научная фантастика, Драма', 'США', 2014);

INSERT INTO Media_Content (media_id, media_type, title, description, genre, country, release_year)
VALUES (3, 'Movie', 'Форрест Гамп', 'Жизнь обычного человека, который случайно участвует в ряде исторических событий в течение нескольких десятилетий.', 'Драма, Романтика', 'США', 1994);

INSERT INTO Media_Content (media_id, media_type, title, description, genre, country, release_year)
VALUES (4, 'Movie', 'Зеленая миля', 'Смотритель тюрьмы обнаруживает, что один из заключенных обладает невероятным даром.', 'Драма, Фэнтези', 'США', 1999);

INSERT INTO Media_Content (media_id, media_type, title, description, genre, country, release_year)
VALUES (5, 'Movie', 'Матрица', 'Программист Нео обнаруживает, что мир, в котором он живет, на самом деле является компьютерной симуляцией.', 'Экшн, Научная фантастика', 'США', 1999);

INSERT INTO Media_Content (media_id, media_type, title, description, genre, country, release_year)
VALUES (6, 'Series', 'Во все тяжкие', 'Учитель химии из старшей школы становится производителем метамфетамина и заключает сделку с бывшим учеником для обеспечения будущего своей семьи.', 'Криминал, Драма, Триллер', 'США', 2008);

INSERT INTO Media_Content (media_id, media_type, title, description,  genre, country, release_year)
VALUES (7, 'Series', 'Игра престолов', 'Эпическая сага о борьбе за власть в вымышленном мире Вестерос.', 'Драма, Фэнтези, Приключения', 'США', 2011);

INSERT INTO Media_Content (media_id, media_type, title, description, genre, country, release_year)
VALUES (8, 'Series', 'Черное зеркало', 'Каждая серия представляет собой отдельную историю, исследующую темы технологии и ее воздействия на общество.', 'Драма, Научная фантастика, Триллер', 'Великобритания', 2011);


INSERT INTO Movie (media_id, watch_link)
VALUES (1, 'https://example.com/watch/1');

INSERT INTO Movie (media_id, watch_link)
VALUES (2, 'https://example.com/watch/2');

INSERT INTO Movie (media_id, watch_link)
VALUES (3, 'https://example.com/watch/3');

INSERT INTO Movie (media_id, watch_link)
VALUES (4, 'https://example.com/watch/4');

INSERT INTO Movie (media_id, watch_link)
VALUES (5, 'https://example.com/watch/5');

INSERT INTO Series (media_id, season_count, episodes_count)
VALUES (6, 1, 0);

INSERT INTO Series (media_id, season_count, episodes_count)
VALUES (7, 1, 0);

INSERT INTO Series (media_id, season_count, episodes_count)
VALUES (8, 1, 0);


-- Вставка данных в таблицу Эпизодов сериала
INSERT INTO Series_Episodes (episode_id, media_id, season_number, episode_number, title, description, watch_link)
VALUES (1, 6, 1, 1, 'Пилотный эпизод', 'Первый эпизод сериала "Во все тяжкие". Учитель химии превращается в производителя метамфетамина.', 'https://example.com/series/6/season/1/episode/1');

INSERT INTO Series_Episodes (episode_id, media_id, season_number, episode_number, title, description, watch_link)
VALUES (2, 7, 1, 1, 'Зима близко', 'Первый эпизод сериала "Игра престолов". Вступление в мир интриг и политических борьб.', 'https://example.com/series/7/season/1/episode/1');

INSERT INTO Series_Episodes (episode_id, media_id, season_number, episode_number, title, description, watch_link)
VALUES (3, 8, 1, 1, 'Первый эпизод', 'Первый эпизод сериала "Черное зеркало". Исследование тем технологии и ее воздействия на общество.', 'https://example.com/series/8/season/1/episode/1');

INSERT INTO Series_Episodes (episode_id, media_id, season_number, episode_number, title, description, watch_link)
VALUES (4, 8, 1, 2, 'Второй эпизод', 'Второй эпизод сериала "Черное зеркало". Еще одна увлекательная история о технологиях.', 'https://example.com/series/8/season/1/episode/2');

INSERT INTO Series_Episodes (episode_id, media_id, season_number, episode_number, title, description, watch_link)
VALUES (5, 7, 2, 3, 'Загадочный эпизод', 'Третий эпизод второго сезона сериала "Игра престолов". Новые повороты в сюжете.', 'https://example.com/series/7/season/2/episode/3');


-- Вставка данных в таблицы Актеров
INSERT INTO Actors (actor_id, actor_name, filmography)
VALUES (1, 'Тим Роббинс', 'Побег из Шоушенка, Зеленая миля, Мистическая река');

INSERT INTO Actors (actor_id, actor_name, filmography)
VALUES (2, 'Мэттью Макконахи', 'Во все тяжкие, Интерстеллар, Загадочная река');

INSERT INTO Actors (actor_id, actor_name, filmography)
VALUES (3, 'Том Хэнкс', 'Форрест Гамп, Побег из Шоушенка, Спасение Райана');

INSERT INTO Actors (actor_id, actor_name, filmography)
VALUES (4, 'Морган Фримен', 'Побег из Шоушенка, Зеленая миля, Семь');

INSERT INTO Actors (actor_id, actor_name, filmography)
VALUES (5, 'Киану Ривз', 'Матрица, Джон Уик, Константин');


INSERT INTO Media_Actor_Relation (media_id, actor_id)
VALUES (1, 1); -- Тим Роббинс в "Побег из Шоушенка"

INSERT INTO Media_Actor_Relation (media_id, actor_id)
VALUES (1, 4); -- Морган Фримен в "Побег из Шоушенка"

INSERT INTO Media_Actor_Relation (media_id, actor_id)
VALUES (2, 2); -- Мэттью Макконахи в "Интерстеллар"

INSERT INTO Media_Actor_Relation (media_id, actor_id)
VALUES (2, 5); -- Киану Ривз в "Интерстеллар"

INSERT INTO Media_Actor_Relation (media_id, actor_id)
VALUES (3, 3); -- Том Хэнкс в "Форрест Гамп"

INSERT INTO Media_Actor_Relation (media_id, actor_id)
VALUES (3, 1); -- Тим Роббинс в "Форрест Гамп"


-- Вставка данных в таблицы Режиссеров
INSERT INTO Directors (director_id, director_name, filmography)
VALUES (1, 'Фрэнк Дарабонт', 'Побег из Шоушенка, Зеленая миля, Мистическая река');

INSERT INTO Directors (director_id, director_name, filmography)
VALUES (2, 'Кристофер Нолан', 'Мemento, The Dark Knight, Интерстеллар');

INSERT INTO Directors (director_id, director_name, filmography)
VALUES (3, 'Роберт Земекис', 'Форрест Гамп, Назад в будущее, Каст away');


INSERT INTO Media_Director_Relation (media_id, director_id)
VALUES (1, 1); -- Фрэнк Дарабонт режиссер "Побег из Шоушенка"

INSERT INTO Media_Director_Relation (media_id, director_id)
VALUES (1, 3); -- Роберт Земекис режиссер "Побег из Шоушенка"

INSERT INTO Media_Director_Relation (media_id, director_id)
VALUES (2, 2); -- Кристофер Нолан режиссер "Интерстеллар"

INSERT INTO Media_Director_Relation (media_id, director_id)
VALUES (3, 3); -- Роберт Земекис режиссер "Форрест Гамп"



-- Вставка данных в таблицу Пользователей
INSERT INTO Users (user_id, username, password_hash, public_name)
VALUES (1, 'user1', 'hashed_password1', 'Пользователь 1');

INSERT INTO Users (user_id, username, password_hash, public_name)
VALUES (2, 'user2', 'hashed_password2', 'Пользователь 2');

INSERT INTO Users (user_id, username, password_hash, public_name)
VALUES (3, 'user3', 'hashed_password3', 'Пользователь 3');


-- Вставка данных в таблицы Оценок
INSERT INTO Ratings (rating_id, user_id, media_id, rating)
VALUES (1, 1, 1, 9); -- Пользователь 1 оценил "Побег из Шоушенка" на 9 баллов

INSERT INTO Ratings (rating_id, user_id, media_id, rating)
VALUES (2, 2, 2, 8); -- Пользователь 2 оценил "Интерстеллар" на 8 баллов

INSERT INTO Ratings (rating_id, user_id, media_id, rating)
VALUES (3, 3, 3, 7); -- Пользователь 3 оценил "Форрест Гамп" на 7 баллов

INSERT INTO Ratings (rating_id, user_id, media_id, rating)
VALUES (4, 1, 4, 8); -- Пользователь 1 оценил "Зеленая миля" на 8 баллов

INSERT INTO Ratings (rating_id, user_id, media_id, rating)
VALUES (5, 2, 5, 9); -- Пользователь 2 оценил "Матрица" на 9 баллов

INSERT INTO Ratings (rating_id, user_id, media_id, rating)
VALUES (6, 1, 5, 10); -- Пользователь 1 оценил "Матрица" на 10 баллов


-- Вставка в таблицы Коллекций
INSERT INTO Collections (collection_id, user_id, collection_name, is_public)
VALUES
    (1, 1, 'Избранное', true),
    (2, 1, 'Смотреть позже', false),
    (3, 2, 'Избранное', true);
    
INSERT INTO Media_Collection_Relation (media_id, collection_id)
VALUES
    (1, 1),
    (2, 1),
    (3, 2),
    (4, 3);
    
    
--------------------------------------------------------Полнотекстовый поиск----------------------------------------

ALTER TABLE Media_Content ADD COLUMN description_vector tsvector;

UPDATE Media_Content SET description_vector = to_tsvector('russian', description);

CREATE INDEX idx_description_vector ON Media_Content USING gin(description_vector);


-- Поиск по слову
CREATE OR REPLACE FUNCTION search_media_content_by_keyword(query_text TEXT)
RETURNS SETOF Media_Content AS
$$
BEGIN
    RETURN QUERY
    SELECT *
    FROM Media_Content
    WHERE description_vector @@ to_tsquery('russian', query_text);
END;
$$ LANGUAGE plpgsql;

-- Пример использования функции
SELECT * FROM search_media_content_by_keyword('заключение');
SELECT * FROM search_media_content_by_keyword('сделка | тюрьма | заключение');



-- Поиск по слову или словосочетанию без учета порядка слов
CREATE OR REPLACE FUNCTION search_media_content_by_phrase(query_text TEXT)
RETURNS SETOF Media_Content AS
$$
BEGIN
    RETURN QUERY
    SELECT *
    FROM Media_Content
    WHERE description_vector @@ plainto_tsquery('russian', query_text);
END;
$$ LANGUAGE plpgsql;

-- Пример использования функции
SELECT * FROM search_media_content_by_phrase('Вестерос');
SELECT * FROM search_media_content_by_phrase('двое заключенных');
SELECT * FROM search_media_content_by_phrase('заключенных двое');



-- Поиск по части слова, пример
SELECT * FROM Media_Content WHERE description ~* 'про';
