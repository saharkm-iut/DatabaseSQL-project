USE DatabaseSQL_Project;
GO

CREATE VIEW Food.vw_RestaurantMenu
AS
SELECT
    r.restaurant_id,
    r.name AS restaurant_name,
    c.category_id,
    c.name AS category_name,
    f.food_id,
    f.name AS food_name,
    f.price,
    f.stock,
    f.is_available
FROM Food.restaurants r
JOIN Food.food_categories c
    ON r.restaurant_id = c.restaurant_id
JOIN Food.foods f
    ON c.category_id = f.category_id;
GO


USE DatabaseSQL_Project;
GO

CREATE VIEW Food.vw_CustomerOrders
AS
SELECT
    o.order_id,
    u.firstname + N' ' + u.lastname AS customer_name,
    r.name AS restaurant_name,
    o.total_amount,
    o.status,
    o.created_at
FROM Food.food_orders o
JOIN Account.users u
    ON o.customer_id = u.user_id
JOIN Food.restaurants r
    ON o.restaurant_id = r.restaurant_id;
GO



USE DatabaseSQL_Project;
GO

CREATE VIEW Food.vw_RestaurantRatings
AS
SELECT
    r.restaurant_id,
    r.name AS restaurant_name,
    COUNT(fr.review_id) AS total_reviews,
    CAST(AVG(CAST(fr.rating AS DECIMAL(4,2))) AS DECIMAL(4,2)) AS average_rating
FROM Food.restaurants r
LEFT JOIN Food.food_reviews fr
    ON r.restaurant_id = fr.restaurant_id
GROUP BY
    r.restaurant_id,
    r.name;
GO



USE DatabaseSQL_Project;
GO

CREATE VIEW Food.vw_AvailableFoods
AS
SELECT
    r.restaurant_id,
    r.name AS restaurant_name,
    c.name AS category_name,
    f.food_id,
    f.name AS food_name,
    f.description,
    f.price,
    f.stock
FROM Food.restaurants r
JOIN Food.food_categories c
    ON r.restaurant_id = c.restaurant_id
JOIN Food.foods f
    ON c.category_id = f.category_id
WHERE
    r.is_active = 1
    AND f.is_available = 1
    AND f.stock > 0;
GO


USE DatabaseSQL_Project;
GO

CREATE VIEW Food.vw_OrderDetails
AS
SELECT
    o.order_id,
    u.firstname + N' ' + u.lastname AS customer_name,
    r.name AS restaurant_name,
    f.name AS food_name,
    oi.quantity,
    oi.unit_price,
    (oi.quantity * oi.unit_price) AS item_total,
    o.total_amount,
    o.status,
    o.created_at
FROM Food.food_orders o
JOIN Account.users u
    ON o.customer_id = u.user_id
JOIN Food.restaurants r
    ON o.restaurant_id = r.restaurant_id
JOIN Food.order_items oi
    ON o.order_id = oi.order_id
JOIN Food.foods f
    ON oi.food_id = f.food_id;
GO


USE DatabaseSQL_Project;
GO

CREATE VIEW Food.vw_RestaurantSales
AS
SELECT
    r.restaurant_id,
    r.name AS restaurant_name,
    COUNT(o.order_id) AS delivered_orders,
    ISNULL(SUM(o.total_amount),0) AS total_sales,
    ISNULL(AVG(o.total_amount),0) AS average_order_amount
FROM Food.restaurants r
LEFT JOIN Food.food_orders o
    ON r.restaurant_id = o.restaurant_id
    AND o.status = 'Delivered'
GROUP BY
    r.restaurant_id,
    r.name;
GO

/*functions*/

USE DatabaseSQL_Project;
GO

CREATE FUNCTION Payment.fn_ValidateCoupon
(
    @CouponCode VARCHAR(50)
)
RETURNS BIT
AS
BEGIN
    DECLARE @Result BIT = 0;

    IF EXISTS
    (
        SELECT 1
        FROM Payment.coupons
        WHERE code = @CouponCode
          AND expiry_date >= GETDATE()
          AND service_type IN ('Food','Global')
    )
        SET @Result = 1;

    RETURN @Result;
END;
GO


USE DatabaseSQL_Project;
GO

CREATE FUNCTION Food.fn_CalculateDeliveryFee
(
    @OrderAmount DECIMAL(18,2)
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @DeliveryFee DECIMAL(18,2);

    IF @OrderAmount >= 500000
        SET @DeliveryFee = 0;
    ELSE IF @OrderAmount >= 300000
        SET @DeliveryFee = 20000;
    ELSE
        SET @DeliveryFee = 40000;

    RETURN @DeliveryFee;
END;
GO

USE DatabaseSQL_Project;
GO

CREATE FUNCTION Food.fn_CalculateFinalAmount
(
    @OrderAmount DECIMAL(18,2),
    @DiscountAmount DECIMAL(18,2)
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @DeliveryFee DECIMAL(18,2);
    DECLARE @FinalAmount DECIMAL(18,2);

    SET @DeliveryFee = Food.fn_CalculateDeliveryFee(@OrderAmount);

    SET @FinalAmount = @OrderAmount + @DeliveryFee - @DiscountAmount;

    IF @FinalAmount < 0
        SET @FinalAmount = 0;

    RETURN @FinalAmount;
END;
GO

USE DatabaseSQL_Project;
GO

CREATE FUNCTION Food.fn_TotalOrderPrice
(
    @OrderID INT
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @Total DECIMAL(18,2);

    SELECT @Total = ISNULL(SUM(quantity * unit_price), 0)
    FROM Food.order_items
    WHERE order_id = @OrderID;

    RETURN @Total;
END;
GO

USE DatabaseSQL_Project;
GO

CREATE FUNCTION Food.fn_RestaurantAverageRating
(
    @RestaurantID INT
)
RETURNS DECIMAL(4,2)
AS
BEGIN
    DECLARE @AverageRating DECIMAL(4,2);

    SELECT @AverageRating =
        CAST(ISNULL(AVG(CAST(rating AS DECIMAL(4,2))),0) AS DECIMAL(4,2))
    FROM Food.food_reviews
    WHERE restaurant_id = @RestaurantID;

    RETURN @AverageRating;
END;
GO

/*triggers*/
USE DatabaseSQL_Project;
GO

CREATE TRIGGER Food.trg_DecreaseFoodStock
ON Food.order_items
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE f
    SET f.stock = f.stock - i.quantity
    FROM Food.foods AS f
    INNER JOIN inserted AS i
        ON f.food_id = i.food_id;
END;
GO

USE DatabaseSQL_Project;
GO

CREATE TRIGGER Food.trg_RestoreFoodStock
ON Food.order_items
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE f
    SET f.stock = f.stock + d.quantity
    FROM Food.foods AS f
    INNER JOIN deleted AS d
        ON f.food_id = d.food_id;
END;
GO



USE DatabaseSQL_Project;
GO

CREATE TRIGGER Food.trg_LogOrderStatusChange
ON Food.food_orders
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Food.food_log
    (
        order_id,
        user_id,
        action_type,
        table_name,
        record_id,
        description
    )
    SELECT
        i.order_id,
        i.customer_id,
        N'UPDATE',
        N'food_orders',
        i.order_id,
        N'وضعیت سفارش از "' + d.status +
        N'" به "' + i.status + N'" تغییر یافت.'
    FROM inserted i
    INNER JOIN deleted d
        ON i.order_id = d.order_id
    WHERE ISNULL(i.status,'') <> ISNULL(d.status,'');
END;
GO

/*procejers*/
USE DatabaseSQL_Project;
GO

CREATE OR ALTER PROCEDURE Food.SP_CreateFoodOrder
(
    @CustomerID INT,
    @RestaurantID INT,
    @AddressID INT,
    @OrderAmount DECIMAL(18,2),
    @CouponCode VARCHAR(50)=NULL,
    @DiscountAmount DECIMAL(18,2)=0
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @CouponID INT = NULL;
        DECLARE @FinalAmount DECIMAL(18,2);

        IF @CouponCode IS NOT NULL
        BEGIN
            IF Payment.fn_ValidateCoupon(@CouponCode)=1
            BEGIN
                SELECT @CouponID=coupon_id
                FROM Payment.coupons
                WHERE code=@CouponCode;
            END
        END

        SET @FinalAmount=
            Food.fn_CalculateFinalAmount
            (
                @OrderAmount,
                @DiscountAmount
            );

        INSERT INTO Food.food_orders
        (
            customer_id,
            restaurant_id,
            address_id,
            coupon_id,
            total_amount,
            status
        )
        VALUES
        (
            @CustomerID,
            @RestaurantID,
            @AddressID,
            @CouponID,
            @FinalAmount,
            'Pending'
        );

        COMMIT;

        SELECT
            SCOPE_IDENTITY() AS OrderID,
            @FinalAmount AS FinalAmount,
            N'Food Order Created Successfully' AS Message;

    END TRY

    BEGIN CATCH

        ROLLBACK;
        THROW;

    END CATCH
END;
GO

USE DatabaseSQL_Project;
GO

CREATE OR ALTER PROCEDURE Food.SP_UpdateFoodOrderStatus
(
    @OrderID INT,
    @NewStatus VARCHAR(20)
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS
        (
            SELECT 1
            FROM Food.food_orders
            WHERE order_id = @OrderID
        )
        BEGIN
            RAISERROR(N'سفارش مورد نظر یافت نشد.',16,1);
            ROLLBACK;
            RETURN;
        END

        UPDATE Food.food_orders
        SET status = @NewStatus
        WHERE order_id = @OrderID;

        COMMIT;

        SELECT
            @OrderID AS OrderID,
            @NewStatus AS NewStatus,
            N'Order Status Updated Successfully' AS Message;

    END TRY

    BEGIN CATCH

        ROLLBACK;
        THROW;

    END CATCH
END;
GO
USE DatabaseSQL_Project;
GO

CREATE OR ALTER PROCEDURE Food.SP_AddFoodReview
(
    @CustomerID INT,
    @RestaurantID INT,
    @Rating INT,
    @Comment NVARCHAR(1000) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- بررسی وجود مشتری
        IF NOT EXISTS
        (
            SELECT 1
            FROM Account.users
            WHERE user_id = @CustomerID
        )
        BEGIN
            RAISERROR(N'مشتری یافت نشد.',16,1);
            ROLLBACK;
            RETURN;
        END

        -- بررسی وجود رستوران
        IF NOT EXISTS
        (
            SELECT 1
            FROM Food.restaurants
            WHERE restaurant_id = @RestaurantID
        )
        BEGIN
            RAISERROR(N'رستوران یافت نشد.',16,1);
            ROLLBACK;
            RETURN;
        END

        -- ثبت نظر
        INSERT INTO Food.food_reviews
        (
            customer_id,
            restaurant_id,
            rating,
            comment
        )
        VALUES
        (
            @CustomerID,
            @RestaurantID,
            @Rating,
            @Comment
        );

        COMMIT;

        SELECT
            SCOPE_IDENTITY() AS ReviewID,
            N'Food Review Added Successfully' AS Message;

    END TRY

    BEGIN CATCH

        ROLLBACK;
        THROW;

    END CATCH
END;
GO
USE DatabaseSQL_Project;
GO

CREATE OR ALTER PROCEDURE Food.SP_AddOrderItem
(
    @OrderID INT,
    @FoodID INT,
    @Quantity INT
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @UnitPrice DECIMAL(18,2);

        IF NOT EXISTS
        (
            SELECT 1
            FROM Food.food_orders
            WHERE order_id=@OrderID
        )
        BEGIN
            RAISERROR(N'سفارش یافت نشد.',16,1);
            ROLLBACK;
            RETURN;
        END

        SELECT @UnitPrice=price
        FROM Food.foods
        WHERE food_id=@FoodID;

        IF @UnitPrice IS NULL
        BEGIN
            RAISERROR(N'غذا یافت نشد.',16,1);
            ROLLBACK;
            RETURN;
        END

        INSERT INTO Food.order_items
        (
            order_id,
            food_id,
            quantity,
            unit_price
        )
        VALUES
        (
            @OrderID,
            @FoodID,
            @Quantity,
            @UnitPrice
        );

        UPDATE Food.food_orders
        SET total_amount =
            Food.fn_TotalOrderPrice(@OrderID)
        WHERE order_id=@OrderID;

        COMMIT;

        SELECT
            @OrderID AS OrderID,
            N'Order Item Added Successfully' AS Message;

    END TRY

    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END;
GO


/*=========================================================
                    PAYMENT PROCEDURES
=========================================================*/
GO
/*charge wallet*/
CREATE OR ALTER PROCEDURE Payment.SP_DepositWallet
(
    @UserID INT,
    @Amount DECIMAL(18,2),
    @Description NVARCHAR(300) = N'Wallet Deposit'
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @Amount <= 0
    BEGIN
        RAISERROR(N'مبلغ باید بیشتر از صفر باشد.',16,1);
        RETURN;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM Payment.wallets
        WHERE user_id=@UserID
    )
    BEGIN
        RAISERROR(N'کیف پول برای این کاربر وجود ندارد.',16,1);
        RETURN;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE Payment.wallets
        SET
            balance = balance + @Amount,
            updated_at = SYSDATETIME()
        WHERE user_id=@UserID;

        INSERT INTO Payment.wallet_transactions
        (
            wallet_id,
            amount,
            transaction_type,
            description
        )
        SELECT
            wallet_id,
            @Amount,
            'Deposit',
            @Description
        FROM Payment.wallets
        WHERE user_id=@UserID;

        COMMIT;
    END TRY

    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END;
GO


/* check and take money*/
CREATE OR ALTER PROCEDURE Payment.SP_PayFromWallet
(
    @UserID INT,
    @Amount DECIMAL(18,2),
    @ServiceType VARCHAR(10),
    @OrderID INT = NULL,
    @TripID INT = NULL,
    @Description NVARCHAR(300)=N'Wallet Payment'
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @WalletID INT;
    DECLARE @Balance DECIMAL(18,2);

    SELECT
        @WalletID = wallet_id,
        @Balance = balance
    FROM Payment.wallets
    WHERE user_id = @UserID;

    IF @WalletID IS NULL
    BEGIN
        RAISERROR(N'کیف پول یافت نشد.',16,1);
        RETURN;
    END;

    IF @Balance < @Amount
    BEGIN
        RAISERROR(N'موجودی کیف پول کافی نیست.',16,1);
        RETURN;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE Payment.wallets
        SET
            balance = balance - @Amount,
            updated_at = SYSDATETIME()
        WHERE wallet_id = @WalletID;

        INSERT INTO Payment.wallet_transactions
        (
            wallet_id,
            amount,
            transaction_type,
            description
        )
        VALUES
        (
            @WalletID,
            @Amount,
            'Withdraw',
            @Description
        );

        INSERT INTO Payment.payments
        (
            user_id,
            service_type,
            order_id,
            trip_id,
            amount,
            payment_method,
            status
        )
        VALUES
        (
            @UserID,
            @ServiceType,
            @OrderID,
            @TripID,
            @Amount,
            'Wallet',
            'Success'
        );

        COMMIT;
    END TRY

    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END;
GO




CREATE OR ALTER PROCEDURE Payment.SP_RefundPayment
(
    @PaymentID INT,
    @Description NVARCHAR(300)=N'Refund Payment'
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UserID INT;
    DECLARE @WalletID INT;
    DECLARE @Amount DECIMAL(18,2);

    SELECT
        @UserID = user_id,
        @Amount = amount
    FROM Payment.payments
    WHERE payment_id = @PaymentID
      AND status = 'Success';

    IF @UserID IS NULL
    BEGIN
        RAISERROR(N'پرداخت معتبر یافت نشد.',16,1);
        RETURN;
    END;

    SELECT @WalletID = wallet_id
    FROM Payment.wallets
    WHERE user_id = @UserID;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE Payment.wallets
        SET
            balance = balance + @Amount,
            updated_at = SYSDATETIME()
        WHERE wallet_id = @WalletID;

        INSERT INTO Payment.wallet_transactions
        (
            wallet_id,
            amount,
            transaction_type,
            description
        )
        VALUES
        (
            @WalletID,
            @Amount,
            'Refund',
            @Description
        );

        UPDATE Payment.payments
        SET status = 'Failed'
        WHERE payment_id = @PaymentID;

        COMMIT;
    END TRY

    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END;
GO


/*  payment triggers */

/*ثبت پرداخت*/
CREATE OR ALTER TRIGGER Payment.TR_Payment_InsertLog
ON Payment.payments
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Payment.payment_log
    (
        user_id,
        pay_id,
        action_type,
        table_name,
        record_id,
        description
    )
    SELECT
        user_id,
        payment_id,
        'INSERT',
        'payments',
        payment_id,
        N'پرداخت جدید ثبت شد.'
    FROM inserted;
END;
GO

/*ثبت تغییر وضعیت پرداخت */
CREATE OR ALTER TRIGGER Payment.TR_Payment_StatusLog
ON Payment.payments
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Payment.payment_log
    (
        user_id,
        pay_id,
        action_type,
        table_name,
        record_id,
        description
    )
    SELECT
        i.user_id,
        i.payment_id,
        'UPDATE',
        'payments',
        i.payment_id,
        N'وضعیت پرداخت از '
        + d.status
        + N' به '
        + i.status
        + N' تغییر یافت.'
    FROM inserted i
    JOIN deleted d
        ON i.payment_id = d.payment_id
    WHERE i.status <> d.status;
END;
GO
/*ثبت تراکنش کیف پول */
CREATE OR ALTER TRIGGER Payment.TR_WalletTransaction_Log
ON Payment.wallet_transactions
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Payment.payment_log
    (
        user_id,
        action_type,
        table_name,
        record_id,
        description
    )
    SELECT
        w.user_id,
        i.transaction_type,
        'wallet_transactions',
        i.transaction_id,
        N'تراکنش کیف پول ثبت شد.'
    FROM inserted i
    JOIN Payment.wallets w
        ON i.wallet_id = w.wallet_id;
END;
GO

/* account*/
CREATE OR ALTER PROCEDURE Account.SP_CreateSupportTicket
(
    @UserID INT,
    @Title NVARCHAR(50),
    @Message NVARCHAR(1000)
)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Account.supp_ticket
    (
        user_id,
        title,
        mess_bod
    )
    VALUES
    (
        @UserID,
        @Title,
        @Message
    );
END;
GO

CREATE OR ALTER PROCEDURE Account.SP_SendNotification
(
    @UserID INT,
    @Title NVARCHAR(50),
    @Message NVARCHAR(1000)
)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Account.notif
    (
        user_id,
        title,
        mess_bod
    )
    VALUES
    (
        @UserID,
        @Title,
        @Message
    );
END;
GO

CREATE OR ALTER PROCEDURE Account.SP_ReadNotification
(
    @NotifID INT
)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Account.notif
    SET is_read = 1
    WHERE notif_id = @NotifID;
END;
GO

CREATE OR ALTER TRIGGER Account.TR_Notification_Log
ON Account.notif
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Account.account_log_activity
    (
        user_id,
        action_type,
        table_name,
        record_id,
        description
    )
    SELECT
        user_id,
        'INSERT',
        'notif',
        notif_id,
        N'اعلان جدید برای کاربر ثبت شد.'
    FROM inserted;
END;
GO

CREATE OR ALTER TRIGGER Account.TR_SupportTicket_Log
ON Account.supp_ticket
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Account.account_log_activity
    (
        user_id,
        action_type,
        table_name,
        record_id,
        description
    )
    SELECT
        user_id,
        'INSERT',
        'supp_ticket',
        tick_id,
        N'تیکت پشتیبانی جدید ثبت شد.'
    FROM inserted;
END;
GO

CREATE OR ALTER TRIGGER Account.TR_TicketStatus_Log
ON Account.supp_ticket
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Account.account_log_activity
    (
        user_id,
        action_type,
        table_name,
        record_id,
        description
    )
    SELECT
        i.user_id,
        'UPDATE',
        'supp_ticket',
        i.tick_id,
        N'وضعیت تیکت از '
        + d.status
        + N' به '
        + i.status
        + N' تغییر یافت.'
    FROM inserted i
    JOIN deleted d
        ON i.tick_id = d.tick_id
    WHERE ISNULL(i.status,'') <> ISNULL(d.status,'');
END;
GO
/* taxi*/
USE DatabaseSQL_Project;
GO

CREATE OR ALTER FUNCTION Taxi.FN_NearDrivers(@Latitude DECIMAL(9,6),@Longitude DECIMAL(9,6))
RETURNS TABLE
AS
RETURN
(SELECT d.driver_id,u.firstname,u.lastname,l.latitude,l.longitude,
--بعد از آن با استفاده از توابع اس کیو آر تی و پاور فاصله تقریبی هر راننده تا موقعیت وارد شده محاسبه میشه. این فاصله در ستونی با نام دیستنس نمایش داده میشه.
SQRT(POWER(l.latitude-@Latitude,2)+POWER(l.longitude-@Longitude,2)) AS Distance
FROM Taxi.live_location_driver l JOIN Taxi.drivers d ON l.driver_id=d.driver_id JOIN Account.users u ON u.user_id=d.driver_id
WHERE d.is_online=1 AND d.is_approved=1);
GO

CREATE OR ALTER FUNCTION Taxi.FN_DriverAverageRate (@DriverID INT)
RETURNS DECIMAL(4,2)
AS
BEGIN
DECLARE @Rate DECIMAL(4,2);
--میانگین امتیازهای ثبت‌شده محاسبه می‌شود
SELECT @Rate=AVG(CAST(r.rating AS DECIMAL(4,2)))
FROM Taxi.trip_review r JOIN Taxi.taxi_trips t ON r.trip_id=t.trip_id
WHERE t.driver_id=@DriverID;
--ممکنه راننده هنوز هیچ سفری انجام نداده باشد و امتیازی نداشته باشد
RETURN ISNULL(@Rate,0);

END;
GO

CREATE OR ALTER FUNCTION Taxi.FN_CanAcceptTrip(@DriverID INT)
RETURNS BIT
AS
BEGIN
DECLARE @Result BIT = 1;
IF NOT EXISTS
--راننده باید آنلاین و تایید شده باشد.
(SELECT 1
FROM Taxi.drivers
WHERE driver_id=@DriverID AND is_online=1 AND is_approved=1)
BEGIN
SET @Result=0;
END
--راننده باید خودروی ثبت‌شده داشته باشد.
IF NOT EXISTS
(SELECT 1
FROM Taxi.vehicles
WHERE driver_id=@DriverID)
 BEGIN
SET @Result=0;
 END
IF EXISTS
--راننده نباید در حال انجام یک سفر دیگر باشد.
(SELECT 1
FROM Taxi.taxi_trips
WHERE driver_id=@DriverID AND status IN ('Accepted','Arrived','OnTrip'))
BEGIN
SET @Result=0;
END
RETURN @Result;
END;
GO


SELECT * 
FROM Taxi.FN_NearDrivers(45.400000 , 50.100000);
SELECT Taxi.FN_CanAcceptTrip(2);

SELECT TOP(5) *
FROM Taxi.FN_NearDrivers(35.700000,51.400000)
ORDER BY Distance;
SELECT Taxi.FN_DriverAverageRate(2);


USE DatabaseSQL_Project;
GO
--  راننده برای دیدن اطلاعات مسافر فقط این ویو را صدا می‌زنه
CREATE OR ALTER VIEW Taxi.VW_DriverPassengerView
AS
SELECT t.trip_id,t.status AS TripStatus,u.firstname AS PassengerFirstName,u.lastname AS PassengerLastName,u.phone_num AS PassengerPhone, t.pickup_address,t.dropoff_address,t.price
FROM Taxi.taxi_trips t JOIN Account.users u ON t.passenger_id = u.user_id;
GO

SELECT *
FROM Taxi.VW_DriverPassengerView;
GO
--ویو به راننده یا مدیر سیستم کمک می‌کند تا فقط سفرهای در حال انجام را ببینند برا سلامت سفر
CREATE OR ALTER VIEW Taxi.VW_DriverCurrentTrip
AS
SELECT t.trip_id, d.driver_id, u.firstname+' '+u.lastname AS PassengerName,u.phone_num,t.pickup_address,t.dropoff_address,t.price,t.status,t.created_at
FROM Taxi.taxi_trips t JOIN Taxi.drivers d ON d.driver_id=t.driver_id JOIN Account.users u ON u.user_id=t.passenger_id
WHERE t.status IN ('Accepted','Arrived','OnTrip');
GO
--برا اینکه راننده ها رتیشون رو ببینن و  وضعیتشون رو 
-- تو تابع دراور اوریج استفاده شده 
CREATE OR ALTER VIEW Taxi.VW_DriverRating
AS
SELECT d.driver_id,u.firstname,u.lastname,Taxi.FN_DriverAverageRate(d.driver_id) AS AverageRate,COUNT(CASE WHEN t.status='Completed' THEN 1 END) AS CompletedTrips,d.is_online,d.is_approved
FROM Taxi.drivers d JOIN Account.users u ON d.driver_id=u.user_id LEFT JOIN Taxi.taxi_trips t ON d.driver_id=t.driver_id
GROUP BY d.driver_id, u.firstname,u.lastname,d.is_online,d.is_approved;
GO
-- تاریخچه سغر ها رو نمایش بده براهمین 
CREATE OR ALTER VIEW Taxi.VW_TripHistory
AS
SELECT t.trip_id,Passenger.firstname+' '+Passenger.lastname AS Passenger,Driver.firstname+' '+Driver.lastname AS Driver, t.pickup_address, t.dropoff_address,t.price,t.status,t.created_at
FROM Taxi.taxi_trips t JOIN Account.users Passenger ON Passenger.user_id=t.passenger_id LEFT JOIN Taxi.drivers d ON d.driver_id=t.driver_id LEFT JOIN Account.users Driver ON Driver.user_id=d.driver_id;
GO

-- برا اینکه اننده هایی که انلاین یا می تونن سرویس بدن رو نشون بده 
CREATE OR ALTER VIEW Taxi.VW_OnlineDrivers
AS
SELECT d.driver_id,u.firstname,u.lastname,u.phone_num,v.model,v.color,v.plak_num,l.latitude,l.longitude
FROM Taxi.drivers d JOIN Account.users u ON d.driver_id=u.user_id LEFT JOIN Taxi.vehicles v ON d.driver_id=v.driver_id LEFT JOIN Taxi.live_location_driver l ON d.driver_id=l.driver_id
WHERE d.is_online=1 AND d.is_approved=1;
GO

USE DatabaseSQL_Project;
GO
--DELETE from Taxi.trip_message;
--DELETE from Taxi.trip_review;
--DELETE from Taxi.taxi_trips;
--DELETE from Taxi.live_location_driver;
--DELETE from Taxi.driver_doc;
--DELETE from Taxi.vehicles;


--DBCC CHECKIDENT ('Taxi.trip_message', RESEED, 0);
--DBCC CHECKIDENT ('Taxi.trip_review', RESEED, 0);
--DBCC CHECKIDENT ('Taxi.taxi_trips', RESEED, 0);
--DBCC CHECKIDENT ('Taxi.live_location_driver', RESEED, 0);
--DBCC CHECKIDENT ('Taxi.driver_doc', RESEED, 0);
--DBCC CHECKIDENT ('Taxi.vehicles', RESEED, 0);
--GO


-- این پرسیجر میاد تفاوت قایل میشه بین یوزر و راننده و داده هر کدوم را تو جدول خودش دخیره می کنه
create or alter procedure Taxi.CreateDriver(@firstname NVARCHAR(50),@lastname NVARCHAR(50),@phone_num VARCHAR(11),@email VARCHAR(100),@pass_hash VARCHAR(255),@license_num VARCHAR(10),@national_code VARCHAR(10))
as begin
begin transaction;
begin try
declare @user_id INT;
declare @driver_role INT;
INSERT INTO Account.users(firstname,lastname,phone_num, email,pass_hash)-- اطلاعات یوزر
VALUES(@firstname,@lastname, @phone_num, @email, @pass_hash );
SET @user_id = SCOPE_IDENTITY();
select @driver_role = role_id
from Account.roles
where role_name='Driver';-- این برا اونایی که راننده باشن نه چیز دیگه
INSERT INTO Account.user_roles(user_id,role_id)
VALUES(@user_id,@driver_role);
INSERT INTO Taxi.drivers(driver_id,license_num,national_code,is_approved,is_online)-- اطلاعات راننده
VALUES(@user_id,@license_num,@national_code,1,0);
COMMIT;
select 'Driver Created' AS Message, @user_id AS UserID;
END TRY
BEGIN CATCH
ROLLBACK;-- اطلاعات غلط را هم جلوشو میگره که وارد نشه 
THROW;
END CATCH
END;
go



-- دیگه ایدی طرف درگیرش نمیشیم پروسیجر ثبت خودرو با شماره تلفن راننده
create or alter procedure Taxi.SP_RegisterVehicle @PhoneNum VARCHAR(11),@Model NVARCHAR(50),@Color NVARCHAR(50),@PlakNum NVARCHAR(15)
as begin
SET NOCOUNT ON;
declare @DriverID INT = (select u.user_id from Account.users u JOIN Taxi.drivers d ON u.user_id = d.driver_id where u.phone_num = @PhoneNum);
IF @DriverID IS NULL
BEGIN RAISERROR(N'خطا: راننده‌ای با این شماره تلفن یافت نشد.', 16, 1); RETURN; END
INSERT INTO Taxi.vehicles (driver_id, model, color, plak_num)
VALUES (@DriverID, @Model, @Color, @PlakNum);
END;
GO

-- در خواست سفر 
create or alter procedure Taxi.SP_RequestTrip @PassengerPhone VARCHAR(11),@PickupText NVARCHAR(500), @DropoffText NVARCHAR(500),@Lat1 DECIMAL(9,6), @Lng1 DECIMAL(9,6),@Lat2 DECIMAL(9,6), @Lng2 DECIMAL(9,6),@Price DECIMAL(18,2),@CouponCode VARCHAR(50) = NULL
as begin
SET NOCOUNT ON;
declare @PassengerID INT = (select user_id from Account.users where phone_num = @PassengerPhone);
declare @CouponID INT = (select coupon_id from Payment.coupons where code = @CouponCode);
IF @PassengerID IS NULL
BEGIN RAISERROR(N'خطا: مسافری با این شماره تلفن یافت نشد.', 16, 1); RETURN; END
INSERT INTO Taxi.taxi_trips (passenger_id, pickup_address, dropoff_address, pickup_latitude, pickup_longitude, dropoff_latitude, dropoff_longitude, price, status, coupon_id)
VALUES (@PassengerID, @PickupText, @DropoffText, @Lat1, @Lng1, @Lat2, @Lng2, @Price, 'Searching', @CouponID);
END;
GO

-- پرسیجر بعد اینکه درخواست قبول شد
create or alter procedure Taxi.SP_AcceptTrip @DriverPhone VARCHAR(11),@PassengerPhone VARCHAR(11)
as begin
SET NOCOUNT ON;
--  پیدا کردن آی‌دی راننده
DECLARE @DriverID INT = (SELECT user_id FROM Account.users WHERE phone_num = @DriverPhone);
-- امنیت لایه بیزینس: چک کردن اینکه آیا این کاربر واقعاً نقش Driver دارد؟
IF NOT EXISTS (
SELECT 1 
FROM Account.user_roles ur JOIN Account.roles r ON ur.role_id = r.role_id 
WHERE ur.user_id = @DriverID AND r.role_name = 'Driver')
begin
RAISERROR(N'خطای امنیتی: این شماره تلفن به عنوان راننده در سیستم تعریف نشده است و سطح دسترسی ندارد.', 16, 1);
RETURN;
END
 --  پیدا کردن آخرین سفر در وضعیت Searching برای این مسافر
DECLARE @TripID INT = (SELECT TOP 1 t.trip_id
FROM Taxi.taxi_trips t JOIN Account.users u ON t.passenger_id = u.user_id 
WHERE u.phone_num = @PassengerPhone AND t.status = 'Searching' ORDER BY t.created_at DESC);
IF @DriverID IS NULL OR @TripID IS NULL
BEGIN 
RAISERROR(N'خطا: راننده یا درخواست سفر فعالی برای این مسافر یافت نشد.', 16, 1); 
RETURN; 
END
 --  بررسی ثبت بودن خودرو
IF NOT EXISTS (SELECT 1 FROM Taxi.vehicles WHERE driver_id = @DriverID)
BEGIN
RAISERROR(N'خطا: این راننده مجاز به قبول سفر نیست، زیرا هیچ خودرویی برای او ثبت نشده است.', 16, 1);
RETURN;
END
UPDATE Taxi.taxi_trips SET driver_id = @DriverID, status = 'Accepted' WHERE trip_id = @TripID;
PRINT 'سفر با موفقیت توسط راننده تایید شد و سطح دسترسی معتبر است.';
END;
GO

--پروسیجر تغییر وضعیت سفر  رسیدن به مبدا شروع سفر اتمام یا لغو سفر
create or alter procedure Taxi.SP_UpdateTripStatus @PassengerPhone VARCHAR(11),@NewStatus VARCHAR(20)
as begin
SET NOCOUNT ON;
declare @TripID INT = (select TOP 1 t.trip_id from Taxi.taxi_trips t JOIN Account.users u ON t.passenger_id = u.user_id where u.phone_num = @PassengerPhone AND t.status NOT IN ('Completed', 'Cancelled') ORDER BY t.created_at DESC);
IF @TripID IS NULL
BEGIN RAISERROR(N'خطا: سفر فعالی برای این مسافر پیدا نشد.', 16, 1); RETURN; END
UPDATE Taxi.taxi_trips SET status = @NewStatus where trip_id = @TripID;
END;
GO

--  پروسیجر ثبت نظر و چت برای آخرین سفر تکمیل‌شده مسافر
create or alter procedure Taxi.SP_AddReviewAndMessage @PassengerPhone VARCHAR(11), @Rating INT, @Comment NVARCHAR(1000),@MessageText NVARCHAR(500),@SenderPhone VARCHAR(11)
as begin
SET NOCOUNT ON;
declare @TripID INT = (select TOP 1 t.trip_id from Taxi.taxi_trips t JOIN Account.users u ON t.passenger_id = u.user_id where u.phone_num = @PassengerPhone ORDER BY t.created_at DESC);
declare @SenderID INT = (select user_id from Account.users where phone_num = @SenderPhone);
IF @TripID IS NULL OR @SenderID IS NULL RETURN;
--  ثبت نشده باشد ثبت کن
IF NOT EXISTS (select 1 from Taxi.trip_review where trip_id = @TripID) AND @Rating BETWEEN 1 AND 5
INSERT INTO Taxi.trip_review (trip_id, rating, comment) VALUES (@TripID, @Rating, @Comment);
-- ثبت پیام چت
IF @MessageText IS NOT NULL
INSERT INTO Taxi.trip_message (trip_id, sender_id, message) VALUES (@TripID, @SenderID, @MessageText);
END;
GO

select trip_id, passenger_id, driver_id, price, status from Taxi.taxi_trips;
select * from Taxi.trip_review;
select * from Taxi.trip_message;
select* from Taxi.vehicles;

USE DatabaseSQL_Project;
GO
--همه تغییرات  مهم توی سفر را لاگ میندازه 

CREATE OR ALTER TRIGGER Taxi.TR_TaxiTrip_Log
ON Taxi.taxi_trips
AFTER INSERT, UPDATE
AS
BEGIN
SET NOCOUNT ON;
INSERT INTO Taxi.taxi_log_activity(trip_id,diver_id,action_type,table_name,record_id,description )
SELECT i.trip_id,i.driver_id,'INSERT','taxi_trips',i.trip_id,N'درخواست سفر جدید ثبت شد.'
FROM inserted i LEFT JOIN deleted d ON i.trip_id=d.trip_id
WHERE d.trip_id IS NULL;

INSERT INTO Taxi.taxi_log_activity(trip_id,diver_id, action_type,table_name,record_id,description )
SELECT i.trip_id,i.driver_id,'UPDATE','taxi_trips',i.trip_id,N'وضعیت سفر از '
+ ISNULL(d.status,'')
+ N' به '
+ ISNULL(i.status,'')+ N' تغییر یافت.'
FROM inserted i JOIN deleted d ON i.trip_id=d.trip_id
WHERE ISNULL(i.status,'')<>ISNULL(d.status,'');
END;
GO



CREATE OR ALTER TRIGGER Taxi.TR_RegisterVehicle_Log
ON Taxi.vehicles
AFTER INSERT
AS
BEGIN
SET NOCOUNT ON;

INSERT INTO Taxi.taxi_log_activity(diver_id,action_type,table_name,record_id,description)
SELECT driver_id,'INSERT','vehicles',v_id,N'خودروی راننده ثبت شد.'
FROM inserted;
END;
GO


CREATE OR ALTER TRIGGER Taxi.TR_Review_Log
ON Taxi.trip_review
AFTER INSERT
AS
BEGIN
SET NOCOUNT ON;
INSERT INTO Taxi.taxi_log_activity(trip_id,action_type,table_name,record_id,description)

SELECT trip_id,'INSERT','trip_review',rew_id,N'نظر جدید برای سفر ثبت شد.'
FROM inserted;

END;
GO
CREATE OR ALTER TRIGGER Taxi.TR_Message_Log
ON Taxi.trip_message
AFTER INSERT
AS
BEGIN
SET NOCOUNT ON;

INSERT INTO Taxi.taxi_log_activity(trip_id,action_type,table_name,record_id,description)
SELECT trip_id,'INSERT','trip_message',m_id,N'پیام جدید بین راننده و مسافر ثبت شد.'
FROM inserted;

END;
GO

CREATE OR ALTER TRIGGER Taxi.TR_DriverStatus
ON Taxi.taxi_trips
AFTER UPDATE
AS
BEGIN
SET NOCOUNT ON;
UPDATE d
SET is_online=1
FROM Taxi.drivers d JOIN inserted i ON d.driver_id=i.driver_id JOIN deleted old ON old.trip_id=i.trip_id
WHERE i.status IN('Completed','Cancelled') AND old.status<>i.status;
END;
GO


CREATE OR ALTER TRIGGER Taxi.TR_CheckDriverAvailability
ON Taxi.taxi_trips
AFTER INSERT, UPDATE
AS
BEGIN
SET NOCOUNT ON;
INSERT INTO Taxi.taxi_log_activity(trip_id,diver_id,action_type,table_name,record_id,description)
SELECT i.trip_id,i.driver_id,'WARNING','taxi_trips',i.trip_id,N'راننده شرایط لازم برای قبول سفر را ندارد.'
FROM inserted i
 WHERE i.driver_id IS NOT NULL AND Taxi.FN_CanAcceptTrip(i.driver_id)=0;

END;
GO
SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='Taxi'
AND TABLE_NAME='taxi_log_activity';

CREATE PROCEDURE Taxi.SP_UpdateTripStatus
@PassengerPhone VARCHAR(11),
@NewStatus VARCHAR(20)
AS
BEGIN
SET NOCOUNT ON;

DECLARE @TripID INT;

SELECT TOP 1 
@TripID = t.trip_id
FROM Taxi.taxi_trips t
JOIN Account.users u 
ON t.passenger_id = u.user_id
WHERE u.phone_num = @PassengerPhone
AND t.status IN ('Searching','Accepted','Arrived','OnTrip')
ORDER BY t.created_at DESC;


IF @TripID IS NULL
BEGIN
    RAISERROR(N'خطا: سفر فعالی برای این مسافر پیدا نشد.',16,1);
    RETURN;
END


-- برای شروع سفر، راننده باید قبلاً قبول کرده باشد
IF @NewStatus IN ('Arrived','OnTrip','Completed')
AND EXISTS
(
    SELECT 1
    FROM Taxi.taxi_trips
    WHERE trip_id = @TripID
    AND driver_id IS NULL
)
BEGIN
    RAISERROR(N'خطا: قبل از تغییر وضعیت باید راننده سفر را قبول کرده باشد.',16,1);
    RETURN;
END


UPDATE Taxi.taxi_trips
SET status = @NewStatus
WHERE trip_id = @TripID;


PRINT N'وضعیت سفر با موفقیت تغییر کرد.';
END;
GO

------------------------------------------------تریگر های تعامل نهایی------
CREATE OR ALTER TRIGGER Food.TR_CreatePaymentAfterOrder
ON Food.food_orders
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Payment.payments
    (
        user_id,
        service_type,
        order_id,
        trip_id,
        amount,
        payment_method,
        status
    )
    SELECT
        customer_id,
        'Food',
        order_id,
        NULL,
        total_amount,
        'Wallet',
        'Pending'
    FROM inserted;

END;
GO




CREATE OR ALTER TRIGGER Taxi.TR_CreatePaymentAfterTripComplete
ON Taxi.taxi_trips
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Payment.payments
    (
        user_id,
        service_type,
        order_id,
        trip_id,
        amount,
        payment_method,
        status
    )
    SELECT
        i.passenger_id,
        'Taxi',
        NULL,
        i.trip_id,
        i.price,
        'Wallet',
        'Pending'
    FROM inserted i
    JOIN deleted d
        ON i.trip_id = d.trip_id
    WHERE i.status='Completed'
      AND d.status <> 'Completed';

END;
GO


CREATE OR ALTER TRIGGER Payment.TR_SendNotificationAfterPayment
ON Payment.payments
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Account.notif
    (
        user_id,
        title,
        mess_bod
    )
    SELECT
        i.user_id,
        N'پرداخت موفق',
        N'پرداخت شما با موفقیت انجام شد.'
    FROM inserted i
    JOIN deleted d
        ON i.payment_id=d.payment_id
    WHERE i.status='Success'
      AND d.status<>'Success';

END;
GO

-- یک مورد از امتیازی ها 
USE master;
GO

CREATE LOGIN AdminUser
WITH PASSWORD='Admin@12345';

CREATE LOGIN DriverUser
WITH PASSWORD='Driver@12345';

CREATE LOGIN PassengerUser
WITH PASSWORD='Passenger@12345';

CREATE LOGIN SupportUser
WITH PASSWORD='Support@12345';
GO



USE DatabaseSQL_Project;
GO

CREATE USER AdminUser FOR LOGIN AdminUser;
CREATE USER DriverUser FOR LOGIN DriverUser;
CREATE USER PassengerUser FOR LOGIN PassengerUser;
CREATE USER SupportUser FOR LOGIN SupportUser;
GO

GRANT INSERT ON SCHEMA::Account TO AdminRole;
GRANT INSERT ON SCHEMA::Taxi TO AdminRole;
GRANT INSERT ON SCHEMA::Food TO AdminRole;
GRANT INSERT ON SCHEMA::Payment TO AdminRole;

GRANT EXECUTE ON SCHEMA::Taxi TO AdminRole;

GRANT SELECT ON OBJECT::Taxi.VW_DriverPassengerView TO AdminRole;
GRANT SELECT ON OBJECT::Taxi.VW_DriverCurrentTrip TO AdminRole;
GRANT SELECT ON OBJECT::Taxi.VW_DriverRating TO AdminRole;
GRANT SELECT ON OBJECT::Taxi.VW_TripHistory TO AdminRole;
GRANT SELECT ON OBJECT::Taxi.VW_OnlineDrivers TO AdminRole;

GO
ALTER ROLE AdminRole ADD MEMBER AdminUser;
ALTER ROLE DriverRole ADD MEMBER DriverUser;
ALTER ROLE PassengerRole ADD MEMBER PassengerUser;
ALTER ROLE SupportRole ADD MEMBER SupportUser;

GRANT EXECUTE ON OBJECT::Taxi.CreateDriver TO DriverRole;
GRANT EXECUTE ON OBJECT::Taxi.SP_RegisterVehicle TO DriverRole;
GRANT EXECUTE ON OBJECT::Taxi.SP_AcceptTrip TO DriverRole;
GRANT EXECUTE ON OBJECT::Taxi.SP_UpdateTripStatus TO DriverRole;
GRANT EXECUTE ON OBJECT::Taxi.SP_AddReviewAndMessage TO DriverRole;

GRANT SELECT ON OBJECT::Taxi.VW_DriverPassengerView TO DriverRole;
GRANT SELECT ON OBJECT::Taxi.VW_DriverCurrentTrip TO DriverRole;
GRANT SELECT ON OBJECT::Taxi.VW_DriverRating TO DriverRole;
GRANT SELECT ON OBJECT::Taxi.VW_OnlineDrivers TO DriverRole;

GO

GRANT EXECUTE ON OBJECT::Taxi.SP_RequestTrip TO PassengerRole;
GRANT EXECUTE ON OBJECT::Taxi.SP_UpdateTripStatus TO PassengerRole;
GRANT EXECUTE ON OBJECT::Taxi.SP_AddReviewAndMessage TO PassengerRole;

GRANT SELECT ON OBJECT::Taxi.VW_TripHistory TO PassengerRole;

GO


GRANT SELECT ON OBJECT::Taxi.VW_TripHistory TO SupportRole;
GRANT SELECT ON OBJECT::Taxi.VW_DriverPassengerView TO SupportRole;
GRANT SELECT ON OBJECT::Taxi.VW_DriverCurrentTrip TO SupportRole;

GO

ALTER ROLE AdminRole
ADD MEMBER AdminUser;

ALTER ROLE DriverRole
ADD MEMBER DriverUser;

ALTER ROLE PassengerRole
ADD MEMBER PassengerUser;

ALTER ROLE SupportRole
ADD MEMBER SupportUser;

