-- Список всех медиа, заданного жанра
CREATE OR REPLACE FUNCTION GetMediaByGenre(p_genre VARCHAR(255))
RETURNS TABLE (
    media_id INT,
    media_type VARCHAR(10),
    title VARCHAR(100),
    description TEXT,
    rating DECIMAL(2, 1),
    genre VARCHAR(255),
    country VARCHAR(50),
    release_year INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM Media_Content
    WHERE LOWER(Media_Content.genre) LIKE '%' || LOWER(p_genre) || '%';
END;
$$ LANGUAGE plpgsql;

-- Вызов функции для получения медиа по жанру
SELECT * FROM GetMediaByGenre('научная фантастика');
