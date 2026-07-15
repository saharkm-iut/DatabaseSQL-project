USE Data_test;
GO

-- ==========================================
-- بخش اول: تعریف متغیرها، یافتن کاربران و شارژ کیف پول
-- ==========================================
DECLARE @SaraUserID INT;
DECLARE @RezaDriverID INT;
DECLARE @FoodCustomerID INT;

-- ۱. استخراج شناسه سارا و راننده رضا بر اساس شماره تلفن آن‌ها
SELECT @SaraUserID = user_id FROM Account.users u WHERE u.phone_num = '09111111112';
SELECT @RezaDriverID = user_id FROM Account.users u WHERE u.phone_num = '09111111113';

-- در نظر گرفتن سارا به عنوان مشتری غذا برای فرآیند تست
SET @FoodCustomerID = @SaraUserID; 

-- ۲. شارژ کیف پول سارا برای سفر
IF @SaraUserID IS NOT NULL
BEGIN
    EXEC Payment.SP_DepositWallet 
        @UserID = @SaraUserID, 
        @Amount = 50000.00, 
        @Description = N'شارژ اولیه پویا برای سفر سارا';
END;

-- ۳. شارژ کیف پول برای سفارش غذا
IF @FoodCustomerID IS NOT NULL
BEGIN
    EXEC Payment.SP_DepositWallet 
        @UserID = @FoodCustomerID, 
        @Amount = 500000.00, 
        @Description = N'شارژ اولیه پویا برای سفارش غذا';
END;

-- نمایش وضعیت موجودی‌ها
SELECT user_id, balance FROM Payment.wallets WHERE user_id IN (@SaraUserID, @FoodCustomerID);
GO


-- ==========================================
-- بخش دوم: سناریوی کامل درخواست، انجام و پرداخت سفر (تاکسی)
-- ==========================================
-- ۱. ثبت درخواست سفر توسط سارا
EXEC Taxi.SP_RequestTrip 
  '09111111112',           -- تلفن سارا
  N'خیابان مرداویج',         -- مبدا
  N'چهارباغ بالا',          -- مقصد
  32.6352, 51.6695,        -- مختصات مبدا
  32.6510, 51.6670,        -- مختصات مقصد
  22000,                   -- هزینه پایه
  'TAXI15';                -- کد تخفیف

-- ۲. رضا سفر سارا را قبول می‌کند
EXEC Taxi.SP_AcceptTrip '09111111113', '09111111112';

-- ۳. رضا به مبدا می‌رسد
EXEC Taxi.SP_UpdateTripStatus '09111111112', 'Arrived';

-- ۴. سفر آغاز می‌شود
EXEC Taxi.SP_UpdateTripStatus '09111111112', 'OnTrip';

-- ۵. سفر پایان می‌یابد 
EXEC Taxi.SP_UpdateTripStatus '09111111112', 'Completed';
GO

-- ۶. دریافت اطلاعات آخرین سفر و تسویه حساب آنلاین
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

-- ۷. بررسی وضعیت پرداخت موقت (Pending) که توسط تریگر ایجاد شده است
SELECT * FROM Payment.payments WHERE trip_id = @DynamicTripID;

-- ۸. اجرای پروسیجر پرداخت و کسر از کیف پول به صورت کاملاً پویا
IF @DynamicTripID IS NOT NULL
BEGIN
    EXEC Payment.SP_PayFromWallet 
        @UserID = @PassengerID, 
        @Amount = @TripPrice, 
        @ServiceType = 'Taxi', 
        @TripID = @DynamicTripID, 
        @Description = N'پرداخت هزینه سفر آنلاین سارا';
END;

-- ۹. بررسی نهایی وضعیت پرداخت و نوتیفیکیشن
SELECT * FROM Payment.payments WHERE trip_id = @DynamicTripID;
SELECT * FROM Account.notif WHERE user_id = @PassengerID;
GO


-- ==========================================
-- بخش سوم: سناریوی کامل ثبت و پرداخت سفارش غذا
-- ==========================================
DECLARE @DynamicCustomerID INT;
SELECT @DynamicCustomerID = user_id FROM Account.users u WHERE u.phone_num = '09111111112';

-- ۱. ایجاد سفارش با وضعیت Pending
INSERT INTO Food.food_orders (customer_id, restaurant_id, address_id, coupon_id, total_amount, status)
VALUES (@DynamicCustomerID, 1, 2, 1, 320000, 'Pending'); 

-- ۲. دریافت شناسه سفارش تولید شده به صورت پویا
DECLARE @DynamicOrderID INT = SCOPE_IDENTITY();

-- ۳. ثبت آیتم‌های سفارش با شناسه سفارش پویا (جلوگیری از تداخل با سفارش‌های قدیمی)
INSERT INTO Food.order_items (order_id, food_id, quantity, unit_price)
VALUES 
(@DynamicOrderID, 1, 1, 320000),  
(@DynamicOrderID, 4, 1, 45000);   

-- ۴. دریافت دقیق شناسه آیتم پیتزا ثبت شده در همین سفارش برای تخصیص آپشن
DECLARE @DynamicOrderItemID INT;
SELECT @DynamicOrderItemID = f.order_id
FROM Food.order_items f
WHERE order_id = @DynamicOrderID AND food_id = 1;

-- ۵. ثبت آپشن‌های غذا برای آیتم تازه ایجاد شده (جلوگیری از خطای UQ_item_option)
IF @DynamicOrderItemID IS NOT NULL
BEGIN
    INSERT INTO Food.order_item_options (order_item_id, option_id, price)
    VALUES (@DynamicOrderItemID, 1, 40000); 
END;

-- ۶. تغییر وضعیت‌های سفارش در سیستم
UPDATE Food.food_orders SET status = 'Preparing' WHERE order_id = @DynamicOrderID;
UPDATE Food.food_orders SET status = 'ReadyForPickup' WHERE order_id = @DynamicOrderID;

-- ۷. تسویه حساب و پرداخت آنلاین بر اساس شناسه سفارش پویا
EXEC Payment.SP_PayFromWallet 
    @UserID = @DynamicCustomerID, 
    @Amount = 320000, 
    @ServiceType = 'Food', 
    @OrderID = @DynamicOrderID, 
    @Description = N'پرداخت آنلاین سفارش غذا با شناسه پویا';

-- ۸. تحویل نهایی سفارش
UPDATE Food.food_orders SET status = 'Delivered' WHERE order_id = @DynamicOrderID;

-- ۹. ثبت نظر مشتری
INSERT INTO Food.food_reviews (customer_id, restaurant_id, rating, comment)
VALUES (@DynamicCustomerID, 1, 5, N'کیفیت غذا عالی بود و خیلی سریع رسید.');

-- ۱۰. بررسی نتایج نهایی تراکنش غذا
SELECT * FROM Food.food_orders WHERE order_id = @DynamicOrderID;
SELECT * FROM Payment.payments WHERE order_id = @DynamicOrderID;
GO


-- ==========================================
-- بخش چهارم: تست سناریوی مرجوعی (Refund) و لاگ‌های سیستم
-- ==========================================
DECLARE @DynamicCustomerID INT;
SELECT @DynamicCustomerID = user_id FROM Account.users u WHERE u.phone_num = '09111111112';

-- ۱. یافتن آخرین پرداخت موفق کاربر به صورت پویا جهت تست مرجوعی
DECLARE @DynamicPaymentID INT;
SELECT TOP 1 @DynamicPaymentID = payment_id 
FROM Payment.payments 
WHERE user_id = @DynamicCustomerID AND status = 'Success' 
ORDER BY payment_id DESC;

-- ۲. بازگشت وجه به کیف پول با شناسه استخراج شده
IF @DynamicPaymentID IS NOT NULL
BEGIN
    EXEC Payment.SP_RefundPayment 
        @PaymentID = @DynamicPaymentID, 
        @Description = N'مرجوعی پویا جهت تست سیستم';
END;

-- ۳. نمایش موجودی نهایی کیف پول و بررسی لاگ‌های ثبت شده در سیستم پرداخت
SELECT balance FROM Payment.wallets WHERE user_id = @DynamicCustomerID;
SELECT * FROM Payment.payment_log ORDER BY log_id DESC;
GO