USE master;
GO

CREATE LOGIN AdminUser
WITH PASSWORD='Admin@12345';

CREATE LOGIN DriverUser
WITH PASSWORD='Driver@12345';

CREATE LOGIN PassengerUser
WITH PASSWORD='Passenger@12345';

CREATE LOGIN SupportUser
WITH PASSWORD='Support@12345';
GO



/*=========================
  ایجاد Role ها
=========================*/
USE dbproject;
GO

CREATE USER AdminUser FOR LOGIN AdminUser;
CREATE USER DriverUser FOR LOGIN DriverUser;
CREATE USER PassengerUser FOR LOGIN PassengerUser;
CREATE USER SupportUser FOR LOGIN SupportUser;
GO
/*=================================================
  Admin
  فقط ثبت اطلاعات (Insert)
==================================================*/

GRANT INSERT ON SCHEMA::Account TO AdminRole;
GRANT INSERT ON SCHEMA::Taxi TO AdminRole;
GRANT INSERT ON SCHEMA::Food TO AdminRole;
GRANT INSERT ON SCHEMA::Payment TO AdminRole;

-- اجرای تمام Stored Procedure ها
GRANT EXECUTE ON SCHEMA::Taxi TO AdminRole;

-- مشاهده View ها
GRANT SELECT ON OBJECT::Taxi.VW_DriverPassengerView TO AdminRole;
GRANT SELECT ON OBJECT::Taxi.VW_DriverCurrentTrip TO AdminRole;
GRANT SELECT ON OBJECT::Taxi.VW_DriverRating TO AdminRole;
GRANT SELECT ON OBJECT::Taxi.VW_TripHistory TO AdminRole;
GRANT SELECT ON OBJECT::Taxi.VW_OnlineDrivers TO AdminRole;

GO
ALTER ROLE AdminRole ADD MEMBER AdminUser;
ALTER ROLE DriverRole ADD MEMBER DriverUser;
ALTER ROLE PassengerRole ADD MEMBER PassengerUser;
ALTER ROLE SupportRole ADD MEMBER SupportUser;
/*=================================================
  Driver
==================================================*/

GRANT EXECUTE ON OBJECT::Taxi.CreateDriver TO DriverRole;
GRANT EXECUTE ON OBJECT::Taxi.SP_RegisterVehicle TO DriverRole;
GRANT EXECUTE ON OBJECT::Taxi.SP_AcceptTrip TO DriverRole;
GRANT EXECUTE ON OBJECT::Taxi.SP_UpdateTripStatus TO DriverRole;
GRANT EXECUTE ON OBJECT::Taxi.SP_AddReviewAndMessage TO DriverRole;

GRANT SELECT ON OBJECT::Taxi.VW_DriverPassengerView TO DriverRole;
GRANT SELECT ON OBJECT::Taxi.VW_DriverCurrentTrip TO DriverRole;
GRANT SELECT ON OBJECT::Taxi.VW_DriverRating TO DriverRole;
GRANT SELECT ON OBJECT::Taxi.VW_OnlineDrivers TO DriverRole;

GO

/*=================================================
  Passenger
==================================================*/

GRANT EXECUTE ON OBJECT::Taxi.SP_RequestTrip TO PassengerRole;
GRANT EXECUTE ON OBJECT::Taxi.SP_UpdateTripStatus TO PassengerRole;
GRANT EXECUTE ON OBJECT::Taxi.SP_AddReviewAndMessage TO PassengerRole;

GRANT SELECT ON OBJECT::Taxi.VW_TripHistory TO PassengerRole;

GO

/*=================================================
  Support
==================================================*/

GRANT SELECT ON OBJECT::Taxi.VW_TripHistory TO SupportRole;
GRANT SELECT ON OBJECT::Taxi.VW_DriverPassengerView TO SupportRole;
GRANT SELECT ON OBJECT::Taxi.VW_DriverCurrentTrip TO SupportRole;

GO

ALTER ROLE AdminRole
ADD MEMBER AdminUser;

ALTER ROLE DriverRole
ADD MEMBER DriverUser;

ALTER ROLE PassengerRole
ADD MEMBER PassengerUser;

ALTER ROLE SupportRole
ADD MEMBER SupportUser;