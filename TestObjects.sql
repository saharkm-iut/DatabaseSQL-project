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
