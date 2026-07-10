------------taxiprocedures

-- این پرسیجر میاد تفاوت قایل میشه بین یوزر و راننده و داده هر کدوم را تو جدول خودش دخیره می کنه
create procedure Taxi.CreateDriver(@firstname NVARCHAR(50),@lastname NVARCHAR(50),@phone_num VARCHAR(11),@email VARCHAR(100),@pass_hash VARCHAR(255),@license_num VARCHAR(10),@national_code VARCHAR(10))
as begin
begin transaction;
begin try
declare @user_id INT;
declare @driver_role INT;
INSERT INTO Account.users(firstname,lastname,phone_num, email,pass_hash)-- اطلاعات یوزر
VALUES(@firstname,@lastname, @phone_num, @email, @pass_hash );
SET @user_id = SCOPE_IDENTITY();
select @driver_role = role_id
from Account.roles
where role_name='Driver';-- این برا اونایی که راننده باشن نه چیز دیگه
INSERT INTO Account.user_roles(user_id,role_id)
VALUES(@user_id,@driver_role);
INSERT INTO Taxi.drivers(driver_id,license_num,national_code,is_approved,is_online)-- اطلاعات راننده
VALUES(@user_id,@license_num,@national_code,1,0);
COMMIT;
select 'Driver Created' AS Message, @user_id AS UserID;
END TRY
BEGIN CATCH
ROLLBACK;-- اطلاعات غلط را هم جلوشو میگره که وارد نشه 
THROW;
END CATCH
END;


use  dbproject;
--DELETE from Taxi.trip_message;
--DELETE from Taxi.trip_review;
--DELETE from Taxi.taxi_trips;
--DELETE from Taxi.live_location_driver;
--DELETE from Taxi.driver_doc;
--DELETE from Taxi.vehicles;


--DBCC CHECKIDENT ('Taxi.trip_message', RESEED, 0);
--DBCC CHECKIDENT ('Taxi.trip_review', RESEED, 0);
--DBCC CHECKIDENT ('Taxi.taxi_trips', RESEED, 0);
--DBCC CHECKIDENT ('Taxi.live_location_driver', RESEED, 0);
--DBCC CHECKIDENT ('Taxi.driver_doc', RESEED, 0);
--DBCC CHECKIDENT ('Taxi.vehicles', RESEED, 0);
--GO



-- دیگه ایدی طرف درگیرش نمیشیم پروسیجر ثبت خودرو با شماره تلفن راننده
CREATE OR ALTER PROCEDURE Taxi.SP_RegisterVehicle @PhoneNum VARCHAR(11),@Model NVARCHAR(50),@Color NVARCHAR(50),@PlakNum NVARCHAR(15)
as begin
SET NOCOUNT ON;
declare @DriverID INT = (select u.user_id from Account.users u JOIN Taxi.drivers d ON u.user_id = d.driver_id where u.phone_num = @PhoneNum);
IF @DriverID IS NULL
BEGIN RAISERROR(N'خطا: راننده‌ای با این شماره تلفن یافت نشد.', 16, 1); RETURN; END
INSERT INTO Taxi.vehicles (driver_id, model, color, plak_num)
VALUES (@DriverID, @Model, @Color, @PlakNum);
END;
GO

-- در خواست سفر 
CREATE OR ALTER PROCEDURE Taxi.SP_RequestTrip @PassengerPhone VARCHAR(11),@PickupText NVARCHAR(500), @DropoffText NVARCHAR(500),@Lat1 DECIMAL(9,6), @Lng1 DECIMAL(9,6),@Lat2 DECIMAL(9,6), @Lng2 DECIMAL(9,6),@Price DECIMAL(18,2),@CouponCode VARCHAR(50) = NULL
as begin
SET NOCOUNT ON;
declare @PassengerID INT = (select user_id from Account.users where phone_num = @PassengerPhone);
declare @CouponID INT = (select coupon_id from Payment.coupons where code = @CouponCode);
IF @PassengerID IS NULL
BEGIN RAISERROR(N'خطا: مسافری با این شماره تلفن یافت نشد.', 16, 1); RETURN; END
INSERT INTO Taxi.taxi_trips (passenger_id, pickup_address, dropoff_address, pickup_latitude, pickup_longitude, dropoff_latitude, dropoff_longitude, price, status, coupon_id)
VALUES (@PassengerID, @PickupText, @DropoffText, @Lat1, @Lng1, @Lat2, @Lng2, @Price, 'Searching', @CouponID);
END;
GO


CREATE OR ALTER PROCEDURE Taxi.SP_AcceptTrip @DriverPhone VARCHAR(11),@PassengerPhone VARCHAR(11)
as begin
SET NOCOUNT ON; 
--  پیدا کردن آی‌دی راننده
DECLARE @DriverID INT = (SELECT user_id FROM Account.users WHERE phone_num = @DriverPhone);
--  پیدا کردن آخرین سفر در وضعیت جستجو برای این مسافر
DECLARE @TripID INT = (SELECT TOP 1 t.trip_id 
FROM Taxi.taxi_trips t JOIN Account.users u ON t.passenger_id = u.user_id 
WHERE u.phone_num = @PassengerPhone AND t.status = 'Searching' ORDER BY t.created_at DESC);
 --  چک کردن وجود راننده و سفر فعال
IF @DriverID IS NULL OR @TripID IS NULL
BEGIN 
RAISERROR(N'خطا: راننده یا درخواست سفر فعالی برای این مسافر یافت نشد.', 16, 1); 
RETURN; 
END
--  بررسی اینکه آیا راننده خودرو ثبت شده دارد یا خیر
IF NOT EXISTS (SELECT 1 FROM Taxi.vehicles WHERE driver_id = @DriverID)
BEGIN
RAISERROR(N'خطا: این راننده مجاز به قبول سفر نیست زیرا هیچ خودرویی برای او ثبت نشده است.', 16, 1);
RETURN;
END

    --  اگر همه شرایط اوکی بود سفر تایید می‌شود
UPDATE Taxi.taxi_trips 
SET driver_id = @DriverID, status = 'Accepted' 
WHERE trip_id = @TripID;
END;
GO


--پروسیجر تغییر وضعیت سفر  رسیدن به مبدا شروع سفر اتمام یا لغو سفر
CREATE OR ALTER PROCEDURE Taxi.SP_UpdateTripStatus @PassengerPhone VARCHAR(11),@NewStatus VARCHAR(20)
as begin
SET NOCOUNT ON;
declare @TripID INT = (select TOP 1 t.trip_id from Taxi.taxi_trips t JOIN Account.users u ON t.passenger_id = u.user_id where u.phone_num = @PassengerPhone AND t.status NOT IN ('Completed', 'Cancelled') ORDER BY t.created_at DESC);
IF @TripID IS NULL
BEGIN RAISERROR(N'خطا: سفر فعالی برای این مسافر پیدا نشد.', 16, 1); RETURN; END
UPDATE Taxi.taxi_trips SET status = @NewStatus where trip_id = @TripID;
END;
GO

--  پروسیجر ثبت نظر و چت برای آخرین سفر تکمیل‌شده مسافر
CREATE OR ALTER PROCEDURE Taxi.SP_AddReviewAndMessage @PassengerPhone VARCHAR(11), @Rating INT, @Comment NVARCHAR(1000),@MessageText NVARCHAR(500),@SenderPhone VARCHAR(11)
as begin
SET NOCOUNT ON;
declare @TripID INT = (select TOP 1 t.trip_id from Taxi.taxi_trips t JOIN Account.users u ON t.passenger_id = u.user_id where u.phone_num = @PassengerPhone ORDER BY t.created_at DESC);
declare @SenderID INT = (select user_id from Account.users where phone_num = @SenderPhone);
IF @TripID IS NULL OR @SenderID IS NULL RETURN;
-- اً ثبت نشده باشد ثبت کن
IF NOT EXISTS (select 1 from Taxi.trip_review where trip_id = @TripID) AND @Rating BETWEEN 1 AND 5
INSERT INTO Taxi.trip_review (trip_id, rating, comment) VALUES (@TripID, @Rating, @Comment);
-- ثبت پیام چت
IF @MessageText IS NOT NULL
INSERT INTO Taxi.trip_message (trip_id, sender_id, message) VALUES (@TripID, @SenderID, @MessageText);
END;
GO





select trip_id, passenger_id, driver_id, price, status from Taxi.taxi_trips;
select * from Taxi.trip_review;
select * from Taxi.trip_message;


select* from Taxi.vehicles;