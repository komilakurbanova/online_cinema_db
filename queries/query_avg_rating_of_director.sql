-- Средний рейтинг для каждого режиссера
WITH DirectorAvgRating AS (
    SELECT
        D.director_id,
        D.director_name,
        AVG(MC.rating) AS avg_rating
    FROM
        Directors D
        JOIN Media_Director_Relation MD ON D.director_id = MD.director_id
        JOIN Media_Content MC ON MD.media_id = MC.media_id
    GROUP BY
        D.director_id, D.director_name
)
SELECT
    director_id,
    director_name,
    COALESCE(avg_rating, 0.0) AS average_rating
FROM DirectorAvgRating;
