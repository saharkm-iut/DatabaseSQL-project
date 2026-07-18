USE DatabaseSQL_Project;
GO
CREATE SCHEMA Account;
GO
CREATE SCHEMA Taxi;
GO
CREATE SCHEMA Food;
GO
CREATE SCHEMA Payment;
GO
ALTER SCHEMA Account TRANSFER dbo.users;
ALTER SCHEMA Account TRANSFER dbo.roles;
ALTER SCHEMA Account TRANSFER dbo.user_roles;
ALTER SCHEMA Account TRANSFER dbo.user_address;
ALTER SCHEMA Account TRANSFER dbo.notif;
ALTER SCHEMA Account TRANSFER dbo.supp_ticket;

ALTER SCHEMA Taxi TRANSFER dbo.drivers;
ALTER SCHEMA Taxi TRANSFER dbo.vehicles;
ALTER SCHEMA Taxi TRANSFER dbo.taxi_trips;
ALTER SCHEMA Taxi TRANSFER dbo.trip_review;
ALTER SCHEMA Taxi TRANSFER dbo.fare_rule;
ALTER SCHEMA Taxi TRANSFER dbo.driver_doc;
ALTER SCHEMA Taxi TRANSFER dbo.trip_message;
ALTER SCHEMA Taxi TRANSFER dbo.live_location_driver;
ALTER SCHEMA Taxi TRANSFER dbo.food_deliveries;

ALTER SCHEMA Food TRANSFER dbo.restaurants;
ALTER SCHEMA Food TRANSFER dbo.food_categories;
ALTER SCHEMA Food TRANSFER dbo.foods;
ALTER SCHEMA Food TRANSFER dbo.food_options;
ALTER SCHEMA Food TRANSFER dbo.food_orders;
ALTER SCHEMA Food TRANSFER dbo.order_items;
ALTER SCHEMA Food TRANSFER dbo.order_item_options;
ALTER SCHEMA Food TRANSFER dbo.food_reviews;
ALTER SCHEMA Food TRANSFER dbo.restaurant_images;
ALTER SCHEMA Food TRANSFER dbo.restaurant_working_hours;

ALTER SCHEMA Payment TRANSFER dbo.wallets;
ALTER SCHEMA Payment TRANSFER dbo.wallet_transactions;
ALTER SCHEMA Payment TRANSFER dbo.payments;
ALTER SCHEMA Payment TRANSFER dbo.coupons;
--SELECT 
--    TABLE_SCHEMA,
--    TABLE_NAME
--FROM INFORMATION_SCHEMA.TABLES
--ORDER BY TABLE_SCHEMA;
create table Account.account_log_activity(
log_id int identity(1,1) primary key,
user_id int ,
action_type nvarchar(50) not null,
table_name nvarchar(50) not null, 
record_id int,
description nvarchar(500),
created_at DATETIME2 default SYSDATETIME()

);
CREATE table Taxi.taxi_log_activity(
log_id int identity(1,1) primary key,
trip_id int ,
diver_id int,
action_type nvarchar(50) not null,
table_name nvarchar(50) not null, 
record_id int,
description nvarchar(500),
created_at DATETIME2 default SYSDATETIME()

);
create table Payment.payment_log(
log_id int identity(1,1) primary key,
user_id int,
pay_id int ,
action_type nvarchar(50) not null,
table_name nvarchar(50) not null, 
record_id int,
description nvarchar(500),
created_at DATETIME2 default SYSDATETIME()

);
create table Food.food_log(
log_id int identity(1,1) primary key,
order_id  int ,
user_id int,
action_type nvarchar(50) not null,
table_name nvarchar(50) not null, 
record_id int,
description nvarchar(500),
created_at DATETIME2 default SYSDATETIME()

);