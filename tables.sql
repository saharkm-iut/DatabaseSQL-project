-------------comman tables--------------
----------user with any role----------
USE DatabaseSQL_Project;
GO

create table users(
user_id int identity(1,1) primary key,
firstname NVARCHAR(50) not null,
lastname NVARCHAR(50) not null ,
phone_num VARCHAR(11) UNIQUE not null, CONSTRAINT CHK_users_phone CHECK ( (LEN(phone_num)=11) and phone_num LIKE '09_________' AND phone_num NOT LIKE '%[^0-9]%'),
email varchar(100) unique null , CONSTRAINT CHK_users_gmail CHECK (email IS NULL OR email LIKE '%@gmail.com'),
pass_hash varchar(255) not null , 
created_at DATETIME2 DEFAULT SYSDATETIME()
);
create table roles (
    role_id int identity(1,1) primary key,
    role_name VARCHAR(20) UNIQUE not null -- ('Customer', 'Driver', 'Vendor', 'Admin')
);
create table user_roles (
    user_id int not null,
    role_id int not null,
    primary key (user_id, role_id),
    CONSTRAINT FK_user_roles_users FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT FK_user_roles_roles FOREIGN KEY (role_id) REFERENCES roles(role_id) ON DELETE CASCADE
);
create table user_address(
address_id int identity(1,1) primary key,
    user_id int not null,
    title NVARCHAR(50) not null, 
    address_text NVARCHAR(500) not null,
    latitude DECIMAL(9,6) not null,
    longitude DECIMAL(9,6) not null,
    CONSTRAINT FK_addresses_users FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE

);
--------------------taxi part-------------
-- a user with driver role
create table drivers(
driver_id int primary key , 
license_num varchar(10) unique not null CHECK((LEN(license_num) = 10) AND license_num NOT LIKE '%[^0-9]%') , 
national_code varchar(10) unique not null CHECK((LEN(national_code)=10) AND national_code NOT LIKE '%[^0-9]%'),
is_approved bit default 0,
is_online bit default 0 ,
created_at DATETIME2 DEFAULT SYSDATETIME(),
CONSTRAINT FK_drivers_users FOREIGN KEY (driver_id) REFERENCES users(user_id) ON DELETE CASCADE
);
-- coupons it also is used for food too
create table coupons (
coupon_id int identity(1,1) primary key,
code VARCHAR(50) UNIQUE not null,
service_type VARCHAR(20) CHECK (service_type IN ('Food', 'Taxi', 'Global')) not null,
discount_type VARCHAR(20) CHECK (discount_type IN ('Percentage', 'Fixed_Amount')) not null,
discount_value DECIMAL(18,2) not null CHECK(discount_value>0),
max_discount DECIMAL(18,2) NULL, 
expiry_date DATETIME2 not null
);
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
coupon_id int NULL, 
CONSTRAINT FK_trip_coupon FOREIGN KEY(coupon_id) REFERENCES coupons(coupon_id),
CONSTRAINT FK_trips_passenger FOREIGN KEY (passenger_id) REFERENCES users(user_id),
CONSTRAINT FK_trips_driver FOREIGN KEY (driver_id) REFERENCES drivers(driver_id),
CHECK(driver_id IS not null OR status='Searching')
);
--car info may be a motor
create table vehicles(
v_id int identity(1 , 1) primary key,
driver_id int not null unique ,-- هر راننده یه ماشین فقط 
model nvarchar(50)not null,
color nvarchar(50) not null , 
plak_num nvarchar(15) unique not null ,-- ==الف=== ایران ==
CONSTRAINT FK_vehicles_drivers FOREIGN KEY (driver_id) REFERENCES drivers(driver_id) ON DELETE CASCADE

);
-- where is diver in what time
create table live_location_driver(
location_id int identity(1,1) primary key,
driver_id int UNIQUE not null,
latitude DECIMAL(9,6) not null,
longitude DECIMAL(9,6) not null,
updated_at DATETIME2 DEFAULT SYSDATETIME(),
CONSTRAINT FK_locations_drivers FOREIGN KEY (driver_id) REFERENCES drivers(driver_id) ON DELETE CASCADE
);
create table trip_review(
rew_id int identity(1,1) primary key,
trip_id int unique not null,
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
create table driver_doc(
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
-------------------food part----------
create table restaurants (
    restaurant_id int identity(1,1) primary key,
    manager_id int not null,
    name NVARCHAR(150) not null,
    phone VARCHAR(11) not null CHECK((LEN(phone)=11) AND phone LIKE '09_________' AND phone NOT LIKE '%[^0-9]%' ),
    address NVARCHAR(500) not null,
    latitude DECIMAL(9,6) not null,
    longitude DECIMAL(9,6) not null,
    is_active BIT DEFAULT 1,
    CONSTRAINT FK_restaurants_users FOREIGN KEY (manager_id) REFERENCES users(user_id)
);
create table food_categories (
    category_id int identity(1,1) primary key,
    restaurant_id int not null,
    name NVARCHAR(100) not null,
    CONSTRAINT FK_categories_restaurants FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id) ON DELETE CASCADE
 ,CONSTRAINT UQ_category
    UNIQUE(restaurant_id,name));
create table foods (
    food_id int identity(1,1) primary key,
    category_id int not null,
    name NVARCHAR(150) not null,
    description NVARCHAR(500) NULL,
    price DECIMAL(18,2) not null CHECK(price>=0),
    stock int not null  DEFAULT 0 CHECK(stock>=0),
    is_available BIT DEFAULT 1,
    CONSTRAINT UQ_food
    UNIQUE(category_id,name),
        CONSTRAINT FK_foods_categories FOREIGN KEY (category_id) REFERENCES food_categories(category_id) ON DELETE CASCADE
);
create table food_options (
    option_id int identity(1,1) primary key,
    food_id int not null,
    name NVARCHAR(100) not null,
    price DECIMAL(18,2) not null CHECK(price>=0) DEFAULT 0.00,
    CONSTRAINT UQ_option UNIQUE(food_id,name),
    CONSTRAINT FK_options_foods FOREIGN KEY (food_id) REFERENCES foods(food_id) ON DELETE CASCADE
);
create table food_orders (
    order_id int identity(1,1) primary key,
    customer_id int not null,
    restaurant_id int not null,
    address_id int not null,
    coupon_id int NULL,
    total_amount DECIMAL(18,2) CHECK(total_amount>=0) not null,
    status VARCHAR(20) CHECK (status IN ('Pending', 'Preparing', 'ReadyForPickup', 'Delivered', 'Cancelled')) DEFAULT 'Pending',
    created_at DATETIME2 DEFAULT SYSDATETIME(),
    CONSTRAINT FK_orders_customer FOREIGN KEY (customer_id) REFERENCES users(user_id),
    CONSTRAINT FK_orders_restaurant FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id),
    CONSTRAINT FK_orders_address FOREIGN KEY (address_id) REFERENCES user_address(address_id),
    CONSTRAINT FK_orders_coupon FOREIGN KEY (coupon_id) REFERENCES coupons(coupon_id)
);
create table order_items (
    item_id int identity(1,1) primary key,
    order_id int not null,
    food_id int not null,
    quantity int not null CHECK (quantity > 0),
    unit_price DECIMAL(18,2)  CHECK(unit_price>=0) not null,  
    CONSTRAINT UQ_order_food UNIQUE(order_id,food_id),
    CONSTRAINT FK_items_orders FOREIGN KEY (order_id) REFERENCES food_orders(order_id) ON DELETE CASCADE,
    CONSTRAINT FK_items_foods FOREIGN KEY (food_id) REFERENCES foods(food_id)
);
create table order_item_options (
    id int identity(1,1) primary key,
    order_item_id int not null,
    option_id int not null,
    price DECIMAL(18,2)  CHECK(price>=0) not null,
         CONSTRAINT UQ_item_option UNIQUE(order_item_id,option_id),

    CONSTRAINT FK_item_options_item FOREIGN KEY (order_item_id) REFERENCES order_items(item_id) ON DELETE CASCADE,
    CONSTRAINT FK_item_options_option FOREIGN KEY (option_id) REFERENCES food_options(option_id)
);
create table food_reviews (
    review_id int identity(1,1) primary key,
    customer_id int not null,
    restaurant_id int not null,
    rating int CHECK (rating BETWEEN 1 AND 5) not null,
    comment NVARCHAR(1000) NULL,
    created_at DATETIME2 DEFAULT SYSDATETIME(),
    CONSTRAINT FK_food_reviews_users FOREIGN KEY (customer_id) REFERENCES users(user_id),
    CONSTRAINT FK_food_reviews_restaurants FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id)
);
create table restaurant_images (
    image_id int identity(1,1) primary key,
    restaurant_id int not null,
    image_url VARCHAR(500) not null,
    CONSTRAINT FK_images_restaurants FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id) ON DELETE CASCADE
);
create table restaurant_working_hours (
    id int identity(1,1) primary key,
    restaurant_id int not null,
    weekday int CHECK (weekday BETWEEN 1 AND 7) not null,
    open_time TIME not null,
    close_time TIME not null,--CHECK(close_time>open_time), 24/7 resturant
    CONSTRAINT UQ_workday UNIQUE(restaurant_id,weekday),
    CONSTRAINT FK_working_hours_restaurants FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id) ON DELETE CASCADE
);
create table wallets(
wallet_id int identity(1,1) primary key ,
user_id int unique not null, 
balance decimal(20, 2) default 0.00 CHECK(balance>=0),
updated_at DATETIME2 DEFAULT SYSDATETIME(),
CONSTRAINT FK_wallets_users FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);
CREATE TABLE wallet_transactions(

transaction_id INT IDENTITY PRIMARY KEY,

wallet_id INT NOT NULL,

amount DECIMAL(18,2)  CHECK(amount>0)
 NOT NULL,

transaction_type VARCHAR(20)
CHECK(transaction_type IN('Deposit','Withdraw','Refund')) not null ,

description NVARCHAR(300),

created_at DATETIME2 DEFAULT SYSDATETIME(),

CONSTRAINT FK_wallet_transaction
FOREIGN KEY(wallet_id)
REFERENCES wallets(wallet_id)

);
create table payments(
payment_id int identity(1,1) primary key,
user_id int not null,
service_type VARCHAR(10) CHECK (service_type IN ('Food', 'Taxi')) not null,
order_id int ,
trip_id int ,
amount DECIMAL(18,2) not null CHECK(amount>0),
payment_method VARCHAR(20) CHECK (payment_method IN ('Online', 'Wallet', 'Cash')) not null,
status VARCHAR(20) CHECK (status IN ('Pending', 'Success', 'Failed')) default 'Pending',
created_at DATETIME2 DEFAULT SYSDATETIME(),
CONSTRAINT FK_payments_users FOREIGN KEY (user_id) REFERENCES users(user_id),
CONSTRAINT FK_payments_orders FOREIGN KEY (order_id) REFERENCES food_orders(order_id),
CONSTRAINT FK_payments_trips FOREIGN KEY (trip_id) REFERENCES taxi_trips(trip_id),
CONSTRAINT CK_payment_reference
CHECK((order_id IS NOT NULL AND trip_id IS NULL) OR (order_id IS NULL AND trip_id IS NOT NULL))

);
create table notif(
notif_id int identity(1,1) primary key,
user_id int not null,
title nvarchar(50),
mess_bod nvarchar(1000) , 
is_read bit default 0,
created_at DATETIME2 default SYSDATETIME() , 
CONSTRAINT FK_notifications_users FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE

);
create table supp_ticket(
tick_id int identity(1,1) primary key,
user_id int not null,
title nvarchar(50),
mess_bod nvarchar(1000) , 
status VARCHAR(20) CHECK (status IN ('Open', 'Pending', 'Closed')) DEFAULT 'Open',
created_at DATETIME2 DEFAULT SYSDATETIME(),
CONSTRAINT FK_tickets_users FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE

);
create table food_deliveries(
driver_id int not null,
delivery_id int identity(1 , 1) primary key,
food_order_id int unique not null , 
taxi_trip_id int unique not null,
delivery_status varchar(20) check (delivery_status IN ('Assigned', 'PickedUp', 'Delivered')) DEFAULT 'Assigned',
assigned_at DATETIME2 DEFAULT SYSDATETIME(),
CONSTRAINT FK_deliveries_trip FOREIGN KEY (taxi_trip_id) REFERENCES taxi_trips(trip_id),
CONSTRAINT FK_delivery_driver FOREIGN KEY(driver_id) REFERENCES drivers(driver_id),
CONSTRAINT FK_delivery_order FOREIGN KEY(food_order_id) REFERENCES food_orders(order_id)

);

