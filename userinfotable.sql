-------------comman tables--------------
----------user with any role----------

create table users(
user_id int identity(1,1) primary key,
firstname NVARCHAR(50) not null,
lastname NVARCHAR(50) not null ,
phone_num VARCHAR(11) UNIQUE not null, CONSTRAint CHK_users_phone CHECK ( (LEN(phone_num)=11) and phone_num LIKE '09_________' AND phone_num NOT LIKE '%[^0-9]%'),
email varchar(100) unique null , CONSTRAint CHK_users_gmail CHECK (email IS NULL OR email LIKE '%@gmail.com'),
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
    CONSTRAint FK_user_roles_users FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAint FK_user_roles_roles FOREIGN KEY (role_id) REFERENCES roles(role_id) ON DELETE CASCADE
);
create table user_address(
address_id int identity(1,1) primary key,
    user_id int not null,
    title NVARCHAR(50) not null, 
    address_text NVARCHAR(500) not null,
    latitude DECIMAL(9,6) not null,
    longitude DECIMAL(9,6) not null,
    CONSTRAint FK_addresses_users FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE

);
