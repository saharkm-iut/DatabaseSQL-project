use dbproject;
go
CREATE OR ALTER FUNCTION Payment.FN_CalculateTripPayment
(
    @TripID INT
)
RETURNS DECIMAL(18,2)
AS
BEGIN

    DECLARE @Price DECIMAL(18,2);
    DECLARE @CouponID INT;
    DECLARE @DiscountType VARCHAR(20);
    DECLARE @DiscountValue DECIMAL(18,2);
    DECLARE @MaxDiscount DECIMAL(18,2);
    DECLARE @FinalPrice DECIMAL(18,2);

    SELECT
        @Price=t.price,
        @CouponID=t.coupon_id
    FROM Taxi.taxi_trips t
    WHERE t.trip_id=@TripID;
    IF @Price IS NULL
    RETURN 0;
    IF @CouponID IS NULL
        RETURN @Price;

    SELECT
        @DiscountType=discount_type,
        @DiscountValue=discount_value,
        @MaxDiscount=max_discount
    FROM Payment.coupons
    WHERE coupon_id=@CouponID;

    IF @DiscountType='Percentage'
    BEGIN

        SET @FinalPrice=@Price-
        CASE
            WHEN (@Price*@DiscountValue/100)>ISNULL(@MaxDiscount,99999999)
            THEN ISNULL(@MaxDiscount,99999999)
            ELSE (@Price*@DiscountValue/100)
        END;

    END
    ELSE
    BEGIN
        SET @FinalPrice=@Price-@DiscountValue;
    END

    IF @FinalPrice<0
        SET @FinalPrice=0;

    RETURN @FinalPrice;

END;
GO
CREATE OR ALTER FUNCTION Payment.FN_CanPayByWallet
(
    @UserID INT,
    @TripID INT
)
RETURNS BIT
AS
BEGIN

    DECLARE @WalletBalance DECIMAL(20,2);
    DECLARE @TripAmount DECIMAL(18,2);

    SELECT
        @WalletBalance = balance
    FROM Payment.wallets
    WHERE user_id = @UserID;

    SET @TripAmount = Payment.FN_CalculateTripPayment(@TripID);

    IF @WalletBalance IS NULL
        RETURN 0;

    IF @WalletBalance >= @TripAmount
        RETURN 1;

    RETURN 0;

END;
GO


SELECT Payment.FN_CalculateTripPayment(1);
SELECT Payment.FN_CanPayByWallet(1,5);