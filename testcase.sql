use dbproject;



--DELETE from Taxi.trip_message;
--DELETE from Taxi.trip_review;
--DELETE from Taxi.taxi_trips;
--DELETE from Taxi.live_location_driver;
--DELETE from Taxi.driver_doc;
--DELETE from Taxi.vehicles;
--DELETE from Taxi.drivers;

--DELETE from Payment.coupons;

--DELETE from Account.user_roles;
--DELETE from Account.user_address;
--DELETE from Account.users;
--DELETE from Account.roles;

--IF OBJECT_ID('Taxi.DriverImport','U') IS NOT NULL
--    DELETE from Taxi.DriverImport;
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


INSERT INTO Account.roles(role_name)
VALUES('Admin'),('Customer'),('RestaurantManager'),('Driver');
GO
INSERT INTO Account.users(firstname, lastname, phone_num, email, pass_hash)
VALUES('Ali','Ahmadi','09111111111','ali@gmail.com','123456'),
('Sara','Karimi','09111111112','sara@gmail.com','123456'),
('Reza','Moradi','09111111113','reza@gmail.com','123456'),
('Maryam','Hashemi','09111111114','maryam@gmail.com','123456'),
('Mohammad','Jafari','09111111115','mohammad@gmail.com','123456');
GO
INSERT INTO Account.user_roles (user_id, role_id)
VALUES(1,1), (2,2), (3,3), (3,4), (4,2), (5,2), (5,4);GO
INSERT INTO Account.user_address(user_id, title, address_text, latitude, longitude)
VALUES(1, N'خانه', N'اصفهان خیابان چهارباغ بالا پلاک 10', 32.654600, 51.668000),
(2, N'خانه', N'اصفهان خیابان مرداویج کوچه 5', 32.635200, 51.669500),
(3, N'رستوران', N'اصفهان خیابان حکیم نظامی پلاک 25', 32.640800, 51.651200),
(4, N'خانه', N'اصفهان خیابان توحید پلاک 18', 32.648900, 51.661700),
(5, N'خانه', N'اصفهان خیابان آمادگاه پلاک 7', 32.657300, 51.677100);
GO
INSERT INTO Payment.coupons(code, service_type, discount_type, discount_value, max_discount, expiry_date)
VALUES('FOOD10',  'Food',   'Percentage', 10, 100000, '2027-12-31'),
('FOOD50',  'Food',   'Fixed_Amount', 50000, NULL, '2027-12-31'),
('TAXI15',  'Taxi',   'Percentage', 15, 80000, '2027-12-31'),
('GLOBAL5', 'Global', 'Percentage', 5, 50000, '2027-12-31'),
('WELCOME', 'Global', 'Fixed_Amount', 30000, NULL, '2027-12-31');
GO

INSERT INTO Account.users(firstname, lastname, phone_num, email, pass_hash)
VALUES('Hossein','Rahimi','09111111116','hossein@gmail.com','123456'),
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
VALUES(3,'4412589631','0087452361',1,1),(5,'5123498765','2256147893',1,0);
GO
------------- از پرسیجر استفاده شده که در فایل پرسیجر تاکسی هست 
EXEC Taxi.CreateDriver
'Ahmad','Ahmadi','09123456789','ahmad.driver@gmail.com','hashed_password','1234567890','0012345678';
GO
-- یه جدول کمکی برا گرفتن داده ها از فایل اکسل
CREATE TABLE Taxi.DriverImport
(firstname NVARCHAR(50),
lastname NVARCHAR(50),
phone_num VARCHAR(11),
email VARCHAR(100),
pass_hash VARCHAR(255),
license_num VARCHAR(10),
national_code VARCHAR(10)
);
GO
BULK INSERT Taxi.DriverImport
from 'C:\Users\Padidar\Desktop\sth you should do\dbproj\Drivers (2).csv'
WITH
(
FORMAT='CSV',
FIRSTROW=2, -- خط اول  اکسل را نادیده میگیره 
FIELDTERMINATOR=',',
ROWTERMINATOR='\n',
CODEPAGE='65001'
);
GO
select phone_num, LEN(phone_num) AS Len, DATALENGTH(phone_num) AS DataLength,'[' + phone_num + ']' AS Value
from Taxi.DriverImport;
declare @firstname NVARCHAR(50),@lastname NVARCHAR(50),@phone VARCHAR(11),@email VARCHAR(100),@pass VARCHAR(255),@license VARCHAR(10),@national VARCHAR(10);
-- برا اینکه داده ها را از جدول کمکی وارد جدول اصلی کنه از کرسر استفاده میشه  
-- بعد از همون پرسیجر استفاده می کنه برا هندل کردن ایدی ها دیگه نیاز نیس خودمون بشماریم ایدی دستی بدیم پرسیجر هندلمی کنه
declare driver_cursor CURSOR LOCAL FAST_FORWARD FOR
select firstname,lastname,phone_num,email,pass_hash,license_num,national_code
from Taxi.DriverImport;
OPEN driver_cursor;
FETCH NEXT from driver_cursor
INTO @firstname,@lastname,@phone,@email,@pass,@license,@national;
WHILE @@FETCH_STATUS=0
BEGIN
EXEC Taxi.CreateDriver
@firstname,@lastname,@phone,@email,@pass,@license,@national;
FETCH NEXT from driver_cursor
INTO @firstname,@lastname,@phone,@email,@pass,@license,@national;
END
CLOSE driver_cursor;
DEALLOCATE driver_cursor;
GO
--select* from Taxi.drivers;

-- قیمت پایه یکیه 
INSERT INTO Taxi.fare_rule (base_price, price_per_km, price_per_min)
VALUES (30000.00, 5000.00, 1500.00);
GO


--INSERT INTO Taxi.fare_rule (base_price, price_per_km, price_per_min)
--VALUES 
--(15000.00, 4500.00, 1200.00),
--(22000.00, 5500.00, 1500.00),
--(25000.00, 6000.00, 1800.00),
--(18000.00, 4900.00, 1300.00),
--(30000.00, 7000.00, 2000.00);

EXEC Taxi.SP_RegisterVehicle '09111111113', N'پژو 206', N'سفید', N'12ب345-ایران23'; -- رضا مرادی
EXEC Taxi.SP_RegisterVehicle '09111111115', N'پراید 131', N'نقره‌ای', N'56ج789-ایران43'; -- محمد جعفری
EXEC Taxi.SP_RegisterVehicle '09573456789', N'سمند LX', N'خاکستری', N'78د123-ایران13'; -- علی احمدی (CSV)
EXEC Taxi.SP_RegisterVehicle '09123416787', N'پژو پارس', N'مشکی', N'45ق432-ایران67'; -- حسین رحیمی (CSV)
EXEC Taxi.SP_RegisterVehicle '09126456785', N'ساینا', N'سفید', N'34ق987-ایران53'; -- سینا مرادی (CSV)

-- ۳.  موقعیت‌های زنده با ساب‌ بر اساس تلفن هندل می‌شن
INSERT INTO Taxi.live_location_driver (driver_id, latitude, longitude)
select user_id, 32.654600, 51.668000 from Account.users where phone_num = '09111111113';
INSERT INTO Taxi.live_location_driver (driver_id, latitude, longitude)
select user_id, 32.635200, 51.669500 from Account.users where phone_num = '09111111115';
INSERT INTO Taxi.live_location_driver (driver_id, latitude, longitude)
select user_id, 32.640800, 51.651200 from Account.users where phone_num = '09573456789';
INSERT INTO Taxi.live_location_driver (driver_id, latitude, longitude)
select user_id, 32.648900, 51.661700 from Account.users where phone_num = '09123416787';
INSERT INTO Taxi.live_location_driver (driver_id, latitude, longitude)
select user_id, 32.657300, 51.677100 from Account.users where phone_num = '09126456785';

--  درج  مدارک برای راننده‌ها
INSERT INTO Taxi.driver_doc (driver_id, doc_type, file_path)
select user_id, N'گواهینامه', '/docs/license_1.jpg' from Account.users where phone_num = '09111111113';
INSERT INTO Taxi.driver_doc (driver_id, doc_type, file_path)
select user_id, N'معاینه فنی', '/docs/tech_1.pdf' from Account.users where phone_num = '09111111113';
INSERT INTO Taxi.driver_doc (driver_id, doc_type, file_path)
select user_id, N'گواهینامه', '/docs/license_2.jpg' from Account.users where phone_num = '09111111115';
INSERT INTO Taxi.driver_doc (driver_id, doc_type, file_path)
select user_id, N'کارت ملی', '/docs/national_card.png' from Account.users where phone_num = '09573456789';
INSERT INTO Taxi.driver_doc (driver_id, doc_type, file_path)
select user_id, N'گواهینامه', '/docs/license_3.jpg' from Account.users where phone_num = '09123416787';



-------------یه سری تست کیس سناریویی
--  مریم درخواست سفر می‌دهد رضا قبول می‌کند سفر با موفقیت تمام شده و چت و نظر ثبت می‌شود.
EXEC Taxi.SP_RequestTrip '09111111114', N'خیابان توحید', N'خیابان مرداویج', 32.6489, 51.6617, 32.6352, 51.6695, 45000.00, 'TAXI15';
EXEC Taxi.SP_AcceptTrip '09111111113', '09111111114';
EXEC Taxi.SP_UpdateTripStatus '09111111114', 'OnTrip';
EXEC Taxi.SP_UpdateTripStatus '09111111114', 'Completed';
EXEC Taxi.SP_AddReviewAndMessage '09111111114', 5, N'عالی و بسیار محترم', N'سلام من رسیدم جلوی بانک ایستادم.', '09111111114';

--  سارا سفر رزرو می‌کند اما بلافاصله آن را لغو می‌کند.
EXEC Taxi.SP_RequestTrip '09111111112', N'خیابان مرداویج', N'میدان نقش جهان', 32.6352, 51.6695, 32.6572, 51.6773, 75000.00, NULL;
EXEC Taxi.SP_UpdateTripStatus '09111111112', 'Cancelled';
EXEC Taxi.SP_AddReviewAndMessage '09111111112', 1, N'هیچ راننده‌ای سفر را قبول نکرد مجبور شدم لغو کنم.', NULL, '09111111112';

--  علی درخواست سفر ثبت کرده و  حسین رحیمی آن را قبول کرده و به مبدا رسیده است .
EXEC Taxi.SP_RequestTrip '09111111111', N'خیابان چهارباغ بالا', N'خیابان نظر', 32.6546, 51.6680, 32.6425, 51.6590, 32000.00, NULL;
EXEC Taxi.SP_AcceptTrip '09123416787', '09111111111';
EXEC Taxi.SP_UpdateTripStatus '09111111111', 'Arrived';
EXEC Taxi.SP_AddReviewAndMessage '09111111111', 0, NULL, N'من دو دقیقه دیگه می‌رسم لوکیشن شما.', '09123416787'; -- چت راننده با مسافر

-- محمد درخواست سفر با کد تخفیف جهانی ثبت کرده و در وضعیت جستجو منتظر راننده است.
EXEC Taxi.SP_RequestTrip '09111111115', N'خیابان آمادگاه', N'سی و سه پل', 32.6573, 51.6771, 32.6442, 51.6675, 25000.00, 'GLOBAL5';

--  سارا مجدد یک درخواست سفر جدید ثبت کرده و منتظر راننده است.
EXEC Taxi.SP_RequestTrip '09111111112', N'دانشگاه صنعتی اصفهان', N'دروازه شیراز', 32.7180, 51.5280, 32.6150, 51.6600, 120000.00, 'WELCOME';
GO

