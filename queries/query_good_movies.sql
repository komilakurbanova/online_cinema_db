-- Список всех фильмов с их рейтингами, где рейтинг выше среднего
SELECT title, rating
FROM Media_Content
WHERE media_type = 'Movie' AND rating > (SELECT AVG(rating) FROM Media_Content WHERE media_type = 'Movie');