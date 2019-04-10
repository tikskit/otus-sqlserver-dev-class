-- Написать функцию возвращающую Клиента с набольшей суммой покупки.

IF OBJECT_ID('Sales.GetBestBuyer') IS NOT NULL
	DROP PROCEDURE Sales.GetBestBuyer;
GO

CREATE PROCEDURE Sales.GetBestBuyer
	@CustomerID INT OUTPUT
AS
BEGIN
	SET NOCOUNT ON;	
	/*В этой ХП подойдет уровень изоляции транзакций READ COMMITED, потому что требуются подтвержденные данные, 
	ввод которых не был по каким-то причинам отменён. Кроме того, эти данные требуются в согласованном
	состоянии. А значит READ UNCOMMITED не подойдет. 
	
	Операция чтения производится только один раз, следовательно проблем с неповторяющимся чтением и фантомными 
	строками тоже не будет, поэтому более строгие уровни REPEATABLE READ и SERIALIZABLE избыточны.

	SNAPSHOT можно было бы использовать, если данный отчет требуется получать моментально, а в системе существует
	множество транзакции, которы надолго блокируют данные монопольными блокировками и ждать их освобождения 
	недопустимо.
	
	*/

	; WITH PurchaseSum AS (
		SELECT InvoiceLines.InvoiceID, SUM(InvoiceLines.Quantity * ISNULL(InvoiceLines.UnitPrice, StockItems.UnitPrice)) AS PurchaseValue
		FROM Sales.InvoiceLines
		INNER JOIN Warehouse.StockItems ON Warehouse.StockItems.StockItemID=InvoiceLines.StockItemID
		GROUP BY InvoiceLines.InvoiceID
	) /*Стоимость покупки. Один пользователь может совершить несколько покупок*/
	SELECT TOP 1 @CustomerID = Customers.CustomerID--, Customers.CustomerName, PurchaseSum.PurchaseValue
	FROM Sales.Invoices 
	INNER JOIN PurchaseSum ON PurchaseSum.InvoiceID=Invoices.InvoiceID
	INNER JOIN Sales.Customers ON Customers.CustomerID=Invoices.CustomerID
	ORDER BY PurchaseValue DESC
END
GO

-- Написать хранимую процедуру с входящим параметром СustomerID, выводящую сумму покупки по этому клиенту.

/*
	В данной ХП тот же самый уровень изоляции транзакций (READ COMMITED) по тем же самым причинам
*/

IF OBJECT_ID('Sales.GetCustomerPurchasesTotal') IS NOT NULL
	DROP PROCEDURE Sales.GetCustomerPurchasesTotal;
GO

CREATE PROCEDURE Sales.GetCustomerPurchasesTotal
	@CustomerID INT,
	@Value MONEY OUT
AS
BEGIN
	SET NOCOUNT ON;

	SELECT @Value = SUM(InvoiceLines.Quantity * ISNULL(InvoiceLines.UnitPrice, StockItems.UnitPrice))
	FROM Sales.InvoiceLines
	INNER JOIN Warehouse.StockItems ON Warehouse.StockItems.StockItemID=InvoiceLines.StockItemID
	INNER JOIN Sales.Invoices ON Invoices.InvoiceID=InvoiceLines.InvoiceID
	WHERE Invoices.CustomerID=@CustomerID
END
GO

-- 1) Создать 1 функцию и 1 хранимую процедуру

/*ХП уже создал выше*/

/*Это функция для задания 08, где требовалось выводить только уточненное название клиента. */

IF OBJECT_ID('Sales.GetCustomerSpecName') IS NOT NULL 
	DROP FUNCTION Sales.GetCustomerSpecName;
GO

CREATE FUNCTION Sales.GetCustomerSpecName(@CustomerName NVARCHAR(100))
RETURNS NVARCHAR(100)
AS
BEGIN
	DECLARE @FirstBracketPos INT = CHARINDEX('(', @CustomerName);
	DECLARE @LastBracketPos INT = CHARINDEX(')', @CustomerName, @FirstBracketPos + 1);
	DECLARE @Res NVARCHAR(100);
	IF (@FirstBracketPos = 0) OR (@LastBracketPos = 0)
		SET @Res = @CustomerName;
	ELSE
		SET @Res = SUBSTRING(@CustomerName, @FirstBracketPos + 1, @LastBracketPos - @FirstBracketPos - 1);
	RETURN @Res;
END;
GO

-- 2) Cоздать одинаковую функцию и хранимую процедуру, посмотреть в чем разница в производительности и почему

/*Допишем UDF Sales.GetCustomerPurchasesTotalUDF, а в качестве аналогичной ХП  будем использовать 
Sales.GetCustomerPurchasesTotal */


IF OBJECT_ID('Sales.GetCustomerPurchasesTotalUDF') IS NOT NULL 
	DROP FUNCTION Sales.GetCustomerPurchasesTotalUDF;
GO

CREATE FUNCTION Sales.GetCustomerPurchasesTotalUDF(@CustomerID INT)
RETURNS MONEY
AS
BEGIN
	DECLARE @ValueUDF MONEY;
	SELECT @ValueUDF = SUM(InvoiceLines.Quantity * ISNULL(InvoiceLines.UnitPrice, StockItems.UnitPrice))
	FROM Sales.InvoiceLines
	INNER JOIN Warehouse.StockItems ON Warehouse.StockItems.StockItemID=InvoiceLines.StockItemID
	INNER JOIN Sales.Invoices ON Invoices.InvoiceID=InvoiceLines.InvoiceID
	WHERE Invoices.CustomerID=@CustomerID

	RETURN @ValueUDF
END;
GO
-- Запуск ХП и функции:
DECLARE @CustomerID INT = 832;
DECLARE @MValue MONEY;

SET @MValue = Sales.GetCustomerPurchasesTotalUDF(@CustomerID);
PRINT @MValue;

EXEC Sales.GetCustomerPurchasesTotal @CustomerID, @MValue OUT;
PRINT @MValue;


-- 3) Создайте табличную функцию покажите как ее можно вызвать для каждой строки result set'а без использования цикла. 

