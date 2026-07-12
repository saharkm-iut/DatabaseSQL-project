use dbproject;



DELETE from Taxi.trip_message;
DELETE from Taxi.trip_review;
DELETE from Taxi.taxi_trips;
DELETE from Taxi.live_location_driver;
DELETE from Taxi.driver_doc;
DELETE from Taxi.vehicles;
DELETE from Taxi.drivers;

DELETE from Payment.coupons;

DELETE from Account.user_roles;
DELETE from Account.user_address;
DELETE from Account.users;
DELETE from Account.roles;

IF OBJECT_ID('Taxi.DriverImport','U') IS NOT NULL
    DELETE from Taxi.DriverImport;
GO
DBCC CHECKIDENT ('Account.users', RESEED, 0);
DBCC CHECKIDENT ('Account.roles', RESEED, 0);
DBCC CHECKIDENT ('Account.user_address', RESEED, 0);

DBCC CHECKIDENT ('Payment.coupons', RESEED, 0);

DBCC CHECKIDENT ('Taxi.taxi_trips', RESEED, 0);
DBCC CHECKIDENT ('Taxi.vehicles', RESEED, 0);
DBCC CHECKIDENT ('Taxi.live_location_driver', RESEED, 0);
DBCC CHECKIDENT ('Taxi.trip_review', RESEED, 0);
DBCC CHECKIDENT ('Taxi.fare_rule', RESEED, 0);
DBCC CHECKIDENT ('Taxi.driver_doc', RESEED, 0);
DBCC CHECKIDENT ('Taxi.trip_message', RESEED, 0);
GO


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
VALUES(1,1), (2,2), (3,3), (3,4), (4,2), (5,2), (5,4);
GO
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
--CREATE TABLE Taxi.DriverImport
--(firstname NVARCHAR(50),
--lastname NVARCHAR(50),
--phone_num VARCHAR(11),
--email VARCHAR(100),
--pass_hash VARCHAR(255),
--license_num VARCHAR(10),
--national_code VARCHAR(10)
--);
--GO
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

-- احمد (راننده جدید) اولین سفر خود را از محمد قبول کرده و سفر را کامل می‌کند.
-- علی درخواست سفر ثبت می‌کند، راننده قبول می‌کند و سفر کامل می‌شود.
EXEC Taxi.SP_RequestTrip
'09111111111',
N'خیابان فردوسی',
N'پل فلزی',
32.650000,
51.665000,
32.640000,
51.670000,
45000,
NULL;

EXEC Taxi.SP_AcceptTrip
'09123416787',
'09111111111';

EXEC Taxi.SP_UpdateTripStatus
'09111111111',
'Arrived';

EXEC Taxi.SP_UpdateTripStatus
'09111111111',
'OnTrip';

EXEC Taxi.SP_UpdateTripStatus
'09111111111',
'Completed';
GO

-- علی سفر را انجام می‌دهد اما هیچ امتیازی ثبت نمی‌کند.
EXEC Taxi.SP_RequestTrip
'09111111111',
N'چهارباغ',
N'دروازه دولت',
32.6546,
51.6680,
32.6559,
51.6710,
28000.00,
NULL;

EXEC Taxi.SP_AcceptTrip
'09573456789',
'09111111111';

EXEC Taxi.SP_UpdateTripStatus
'09111111111',
'OnTrip';

EXEC Taxi.SP_UpdateTripStatus
'09111111111',
'Completed';
GO

-- حسین به محل رسیده و برای مسافر پیام ارسال می‌کند.
-- حسین به محل رسیده و برای مسافر پیام ارسال می‌کند.
EXEC Taxi.SP_RequestTrip
'09111111112',
N'خانه اصفهان',
N'خیابان فردوسی',
32.6400,
51.6600,
32.6490,
51.6750,
47000.00,
NULL;

EXEC Taxi.SP_AcceptTrip
'09123416787',
'09111111112';

EXEC Taxi.SP_UpdateTripStatus
'09111111112',
'Arrived';

EXEC Taxi.SP_AddReviewAndMessage
'09111111112',
0,
NULL,
N'من جلوی سوپرمارکت هستم.',
'09123416787';

EXEC Taxi.SP_UpdateTripStatus
'09111111112',
'OnTrip';

EXEC Taxi.SP_UpdateTripStatus
'09111111112',
'Completed';
GO
-- مریم هنگام سفر از راننده درخواست توقف کوتاه می‌کند.
EXEC Taxi.SP_RequestTrip
'09111111114',
N'میدان احمدآباد',
N'ترمینال صفه',
32.6355,
51.6650,
32.5980,
51.6550,
95000.00,
'GLOBAL5';

EXEC Taxi.SP_AcceptTrip
'09111111113',
'09111111114';

EXEC Taxi.SP_UpdateTripStatus
'09111111114',
'OnTrip';

EXEC Taxi.SP_AddReviewAndMessage
'09111111114',
0,
NULL,
N'لطفا کنار داروخانه یک دقیقه توقف کنید.',
'09111111114';

EXEC Taxi.SP_UpdateTripStatus
'09111111114',
'Completed';

EXEC Taxi.SP_AddReviewAndMessage
'09111111114',
4,
N'راننده همکاری خوبی داشت.',
NULL,
'09111111114';
GO

-- سارا یک مسیر کوتاه را طی می‌کند.
EXEC Taxi.SP_RequestTrip
'09111111112',
N'چهارباغ بالا',
N'سی و سه پل',
32.6510,
51.6670,
32.6450,
51.6675,
22000.00,
NULL;

EXEC Taxi.SP_AcceptTrip
'09111111115',
'09111111112';

EXEC Taxi.SP_UpdateTripStatus
'09111111112',
'OnTrip';

EXEC Taxi.SP_UpdateTripStatus
'09111111112',
'Completed';

EXEC Taxi.SP_AddReviewAndMessage
'09111111112',
5,
N'خیلی سریع رسیدم.',
NULL,
'09111111112';
GO

-- سارا یک مسیر کوتاه را طی می‌کند.
EXEC Taxi.SP_RequestTrip
'09111111112',
N'چهارباغ بالا',
N'سی و سه پل',
32.6510,
51.6670,
32.6450,
51.6675,
22000.00,
NULL;

EXEC Taxi.SP_AcceptTrip
'09111111115',
'09111111112';

EXEC Taxi.SP_UpdateTripStatus
'09111111112',
'OnTrip';

EXEC Taxi.SP_UpdateTripStatus
'09111111112',
'Completed';

EXEC Taxi.SP_AddReviewAndMessage
'09111111112',
5,
N'خیلی سریع رسیدم.',
NULL,
'09111111112';
GO

-- علی با کد تخفیف GLOBAL5 سفر خود را ثبت می‌کند.
-- علی با کد GLOBAL5 سفر ثبت می‌کند.
EXEC Taxi.SP_RequestTrip
'09111111111',
N'خیابان شیخ صدوق',
N'پل فلزی',
32.6460,
51.6610,
32.6390,
51.6680,
43000.00,
'GLOBAL5';

EXEC Taxi.SP_AcceptTrip
'09126456785',
'09111111111';

EXEC Taxi.SP_UpdateTripStatus
'09111111111',
'Arrived';

EXEC Taxi.SP_UpdateTripStatus
'09111111111',
'OnTrip';

EXEC Taxi.SP_UpdateTripStatus
'09111111111',
'Completed';

EXEC Taxi.SP_AddReviewAndMessage
'09111111111',
5,
N'سفر بسیار خوبی بود.',
NULL,
'09111111111';
GO
--SELECT TOP 5
--trip_id,
--driver_id,
--status
--FROM Taxi.taxi_trips
--ORDER BY trip_id DESC;
--EXEC sp_helpconstraint 'Taxi.taxi_trips';

-- تست لاگ 
EXEC Taxi.SP_RequestTrip
'09111111115',
N'سی و سه پل',
N'میدان انقلاب',
32.6445,
51.6671,
32.6320,
51.6535,
65000.00,
NULL;

EXEC Taxi.SP_AcceptTrip
'09123456789',
'09111111115';

EXEC Taxi.SP_UpdateTripStatus
'09111111115',
'Arrived';

EXEC Taxi.SP_UpdateTripStatus
'09111111115',
'OnTrip';

EXEC Taxi.SP_UpdateTripStatus
'09111111115',
'Completed';

EXEC Taxi.SP_AddReviewAndMessage
'09111111115',
5,
N'اولین سفر بسیار خوب بود.',
N'از سفرتان متشکرم.',
'09123456789';
GO

--  مشاهده وضعیت و آمار کلی سفرهای انجام شده بر اساس وضعیت
SELECT status, COUNT(*) AS TotalTrips
FROM Taxi.taxi_trips
GROUP BY status;

--  مشاهده لیست چت‌ها و پیام‌های درون سفر به همراه شماره سفر
SELECT t.trip_id, t.sender_id, t.message
FROM Taxi.trip_message t;

--   رتبه‌بندی و نظرات 
SELECT t.trip_id, t.rating, t.comment
FROM Taxi.trip_review t;

--  بررسی وضعیت تایید و آنلاین بودن رانندگان
SELECT driver_id, is_approved, is_online 
FROM Taxi.drivers;

USE dbproject;
GO

PRINT '==================================================';
PRINT '          (Account)      ';
PRINT '==================================================';

-- مشاهده نقش‌ها
SELECT role_id AS [کد نقش], role_name AS [نام نقش] 
FROM Account.roles;

-- مشاهده کاربران و نقش‌های آن‌ها
SELECT 
    u.user_id AS [شناسه کاربر],
    u.firstname AS [نام],
    u.lastname AS [نام خانوادگی],
    u.phone_num AS [شماره تلفن],
    u.email AS [ایمیل],
    STRING_AGG(r.role_name, '، ') AS [نقش‌ها در سیستم]
FROM Account.users u
LEFT JOIN Account.user_roles ur ON u.user_id = ur.user_id
LEFT JOIN Account.roles r ON ur.role_id = r.role_id
GROUP BY u.user_id, u.firstname, u.lastname, u.phone_num, u.email;

-- مشاهده آدرس‌های ثبت شده کاربران
SELECT 
    ua.address_id AS [شناسه آدرس],
    CONCAT(u.firstname, ' ', u.lastname) AS [نام کاربر],
    ua.title AS [عنوان محل],
    ua.address_text AS [آدرس متنی],
    ua.latitude AS [عرض جغرافیایی],
    ua.longitude AS [طول جغرافیایی]
FROM Account.user_address ua
JOIN Account.users u ON ua.user_id = u.user_id;


PRINT '==================================================';
PRINT '                 (Payment)                        ';
PRINT '==================================================';

SELECT 
    coupon_id AS [شناسه کوپن],
    code AS [کد تخفیف],
    service_type AS [نوع سرویس],
    discount_type AS [نوع تخفیف],
    discount_value AS [مقدار تخفیف],
    ISNULL(CAST(max_discount AS VARCHAR), 'بدون سقف') AS [سقف تخفیف],
    expiry_date AS [تاریخ انقضا]
FROM Payment.coupons;


PRINT N'==================================================';
PRINT '                     (Taxi)                        ';
PRINT '==================================================';

-- اطلاعات کلی راننده‌ها و خودروی آن‌ها
SELECT 
    d.driver_id AS [شناسه راننده],
    CONCAT(u.firstname, ' ', u.lastname) AS [نام راننده],
    u.phone_num AS [تلفن],
    d.license_num AS [شماره گواهینامه],
    d.national_code AS [کد ملی],
    v.model AS [مدل خودرو],
    v.color AS [رنگ],
    v.plak_num AS [پلاک خودرو],
    CASE WHEN d.is_approved = 1 THEN N'تایید شده' ELSE N'در انتظار تایید' END AS [وضعیت مدارک],
    CASE WHEN d.is_online = 1 THEN N'آنلاین' ELSE N'آفلاین' END AS [وضعیت حضور]
FROM Taxi.drivers d
JOIN Account.users u ON d.driver_id = u.user_id
LEFT JOIN Taxi.vehicles v ON d.driver_id = v.driver_id;

-- موقعیت زنده راننده‌های آنلاین
SELECT 
    ll.location_id AS [شناسه موقعیت],
    CONCAT(u.firstname, ' ', u.lastname) AS [راننده],
    ll.latitude AS [عرض جغرافیایی],
    ll.longitude AS [طول جغرافیایی]
FROM Taxi.live_location_driver ll
JOIN Account.users u ON ll.driver_id = u.user_id;

-- مدارک آپلود شده رانندگان
SELECT 
    dd.doc_id AS [شناسه مدرک],
    CONCAT(u.firstname, ' ', u.lastname) AS [راننده],
    dd.doc_type AS [نوع مدرک],
    dd.file_path AS [مسیر فایل مدرک]
FROM Taxi.driver_doc dd
JOIN Account.users u ON dd.driver_id = u.user_id;


PRINT '==================================================';
PRINT '                       (Trips)                    ';
PRINT '==================================================';

-- جدول اصلی سفرها همراه با نام مسافر، راننده و کد تخفیف اعمال شده
SELECT 
    t.trip_id AS [شماره سفر],
    CONCAT(u_pass.firstname, ' ', u_pass.lastname) AS [مسافر (درخواست کننده)],
    ISNULL(CONCAT(u_driv.firstname, ' ', u_driv.lastname), N'---') AS [راننده (پذیرنده)],
    t.pickup_address AS [مبداء],
    t.dropoff_address AS [مقصد],
    t.status AS [وضعیت نهایی سفر],
    FORMAT(t.price, 'N0') + ' ریال' AS [قیمت ثبت شده],
    ISNULL(c.code, N'بدون تخفیف') AS [کد تخفیف]
FROM Taxi.taxi_trips t
JOIN Account.users u_pass ON t.passenger_id = u_pass.user_id    
LEFT JOIN Account.users u_driv ON t.driver_id = u_driv.user_id
LEFT JOIN Payment.coupons c ON t.coupon_id = c.coupon_id;

-- چت‌ها و پیام‌های رد و بدل شده درون سفرها
SELECT 
    tm.m_id AS [شناسه پیام],
    tm.trip_id AS [شماره سفر],
    CONCAT(u.firstname, ' ', u.lastname) AS [فرستنده پیام],
    tm.message AS [متن پیام]
FROM Taxi.trip_message tm
JOIN Account.users u ON tm.sender_id = u.user_id;

-- نظرات، امتیازها و بازخوردهای ثبت شده مسافران
SELECT 
    tr.rew_id AS [شناسه نظر],
    tr.trip_id AS [شماره سفر],
    tr.rating AS [امتیاز (0 تا 5)],
    ISNULL(tr.comment, N'بدون متن بازخورد') AS [توضیحات مسافر]
FROM Taxi.trip_review tr;
-- چت‌ها و پیام‌های رد و بدل شده درون سفرها
SELECT 
    tm.m_id AS [شناسه پیام],
    tm.trip_id AS [شماره سفر],
    CONCAT(u.firstname, ' ', u.lastname) AS [فرستنده پیام],
    tm.message AS [متن پیام]
FROM Taxi.trip_message tm
JOIN Account.users u ON tm.sender_id = u.user_id;

-- نظرات، امتیازها و بازخوردهای ثبت شده مسافران
SELECT 
    tr.rew_id AS [شناسه نظر],
    tr.trip_id AS [شماره سفر],
    tr.rating AS [امتیاز (0 تا 5)],
    ISNULL(tr.comment, N'بدون متن بازخورد') AS [توضیحات مسافر]
FROM Taxi.trip_review tr;

-- جدول نرخ پایه سیستم
SELECT 
    f.r_id AS [شناسه نرخ],
    FORMAT(base_price, 'N0') AS [قیمت پایه],
    FORMAT(price_per_km, 'N0') AS [قیمت هر کیلومتر],
    FORMAT(price_per_min, 'N0') AS [قیمت هر دقیقه]
FROM Taxi.fare_rule f;

-- اطلاعات خام باقی‌مانده در جدول ایمپورت اکسل
IF OBJECT_ID('Taxi.DriverImport','U') IS NOT NULL
BEGIN
    SELECT * FROM Taxi.DriverImport;
END
GO