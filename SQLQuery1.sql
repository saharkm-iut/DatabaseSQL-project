-------------comman tables--------------
----------user with any role----------


create table users(
user_id int identity(1,1) primary key,
firstname NVARCHAR(50) NOT NULL,
lastname NVARCHAR(50) NOT NULL ,
phone_num VARCHAR(11) UNIQUE NOT NULL, CONSTRAINT CHK_users_phone CHECK (phone_num LIKE '09_________' AND phone_num NOT LIKE '%[^0-9]%'),
email varchar(100) unique null , CONSTRAINT CHK_users_gmail CHECK (email IS NULL OR email LIKE '%@gmail.com'),
pass_hash varchar(255) not null , 
created_at DATETIME2 DEFAULT SYSDATETIME()
);
CREATE TABLE roles (
    role_id INT IDENTITY(1,1) PRIMARY KEY,
    role_name VARCHAR(20) UNIQUE NOT NULL -- ('Customer', 'Driver', 'Vendor', 'Admin')
);
CREATE TABLE user_roles (
    user_id INT NOT NULL,
    role_id INT NOT NULL,
    PRIMARY KEY (user_id, role_id),
    CONSTRAINT FK_user_roles_users FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT FK_user_roles_roles FOREIGN KEY (role_id) REFERENCES roles(role_id) ON DELETE CASCADE
);


create table drivers(
driver_id int primary key , 
license_num varchar(10) unique not null CHECK(LEN(license_num) = 10), 
national_code varchar(10) unique not null CHECK(LEN(national_code)=10),
is_approved bit default 0,
is_online bit default 0 ,
created_at DATETIME2 DEFAULT SYSDATETIME(),
CONSTRAINT FK_drivers_users FOREIGN KEY (driver_id) REFERENCES users(user_id) ON DELETE CASCADE
);

create table wallets(
wallet_id int identity(1,1) primary key ,
user_id int unique not null, 
balance decimal(20, 2) default 0.00 CHECK(balance>=0),
updated_at DATETIME2 DEFAULT SYSDATETIME(),
CONSTRAINT FK_wallets_users FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

create table taxi_trips(
trip_id int identity(1,1) primary key,
passenger_id int not null, 
--driver_id int CHECK(driver_id IS NOT NULL OR status='Searching'),
pickup_address NVARCHAR(500) NOT NULL,
dropoff_address NVARCHAR(500) NOT NULL,
pickup_latitude DECIMAL(9,6) NOT NULL,
pickup_longitude DECIMAL(9,6) NOT NULL,
dropoff_latitude DECIMAL(9,6) NOT NULL,
dropoff_longitude DECIMAL(9,6) NOT NULL,
price DECIMAL(18,2) NOT NULL CHECK(price>=0),
status VARCHAR(20) CHECK (status IN ('Searching', 'Accepted', 'Arrived', 'OnTrip', 'Completed', 'Cancelled')) DEFAULT 'Searching',
created_at DATETIME2 DEFAULT SYSDATETIME(),
coupon_id INT NULL, 
CONSTRAINT FK_trip_coupon FOREIGN KEY(coupon_id) REFERENCES coupons(coupon_id),
CONSTRAINT FK_trips_passenger FOREIGN KEY (passenger_id) REFERENCES users(user_id),
CONSTRAINT FK_trips_driver FOREIGN KEY (driver_id) REFERENCES drivers(driver_id)
);

create table food_deliveries(
driver_id INT NOT NULL,
delivery_id int identity(1 , 1) primary key,
food_order_id int unique not null , 
taxi_trip_id int unique not null,
delivery_status varchar(20) check (delivery_status IN ('Assigned', 'PickedUp', 'Delivered')) DEFAULT 'Assigned',
assigned_at DATETIME2 DEFAULT SYSDATETIME(),
CONSTRAINT FK_deliveries_trip FOREIGN KEY (taxi_trip_id) REFERENCES taxi_trips(trip_id),
CONSTRAINT FK_delivery_driver FOREIGN KEY(driver_id) REFERENCES drivers(driver_id)

);







ALTER TABLE food_deliveries ADD CONSTRAINT FK_delivery_order FOREIGN KEY(food_order_id) REFERENCES food_orders(order_id);