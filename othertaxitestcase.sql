-- رضا بعد از قبول سفر، اطلاعات مسافر را مشاهده می‌کند.
SELECT *
FROM Taxi.VW_DriverPassengerView
WHERE PassengerPhone='09111111114';
GO

-- مدیر فقط سفرهای فعال را مشاهده می‌کند.
SELECT *
FROM Taxi.VW_DriverCurrentTrip;
GO

-- رضا وضعیت فعالیت و میانگین امتیاز خود را مشاهده می‌کند.
SELECT *
FROM Taxi.VW_DriverRating
WHERE driver_id=3;
GO


-- مدیر تاریخچه کامل سفرهای ثبت شده را مشاهده می‌کند.
SELECT *
FROM Taxi.VW_TripHistory
ORDER BY created_at DESC;
GO

-- مسافر قبل از ثبت درخواست رانندگان آنلاین را مشاهده می‌کند.
SELECT *
FROM Taxi.VW_OnlineDrivers;
GO

-- علی درخواست سفر جدید ثبت می‌کند.
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

-- راننده سفر را شروع می‌کند و تغییر وضعیت ثبت می‌شود.
EXEC Taxi.SP_UpdateTripStatus
'09111111111',
'OnTrip';

SELECT TOP(5) *
FROM Taxi.taxi_log_activity
ORDER BY log_id DESC;
GO

-- راننده جدید خودروی خود را ثبت می‌کند.
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

-- مسافر بعد از پایان سفر نظر ثبت می‌کند.
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



-- راننده برای مسافر پیام ارسال می‌کند.
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

-- سفر پایان یافته و راننده دوباره آنلاین می‌شود.
EXEC Taxi.SP_UpdateTripStatus
'09111111111',
'Completed';

SELECT
driver_id,
is_online
FROM Taxi.drivers
WHERE driver_id=9;
GO

-- راننده‌ای که شرایط سرویس ندارد به سفر اختصاص داده می‌شود.
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

-- مسافر در محدوده چهارباغ نزدیک‌ترین رانندگان را جستجو می‌کند.
SELECT TOP(5) *
FROM Taxi.FN_NearDrivers
(
32.654600,
51.668000
)
ORDER BY Distance;
GO

-- نزدیک‌ترین رانندگان حوالی میدان آزادی.
SELECT *
FROM Taxi.FN_NearDrivers
(
32.640000,
51.650000
)
ORDER BY Distance;
GO

-- مدیر میانگین امتیاز رضا را بررسی می‌کند.
SELECT Taxi.FN_DriverAverageRate(3) AS AverageRate;
GO

-- احمد هنوز سفری انجام نداده است.
SELECT Taxi.FN_DriverAverageRate(8) AS AverageRate;
GO

-- بررسی شرایط راننده برای قبول سفر.
SELECT Taxi.FN_CanAcceptTrip(3) AS CanAcceptTrip;
GO

-- وضعیت راننده‌ای که در حال سفر است بررسی می‌شود.
SELECT Taxi.FN_CanAcceptTrip(9) AS CanAcceptTrip;
GO

-- راننده موقتا آفلاین می‌شود.
UPDATE Taxi.drivers
SET is_online=0
WHERE driver_id=3;

SELECT Taxi.FN_CanAcceptTrip(3) AS CanAcceptTrip;

UPDATE Taxi.drivers
SET is_online=1
WHERE driver_id=3;
GO

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
