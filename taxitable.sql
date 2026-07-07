-- a user with driver role
create table drivers(
driver_id int primary key , 
license_num varchar(10) unique not null CHECK(LEN(license_num) = 10), 
national_code varchar(10) unique not null CHECK(LEN(national_code)=10),
is_approved bit default 0,
is_online bit default 0 ,
created_at DATETIME2 DEFAULT SYSDATETIME(),
CONSTRAINT FK_drivers_users FOREIGN KEY (driver_id) REFERENCES users(user_id) ON DELETE CASCADE
);
-- coupons it also is used for food too
CREATE TABLE coupons (
coupon_id INT IDENTITY(1,1) PRIMARY KEY,
code VARCHAR(50) UNIQUE not null,
service_type VARCHAR(20) CHECK (service_type IN ('Food', 'Taxi', 'Global')) not null,
discount_type VARCHAR(20) CHECK (discount_type IN ('Percentage', 'Fixed_Amount')) not null,
discount_value DECIMAL(18,2) not null CHECK(discount_value>0),
max_discount DECIMAL(18,2) NULL, 
expiry_date DATETIME2 not null
);

-- taxi
create table taxi_trips(
trip_id int identity(1,1) primary key,
passenger_id int not null, 
driver_id int ,
pickup_address NVARCHAR(500) not null,
dropoff_address NVARCHAR(500) not null,
pickup_latitude DECIMAL(9,6) not null,
pickup_longitude DECIMAL(9,6) not null,
dropoff_latitude DECIMAL(9,6) not null,
dropoff_longitude DECIMAL(9,6) not null,
price DECIMAL(18,2) not null CHECK(price>=0),
status VARCHAR(20) CHECK (status IN ('Searching', 'Accepted', 'Arrived', 'OnTrip', 'Completed', 'Cancelled')) DEFAULT 'Searching',
created_at DATETIME2 DEFAULT SYSDATETIME(),
coupon_id INT NULL, 
CONSTRAINT FK_trip_coupon FOREIGN KEY(coupon_id) REFERENCES coupons(coupon_id),
CONSTRAINT FK_trips_passenger FOREIGN KEY (passenger_id) REFERENCES users(user_id),
CONSTRAINT FK_trips_driver FOREIGN KEY (driver_id) REFERENCES drivers(driver_id),
CHECK(driver_id IS not null OR status='Searching')
);
--car info may be a motor
create table vehicles(
v_id int identity(1 , 1) primary key,
driver_id int not null ,
model nvarchar(50)not null,
color nvarchar(50) not null , 
plak_num nvarchar(15) unique not null ,-- ==الف=== ایران ==
CONSTRAINT FK_vehicles_drivers FOREIGN KEY (driver_id) REFERENCES drivers(driver_id) ON DELETE CASCADE

);
-- where is diver in what time
create table live_location_driver(
location_id INT IDENTITY(1,1) PRIMARY KEY,
driver_id INT UNIQUE not null,
latitude DECIMAL(9,6) not null,
longitude DECIMAL(9,6) not null,
updated_at DATETIME2 DEFAULT SYSDATETIME(),
CONSTRAINT FK_locations_drivers FOREIGN KEY (driver_id) REFERENCES drivers(driver_id) ON DELETE CASCADE
);


create table trip_review(
rew_id int identity(1,1) primary key,
trip_id int not null,
rating int check(rating between 1 and 5) not null,
comment nvarchar(1000) ,
CONSTRAINT FK_trip_reviews_trips FOREIGN KEY (trip_id) REFERENCES taxi_trips(trip_id) ON DELETE CASCADE

);
create table fare_rule(
r_id int identity(1,1) primary key,
base_price decimal(18,2) not null check(base_price>=0),
price_per_km decimal(18,2) not null check( price_per_km >=0 ),
price_per_min decimal(18,2) not null check( price_per_min >=0 )

);

create table diver_doc(
doc_id int identity(1,1) primary key,
driver_id int not null , 
doc_type nvarchar(100) not null,
file_path nvarchar(500) not null,
CONSTRAINT FK_documents_drivers FOREIGN KEY (driver_id) REFERENCES drivers(driver_id) ON DELETE CASCADE


);
create table trip_message(
m_id int identity(1,1) primary key ,
trip_id int not null,
sender_id int not null,
message nvarchar(500) ,
created_at DATETIME2 DEFAULT SYSDATETIME(),
CONSTRAINT FK_messages_trips FOREIGN KEY (trip_id) REFERENCES taxi_trips(trip_id) ON DELETE CASCADE,
CONSTRAINT FK_messages_sender FOREIGN KEY (sender_id) REFERENCES users(user_id)

);