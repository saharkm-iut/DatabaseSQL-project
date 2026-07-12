use dbproject;
go
create table wallets(
wallet_id int identity(1,1) primary key ,
user_id int unique not null, 
balance decimal(20, 2) default 0.00 CHECK(balance>=0),
updated_at DATETIME2 DEFAULT SYSDATETIME(),
CONSTRAint FK_wallets_users FOREIGN KEY (user_id) REFERENCES Account.users(user_id) ON DELETE CASCADE
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
CONSTRAint FK_payments_users FOREIGN KEY (user_id) REFERENCES Account.users(user_id),
CONSTRAint FK_payments_orders FOREIGN KEY (order_id) REFERENCES Food.food_orders(order_id),
CONSTRAint FK_payments_trips FOREIGN KEY (trip_id) REFERENCES Taxi.taxi_trips(trip_id),
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
CONSTRAint FK_notifications_users FOREIGN KEY (user_id) REFERENCES Account.users(user_id) ON DELETE CASCADE

);
create table supp_ticket(
tick_id int identity(1,1) primary key,
user_id int not null,
title nvarchar(50),
mess_bod nvarchar(1000) , 
status VARCHAR(20) CHECK (status IN ('Open', 'Pending', 'Closed')) DEFAULT 'Open',
created_at DATETIME2 DEFAULT SYSDATETIME(),
CONSTRAint FK_tickets_users FOREIGN KEY (user_id) REFERENCES Account.users(user_id) ON DELETE CASCADE

);
create table activity_log(
log_id int identity(1,1) primary key,
user_id int not null,
action nvarchar(200) not null, 
created_at DATETIME2 DEFAULT SYSDATETIME(),
CONSTRAint FK_logs_users FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE


);
create table food_deliveries(
driver_id int not null,
delivery_id int identity(1 , 1) primary key,
food_order_id int unique not null , 
taxi_trip_id int unique not null,
delivery_status varchar(20) check (delivery_status IN ('Assigned', 'PickedUp', 'Delivered')) DEFAULT 'Assigned',
assigned_at DATETIME2 DEFAULT SYSDATETIME(),
CONSTRAint FK_deliveries_trip FOREIGN KEY (taxi_trip_id) REFERENCES Taxi.taxi_trips(trip_id),
CONSTRAint FK_delivery_driver FOREIGN KEY(driver_id) REFERENCES Taxi.drivers(driver_id),
CONSTRAint FK_delivery_order FOREIGN KEY(food_order_id) REFERENCES Food.food_orders(order_id)

);

