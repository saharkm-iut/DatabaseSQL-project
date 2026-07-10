

use dbproject;
go

CREATE OR ALTER FUNCTION Taxi.FN_NearDrivers(@Latitude DECIMAL(9,6),@Longitude DECIMAL(9,6))
RETURNS TABLE
AS
RETURN
(SELECT d.driver_id,u.firstname,u.lastname,l.latitude,l.longitude,
--بعد از آن با استفاده از توابع اس کیو آر تی و پاور فاصله تقریبی هر راننده تا موقعیت وارد شده محاسبه میشه. این فاصله در ستونی با نام دیستنس نمایش داده میشه.
SQRT(POWER(l.latitude-@Latitude,2)+POWER(l.longitude-@Longitude,2)) AS Distance
FROM Taxi.live_location_driver l JOIN Taxi.drivers d ON l.driver_id=d.driver_id JOIN Account.users u ON u.user_id=d.driver_id
WHERE d.is_online=1 AND d.is_approved=1);
GO

CREATE OR ALTER FUNCTION Taxi.FN_DriverAverageRate (@DriverID INT)
RETURNS DECIMAL(4,2)
AS
BEGIN
DECLARE @Rate DECIMAL(4,2);
--میانگین امتیازهای ثبت‌شده محاسبه می‌شود
SELECT @Rate=AVG(CAST(r.rating AS DECIMAL(4,2)))
FROM Taxi.trip_review r JOIN Taxi.taxi_trips t ON r.trip_id=t.trip_id
WHERE t.driver_id=@DriverID;
--ممکنه راننده هنوز هیچ سفری انجام نداده باشد و امتیازی نداشته باشد
RETURN ISNULL(@Rate,0);

END;
GO

CREATE OR ALTER FUNCTION Taxi.FN_CanAcceptTrip(@DriverID INT)
RETURNS BIT
AS
BEGIN
DECLARE @Result BIT = 1;
IF NOT EXISTS
--راننده باید آنلاین و تایید شده باشد.
(SELECT 1
FROM Taxi.drivers
WHERE driver_id=@DriverID AND is_online=1 AND is_approved=1)
BEGIN
SET @Result=0;
END
--راننده باید خودروی ثبت‌شده داشته باشد.
IF NOT EXISTS
(SELECT 1
FROM Taxi.vehicles
WHERE driver_id=@DriverID)
 BEGIN
SET @Result=0;
 END
IF EXISTS
--راننده نباید در حال انجام یک سفر دیگر باشد.
(SELECT 1
FROM Taxi.taxi_trips
WHERE driver_id=@DriverID AND status IN ('Accepted','Arrived','OnTrip'))
BEGIN
SET @Result=0;
END
RETURN @Result;
END;
GO


SELECT * 
FROM Taxi.FN_NearDrivers(45.400000 , 50.100000);
SELECT Taxi.FN_CanAcceptTrip(2);

SELECT TOP(5) *
FROM Taxi.FN_NearDrivers(35.700000,51.400000)
ORDER BY Distance;
SELECT Taxi.FN_DriverAverageRate(2);
