create table restaurants (
    restaurant_id int identity(1,1) primary key,
    manager_id int not null,
    name NVARCHAR(150) not null,
    phone VARCHAR(11) not null CHECK((LEN(phone)=11) AND phone LIKE '09_________' AND phone NOT LIKE '%[^0-9]%' ),
    address NVARCHAR(500) not null,
    latitude DECIMAL(9,6) not null,
    longitude DECIMAL(9,6) not null,
    is_active BIT DEFAULT 1,
    CONSTRAint FK_restaurants_users FOREIGN KEY (manager_id) REFERENCES users(user_id)
);
create table food_categories (
    category_id int identity(1,1) primary key,
    restaurant_id int not null,
    name NVARCHAR(100) not null,
    CONSTRAint FK_categories_restaurants FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id) ON DELETE CASCADE
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
        CONSTRAint FK_foods_categories FOREIGN KEY (category_id) REFERENCES food_categories(category_id) ON DELETE CASCADE
);
create table food_options (
    option_id int identity(1,1) primary key,
    food_id int not null,
    name NVARCHAR(100) not null,
    price DECIMAL(18,2) not null CHECK(price>=0) DEFAULT 0.00,
    CONSTRAINT UQ_option UNIQUE(food_id,name),
    CONSTRAint FK_options_foods FOREIGN KEY (food_id) REFERENCES foods(food_id) ON DELETE CASCADE
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
    CONSTRAint FK_orders_customer FOREIGN KEY (customer_id) REFERENCES users(user_id),
    CONSTRAint FK_orders_restaurant FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id),
    CONSTRAint FK_orders_address FOREIGN KEY (address_id) REFERENCES user_address(address_id),
    CONSTRAint FK_orders_coupon FOREIGN KEY (coupon_id) REFERENCES coupons(coupon_id)
);
create table order_items (
    item_id int identity(1,1) primary key,
    order_id int not null,
    food_id int not null,
    quantity int not null CHECK (quantity > 0),
    unit_price DECIMAL(18,2)  CHECK(unit_price>=0) not null,  
    CONSTRAINT UQ_order_food UNIQUE(order_id,food_id),
    CONSTRAint FK_items_orders FOREIGN KEY (order_id) REFERENCES food_orders(order_id) ON DELETE CASCADE,
    CONSTRAint FK_items_foods FOREIGN KEY (food_id) REFERENCES foods(food_id)
);
create table order_item_options (
    id int identity(1,1) primary key,
    order_item_id int not null,
    option_id int not null,
    price DECIMAL(18,2)  CHECK(price>=0) not null,
         CONSTRAINT UQ_item_option UNIQUE(order_item_id,option_id),

    CONSTRAint FK_item_options_item FOREIGN KEY (order_item_id) REFERENCES order_items(item_id) ON DELETE CASCADE,
    CONSTRAint FK_item_options_option FOREIGN KEY (option_id) REFERENCES food_options(option_id)
);
create table food_reviews (
    review_id int identity(1,1) primary key,
    customer_id int not null,
    restaurant_id int not null,
    rating int CHECK (rating BETWEEN 1 AND 5) not null,
    comment NVARCHAR(1000) NULL,
    created_at DATETIME2 DEFAULT SYSDATETIME(),
    CONSTRAint FK_food_reviews_users FOREIGN KEY (customer_id) REFERENCES users(user_id),
    CONSTRAint FK_food_reviews_restaurants FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id)
);
create table restaurant_images (
    image_id int identity(1,1) primary key,
    restaurant_id int not null,
    image_url VARCHAR(500) not null,
    CONSTRAint FK_images_restaurants FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id) ON DELETE CASCADE
);
create table restaurant_working_hours (
    id int identity(1,1) primary key,
    restaurant_id int not null,
    weekday int CHECK (weekday BETWEEN 1 AND 7) not null,
    open_time TIME not null,
    close_time TIME not null,--CHECK(close_time>open_time), 24/7 resturant
    CONSTRAINT UQ_workday UNIQUE(restaurant_id,weekday),
    CONSTRAint FK_working_hours_restaurants FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id) ON DELETE CASCADE
);
