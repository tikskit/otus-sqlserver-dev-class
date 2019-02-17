-- Подзапросы и CTE
-- Сделайте 2 варианта запросов:

-- 1) через вложенный запрос


-- 1. Выберите сотрудников, которые являются продажниками, и еще не сделали ни одной продажи.

-- 1) через вложенный запрос
SELECT PersonID, FullName
FROM Application.People
WHERE Application.People.IsSalesperson=1
	AND NOT EXISTS(
				SELECT *
				FROM Sales.Invoices
				WHERE SalespersonPersonID=People.PersonID
			);

-- 2) через WITH (для производных таблиц) 

WITH SalerInvoces(InvoiceID, SalespersonPersonID) AS
(
	SELECT InvoiceID, SalespersonPersonID
	FROM Sales.Invoices
)
SELECT PersonID, FullName
FROM Application.People
LEFT JOIN SalerInvoces ON SalerInvoces.SalespersonPersonID=People.PersonID
WHERE Application.People.IsSalesperson=1 AND SalerInvoces.InvoiceID IS NULL
/*
SELECT PersonID, FullName
FROM Application.People
LEFT JOIN (
			SELECT InvoiceID, SalespersonPersonID
			FROM Sales.Invoices
			) AS I ON I.SalespersonPersonID=People.PersonID
WHERE Application.People.IsSalesperson=1 AND I.InvoiceID IS NULL
*/

-- 2. Выберите товары с минимальной ценой (подзапросом), 2 варианта подзапроса. 


-- 1) через вложенный запрос

SELECT * 
FROM Warehouse.StockItems
WHERE UnitPrice <= ALL(SELECT UnitPrice FROM Warehouse.StockItems);


-- 2) через WITH (для производных таблиц) 
WITH StockItemPrices(Price) AS 
(
	SELECT UnitPrice FROM Warehouse.StockItems
)
SELECT * 
FROM Warehouse.StockItems
WHERE  UnitPrice <= ALL(SELECT Price FROM StockItemPrices)


-- 3. Выберите всех клиентов у которых было 5 максимальных оплат из [Sales].[CustomerTransactions] представьте 3 способа (в том числе с CTE)

SELECT Customers.CustomerID, Customers.CustomerName, CustomerTransactions.CustomerTransactionID
FROM Sales.Customers
INNER JOIN Sales.CustomerTransactions ON Customers.CustomerID=CustomerTransactions.CustomerID
WHERE CustomerTransactions.TransactionAmount IN (
												SELECT DISTINCT TOP 5 TransactionAmount
												FROM Sales.CustomerTransactions
												ORDER BY TransactionAmount DESC
												)

SELECT Customers.CustomerID, Customers.CustomerName, CustomerTransactions.CustomerTransactionID
FROM Sales.Customers
INNER JOIN Sales.CustomerTransactions ON Customers.CustomerID=CustomerTransactions.CustomerID
INNER JOIN (
			SELECT DISTINCT TOP 5 TransactionAmount
			FROM Sales.CustomerTransactions
			ORDER BY TransactionAmount DESC
			) AS TOP5Trans ON TOP5Trans.TransactionAmount=CustomerTransactions.TransactionAmount

; WITH TOP5Trans (TransactionAmount) AS
(
	SELECT DISTINCT TOP 5 TransactionAmount
	FROM Sales.CustomerTransactions
	ORDER BY TransactionAmount DESC
)
SELECT Customers.CustomerID, Customers.CustomerName, CustomerTransactions.CustomerTransactionID
FROM Sales.Customers
INNER JOIN Sales.CustomerTransactions ON Customers.CustomerID=CustomerTransactions.CustomerID
INNER JOIN TOP5Trans ON TOP5Trans.TransactionAmount=CustomerTransactions.TransactionAmount



/* 4. Выберите города (ид и название), в которые были доставлены товары входящие в тройку самых дорогих товаров, а также Имя сотрудника, 
который осуществлял упаковку заказов */

/*SELECT TOP 3 StockItemID, UnitPrice
FROM Warehouse.StockItems
ORDER BY UnitPrice DESC
*/

SELECT DISTINCT Cities.CityID, Cities.CityName, People.FullName
FROM Sales.OrderLines
INNER JOIN (
			SELECT TOP 3 StockItemID--, UnitPrice
			FROM Warehouse.StockItems
			ORDER BY UnitPrice DESC
			) AS TOP3Items ON OrderLines.StockItemID=TOP3Items.StockItemID
INNER JOIN Sales.Orders ON Orders.OrderID=OrderLines.OrderID
INNER JOIN Sales.Customers ON Customers.CustomerID=Orders.CustomerID
INNER JOIN Application.Cities ON Application.Cities.CityID=Customers.DeliveryCityID
INNER JOIN Sales.Invoices ON Invoices.InvoiceID=Orders.OrderID
INNER JOIN Application.People ON People.PersonID=Invoices.PackedByPersonID


; WITH TOP3Items(StockItemID) AS
(
	SELECT TOP 3 StockItemID
	FROM Warehouse.StockItems
	ORDER BY UnitPrice DESC
)
SELECT DISTINCT Cities.CityID, Cities.CityName, People.FullName
FROM Sales.OrderLines
INNER JOIN TOP3Items ON OrderLines.StockItemID=TOP3Items.StockItemID
INNER JOIN Sales.Orders ON Orders.OrderID=OrderLines.OrderID
INNER JOIN Sales.Customers ON Customers.CustomerID=Orders.CustomerID
INNER JOIN Application.Cities ON Application.Cities.CityID=Customers.DeliveryCityID
INNER JOIN Sales.Invoices ON Invoices.InvoiceID=Orders.OrderID
INNER JOIN Application.People ON People.PersonID=Invoices.PackedByPersonID



-- 5. Объясните, что делает и оптимизируйте запрос:

SELECT Invoices.InvoiceID,
       Invoices.InvoiceDate,
       (
           SELECT People.FullName
           FROM Application.People
           WHERE People.PersonID = Invoices.SalespersonPersonID
       ) AS SalesPersonName,
       SalesTotals.TotalSumm AS TotalSummByInvoice,
       (
           SELECT SUM(OrderLines.PickedQuantity * OrderLines.UnitPrice)
           FROM Sales.OrderLines
           WHERE OrderLines.OrderId =
                                      (
                                          SELECT Orders.OrderId
                                          FROM Sales.Orders
                                          WHERE Orders.PickingCompletedWhen IS NOT NULL
                                                AND Orders.OrderId = Invoices.OrderId
                                      )
       ) AS TotalSummForPickedItems
FROM Sales.Invoices
     JOIN
         (
             SELECT InvoiceId,
                    SUM(Quantity * UnitPrice) AS TotalSumm
             FROM Sales.InvoiceLines
             GROUP BY InvoiceId
             HAVING SUM(Quantity * UnitPrice) > 27000
         ) AS SalesTotals ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

/*
Для счетов (Invoice), по которым стоимость превышает 27000 выводит ИД и дату счета, ФИО продавца, а также саму эту стоимость.

Если заказ (Order) забран, то также будет выведена стоимость всего заказа. Цена позиций в счете и заказе может быть разная, поэтому 
выводится разная сумма из счета и из заказа.

Насчет оптимизации.
1. Вынести поздапрос SalesTotals в CTE для улучшения читабельности
2. Конструкция (см. ниже) кажется сложной для понимания, посмотрю можно ли её упростить
       (
           SELECT SUM(OrderLines.PickedQuantity * OrderLines.UnitPrice)
           FROM Sales.OrderLines
           WHERE OrderLines.OrderId =
                                      (
                                          SELECT Orders.OrderId
                                          FROM Sales.Orders
                                          WHERE Orders.PickingCompletedWhen IS NOT NULL
                                                AND Orders.OrderId = Invoices.OrderId
                                      )
       ) AS TotalSummForPickedItems


Оказалось, что её можно перенести в секцию FROM:

LEFT JOIN (
	SELECT Orders.OrderID, SUM(OrderLines.PickedQuantity * OrderLines.UnitPrice) AS TotalSummForPickedItems
	FROM Sales.Orders
	INNER JOIN Sales.OrderLines ON OrderLines.OrderID=Orders.OrderID
	WHERE Orders.PickingCompletedWhen IS NOT NULL
	GROUP BY Orders.OrderID
) AS OrdersTotal ON OrdersTotal.OrderID = Invoices.OrderId

Теперь видно, что из неё можно сделать CTE аналогичную SalesTotals


Выборка из Application.People в принципе не очень сложно выглядит, но её тоже можно немного привести к более , поместив в FROM
(
           SELECT People.FullName
           FROM Application.People
           WHERE People.PersonID = Invoices.SalespersonPersonID
       ) AS SalesPersonName

*/

; WITH SalesTotals(InvoiceId, TotalSumm) AS
( 
	SELECT InvoiceId, SUM(Quantity * UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity * UnitPrice) > 27000
),
OrdersTotal(OrderID, TotalSummForPickedItems) AS 
(
	SELECT Orders.OrderID, SUM(OrderLines.PickedQuantity * OrderLines.UnitPrice) AS TotalSummForPickedItems
	FROM Sales.Orders
	INNER JOIN Sales.OrderLines ON OrderLines.OrderID=Orders.OrderID
	WHERE Orders.PickingCompletedWhen IS NOT NULL
	GROUP BY Orders.OrderID
)

SELECT Invoices.InvoiceID
       , Invoices.InvoiceDate
	   , People.FullName AS SalesPersonName
       , SalesTotals.TotalSumm AS TotalSummByInvoice
	   , OrdersTotal.TotalSummForPickedItems

FROM Sales.Invoices
JOIN SalesTotals ON Invoices.InvoiceID = SalesTotals.InvoiceID
JOIN Application.People ON People.PersonID = Invoices.SalespersonPersonID
LEFT JOIN OrdersTotal ON OrdersTotal.OrderID = Invoices.OrderId
ORDER BY TotalSumm DESC
