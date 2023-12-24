-- Рейтинги фильмов в порядке убывания среди всех фильмов и их место в рейтинге (если не ноль)
SELECT
    media_id,
    title,
    rating,
    ROW_NUMBER() OVER (ORDER BY rating DESC) AS position_in_rating
FROM Media_Content
WHERE media_type = 'Movie';
