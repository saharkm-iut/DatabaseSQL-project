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

create table user_address(
address_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    title NVARCHAR(50) NOT NULL, 
    address_text NVARCHAR(500) NOT NULL,
    latitude DECIMAL(9,6) NOT NULL,
    longitude DECIMAL(9,6) NOT NULL,
    CONSTRAINT FK_addresses_users FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE

);