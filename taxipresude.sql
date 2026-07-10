------------taxiprocedures


create procedure Taxi.CreateDriver
(
    @firstname NVARCHAR(50),
    @lastname NVARCHAR(50),
    @phone_num VARCHAR(11),
    @email VARCHAR(100),
    @pass_hash VARCHAR(255),

    @license_num VARCHAR(10),
    @national_code VARCHAR(10)
)


as begin
begin transaction;
begin try

DECLARE @user_id INT;
DECLARE @driver_role INT;
INSERT INTO Account.users(firstname,lastname,phone_num, email,pass_hash)
VALUES(@firstname,@lastname, @phone_num, @email, @pass_hash );
SET @user_id = SCOPE_IDENTITY();

SELECT @driver_role = role_id
FROM Account.roles
WHERE role_name='Driver';
INSERT INTO Account.user_roles(user_id,role_id)
VALUES(@user_id,@driver_role);
INSERT INTO Taxi.drivers(driver_id,license_num,national_code,is_approved,is_online)
VALUES(@user_id,@license_num,@national_code,1,0);
COMMIT;
SELECT 'Driver Created' AS Message, @user_id AS UserID;
END TRY
BEGIN CATCH
ROLLBACK;
THROW;
END CATCH
END;

