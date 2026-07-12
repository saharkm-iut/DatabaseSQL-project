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

