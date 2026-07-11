
use  dbproject;
go
--  راننده برای دیدن اطلاعات مسافر فقط این ویو را صدا می‌زنه
CREATE OR ALTER VIEW Taxi.VW_DriverPassengerView
AS
SELECT t.trip_id,t.status AS TripStatus,u.firstname AS PassengerFirstName,u.lastname AS PassengerLastName,u.phone_num AS PassengerPhone, t.pickup_address,t.dropoff_address,t.price
FROM Taxi.taxi_trips t JOIN Account.users u ON t.passenger_id = u.user_id;
GO

SELECT *
FROM Taxi.VW_DriverPassengerView;
GO
--ویو به راننده یا مدیر سیستم کمک می‌کند تا فقط سفرهای در حال انجام را ببینند برا سلامت سفر
CREATE OR ALTER VIEW Taxi.VW_DriverCurrentTrip
AS
SELECT t.trip_id, d.driver_id, u.firstname+' '+u.lastname AS PassengerName,u.phone_num,t.pickup_address,t.dropoff_address,t.price,t.status,t.created_at
FROM Taxi.taxi_trips t JOIN Taxi.drivers d ON d.driver_id=t.driver_id JOIN Account.users u ON u.user_id=t.passenger_id
WHERE t.status IN ('Accepted','Arrived','OnTrip');
GO
--برا اینکه راننده ها رتیشون رو ببینن و  وضعیتشون رو 
-- تو تابع دراور اوریج استفاده شده 
CREATE OR ALTER VIEW Taxi.VW_DriverRating
AS
SELECT d.driver_id,u.firstname,u.lastname,Taxi.FN_DriverAverageRate(d.driver_id) AS AverageRate,COUNT(CASE WHEN t.status='Completed' THEN 1 END) AS CompletedTrips,d.is_online,d.is_approved
FROM Taxi.drivers d JOIN Account.users u ON d.driver_id=u.user_id LEFT JOIN Taxi.taxi_trips t ON d.driver_id=t.driver_id
GROUP BY d.driver_id, u.firstname,u.lastname,d.is_online,d.is_approved;
GO
-- تاریخچه سغر ها رو نمایش بده براهمین 
CREATE OR ALTER VIEW Taxi.VW_TripHistory
AS
SELECT t.trip_id,Passenger.firstname+' '+Passenger.lastname AS Passenger,Driver.firstname+' '+Driver.lastname AS Driver, t.pickup_address, t.dropoff_address,t.price,t.status,t.created_at
FROM Taxi.taxi_trips t JOIN Account.users Passenger ON Passenger.user_id=t.passenger_id LEFT JOIN Taxi.drivers d ON d.driver_id=t.driver_id LEFT JOIN Account.users Driver ON Driver.user_id=d.driver_id;
GO

-- برا اینکه اننده هایی که انلاین یا می تونن سرویس بدن رو نشون بده 
CREATE OR ALTER VIEW Taxi.VW_OnlineDrivers
AS
SELECT d.driver_id,u.firstname,u.lastname,u.phone_num,v.model,v.color,v.plak_num,l.latitude,l.longitude
FROM Taxi.drivers d JOIN Account.users u ON d.driver_id=u.user_id LEFT JOIN Taxi.vehicles v ON d.driver_id=v.driver_id LEFT JOIN Taxi.live_location_driver l ON d.driver_id=l.driver_id
WHERE d.is_online=1 AND d.is_approved=1;
GO