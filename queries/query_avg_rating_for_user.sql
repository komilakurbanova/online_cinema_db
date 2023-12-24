-- Средняя оценка, которую поставил пользователь
WITH UserAvgRating AS (
    SELECT user_id, AVG(rating) AS avg_rating
    FROM Ratings
    GROUP BY user_id
)

SELECT u.user_id, u.public_name, uar.avg_rating
FROM Users u
JOIN UserAvgRating uar ON u.user_id = uar.user_id;
