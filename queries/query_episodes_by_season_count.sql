-- Количестве эпизодов в каждом сезоне всех сериалов в кинотеатре
WITH Season_Episodes AS (
    SELECT media_id, season_number, COUNT(*) AS episode_count
    FROM Series_Episodes
    GROUP BY media_id, season_number
)

SELECT m.title, s.season_number, s.episode_count
FROM Season_Episodes s
JOIN Media_Content m ON s.media_id = m.media_id
WHERE m.media_type = 'Series';
