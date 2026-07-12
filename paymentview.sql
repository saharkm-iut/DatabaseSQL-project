use dbproject;
go
CREATE OR ALTER VIEW Payment.VW_SuccessTaxiPayments
AS
SELECT

p.payment_id,

u.firstname,

u.lastname,

p.trip_id,

p.amount,

p.payment_method,

p.created_at

FROM Payment.payments p

JOIN Account.users u

ON u.user_id=p.user_id

WHERE

p.status='Success'

AND

p.service_type='Taxi';
GO
CREATE OR ALTER VIEW Payment.VW_UserWalletBalance
AS
SELECT

u.user_id,

u.firstname,

u.lastname,

w.wallet_id,

w.balance,

w.updated_at

FROM Payment.wallets w

JOIN Account.users u

ON u.user_id=w.user_id;
GO
CREATE OR ALTER VIEW Payment.VW_WalletTransactions
AS
SELECT

wt.transaction_id,

u.firstname,

u.lastname,

wt.amount,

wt.transaction_type,

wt.description,

wt.created_at

FROM Payment.wallet_transactions wt

JOIN Payment.wallets w

ON wt.wallet_id=w.wallet_id

JOIN Account.users u

ON u.user_id=w.user_id;
GO