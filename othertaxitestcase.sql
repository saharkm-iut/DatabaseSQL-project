USE dbproject;
GO
--     تریگر ثبت خودرو و تابع بررسی وضعیت راننده
-- 
---   تابع بررسی مرحله به مرحل همه شرط ها را تست می کنیمCanAcceptTrip

PRINT N'---  ثبت خودروی جدید و بررسی وضعیت مجاز بودن راننده ---';

DELETE FROM Taxi.vehicles WHERE driver_id IN (SELECT user_id FROM Account.users WHERE phone_num = '09139998877');
DELETE FROM Taxi.drivers WHERE driver_id IN (SELECT user_id FROM Account.users WHERE phone_num = '09139998877');
DELETE FROM Account.user_roles WHERE user_id IN (SELECT user_id FROM Account.users WHERE phone_num = '09139998877');
DELETE FROM Account.users WHERE phone_num = '09139998877';

-- راننده جدید اضافه کردن با پرسیجر 
EXEC Taxi.CreateDriver 
 N'امیر', N'علیزاده', '09139998877', 'amir@gmail.com', 'hash123', '9988776655', '1270001122';

DECLARE @NewDriverID INT;
SELECT @NewDriverID = user_id FROM Account.users WHERE phone_num = '09139998877';

-- بررسی تابع قبل از ثبت خودرو 
PRINT  CAST(ISNULL(Taxi.FN_CanAcceptTrip(@NewDriverID), 0) AS VARCHAR);

-- آنلاین کردن راننده 
UPDATE Taxi.drivers SET is_online = 1 WHERE driver_id = @NewDriverID;

-- ثبت ماشین با رکور ایدی نال و گرفتن خطا
BEGIN TRY
EXEC Taxi.SP_RegisterVehicle '09139998877', N'تندر 90', N'سفید', N'99ب999-ایران99';
END TRY
BEGIN CATCH
PRINT N'خطای اضافه کردن  ';
END CATCH;

-- فراخوانی تابع و  صلاحیت داره یا نه 
PRINT N'وضعیت راننده بعد از ثبت خودرو: ' + CAST(ISNULL(Taxi.FN_CanAcceptTrip(@NewDriverID), 0) AS VARCHAR);
GO



--- توابع تستNearDrivers
-- ببینیم کدوم به این لوکیشن نزدیک تره
SELECT * 
FROM Taxi.FN_NearDrivers(32.654600, 51.668000)
ORDER BY Distance;
GO
BEGIN TRY
EXEC Taxi.SP_RequestTrip '09111111112', N'میدان آزادی', N'خیابان بزرگمهر', 32.6500, 51.6600, 32.6600, 51.6800, 50000.00, NULL;
PRINT N'درخواست سفر با موفقیت ثبت شد.';
END TRY
BEGIN CATCH
PRINT N'خطا در ثبت سفر: ' + ERROR_MESSAGE();
END CATCH;
GO

--- تست  Taxi.FN_DriverAverageRate
DECLARE @TargetDriverID INT;
SELECT @TargetDriverID = user_id FROM Account.users WHERE phone_num = '09111111113';
IF @TargetDriverID IS NOT NULL
BEGIN
SELECT  @TargetDriverID AS [شناسه راننده], N'رضا مرادی' AS [نام راننده],Taxi.FN_DriverAverageRate(@TargetDriverID) AS [میانگین امتیاز محاسبه شده];
END
ELSE
BEGIN
PRINT N'راننده‌ای با این شماره یافت نشد.';
END;
GO
DECLARE @DriverID5 INT;
SELECT @DriverID5 = user_id FROM Account.users WHERE phone_num = '09111111115';

IF @DriverID5 IS NOT NULL
BEGIN -- تست افلاین کردن
UPDATE Taxi.drivers SET is_online = 0 WHERE driver_id = @DriverID5;
PRINT N' راننده آفلاین است.';
 -- بررسی  مجاز بودن با تابع
 --چون تابع اس تو سلکت استفاده می شه 
SELECT driver_id, is_online, Taxi.FN_CanAcceptTrip(driver_id) AS [امکان قبول سفر]
FROM Taxi.drivers 
WHERE driver_id = @DriverID5;
-- تست انلاین کردن
UPDATE Taxi.drivers SET is_online = 1 WHERE driver_id = @DriverID5;
END
ELSE
BEGIN
PRINT N'راننده نات فوند';
END;
GO

-- رضا بعد از قبول سفر، اطلاعات مسافر را مشاهده میکنه
SELECT *
FROM Taxi.VW_DriverPassengerView
WHERE PassengerPhone='09111111114';
GO

-- مدیر فقط سفرهای فعال را مشاهده میکنه.
SELECT *
FROM Taxi.VW_DriverCurrentTrip;
GO

-- رضا وضعیت فعالیت و میانگین امتیاز خود را مشاهده میکنه
SELECT *
FROM Taxi.VW_DriverRating
WHERE driver_id=3;
GO


-- مدیر تاریخچه کامل سفرهای ثبت شده را مشاهده میکنه
SELECT *
FROM Taxi.VW_TripHistory
ORDER BY created_at DESC;
GO

-- مسافر قبل از ثبت درخواست رانندگان آنلاین را مشاهده میکنه
SELECT *
FROM Taxi.VW_OnlineDrivers;
GO

-- علی درخواست سفر جدید ثبت میکنه
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


SELECT TOP(1) *
FROM Taxi.taxi_log_activity
ORDER BY log_id DESC;
GO

-- راننده سفر را شروع میکنه و تغییر وضعیت ثبت میشه
EXEC Taxi.SP_UpdateTripStatus
'09111111111',
'OnTrip';

SELECT TOP(5) *
FROM Taxi.taxi_log_activity
ORDER BY log_id DESC;
GO

-- راننده جدید خودروی خود را ثبت میکنه
EXEC Taxi.SP_RegisterVehicle
'09128888888',
N'تیبا',
N'سفید',
N'44الف111-ایران88';

SELECT TOP(1) *
FROM Taxi.taxi_log_activity
WHERE table_name='vehicles'
ORDER BY log_id DESC;
GO

-- مسافر بعد از پایان سفر نظر ثبت میکنه
EXEC Taxi.SP_AddReviewAndMessage
'09111111111',
5,
N'راننده بسیار خوش برخورد بود.',
NULL,
'09111111111';

SELECT TOP(1) *
FROM Taxi.taxi_log_activity
WHERE table_name='trip_review'
ORDER BY log_id DESC;
GO



-- راننده برای مسافر پیام ارسال میکنه
EXEC Taxi.SP_AddReviewAndMessage
'09111111111',
0,
NULL,
N'من روبروی بانک هستم.',
'09123416787';

SELECT TOP(1) *
FROM Taxi.taxi_log_activity
WHERE table_name='trip_message'
ORDER BY log_id DESC;
GO

-- سفر پایان یافته و راننده دوباره آنلاین میشه
EXEC Taxi.SP_UpdateTripStatus
'09111111111',
'Completed';

SELECT
driver_id,
is_online
FROM Taxi.drivers
WHERE driver_id=9;
GO

-- راننده‌ای که شرایط سرویس ندارد به سفر اختصاص داده میشه
UPDATE Taxi.drivers
SET is_online=0
WHERE driver_id=5;

UPDATE Taxi.taxi_trips
SET driver_id=5
WHERE trip_id=
(
SELECT MAX(trip_id)
FROM Taxi.taxi_trips
);

SELECT TOP(1) *
FROM Taxi.taxi_log_activity
WHERE action_type='WARNING'
ORDER BY log_id DESC;
GO

-- مسافر در محدوده چهارباغ نزدیک‌ترین رانندگان را سرچ میکنه
SELECT TOP(5) *
FROM Taxi.FN_NearDrivers
(
32.654600,
51.668000
)
ORDER BY Distance;
GO

-- نزدیک‌ترین رانندگان حوالی میدان آزادی
SELECT *
FROM Taxi.FN_NearDrivers
(
32.640000,
51.650000
)
ORDER BY Distance;
GO

-- مدیر میانگین امتیاز رضا را بررسی میکنه
SELECT Taxi.FN_DriverAverageRate(3) AS AverageRate;
GO

-- احمد هنوز سفری انجام نداده است
SELECT Taxi.FN_DriverAverageRate(8) AS AverageRate;
GO

-- بررسی شرایط راننده برای قبول سفر
SELECT Taxi.FN_CanAcceptTrip(3) AS CanAcceptTrip;
GO

-- وضعیت راننده‌ای که در حال سفر است بررسی میشه
SELECT Taxi.FN_CanAcceptTrip(9) AS CanAcceptTrip;
GO

-- راننده  آفلاین میشه
UPDATE Taxi.drivers
SET is_online=0
WHERE driver_id=3;

SELECT Taxi.FN_CanAcceptTrip(3) AS CanAcceptTrip;

UPDATE Taxi.drivers
SET is_online=1
WHERE driver_id=3;


EXEC Taxi.SP_RequestTrip
'09120000000',
N'A',
N'B',
35.7,
51.4,
35.8,
51.5,
50000,
NULL;
--   تریگرها درست کار می کنه و لاگ ثبت شده است یا نه
SELECT TOP 10 
    log_id, 
    table_name, 
    action_type, 
    created_at 
FROM Taxi.taxi_log_activity 
ORDER BY log_id DESC;

--   راننده‌ها بعد از پایان سفر وضعیت‌شان به آنلاین (1) برگشته یا نه
SELECT driver_id, is_online 
FROM Taxi.drivers 
WHERE is_online = 1;