-- 1) Написать функцию возвращающую Клиента с набольшей суммой покупки.

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

	во всех приведенных тут ХП и функциях используется READ COMMITED по тем же самым причинам
	
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

/*
2) Написать хранимую процедуру с входящим параметром СustomerID, выводящую сумму покупки по этому клиенту.

Использовать таблицы :
Sales.Customers
Sales.Invoices
Sales.InvoiceLines
*/

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

-- 3) Cозда5ть одинаковую функцию и хранимую процедуру, посмотреть в чем разница в производительности и почему

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

/*
Планы выполнения ХП и UDF абсолютно одинаковые (файлы GetCustomerPurchasesTotal.sqlplan и GetCustomerPurchasesTotalUDF.sqlplan), поэтому разницы в производительности нет. 
*/


-- 4) Создайте табличную функцию покажите как ее можно вызвать для каждой строки result set'а без использования цикла. 

/*Напишем UDF, которая будет выводить 3 самых дорогих заказа пользователя по его идентификатору. И затем запрос, использующий её */


IF OBJECT_ID('Sales.GetCustomerTop3Orders') IS NOT NULL 
	DROP FUNCTION Sales.GetCustomerTop3Orders;
GO

CREATE FUNCTION Sales.GetCustomerTop3Orders(@CustomerID INT)
RETURNS TABLE
AS
	RETURN(	
		SELECT TOP 3 Invoices.InvoiceID, SUM(InvoiceLines.Quantity * ISNULL(InvoiceLines.UnitPrice, StockItems.UnitPrice)) AS Total
		FROM Sales.Invoices 
		INNER JOIN Sales.InvoiceLines ON Invoices.InvoiceID=InvoiceLines.InvoiceID
		INNER JOIN Warehouse.StockItems ON StockItems.StockItemID=InvoiceLines.StockItemID
		WHERE Invoices.CustomerID=@CustomerID
		GROUP BY Invoices.InvoiceID
		ORDER BY Total DESC
	)
GO


SELECT Customers.CustomerName, TOP3.InvoiceID, TOP3.Total,
	CASE DENSE_RANK() OVER (PARTITION BY Customers.CustomerName ORDER BY TOP3.Total)
		WHEN 1 THEN 'First'
		WHEN 2 THEN 'Second'
		WHEN 3 THEN 'Third'
	END AS 'Order rank'
FROM Sales.Customers
CROSS APPLY(
	SELECT InvoiceID, Total
	FROM Sales.GetCustomerTop3Orders(Customers.CustomerID)
	) AS TOP3