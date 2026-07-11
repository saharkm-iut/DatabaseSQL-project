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
