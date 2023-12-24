-- Смена имени пользователя
CREATE OR REPLACE FUNCTION ChangePublicName(
    p_user_id INT,
    p_new_public_name VARCHAR(50)
)
RETURNS VOID AS $$
BEGIN
    UPDATE Users
    SET public_name = p_new_public_name
    WHERE user_id = p_user_id;
END;
$$ LANGUAGE plpgsql;

-- Вызов функции для смены имени
SELECT ChangePublicName(1, 'Кисуня1998');
SELECT ChangePublicName(2, 'Звездный Путник');
SELECT ChangePublicName(3, 'Смотритель');
