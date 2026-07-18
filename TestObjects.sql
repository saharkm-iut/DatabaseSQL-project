SELECT *
FROM Food.vw_RestaurantMenu;
SELECT *
FROM Food.vw_CustomerOrders
ORDER BY created_at DESC;
SELECT *
FROM Food.vw_RestaurantRatings
ORDER BY average_rating DESC;
SELECT *
FROM Food.vw_AvailableFoods
ORDER BY restaurant_name, category_name, food_name;
SELECT *
FROM Food.vw_OrderDetails
ORDER BY order_id;
SELECT *
FROM Food.vw_RestaurantSales
ORDER BY total_sales DESC;
/*functions test*/
SELECT Payment.fn_ValidateCoupon('FOOD10') AS Result;
GO

SELECT Payment.fn_ValidateCoupon('WELCOME') AS Result;
GO

SELECT Payment.fn_ValidateCoupon('ABC') AS Result;
GO
SELECT Food.fn_CalculateDeliveryFee(600000) AS DeliveryFee;
SELECT Food.fn_CalculateDeliveryFee(350000) AS DeliveryFee;
SELECT Food.fn_CalculateDeliveryFee(150000) AS DeliveryFee;

SELECT Food.fn_CalculateFinalAmount(250000,50000) AS FinalAmount;

SELECT Food.fn_CalculateFinalAmount(600000,100000) AS FinalAmount;

SELECT Food.fn_TotalOrderPrice(1) AS TotalPrice;
SELECT Food.fn_TotalOrderPrice(2) AS TotalPrice;
SELECT Food.fn_TotalOrderPrice(7) AS TotalPrice;

SELECT Food.fn_RestaurantAverageRating(1) AS AverageRating;
SELECT Food.fn_RestaurantAverageRating(2) AS AverageRating;
SELECT Food.fn_RestaurantAverageRating(5) AS AverageRating;

/*triggers test*/

-- مشاهده موجودی قبل از ثبت آیتم سفارش
SELECT food_id, name, stock
FROM Food.foods
WHERE food_id = 3;
GO

-- مشاهده آیتم های سفارش شماره 1
SELECT *
FROM Food.order_items
WHERE order_id = 1;
GO

-- ثبت آیتم جدید (اگر food_id=3 داخل سفارش 1 وجود ندارد)
INSERT INTO Food.order_items
(
    order_id,
    food_id,
    quantity,
    unit_price
)
VALUES
(
    1,
    3,
    1,
    180000
);
GO

-- بررسی موجودی بعد از ثبت
SELECT food_id, name, stock
FROM Food.foods
WHERE food_id = 3;
GO

-- بررسی آیتم های سفارش
SELECT *
FROM Food.order_items
WHERE order_id = 1;
GO

/*---------------------------------------------------------
  تست Trigger دوم
---------------------------------------------------------*/

-- حذف همان آیتم
DELETE FROM Food.order_items
WHERE order_id = 1
AND food_id = 3;
GO

-- بررسی موجودی بعد از حذف
SELECT food_id, name, stock
FROM Food.foods
WHERE food_id = 3;
GO

-- بررسی آیتم های سفارش
SELECT *
FROM Food.order_items
WHERE order_id = 1;
GO

/*
نتیجه مورد انتظار:

1- بعد از INSERT
   موجودی غذا یک واحد کاهش پیدا کند.

2- بعد از DELETE
   موجودی غذا به مقدار اولیه برگردد.

3- در انتهای تست، دیتابیس دقیقاً به حالت اولیه برگردد.
*/

/*=========================================================
    TEST : Food.trg_LogOrderStatusChange
=========================================================*/

-- مشاهده وضعیت سفارش قبل از تغییر
SELECT order_id, status
FROM Food.food_orders
WHERE order_id = 1;
GO

-- تغییر وضعیت سفارش
UPDATE Food.food_orders
SET status = 'Preparing'
WHERE order_id = 1;
GO

-- مشاهده وضعیت جدید
SELECT order_id, status
FROM Food.food_orders
WHERE order_id = 1;
GO

-- بررسی ثبت لاگ
SELECT TOP 10 *
FROM Food.food_log
ORDER BY log_id DESC;
GO

/*test npro*/
EXEC Food.SP_CreateFoodOrder
    @CustomerID = 2,
    @RestaurantID = 1,
    @AddressID = 1,
    @OrderAmount = 250000,
    @CouponCode = NULL,
    @DiscountAmount = 0;

SELECT * FROM Food.food_orders;
GO

EXEC Food.SP_UpdateFoodOrderStatus
    @OrderID = 1,
    @NewStatus = 'Preparing';

SELECT * FROM Food.food_orders
WHERE order_id = 1;
GO

EXEC Food.SP_AddFoodReview
    @CustomerID = 2,
    @RestaurantID = 1,
    @Rating = 5,
    @Comment = N'غذا بسیار با کیفیت بود';

SELECT * FROM Food.food_reviews;
GO

EXEC Food.SP_AddOrderItem
    @OrderID = 1,
    @FoodID = 2,
    @Quantity = 2;

SELECT * FROM Food.order_items
WHERE order_id = 1;

SELECT * FROM Food.food_orders
WHERE order_id = 1;
GO
/* ساخت کیف پول */

INSERT INTO Payment.wallets(user_id, balance)
VALUES
(2,500000),
(4,300000),
(5,200000);
GO

-----------------------------------------------------------food test senario-------------------

USE DatabaseSQL_Project;
GO

PRINT '==================================================';
PRINT '              FOOD SCENARIO TESTS                 ';
PRINT '==================================================';


----------------------------------------------------
-- سناریو 1
-- مشتری 1 سفارش بدون تخفیف ثبت می‌کند
----------------------------------------------------

PRINT N'--- Scenario 1 : Normal Food Order ---';


DECLARE @OrderID1 INT;


EXEC Food.SP_CreateFoodOrder
    @CustomerID = 1,
    @RestaurantID = 1,
    @AddressID = 1,
    @OrderAmount = 250000,
    @CouponCode = NULL,
    @DiscountAmount = 0;


SELECT TOP 1
    @OrderID1 = order_id
FROM Food.food_orders
ORDER BY created_at DESC;



EXEC Food.SP_AddOrderItem
    @OrderID = @OrderID1,
    @FoodID = 1,
    @Quantity = 2;



EXEC Food.SP_UpdateFoodOrderStatus
    @OrderID = @OrderID1,
    @NewStatus = 'Preparing';



EXEC Food.SP_UpdateFoodOrderStatus
    @OrderID = @OrderID1,
    @NewStatus = 'Delivered';



SELECT *
FROM Food.vw_CustomerOrders
WHERE order_id=@OrderID1;



----------------------------------------------------
-- سناریو 2
-- سفارش با کوپن FOOD10 و ثبت نظر
----------------------------------------------------

PRINT N'--- Scenario 2 : Coupon + Review ---';


DECLARE @OrderID2 INT;


EXEC Food.SP_CreateFoodOrder
    @CustomerID = 2,
    @RestaurantID = 2,
    @AddressID = 2,
    @OrderAmount = 400000,
    @CouponCode = 'FOOD10',
    @DiscountAmount = 50000;



SELECT TOP 1
    @OrderID2 = order_id
FROM Food.food_orders
ORDER BY created_at DESC;



EXEC Food.SP_AddOrderItem
    @OrderID=@OrderID2,
    @FoodID=3,
    @Quantity=1;



EXEC Food.SP_UpdateFoodOrderStatus
    @OrderID=@OrderID2,
    @NewStatus='Delivered';



EXEC Food.SP_AddFoodReview
    @CustomerID=2,
    @RestaurantID=2,
    @Rating=5,
    @Comment=N'غذا عالی بود و ارسال سریع انجام شد';



SELECT *
FROM Food.vw_RestaurantRatings
WHERE restaurant_id=2;



----------------------------------------------------
-- سناریو 3
-- تست Trigger موجودی غذا
----------------------------------------------------

PRINT N'--- Scenario 3 : Food Stock Trigger ---';



DECLARE @BeforeStock INT;


SELECT 
@BeforeStock = stock
FROM Food.foods
WHERE food_id=5;



PRINT N'Before Stock = '
+ CAST(@BeforeStock AS VARCHAR);



DECLARE @OrderID3 INT;


EXEC Food.SP_CreateFoodOrder
    @CustomerID=3,
    @RestaurantID=1,
    @AddressID=3,
    @OrderAmount=150000,
    @CouponCode=NULL,
    @DiscountAmount=0;



SELECT TOP 1
@OrderID3=order_id
FROM Food.food_orders
ORDER BY created_at DESC;



-- کاهش موجودی توسط Trigger

EXEC Food.SP_AddOrderItem
    @OrderID=@OrderID3,
    @FoodID=5,
    @Quantity=3;



SELECT 
food_id,
stock
FROM Food.foods
WHERE food_id=5;



-- برگشت موجودی با حذف آیتم

DELETE FROM Food.order_items
WHERE order_id=@OrderID3
AND food_id=5;



SELECT 
food_id,
stock
FROM Food.foods
WHERE food_id=5;



----------------------------------------------------
-- گزارش نهایی برای ارائه
----------------------------------------------------

PRINT N'--- Orders Report ---';


SELECT *
FROM Food.vw_OrderDetails
ORDER BY created_at DESC;



PRINT N'--- Food Logs ---';


SELECT TOP 20 *
FROM Food.food_log
ORDER BY created_at DESC;

GO


USE DatabaseSQL_Project;
GO
USE DatabaseSQL_Project;
GO

-- حذف وابستگی‌ها اول

DELETE FROM Payment.payments;

DELETE FROM Food.order_items;

DELETE FROM Food.food_reviews;

DELETE FROM Food.food_log;

DELETE FROM Food.food_orders;


-- ریست شماره‌ها

DBCC CHECKIDENT ('Food.food_orders', RESEED, 0);

DBCC CHECKIDENT ('Food.order_items', RESEED, 0);

DBCC CHECKIDENT ('Food.food_reviews', RESEED, 0);

DBCC CHECKIDENT ('Food.food_log', RESEED, 0);

GO


PRINT '==================================================';
PRINT '              FOOD SCENARIO 1';
PRINT '  سفارش موفق با کوپن و تکمیل سفارش';
PRINT '==================================================';


EXEC Food.SP_CreateFoodOrder
    @CustomerID = 1,
    @RestaurantID = 1,
    @AddressID = 1,
    @OrderAmount = 250000,
    @CouponCode = 'FOOD10',
    @DiscountAmount = 25000;
GO


-- فرض: OrderID = 1

EXEC Food.SP_AddOrderItem
    @OrderID = 1,
    @FoodID = 4,
    @Quantity = 2;
GO


EXEC Food.SP_UpdateFoodOrderStatus
    @OrderID = 1,
    @NewStatus = 'Preparing';
GO


EXEC Food.SP_UpdateFoodOrderStatus
    @OrderID = 1,
    @NewStatus = 'Delivered';
GO


SELECT *
FROM Food.vw_CustomerOrders
WHERE order_id = 1;


SELECT *
FROM Food.food_log
WHERE order_id = 1;


PRINT '==================================================';
PRINT '              FOOD SCENARIO 2';
PRINT '  سفارش بدون تخفیف و لغو سفارش';
PRINT '==================================================';


EXEC Food.SP_CreateFoodOrder
    @CustomerID = 2,
    @RestaurantID = 2,
    @AddressID = 2,
    @OrderAmount = 180000,
    @CouponCode = NULL,
    @DiscountAmount = 0;
GO


-- فرض: OrderID = 2

EXEC Food.SP_AddOrderItem
    @OrderID = 2,
    @FoodID = 6,
    @Quantity = 1;
GO


EXEC Food.SP_UpdateFoodOrderStatus
    @OrderID = 2,
    @NewStatus = 'Cancelled';
GO


SELECT *
FROM Food.food_log
WHERE order_id = 2;


PRINT '==================================================';
PRINT '              FOOD SCENARIO 3';
PRINT '  بررسی کاهش موجودی غذا';
PRINT '==================================================';


SELECT 
    food_id,
    name,
    stock
FROM Food.foods
WHERE food_id = 1;
GO


EXEC Food.SP_AddOrderItem
    @OrderID = 1,
    @FoodID = 3,
    @Quantity = 3;
GO


SELECT 
    food_id,
    name,
    stock
FROM Food.foods
WHERE food_id = 1;
GO



PRINT '==================================================';
PRINT '              FOOD SCENARIO 4';
PRINT '  ثبت نظر مشتری و میانگین امتیاز';
PRINT '==================================================';


EXEC Food.SP_AddFoodReview
    @CustomerID = 1,
    @RestaurantID = 1,
    @Rating = 5,
    @Comment = N'کیفیت غذا عالی بود';
GO


SELECT 
    restaurant_id,
    name,
    Food.fn_RestaurantAverageRating(restaurant_id) AS AverageRating
FROM Food.restaurants
WHERE restaurant_id = 1;
GO



PRINT '==================================================';
PRINT '              FOOD SCENARIO 5';
PRINT '  گزارش نهایی برای ارائه';
PRINT '==================================================';


-- سفارش‌ها

SELECT *
FROM Food.vw_CustomerOrders;


-- جزئیات سفارش‌ها

SELECT *
FROM Food.vw_OrderDetails;


-- فروش رستوران‌ها

SELECT *
FROM Food.vw_RestaurantSales;


-- امتیاز رستوران‌ها

SELECT *
FROM Food.vw_RestaurantRatings;


-- لاگ تریگرها

SELECT TOP 20 *
FROM Food.food_log
ORDER BY created_at DESC;
GO



PRINT '==================================================';
PRINT '              FUNCTION TESTS';
PRINT '==================================================';


-- تست محاسبه هزینه ارسال

SELECT 
    Food.fn_CalculateDeliveryFee(100000) AS DeliveryFee;


SELECT 
    Food.fn_CalculateFinalAmount(300000,50000) AS FinalAmount;


-- تست اعتبار کوپن

SELECT 
    Payment.fn_ValidateCoupon('FOOD10') AS CouponIsValid;


PRINT '==================================================';
PRINT '              TRIGGER TESTS';
PRINT '==================================================';


-- بررسی موجودی غذاها

SELECT 
    food_id,
    name,
    stock
FROM Food.foods;


-- بررسی ثبت لاگ تغییر وضعیت

SELECT TOP 20 *
FROM Food.food_log
ORDER BY created_at DESC;

GO
/*=========================================================
        PAYMENT PROCEDURES TEST
=========================================================*/

-- شارژ کیف پول
EXEC Payment.SP_DepositWallet
    @UserID = 2,
    @Amount = 500000;

SELECT *
FROM Payment.wallets
WHERE user_id = 2;

SELECT TOP 5 *
FROM Payment.wallet_transactions
ORDER BY transaction_id DESC;
GO

-- پرداخت از کیف پول
EXEC Payment.SP_PayFromWallet
    @UserID = 2,
    @Amount = 100000,
    @ServiceType = 'Food',
    @OrderID = 1;

SELECT *
FROM Payment.wallets
WHERE user_id = 2;

SELECT TOP 5 *
FROM Payment.payments
ORDER BY payment_id DESC;
GO

-- بازگشت وجه
EXEC Payment.SP_RefundPayment
    @PaymentID = 1;

SELECT *
FROM Payment.wallets
WHERE user_id = 2;

SELECT TOP 5 *
FROM Payment.wallet_transactions
ORDER BY transaction_id DESC;
GO
/*=========================================================
        PAYMENT TRIGGERS TEST
=========================================================*/

-- مشاهده لاگ قبل از تست
SELECT *
FROM Payment.payment_log
ORDER BY log_id DESC;
GO

----------------------------------------------------------
-- تست Trigger ثبت پرداخت
----------------------------------------------------------

INSERT INTO Payment.payments
(
    user_id,
    service_type,
    order_id,
    amount,
    payment_method,
    status
)
VALUES
(
    2,
    'Food',
    1,
    120000,
    'Online',
    'Success'
);
GO

-- بررسی ثبت لاگ
SELECT TOP 10 *
FROM Payment.payment_log
ORDER BY log_id DESC;
GO

----------------------------------------------------------
-- تست Trigger ثبت تراکنش کیف پول
----------------------------------------------------------

INSERT INTO Payment.wallet_transactions
(
    wallet_id,
    amount,
    transaction_type,
    description
)
VALUES
(
    1,
    50000,
    'Deposit',
    N'شارژ آزمایشی کیف پول'
);
GO

-- بررسی لاگ
SELECT TOP 10 *
FROM Payment.payment_log
ORDER BY log_id DESC;
GO

/*=========================================================
        ACCOUNT PROCEDURES TEST
=========================================================*/

----------------------------------------------------------
-- 1- ثبت تیکت پشتیبانی
----------------------------------------------------------

EXEC Account.SP_CreateSupportTicket
    @UserID = 2,
    @Title = N'مشکل در ثبت سفارش',
    @Message = N'پرداخت انجام شد اما سفارش ثبت نشد.';
GO

SELECT *
FROM Account.supp_ticket
ORDER BY tick_id DESC;
GO

----------------------------------------------------------
-- 2- ارسال اعلان
----------------------------------------------------------

EXEC Account.SP_SendNotification
    @UserID = 2,
    @Title = N'ثبت سفارش',
    @Message = N'سفارش شما با موفقیت ثبت شد.';
GO

SELECT *
FROM Account.notif
ORDER BY notif_id DESC;
GO

----------------------------------------------------------
-- 3- خواندن اعلان
----------------------------------------------------------

EXEC Account.SP_ReadNotification
    @NotifID = 1;
GO

SELECT *
FROM Account.notif
WHERE notif_id = 1;
GO


/*=========================================================
        ACCOUNT TRIGGERS TEST
=========================================================*/

----------------------------------------------------------
-- بررسی لاگ قبل از تست
----------------------------------------------------------

SELECT *
FROM Account.account_log_activity
ORDER BY log_id DESC;
GO

----------------------------------------------------------
-- تست Trigger ثبت اعلان
----------------------------------------------------------

INSERT INTO Account.notif
(
    user_id,
    title,
    mess_bod
)
VALUES
(
    2,
    N'اعلان تست',
    N'این یک اعلان آزمایشی است.'
);
GO

SELECT TOP 10 *
FROM Account.account_log_activity
ORDER BY log_id DESC;
GO

----------------------------------------------------------
-- تست Trigger ثبت تیکت
----------------------------------------------------------

INSERT INTO Account.supp_ticket
(
    user_id,
    title,
    mess_bod
)
VALUES
(
    2,
    N'تیکت تست',
    N'این یک تیکت آزمایشی است.'
);
GO

SELECT TOP 10 *
FROM Account.account_log_activity
ORDER BY log_id DESC;
GO

----------------------------------------------------------
-- تست Trigger تغییر وضعیت تیکت
----------------------------------------------------------

UPDATE Account.supp_ticket
SET status = 'Closed'
WHERE tick_id =
(
    SELECT MAX(tick_id)
    FROM Account.supp_ticket
);
GO

SELECT TOP 10 *
FROM Account.account_log_activity
ORDER BY log_id DESC;
GO

--------------------------------------taxi--------------------------------------------------------------------
USE DatabaseSQL_Project;
GO

PRINT '==================================================';
PRINT '                 Taxi Summary                     ';
PRINT '==================================================';


-- تعداد سفرها بر اساس وضعیت
SELECT 
    status AS [وضعیت سفر],
    COUNT(*) AS [تعداد سفر]
FROM Taxi.taxi_trips
GROUP BY status;



PRINT '==================================================';
PRINT '                 Trip Messages                    ';
PRINT '==================================================';


-- پیام‌های داخل سفرها
SELECT 
    tm.m_id AS [شناسه پیام],
    tm.trip_id AS [شماره سفر],
    CONCAT(u.firstname,' ',u.lastname) AS [فرستنده],
    tm.message AS [متن پیام]
FROM Taxi.trip_message tm
JOIN Account.users u 
ON tm.sender_id = u.user_id;



PRINT '==================================================';
PRINT '                 Trip Reviews                     ';
PRINT '==================================================';


-- نظرات و امتیازها
SELECT
    tr.rew_id AS [شناسه نظر],
    tr.trip_id AS [شماره سفر],
    tr.rating AS [امتیاز],
    ISNULL(tr.comment,N'بدون متن') AS [نظر]
FROM Taxi.trip_review tr;



PRINT '==================================================';
PRINT '                 Drivers Status                   ';
PRINT '==================================================';


-- وضعیت رانندگان
SELECT 
    d.driver_id AS [شناسه راننده],
    CONCAT(u.firstname,' ',u.lastname) AS [نام راننده],
    u.phone_num AS [شماره تلفن],
    d.is_approved AS [تایید شده],
    d.is_online AS [آنلاین]
FROM Taxi.drivers d
JOIN Account.users u
ON d.driver_id = u.user_id;



PRINT '==================================================';
PRINT '                 Account                          ';
PRINT '==================================================';


-- نقش‌ها
SELECT 
    role_id AS [کد نقش],
    role_name AS [نام نقش]
FROM Account.roles;



-- کاربران همراه نقش‌ها
SELECT
    u.user_id AS [شناسه کاربر],
    u.firstname AS [نام],
    u.lastname AS [نام خانوادگی],
    u.phone_num AS [تلفن],
    STRING_AGG(r.role_name,'، ') AS [نقش‌ها]
FROM Account.users u
LEFT JOIN Account.user_roles ur
ON u.user_id = ur.user_id
LEFT JOIN Account.roles r
ON ur.role_id = r.role_id
GROUP BY
    u.user_id,
    u.firstname,
    u.lastname,
    u.phone_num;



-- آدرس کاربران
SELECT
    ua.address_id AS [شناسه آدرس],
    CONCAT(u.firstname,' ',u.lastname) AS [کاربر],
    ua.title AS [عنوان],
    ua.address_text AS [آدرس]
FROM Account.user_address ua
JOIN Account.users u
ON ua.user_id=u.user_id;



PRINT '==================================================';
PRINT '                 Coupons                          ';
PRINT '==================================================';


-- کدهای تخفیف
SELECT
    coupon_id AS [شناسه],
    code AS [کد تخفیف],
    service_type AS [نوع سرویس],
    discount_type AS [نوع تخفیف],
    discount_value AS [مقدار]
FROM Payment.coupons;



PRINT '==================================================';
PRINT '                 Drivers Detail                   ';
PRINT '==================================================';


-- اطلاعات کامل رانندگان و خودرو
SELECT
    d.driver_id AS [راننده],
    CONCAT(u.firstname,' ',u.lastname) AS [نام],
    v.model AS [خودرو],
    v.color AS [رنگ],
    v.plak_num AS [پلاک]
FROM Taxi.drivers d
JOIN Account.users u
ON d.driver_id=u.user_id
LEFT JOIN Taxi.vehicles v
ON d.driver_id=v.driver_id;



PRINT '==================================================';
PRINT '                 Trips Detail                     ';
PRINT '==================================================';


-- اطلاعات کامل سفرها
SELECT
    t.trip_id AS [شماره سفر],

    CONCAT(p.firstname,' ',p.lastname) 
    AS [مسافر],

    ISNULL(CONCAT(d.firstname,' ',d.lastname),N'بدون راننده')
    AS [راننده],

    t.pickup_address AS [مبدا],
    t.dropoff_address AS [مقصد],
    t.status AS [وضعیت],

    t.price AS [قیمت],

    ISNULL(c.code,N'بدون تخفیف')
    AS [کد تخفیف]

FROM Taxi.taxi_trips t

JOIN Account.users p
ON t.passenger_id=p.user_id

LEFT JOIN Account.users d
ON t.driver_id=d.user_id
LEFT JOIN Payment.coupons c
ON t.coupon_id=c.coupon_id;



PRINT '==================================================';
PRINT '                 Fare Rule                        ';
PRINT '==================================================';


-- نرخ پایه
SELECT
    r_id AS [شناسه نرخ],
    base_price AS [قیمت پایه],
    price_per_km AS [هزینه هر کیلومتر],
    price_per_min AS [هزینه هر دقیقه]
FROM Taxi.fare_rule;



PRINT '==================================================';
PRINT '                 Driver Import                    ';
PRINT '==================================================';


-- داده وارد شده از اکسل
IF OBJECT_ID('Taxi.DriverImport','U') IS NOT NULL
BEGIN
    SELECT *
    FROM Taxi.DriverImport;
END

GO
------------------------------------------------------------------------------------------------------
USE DatabaseSQL_Project;
GO

PRINT N'==================================================';
PRINT N'       FUNCTION TESTS                              ';
PRINT N'==================================================';


-----------------------------------------------------
-- تست FN_CanAcceptTrip
-- ایجاد راننده آزمایشی
-----------------------------------------------------

IF EXISTS (SELECT 1 FROM Account.users WHERE phone_num='09139998877')
BEGIN
    DELETE FROM Taxi.vehicles 
    WHERE driver_id IN 
    (
        SELECT user_id FROM Account.users 
        WHERE phone_num='09139998877'
    );

    DELETE FROM Taxi.drivers
    WHERE driver_id IN 
    (
        SELECT user_id FROM Account.users 
        WHERE phone_num='09139998877'
    );

    DELETE FROM Account.user_roles
    WHERE user_id IN
    (
        SELECT user_id FROM Account.users 
        WHERE phone_num='09139998877'
    );

    DELETE FROM Account.users
    WHERE phone_num='09139998877';
END
GO


EXEC Taxi.CreateDriver
N'امیر',
N'علیزاده',
'09139998877',
'amir@gmail.com',
'hash123',
'9988776655',
'1270001122';
GO


DECLARE @NewDriverID INT;

SELECT @NewDriverID=user_id
FROM Account.users
WHERE phone_num='09139998877';


PRINT N'وضعیت راننده قبل از ثبت خودرو';

SELECT 
Taxi.FN_CanAcceptTrip(@NewDriverID)
AS CanAcceptTrip;


UPDATE Taxi.drivers
SET is_online=1
WHERE driver_id=@NewDriverID;


EXEC Taxi.SP_RegisterVehicle
'09139998877',
N'تندر 90',
N'سفید',
N'99ب999-ایران99';


PRINT N'وضعیت راننده بعد از ثبت خودرو';


SELECT 
Taxi.FN_CanAcceptTrip(@NewDriverID)
AS CanAcceptTrip;

GO



-----------------------------------------------------
-- تست نزدیک‌ترین رانندگان
-----------------------------------------------------

PRINT N'--- Near Drivers ---';


SELECT *
FROM Taxi.FN_NearDrivers
(
32.654600,
51.668000
)
ORDER BY Distance;

GO



-----------------------------------------------------
-- تست FN_DriverAverageRate
-----------------------------------------------------

PRINT N'--- Driver Average Rate ---';


DECLARE @RezaID INT;


SELECT @RezaID=user_id
FROM Account.users
WHERE phone_num='09111111113';


SELECT
@RezaID AS DriverID,
N'رضا مرادی' AS DriverName,
Taxi.FN_DriverAverageRate(@RezaID)
AS AverageRate;


GO



-----------------------------------------------------
-- تست آنلاین / آفلاین راننده
-----------------------------------------------------

DECLARE @DriverID INT;


SELECT @DriverID=user_id
FROM Account.users
WHERE phone_num='09111111113';


UPDATE Taxi.drivers
SET is_online=0
WHERE driver_id=@DriverID;


SELECT
driver_id,
is_online,
Taxi.FN_CanAcceptTrip(driver_id)
AS CanAcceptTrip
FROM Taxi.drivers
WHERE driver_id=@DriverID;



UPDATE Taxi.drivers
SET is_online=1
WHERE driver_id=@DriverID;

GO





PRINT N'==================================================';
PRINT N'                 VIEW TESTS                       ';
PRINT N'==================================================';



-- اطلاعات مسافر برای راننده

SELECT *
FROM Taxi.VW_DriverPassengerView
WHERE PassengerPhone='09111111114';


GO


-- سفرهای فعال مدیر

SELECT *
FROM Taxi.VW_DriverCurrentTrip;


GO


-- امتیاز راننده رضا

SELECT *
FROM Taxi.VW_DriverRating
WHERE driver_id=3;


GO


-- تاریخچه سفرها

SELECT *
FROM Taxi.VW_TripHistory
ORDER BY created_at DESC;


GO


-- رانندگان آنلاین

SELECT *
FROM Taxi.VW_OnlineDrivers;


GO

USE DatabaseSQL_Project;
GO


PRINT '==================================================';
PRINT '          STORED PROCEDURE TESTS                  ';
PRINT '==================================================';


-- ایجاد یک راننده تست جدید فقط برای تست خودرو
IF NOT EXISTS (
SELECT 1 FROM Account.users 
WHERE phone_num='09128888888'
)
BEGIN

EXEC Taxi.CreateDriver
N'رضا',
N'تست',
'09128888888',
'test.driver@gmail.com',
'hash',
'8899776655',
'0011223344';

END
GO


DECLARE @TestDriverID INT;

SELECT @TestDriverID=user_id
FROM Account.users
WHERE phone_num='09128888888';


-- ثبت خودرو برای راننده جدید
IF NOT EXISTS(
SELECT 1 FROM Taxi.vehicles
WHERE driver_id=@TestDriverID
)
BEGIN

EXEC Taxi.SP_RegisterVehicle
'09128888888',
N'تیبا',
N'سفید',
N'44الف111-ایران88';

END
GO



-- تست ثبت سفر جدید
EXEC Taxi.SP_RequestTrip
'09111111111',
N'خیابان فردوسی',
N'پل فلزی',
32.650000,
51.665000,
32.640000,
51.670000,
45000,
NULL;


-- قبول سفر توسط راننده موجود
EXEC Taxi.SP_AcceptTrip
'09111111113',
'09111111111';



-- تغییر وضعیت درست
EXEC Taxi.SP_UpdateTripStatus
'09111111111',
'Arrived';


EXEC Taxi.SP_UpdateTripStatus
'09111111111',
'OnTrip';


EXEC Taxi.SP_UpdateTripStatus
'09111111111',
'Completed';


GO



PRINT '==================================================';
PRINT '              LOG / TRIGGER TESTS                 ';
PRINT '==================================================';



-- بررسی لاگ‌ها
SELECT TOP 10 *
FROM Taxi.taxi_log_activity
ORDER BY log_id DESC;



-- تست ثبت پیام بعد از سفر
EXEC Taxi.SP_AddReviewAndMessage
'09111111111',
5,
N'راننده عالی بود',
NULL,
'09111111111';


SELECT TOP 5 *
FROM Taxi.taxi_log_activity
ORDER BY log_id DESC;



-- تست پیام راننده
EXEC Taxi.SP_AddReviewAndMessage
'09111111111',
0,
NULL,
N'به مقصد رسیدم',
'09111111113';


SELECT TOP 5 *
FROM Taxi.taxi_log_activity
ORDER BY log_id DESC;



-- وضعیت رانندگان آنلاین
SELECT 
driver_id,
is_online
FROM Taxi.drivers;



-- تست تابع نزدیک‌ترین راننده‌ها

SELECT *
FROM Taxi.FN_NearDrivers
(
32.654600,
51.668000
)
ORDER BY Distance;



-- تست میانگین امتیاز رضا

SELECT 
Taxi.FN_DriverAverageRate(3)
AS AverageRate;



-- تست شرایط قبول سفر

SELECT
driver_id,
Taxi.FN_CanAcceptTrip(driver_id)
AS CanAcceptTrip
FROM Taxi.drivers;



GO

-------------------------------------------------------تست تریگر های تعامل-----
----تست غذا

EXEC Food.SP_CreateFoodOrder
2,
1,
1,
200000,
NULL,
0;
SELECT * FROM Payment.payments;
 
 ---تست تاکسی 
EXEC Taxi.SP_RequestTrip
'09111111111',
N'چهارباغ',
N'سی و سه پل',
32.6500,
51.6600,
32.6400,
51.6700,
50000,
NULL;

EXEC Taxi.SP_AcceptTrip
'09111111113',
'09111111111';

EXEC Taxi.SP_UpdateTripStatus
'09111111111',
'Arrived';


EXEC Taxi.SP_UpdateTripStatus
'09111111111',
'OnTrip';


EXEC Taxi.SP_UpdateTripStatus
'09111111111',
'Completed';

SELECT *
FROM Payment.payments
ORDER BY payment_id DESC;

---تست اعلان
UPDATE Payment.payments
SET status='Success'
WHERE payment_id=1;
SELECT * FROM Account.notif;


SELECT * FROM Payment.payments;

SELECT * FROM Account.notif;

SELECT * FROM Payment.payment_log;





--تست نهایی کامل 
USE DatabaseSQL_Project;
GO

DECLARE @SaraUserID INT;
DECLARE @RezaDriverID INT;
DECLARE @FoodCustomerID INT;

SELECT @SaraUserID = user_id FROM Account.users u WHERE u.phone_num = '09111111112';
SELECT @RezaDriverID = user_id FROM Account.users u WHERE u.phone_num = '09111111113';

SET @FoodCustomerID = @SaraUserID; 

IF @SaraUserID IS NOT NULL
BEGIN
    EXEC Payment.SP_DepositWallet 
        @UserID = @SaraUserID, 
        @Amount = 50000.00, 
        @Description = N'شارژ اولیه  برای سفر ';
END;

--  شارژ کیف پول برای سفارش غذا
IF @FoodCustomerID IS NOT NULL
BEGIN
    EXEC Payment.SP_DepositWallet 
        @UserID = @FoodCustomerID, 
        @Amount = 500000.00, 
        @Description = N'شارژ اولیه  برای سفارش غذا';
END;

SELECT user_id, balance FROM Payment.wallets WHERE user_id IN (@SaraUserID, @FoodCustomerID);
GO

EXEC Taxi.SP_RequestTrip '09111111112',           -- تلفن سارا
N'خیابان مرداویج',         -- مبدا
  N'چهارباغ بالا',          -- مقصد
  32.6352, 51.6695,        -- مختصات مبدا
  32.6510, 51.6670,        -- مختصات مقصد
  22000,                   -- هزینه پایه
  'TAXI15';                -- کد تخفیف

EXEC Taxi.SP_AcceptTrip '09111111113', '09111111112';

EXEC Taxi.SP_UpdateTripStatus '09111111112', 'Arrived';

EXEC Taxi.SP_UpdateTripStatus '09111111112', 'OnTrip';

EXEC Taxi.SP_UpdateTripStatus '09111111112', 'Completed';
GO

DECLARE @DynamicTripID INT;
DECLARE @TripPrice DECIMAL(18,2);
DECLARE @PassengerID INT;

SELECT @PassengerID = user_id FROM Account.users u WHERE u.phone_num = '09111111112';

SELECT TOP 1 
    @DynamicTripID = trip_id,
    @TripPrice = price
FROM Taxi.taxi_trips 
WHERE passenger_id = @PassengerID 
ORDER BY trip_id DESC;

SELECT * FROM Payment.payments WHERE trip_id = @DynamicTripID;

IF @DynamicTripID IS NOT NULL
BEGIN
    EXEC Payment.SP_PayFromWallet 
        @UserID = @PassengerID, 
        @Amount = @TripPrice, 
        @ServiceType = 'Taxi', 
        @TripID = @DynamicTripID, 
        @Description = N'پرداخت هزینه سفر انلاین سارا';
END;

SELECT * FROM Payment.payments WHERE trip_id = @DynamicTripID;
GO



DECLARE @DynamicCustomerID INT;
SELECT @DynamicCustomerID = user_id FROM Account.users u WHERE u.phone_num = '09111111112';

INSERT INTO Food.food_orders (customer_id, restaurant_id, address_id, coupon_id, total_amount, status)
VALUES (@DynamicCustomerID, 1, 2, 1, 320000, 'Pending'); 

DECLARE @DynamicOrderID INT = SCOPE_IDENTITY();

INSERT INTO Food.order_items (order_id, food_id, quantity, unit_price)
VALUES 
(@DynamicOrderID, 1, 1, 320000),  
(@DynamicOrderID, 4, 1, 45000);   

DECLARE @DynamicOrderItemID INT;
SELECT @DynamicOrderItemID = f.order_id
FROM Food.order_items f
WHERE order_id = @DynamicOrderID AND food_id = 1;

IF @DynamicOrderItemID IS NOT NULL
BEGIN
    INSERT INTO Food.order_item_options (order_item_id, option_id, price)
    VALUES (@DynamicOrderItemID, 1, 40000); 
END;

UPDATE Food.food_orders SET status = 'Preparing' WHERE order_id = @DynamicOrderID;
UPDATE Food.food_orders SET status = 'ReadyForPickup' WHERE order_id = @DynamicOrderID;

EXEC Payment.SP_PayFromWallet 
    @UserID = @DynamicCustomerID, 
    @Amount = 320000, 
    @ServiceType = 'Food', 
    @OrderID = @DynamicOrderID, 
    @Description = N'پرداخت انلاین سفارش غذا با شناسه پویا';

UPDATE Food.food_orders SET status = 'Delivered' WHERE order_id = @DynamicOrderID;

INSERT INTO Food.food_reviews (customer_id, restaurant_id, rating, comment)
VALUES (@DynamicCustomerID, 1, 5, N'کیفیت غذا عالی بود و خیلی سریع رسید.');

SELECT * FROM Food.food_orders WHERE order_id = @DynamicOrderID;
SELECT * FROM Payment.payments WHERE order_id = @DynamicOrderID;
GO



DECLARE @DynamicCustomerID INT;
SELECT @DynamicCustomerID = user_id FROM Account.users u WHERE u.phone_num = '09111111112';

DECLARE @DynamicPaymentID INT;
SELECT TOP 1 @DynamicPaymentID = payment_id 
FROM Payment.payments 
WHERE user_id = @DynamicCustomerID AND status = 'Success' 
ORDER BY payment_id DESC;

IF @DynamicPaymentID IS NOT NULL
BEGIN
    EXEC Payment.SP_RefundPayment 
        @PaymentID = @DynamicPaymentID, 
        @Description = N'مرجوعی پویا جهت تست سیستم';
END;

SELECT balance FROM Payment.wallets WHERE user_id = @DynamicCustomerID;
SELECT * FROM Payment.payment_log ORDER BY log_id DESC;
GO