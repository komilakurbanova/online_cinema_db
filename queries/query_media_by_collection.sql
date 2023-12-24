-- Создание хранимой функции для выборки медиа из указанной коллекции пользователя
CREATE OR REPLACE FUNCTION GetMediaByCollection(
    p_collection_name VARCHAR(100),
    p_user_id INT
)
RETURNS TABLE (
    title VARCHAR(100),
    media_type VARCHAR(10)
) AS $$
BEGIN
    RETURN QUERY
    SELECT Media_Content.title, Media_Content.media_type
    FROM Media_Content
    JOIN Media_Collection_Relation ON Media_Content.media_id = Media_Collection_Relation.media_id
    JOIN Collections ON Media_Collection_Relation.collection_id = Collections.collection_id
    WHERE Collections.collection_name = p_collection_name AND Collections.user_id = p_user_id;
END;
$$ LANGUAGE plpgsql;
-- Вызов функции для получения фильмов коллекции
SELECT * FROM GetMediaByCollection('Избранное', 1);