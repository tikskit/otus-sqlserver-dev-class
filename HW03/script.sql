SELECT CustomerID, CustomerName, BillToCustomerId, CustomerCategoryID, PrimaryContactPersonID, DeliveryMethodID, DeliveryCityID, PostalCityID, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber, WebsiteURL, DeliveryAddressLine1, DeliveryPostalCode, PostalAddressLine1, PostalPostalCode, ValidFrom, ValidTo, LastEditedBy
FROM Sales.Customers

/*
	DELETE FROM Sales.Customers WHERE CustomerID > 1061
	DROP TABLE Sales.AddedCustomers
*/

DECLARE @MaxCustomerID INT
SELECT @MaxCustomerID = MAX(CustomerID) FROM Sales.Customers

-- Создаем таблицу на будущее

SELECT CustomerID, CustomerName, BillToCustomerId, CustomerCategoryID, PrimaryContactPersonID, DeliveryMethodID, DeliveryCityID, PostalCityID
		, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber, WebsiteURL
		, DeliveryAddressLine1, DeliveryPostalCode, PostalAddressLine1, PostalPostalCode, LastEditedBy
INTO Sales.AddedCustomers
FROM Sales.Customers
WHERE CustomerID > @MaxCustomerID

-- 1. Довставлять в базу 5 записей используя insert в таблицу Customers или Suppliers
INSERT INTO Sales.Customers
	(CustomerID, CustomerName, BillToCustomerId, CustomerCategoryID, PrimaryContactPersonID, DeliveryMethodID, DeliveryCityID, PostalCityID
		, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber, WebsiteURL
		, DeliveryAddressLine1, DeliveryPostalCode, PostalAddressLine1, PostalPostalCode, LastEditedBy)

	OUTPUT 
		inserted.CustomerID
		, inserted.CustomerName
		, inserted.BillToCustomerId
		, inserted.CustomerCategoryID
		, inserted.PrimaryContactPersonID
		, inserted.DeliveryMethodID
		, inserted.DeliveryCityID
		, inserted.PostalCityID
		, inserted.AccountOpenedDate
		, inserted.StandardDiscountPercentage
		, inserted.IsStatementSent
		, inserted.IsOnCreditHold
		, inserted.PaymentDays
		, inserted.PhoneNumber
		, inserted.FaxNumber
		, inserted.WebsiteURL
		, inserted.DeliveryAddressLine1
		, inserted.DeliveryPostalCode
		, inserted.PostalAddressLine1
		, inserted.PostalPostalCode
		, inserted.LastEditedBy
		INTO Sales.AddedCustomers (
			CustomerID
			, CustomerName
			, BillToCustomerId
			, CustomerCategoryID
			, PrimaryContactPersonID
			, DeliveryMethodID
			, DeliveryCityID
			, PostalCityID
			, AccountOpenedDate
			, StandardDiscountPercentage
			, IsStatementSent
			, IsOnCreditHold
			, PaymentDays
			, PhoneNumber
			, FaxNumber
			, WebsiteURL
			, DeliveryAddressLine1
			, DeliveryPostalCode
			, PostalAddressLine1
			, PostalPostalCode
			, LastEditedBy)
VALUES
	(NEXT VALUE FOR Sequences.CustomerID
	, 'Tailspin Toys (Head Office) Ex - B1'
	, 1
	, 3
	, 1001
	, 3
	, 19586
	, 19586
	, '20130101'
	, 0.000
	, 0
	, 0
	, 7
	, '(308) 555-0100'
	, '(308) 555-0101'
	, 'http://www.tailspintoys.com'
	, 'Shop 38'
	, 90410
	,' PO Box 8975'
	, 90410
	, 1),
	(NEXT VALUE FOR Sequences.CustomerID
	, 'Tailspin Toys (Head Office) Ex - B2'
	, 1
	, 3
	, 1001
	, 3
	, 19586
	, 19586
	, '20130101'
	, 0.000
	, 0
	, 0
	, 7
	, '(308) 555-0100'
	, '(308) 555-0101'
	, 'http://www.tailspintoys.com'
	, 'Shop 38'
	, 90410
	,' PO Box 8975'
	, 90410
	, 1)

INSERT INTO Sales.Customers
	(CustomerID, CustomerName, BillToCustomerId, CustomerCategoryID, PrimaryContactPersonID, DeliveryMethodID, DeliveryCityID, PostalCityID
		, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber, WebsiteURL
		, DeliveryAddressLine1, DeliveryPostalCode, PostalAddressLine1, PostalPostalCode, LastEditedBy)
	OUTPUT 
		inserted.CustomerID
		, inserted.CustomerName
		, inserted.BillToCustomerId
		, inserted.CustomerCategoryID
		, inserted.PrimaryContactPersonID
		, inserted.DeliveryMethodID
		, inserted.DeliveryCityID
		, inserted.PostalCityID
		, inserted.AccountOpenedDate
		, inserted.StandardDiscountPercentage
		, inserted.IsStatementSent
		, inserted.IsOnCreditHold
		, inserted.PaymentDays
		, inserted.PhoneNumber
		, inserted.FaxNumber
		, inserted.WebsiteURL
		, inserted.DeliveryAddressLine1
		, inserted.DeliveryPostalCode
		, inserted.PostalAddressLine1
		, inserted.PostalPostalCode
		, inserted.LastEditedBy
		INTO Sales.AddedCustomers (
			CustomerID
			, CustomerName
			, BillToCustomerId
			, CustomerCategoryID
			, PrimaryContactPersonID
			, DeliveryMethodID
			, DeliveryCityID
			, PostalCityID
			, AccountOpenedDate
			, StandardDiscountPercentage
			, IsStatementSent
			, IsOnCreditHold
			, PaymentDays
			, PhoneNumber
			, FaxNumber
			, WebsiteURL
			, DeliveryAddressLine1
			, DeliveryPostalCode
			, PostalAddressLine1
			, PostalPostalCode
			, LastEditedBy)
	--OUTPUT inserted.*

SELECT 
	NEXT VALUE FOR Sequences.CustomerID
	, CustomerName + ' - C' + CAST(NEXT VALUE FOR Sequences.CustomerID AS VARCHAR) -- Тут NEXT VALUE FOR Sequences.CustomerID то же самое значение, что и строчкой выше
	, BillToCustomerId
	, CustomerCategoryID
	, PrimaryContactPersonID
	, DeliveryMethodID
	, DeliveryCityID
	, PostalCityID
	, AccountOpenedDate
	, StandardDiscountPercentage
	, IsStatementSent
	, IsOnCreditHold
	, PaymentDays
	, PhoneNumber
	, FaxNumber
	, WebsiteURL
	, DeliveryAddressLine1
	, DeliveryPostalCode
	, PostalAddressLine1
	, PostalPostalCode
	, LastEditedBy
FROM Sales.Customers
WHERE CustomerID IN (1, 2, 3)

SELECT * FROM Sales.AddedCustomers


-- 2. удалите 1 запись из Customers, которая была вами добавлена

DELETE FROM Sales.Customers WHERE CustomerName LIKE '% Ex - B2'


-- 3. изменить одну запись, из добавленных через UPDATE

UPDATE C
SET CustomerName=CustomerName + ' UPDATED'
OUTPUT	inserted.*, deleted.*
FROM Sales.Customers AS C
INNER JOIN
	(
		SELECT CustomerID 
		FROM Sales.AddedCustomers 
		WHERE CustomerName LIKE '% Ex - B1'
	) AS NewCustomers ON C.CustomerID=NewCustomers.CustomerID


-- 4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть

MERGE Sales.Customers AS target
USING (
	SELECT CustomerID, CustomerName, BillToCustomerId, CustomerCategoryID, PrimaryContactPersonID, DeliveryMethodID, DeliveryCityID, PostalCityID
					, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber, WebsiteURL
					, DeliveryAddressLine1, DeliveryPostalCode, PostalAddressLine1, PostalPostalCode, LastEditedBy
	FROM Sales.AddedCustomers
) AS source 
ON (target.CustomerID=Source.CustomerID)
WHEN MATCHED
	THEN UPDATE SET
					CustomerName = source.CustomerName + ' UPDATED BY MERGING '
WHEN NOT MATCHED
	THEN INSERT (CustomerID, CustomerName, BillToCustomerId, CustomerCategoryID, PrimaryContactPersonID, DeliveryMethodID, DeliveryCityID, PostalCityID
					, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber, WebsiteURL
					, DeliveryAddressLine1, DeliveryPostalCode, PostalAddressLine1, PostalPostalCode, LastEditedBy)
			VALUES(
				source.CustomerID
				, source.CustomerName + ' INSERTED BY MERGING '
				, source.BillToCustomerId
				, source.CustomerCategoryID
				, source.PrimaryContactPersonID
				, source.DeliveryMethodID
				, source.DeliveryCityID
				, source.PostalCityID
				, source.AccountOpenedDate
				, source.StandardDiscountPercentage
				, source.IsStatementSent
				, source.IsOnCreditHold
				, source.PaymentDays
				, source.PhoneNumber
				, source.FaxNumber
				, source.WebsiteURL
				, source.DeliveryAddressLine1
				, source.DeliveryPostalCode
				, source.PostalAddressLine1
				, source.PostalPostalCode
				, source.LastEditedBy)
OUTPUT deleted.*, $action, inserted.*;


-- 5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert

-- To allow advanced options to be changed.  
EXEC sp_configure 'show advanced options', 1;  
GO  
-- To update the currently configured value for advanced options.  
RECONFIGURE;  
GO  
-- To enable the feature.  
EXEC sp_configure 'xp_cmdshell', 1;  
GO  
-- To update the currently configured value for this feature.  
RECONFIGURE;  
GO  


--exec master..xp_cmdshell 'bcp "[WideWorldImporters].Sales.Customers" out  "E:\OTUS\MS SQL Server\Artifacts\otus-sqlserver-dev-class\HW03\Customers.data" -T -w -t, -S TIKSKIT-PC\SQLSERVER2017'
exec master..xp_cmdshell 'bcp "[dbo].Devices" out  "E:\OTUS\MS SQL Server\Artifacts\otus-sqlserver-dev-class\HW03\Devices.data" -d DBC20190203 -w -t# -S 192.168.101.207 -Usa -P [reallystrongpass]'




CREATE TABLE [Sales].[Devices](
	[Code] [bigint],
	[Name] [varchar](400) NOT NULL,
	[AETitle] [varchar](400) NULL,
	[Date] [datetime] NOT NULL,
	[Description] [varchar](max) NULL,
	[IsDICOM] [bit] NOT NULL,
	[ModalityCode] [bigint] NULL,
	[RowGuid] [uniqueidentifier] ROWGUIDCOL  NOT NULL,
	[OwnerHospitalId] [bigint] NOT NULL,
	[ICFTitle] [varchar](400) NULL,
	[INumber] [varchar](50) NULL,
	[FNumber] [varchar](50) NULL,
	[InArhive] [bit] NULL,
	[DeviceKind] [bigint] NULL,
	[IP] [varchar](15) NULL,
	[HL7Support] [bit] NULL,
	[DeviceModel] [bigint] NULL,
 
) 
GO
BULK INSERT [WideWorldImporters].[Sales].[Devices]
				FROM "E:\OTUS\MS SQL Server\Artifacts\otus-sqlserver-dev-class\HW03\Devices.data"
				WITH 
					(
					BATCHSIZE = 1000, 
					DATAFILETYPE = 'widechar',
					FIELDTERMINATOR = '#',
					ROWTERMINATOR ='\n',
					KEEPNULLS,
					TABLOCK,
					CODEPAGE=65001
					);


SELECT * FROM Sales.Devices
--truncate table Sales.Devices