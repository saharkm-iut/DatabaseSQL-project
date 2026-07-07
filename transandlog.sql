
create table wallets(
wallet_id int identity(1,1) primary key ,
user_id int unique not null, 
balance decimal(20, 2) default 0.00 CHECK(balance>=0),
updated_at DATETIME2 DEFAULT SYSDATETIME(),
CONSTRAINT FK_wallets_users FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);
create table payments(
payment_id INT IDENTITY(1,1) PRIMARY KEY,
user_id INT not null,
service_type VARCHAR(10) CHECK (service_type IN ('Food', 'Taxi')) not null,
order_id INT ,
trip_id INT ,
amount DECIMAL(18,2) not null,
payment_method VARCHAR(20) CHECK (payment_method IN ('Online', 'Wallet', 'Cash')) not null,
status VARCHAR(20) CHECK (status IN ('Pending', 'Success', 'Failed')) default 'Pending',
created_at DATETIME2 DEFAULT SYSDATETIME(),
CONSTRAINT FK_payments_users FOREIGN KEY (user_id) REFERENCES users(user_id),
CONSTRAINT FK_payments_orders FOREIGN KEY (order_id) REFERENCES food_orders(order_id),
CONSTRAINT FK_payments_trips FOREIGN KEY (trip_id) REFERENCES taxi_trips(trip_id)
);
create table notif(
notif_id int identity(1,1) primary key,
useer_id int not null,
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
create table activity_log(
log_id int identity(1,1) primary key,
user_id int not null,
action nvarchar(200) not null, 
createt_at DATETIME2 DEFAULT SYSDATETIME(),
CONSTRAINT FK_logs_users FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE


);
create table food_deliveries(
driver_id INT not null,
delivery_id int identity(1 , 1) primary key,
food_order_id int unique not null , 
taxi_trip_id int unique not null,
delivery_status varchar(20) check (delivery_status IN ('Assigned', 'PickedUp', 'Delivered')) DEFAULT 'Assigned',
assigned_at DATETIME2 DEFAULT SYSDATETIME(),
CONSTRAINT FK_deliveries_trip FOREIGN KEY (taxi_trip_id) REFERENCES taxi_trips(trip_id),
CONSTRAINT FK_delivery_driver FOREIGN KEY(driver_id) REFERENCES drivers(driver_id)

);



