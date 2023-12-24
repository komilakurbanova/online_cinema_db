-- Авторизация пользователя
CREATE OR REPLACE FUNCTION ValidateUserCredentials(
    p_username VARCHAR(50),
    p_password_hash VARCHAR(100)
) 
RETURNS BOOLEAN AS $$
DECLARE
    v_count INT;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM Users
    WHERE username = p_username AND password_hash = p_password_hash;
    RETURN v_count > 0;
END;
$$ LANGUAGE plpgsql;

-- Вызов функции для авторизации
SELECT ValidateUserCredentials('user1', 'hashed_password1'); -- True

SELECT ValidateUserCredentials('user100000', 'hashed_password100000'); -- False

