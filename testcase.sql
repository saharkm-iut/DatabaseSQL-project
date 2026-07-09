use dbproject;



--DELETE FROM Taxi.trip_message;
--DELETE FROM Taxi.trip_review;
--DELETE FROM Taxi.taxi_trips;
--DELETE FROM Taxi.live_location_driver;
--DELETE FROM Taxi.driver_doc;
--DELETE FROM Taxi.vehicles;
--DELETE FROM Taxi.drivers;

--DELETE FROM Payment.coupons;

--DELETE FROM Account.user_roles;
--DELETE FROM Account.user_address;
--DELETE FROM Account.users;
--DELETE FROM Account.roles;

--IF OBJECT_ID('Taxi.DriverImport','U') IS NOT NULL
--    DELETE FROM Taxi.DriverImport;
--GO
--DBCC CHECKIDENT ('Account.users', RESEED, 0);
--DBCC CHECKIDENT ('Account.roles', RESEED, 0);
--DBCC CHECKIDENT ('Account.user_address', RESEED, 0);

--DBCC CHECKIDENT ('Payment.coupons', RESEED, 0);

--DBCC CHECKIDENT ('Taxi.taxi_trips', RESEED, 0);
--DBCC CHECKIDENT ('Taxi.vehicles', RESEED, 0);
--DBCC CHECKIDENT ('Taxi.live_location_driver', RESEED, 0);
--DBCC CHECKIDENT ('Taxi.trip_review', RESEED, 0);
--DBCC CHECKIDENT ('Taxi.fare_rule', RESEED, 0);
--DBCC CHECKIDENT ('Taxi.driver_doc', RESEED, 0);
--DBCC CHECKIDENT ('Taxi.trip_message', RESEED, 0);
--GO

-- Roles
INSERT INTO Account.roles(role_name)
VALUES
('Admin'),
('Customer'),
('RestaurantManager'),
('Driver');
GO
-- Users
INSERT INTO Account.users
(firstname, lastname, phone_num, email, pass_hash)
VALUES
('Ali','Ahmadi','09111111111','ali@gmail.com','123456'),
('Sara','Karimi','09111111112','sara@gmail.com','123456'),
('Reza','Moradi','09111111113','reza@gmail.com','123456'),
('Maryam','Hashemi','09111111114','maryam@gmail.com','123456'),
('Mohammad','Jafari','09111111115','mohammad@gmail.com','123456');
GO

INSERT INTO Account.user_roles (user_id, role_id)
VALUES
(1,1),  -- Ali -> Admin

(2,2),  -- Sara -> Customer

(3,3),  -- Reza -> RestaurantManager
(3,4),  -- Reza -> Driver

(4,2),  -- Maryam -> Customer

(5,2),  -- Mohammad -> Customer
(5,4);  -- Mohammad -> Driver
GO

INSERT INTO Account.user_address
(user_id, title, address_text, latitude, longitude)
VALUES
(1, N'خانه', N'اصفهان، خیابان چهارباغ بالا، پلاک 10', 32.654600, 51.668000),

(2, N'خانه', N'اصفهان، خیابان مرداویج، کوچه 5', 32.635200, 51.669500),

(3, N'رستوران', N'اصفهان، خیابان حکیم نظامی، پلاک 25', 32.640800, 51.651200),

(4, N'خانه', N'اصفهان، خیابان توحید، پلاک 18', 32.648900, 51.661700),

(5, N'خانه', N'اصفهان، خیابان آمادگاه، پلاک 7', 32.657300, 51.677100);
GO



INSERT INTO Payment.coupons
(code, service_type, discount_type, discount_value, max_discount, expiry_date)
VALUES
('FOOD10',  'Food',   'Percentage', 10, 100000, '2027-12-31'),
('FOOD50',  'Food',   'Fixed_Amount', 50000, NULL, '2027-12-31'),
('TAXI15',  'Taxi',   'Percentage', 15, 80000, '2027-12-31'),
('GLOBAL5', 'Global', 'Percentage', 5, 50000, '2027-12-31'),
('WELCOME', 'Global', 'Fixed_Amount', 30000, NULL, '2027-12-31');
GO

INSERT INTO Account.users
(firstname, lastname, phone_num, email, pass_hash)
VALUES
('Hossein','Rahimi','09111111116','hossein@gmail.com','123456'),
('Narges','Mohammadi','09111111117','narges@gmail.com','123456');
GO

INSERT INTO Account.user_roles(user_id, role_id)
VALUES
(6,3),
(7,3);
GO


------taxi test case
-- in this senario we need persuade to not evolve with role and id 
INSERT INTO Taxi.drivers(driver_id,license_num,national_code,is_approved,is_online)
VALUES
(3,'4412589631','0087452361',1,1),
(5,'5123498765','2256147893',1,0);
GO
-- حذف Procedureها
EXEC Taxi.CreateDriver
'Ahmad','Ahmadi','09123456789','ahmad.driver@gmail.com','hashed_password','1234567890','0012345678';
GO

CREATE TABLE Taxi.DriverImport
(
firstname NVARCHAR(50),
lastname NVARCHAR(50),
phone_num VARCHAR(11),
email VARCHAR(100),
pass_hash VARCHAR(255),
license_num VARCHAR(10),
national_code VARCHAR(10)
);
GO
--BULK INSERT Taxi.DriverImport
--FROM 'C:\Users\Padidar\Desktop\sth you should do\dbproj\drivers.csv'
--WITH
--(
--FORMAT='CSV',
--FIRSTROW=2,
--FIELDTERMINATOR=';',
--ROWTERMINATOR='0x0a',
--CODEPAGE='65001'
--);
--GO
--SELECT
--    phone_num,
--    LEN(phone_num) AS Len,
--    DATALENGTH(phone_num) AS DataLength,
--    '[' + phone_num + ']' AS Value
--FROM Taxi.DriverImport;
--DECLARE @firstname NVARCHAR(50),@lastname NVARCHAR(50),@phone VARCHAR(11),@email VARCHAR(100),@pass VARCHAR(255),@license VARCHAR(10),@national VARCHAR(10);

--DECLARE driver_cursor CURSOR LOCAL FAST_FORWARD FOR
--SELECT firstname,lastname,phone_num,email,pass_hash,license_num,national_code
--FROM Taxi.DriverImport;

--OPEN driver_cursor;

--FETCH NEXT FROM driver_cursor
--INTO @firstname,@lastname,@phone,@email,@pass,@license,@national;

--WHILE @@FETCH_STATUS=0
--BEGIN
--EXEC Taxi.CreateDriver
--@firstname,@lastname,@phone,@email,@pass,@license,@national;

--FETCH NEXT FROM driver_cursor
--INTO @firstname,@lastname,@phone,@email,@pass,@license,@national;
--END

--CLOSE driver_cursor;
--DEALLOCATE driver_cursor;
--GO
select* from Taxi.drivers;

