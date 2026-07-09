USE DatabaseSQL_Project;
GO

-- Roles
INSERT INTO Account.roles(role_name)
VALUES
('Admin'),
('Customer'),
('RestaurantManager'),
('Driver');
GO


-- Users
INSERT INTO Account.users
(firstname, lastname, phone_num, email, pass_hash)
VALUES
('Ali','Ahmadi','09111111111','ali@gmail.com','123456'),
('Sara','Karimi','09111111112','sara@gmail.com','123456'),
('Reza','Moradi','09111111113','reza@gmail.com','123456'),
('Maryam','Hashemi','09111111114','maryam@gmail.com','123456'),
('Mohammad','Jafari','09111111115','mohammad@gmail.com','123456');
GO
USE DatabaseSQL_Project;
GO

INSERT INTO Account.user_roles (user_id, role_id)
VALUES
(1,1),  -- Ali -> Admin

(2,2),  -- Sara -> Customer

(3,3),  -- Reza -> RestaurantManager
(3,4),  -- Reza -> Driver

(4,2),  -- Maryam -> Customer

(5,2),  -- Mohammad -> Customer
(5,4);  -- Mohammad -> Driver
GO
USE DatabaseSQL_Project;
GO

INSERT INTO Account.user_address
(user_id, title, address_text, latitude, longitude)
VALUES
(1, N'خانه', N'اصفهان، خیابان چهارباغ بالا، پلاک 10', 32.654600, 51.668000),

(2, N'خانه', N'اصفهان، خیابان مرداویج، کوچه 5', 32.635200, 51.669500),

(3, N'رستوران', N'اصفهان، خیابان حکیم نظامی، پلاک 25', 32.640800, 51.651200),

(4, N'خانه', N'اصفهان، خیابان توحید، پلاک 18', 32.648900, 51.661700),

(5, N'خانه', N'اصفهان، خیابان آمادگاه، پلاک 7', 32.657300, 51.677100);
GO

USE DatabaseSQL_Project;
GO

INSERT INTO Payment.coupons
(code, service_type, discount_type, discount_value, max_discount, expiry_date)
VALUES
('FOOD10',  'Food',   'Percentage', 10, 100000, '2027-12-31'),
('FOOD50',  'Food',   'Fixed_Amount', 50000, NULL, '2027-12-31'),
('TAXI15',  'Taxi',   'Percentage', 15, 80000, '2027-12-31'),
('GLOBAL5', 'Global', 'Percentage', 5, 50000, '2027-12-31'),
('WELCOME', 'Global', 'Fixed_Amount', 30000, NULL, '2027-12-31');
GO
INSERT INTO Account.users
(firstname, lastname, phone_num, email, pass_hash)
VALUES
('Hossein','Rahimi','09111111116','hossein@gmail.com','123456'),
('Narges','Mohammadi','09111111117','narges@gmail.com','123456');
GO
INSERT INTO Account.user_roles(user_id, role_id)
VALUES
(6,3),
(7,3);
GO
USE DatabaseSQL_Project;
GO

INSERT INTO Food.restaurants
(manager_id, name, phone, address, latitude, longitude)
VALUES
(3, N'رستوران ایتالیایی رومانا', '09120000001', N'اصفهان، خیابان چهارباغ بالا', 32.654100, 51.667500),

(3, N'فست فود برگرلند', '09120000002', N'اصفهان، خیابان توحید', 32.648200, 51.660800),

(6, N'کبابی سنتی آریا', '09120000003', N'اصفهان، خیابان نظر شرقی', 32.656300, 51.676500),

(7, N'کافه رستوران آفتاب', '09120000004', N'اصفهان، خیابان مرداویج', 32.636700, 51.669900),

(7, N'پیتزا هات اصفهان', '09120000005', N'اصفهان، خیابان حکیم نظامی', 32.642000, 51.652700);
GO
USE DatabaseSQL_Project;
GO

INSERT INTO Food.food_categories (restaurant_id, name)
VALUES
-- Restaurant 1
(1, N'پیتزا'),
(1, N'پاستا'),
(1, N'نوشیدنی'),

-- Restaurant 2
(2, N'برگر'),
(2, N'سیب زمینی'),
(2, N'نوشیدنی'),

-- Restaurant 3
(3, N'کباب'),
(3, N'خورشت'),
(3, N'نوشیدنی'),

-- Restaurant 4
(4, N'قهوه'),
(4, N'کیک'),
(4, N'نوشیدنی'),

-- Restaurant 5
(5, N'پیتزا'),
(5, N'سالاد'),
(5, N'نوشیدنی');
GO
USE DatabaseSQL_Project;
GO

INSERT INTO Food.foods
(category_id, name, description, price, stock)
VALUES
-- Restaurant 1
(1, N'پیتزا مخصوص', N'پیتزا با ژامبون، قارچ و پنیر', 320000, 20),
(1, N'پیتزا پپرونی', N'پیتزا پپرونی', 340000, 15),
(2, N'پاستا آلفردو', N'پاستا با سس آلفردو', 280000, 18),
(3, N'نوشابه خانواده', N'نوشابه 1.5 لیتری', 45000, 50),

-- Restaurant 2
(4, N'برگر مخصوص', N'برگر گوشت دوبل', 260000, 25),
(4, N'چیزبرگر', N'برگر با پنیر', 230000, 30),
(5, N'سیب زمینی ویژه', N'سیب زمینی با پنیر', 120000, 40),
(6, N'دلستر', N'دلستر لیمویی', 35000, 60),

-- Restaurant 3
(7, N'کباب کوبیده', N'دو سیخ کوبیده', 310000, 20),
(7, N'جوجه کباب', N'جوجه زعفرانی', 330000, 18),
(8, N'قورمه سبزی', N'خورشت قورمه سبزی', 250000, 15),
(9, N'دوغ', N'دوغ محلی', 30000, 50),

-- Restaurant 4
(10, N'اسپرسو', N'قهوه اسپرسو', 90000, 40),
(10, N'کاپوچینو', N'قهوه کاپوچینو', 120000, 30),
(11, N'چیزکیک', N'چیزکیک توت فرنگی', 150000, 20),
(12, N'آب معدنی', N'آب معدنی 500 میلی', 15000, 100),

-- Restaurant 5
(13, N'پیتزا سبزیجات', N'پیتزای سبزیجات', 290000, 20),
(13, N'پیتزا مرغ', N'پیتزا مرغ و قارچ', 310000, 18),
(14, N'سالاد سزار', N'سالاد سزار با مرغ', 180000, 15),
(15, N'نوشابه قوطی', N'نوشابه قوطی', 25000, 80);
GO
USE DatabaseSQL_Project;
GO

INSERT INTO Food.food_options (food_id, name, price)
VALUES
-- پیتزا مخصوص
(1, N'پنیر اضافه', 40000),
(1, N'قارچ اضافه', 30000),

-- پیتزا پپرونی
(2, N'پنیر اضافه', 40000),
(2, N'زیتون', 25000),

-- پاستا آلفردو
(3, N'مرغ اضافه', 50000),

-- برگر مخصوص
(5, N'پنیر اضافه', 25000),
(5, N'سیب زمینی', 50000),

-- چیزبرگر
(6, N'بیکن', 45000),

-- کباب کوبیده
(9, N'برنج اضافه', 60000),

-- جوجه کباب
(10, N'کره', 20000),

-- اسپرسو
(13, N'شات اضافه', 30000),

-- کاپوچینو
(14, N'شیر اضافه', 15000),

-- پیتزا سبزیجات
(17, N'پنیر اضافه', 40000),

-- پیتزا مرغ
(18, N'قارچ اضافه', 30000),

-- سالاد سزار
(19, N'مرغ اضافه', 50000);
GO
USE DatabaseSQL_Project;
GO

INSERT INTO Food.restaurant_working_hours
(restaurant_id, weekday, open_time, close_time)
VALUES

-- رستوران 1 (همه روزه)
(1,1,'10:00','23:00'),
(1,2,'10:00','23:00'),
(1,3,'10:00','23:00'),
(1,4,'10:00','23:00'),
(1,5,'10:00','23:30'),
(1,6,'10:00','23:30'),
(1,7,'11:00','22:30'),

-- رستوران 2 (فست فود)
(2,1,'11:00','23:30'),
(2,2,'11:00','23:30'),
(2,3,'11:00','23:30'),
(2,4,'11:00','23:30'),
(2,5,'11:00','00:00'),
(2,6,'11:00','00:00'),
(2,7,'12:00','23:00'),

-- رستوران 3 (کبابی)
(3,1,'12:00','22:00'),
(3,2,'12:00','22:00'),
(3,3,'12:00','22:00'),
(3,4,'12:00','22:00'),
(3,5,'12:00','22:30'),
(3,6,'12:00','22:30'),
(3,7,'12:00','21:00'),

-- رستوران 4 (کافه)
(4,1,'08:00','22:00'),
(4,2,'08:00','22:00'),
(4,3,'08:00','22:00'),
(4,4,'08:00','22:00'),
(4,5,'08:00','23:00'),
(4,6,'09:00','23:00'),
(4,7,'09:00','22:00'),

-- رستوران 5 (پیتزا)
(5,1,'11:30','23:30'),
(5,2,'11:30','23:30'),
(5,3,'11:30','23:30'),
(5,4,'11:30','23:30'),
(5,5,'11:30','00:30'),
(5,6,'11:30','00:30'),
(5,7,'12:00','23:30');
GO
USE DatabaseSQL_Project;
GO

INSERT INTO Food.food_orders
(customer_id, restaurant_id, address_id, coupon_id, total_amount, status)
VALUES

-- سفارش در انتظار
(2, 1, 1, NULL, 320000, 'Pending'),

-- در حال آماده سازی
(4, 2, 2, 1, 295000, 'Preparing'),

-- آماده تحویل به پیک
(2, 3, 1, NULL, 340000, 'ReadyForPickup'),

-- تحویل شده
(4, 4, 2, 2, 210000, 'Delivered'),

-- لغو شده
(2, 5, 1, NULL, 310000, 'Cancelled'),

-- تحویل شده
(4, 1, 2, NULL, 365000, 'Delivered'),

-- در حال آماده سازی
(2, 2, 1, 3, 275000, 'Preparing');
GO
USE DatabaseSQL_Project;
GO

INSERT INTO Food.order_items
(order_id, food_id, quantity, unit_price)
VALUES

-- سفارش 1 (Restaurant 1)
(1, 1, 1, 320000),

-- سفارش 2 (Restaurant 2)
(2, 5, 1, 260000),
(2, 7, 1, 120000),

-- سفارش 3 (Restaurant 3)
(3, 9, 1, 310000),
(3,12, 1, 30000),

-- سفارش 4 (Restaurant 4)
(4,13, 1, 90000),
(4,15, 1, 150000),

-- سفارش 5 (Restaurant 5)
(5,18, 1, 310000),

-- سفارش 6 (Restaurant 1)
(6, 2, 1, 340000),
(6, 4, 1, 45000),

-- سفارش 7 (Restaurant 2)
(7, 6, 1, 230000),
(7, 8, 1, 35000);
GO
USE DatabaseSQL_Project;
GO

INSERT INTO Food.order_item_options
(order_item_id, option_id, price)
VALUES

-- سفارش 1 (پیتزا مخصوص)
(1, 1, 40000),   -- پنیر اضافه

-- سفارش 2 (برگر مخصوص)
(2, 6, 25000),   -- پنیر اضافه
(2, 7, 50000),   -- سیب زمینی

-- سفارش 3 (سیب زمینی ویژه)
(3, 8, 45000),   -- بیکن

-- سفارش 4 (کباب کوبیده)
(4, 9, 60000),   -- برنج اضافه

-- سفارش 6 (اسپرسو)
(6,11,30000),    -- شات اضافه

-- سفارش 8 (پیتزا مرغ)
(8,14,30000),    -- قارچ اضافه

-- سفارش 10 (پیتزا پپرونی)
(10,4,25000),    -- زیتون

-- سفارش 11 (چیزبرگر)
(11,8,45000);    -- بیکن
GO
USE DatabaseSQL_Project;
GO

INSERT INTO Food.food_reviews
(customer_id, restaurant_id, rating, comment)
VALUES

(2, 1, 5, N'کیفیت غذا عالی بود و خیلی سریع رسید.'),

(4, 2, 4, N'برگر خوشمزه بود ولی سیب زمینی کمی سرد بود.'),

(2, 3, 5, N'کباب بسیار باکیفیت و تازه بود.'),

(4, 4, 3, N'قهوه خوب بود اما زمان آماده شدن زیاد طول کشید.'),

(2, 5, 4, N'پیتزا خوشمزه بود و بسته بندی مناسبی داشت.'),

(4, 1, 5, N'هم کیفیت غذا و هم برخورد پرسنل عالی بود.'),

(2, 2, 2, N'سفارش با تأخیر رسید.');
GO

