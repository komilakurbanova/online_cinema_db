-- Список публичных коллекций
SELECT
    Collections.collection_id,
    Collections.user_id,
    Collections.collection_name,
    Users.public_name
FROM Collections
JOIN Users ON Collections.user_id = Users.user_id
WHERE Collections.is_public = true;

