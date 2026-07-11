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
SELECT i.trip_id,i.driver_id,'UPDATE','taxi_trips',i.trip_id,N'وضعیت سفر از '+ d.status+ N' به '+ i.status+ N' تغییر یافت.'
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