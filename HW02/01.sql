-- 1. Все товары, в которых в название есть пометка urgent или название начинается с Animal
SELECT *
FROM Warehouse.StockItems
WHERE StockItemName LIKE '%urgent%' OR StockItemName LIKE 'Animal%'

-- 2. Поставщиков, у которых не было сделано ни одного заказа (потом покажем как это делать через подзапрос, сейчас сделайте через JOIN)
SELECT S.*
FROM Purchasing.Suppliers AS S
LEFT JOIN Purchasing.PurchaseOrders AS O ON S.SupplierID=O.SupplierID
WHERE O.PurchaseOrderID IS NULL

/* 3. Продажи с названием месяца, в котором была продажа, номером квартала, к которому относится продажа, включите также к какой трети года 
относится дата - каждая треть по 4 месяца, дата забора заказа должна быть задана, с ценой товара более 100$ либо количество единиц товара более 20.*/

SELECT FORMAT(O.OrderDate, 'MMMM', 'RU-ru') AS [Месяц]
	, DATEPART(QUARTER, O.OrderDate) AS [Квартал]
	, CEILING(CONVERT(FLOAT, DATEPART(M, O.OrderDate)) / 4) AS [Треть]
	, COALESCE(OL.UnitPrice, I.UnitPrice) AS [Цена]
	, OL.Quantity AS [Количество]
FROM Sales.Orders AS O
INNER JOIN Sales.OrderLines AS OL ON OL.OrderID=O.OrderID
INNER JOIN Warehouse.StockItems AS I ON I.StockItemID=OL.StockItemID
WHERE O.PickingCompletedWhen IS NOT NULL
	AND (COALESCE(OL.UnitPrice, I.UnitPrice) > 100 OR OL.Quantity > 20)


/* Добавьте вариант этого запроса с постраничной выборкой пропустив первую 1000 и отобразив следующие 100 записей. Соритровка должна быть по 
номеру квартала, трети года, дате продажи. */
SELECT FORMAT(O.OrderDate, 'MMMM', 'RU-ru') AS [Месяц]
	, DATEPART(QUARTER, O.OrderDate) AS [Квартал]
	, CEILING(CONVERT(FLOAT, DATEPART(M, O.OrderDate)) / 4) AS [Треть]
	, COALESCE(OL.UnitPrice, I.UnitPrice) AS [Цена]
	, OL.Quantity AS [Количество]
FROM Sales.Orders AS O
INNER JOIN Sales.OrderLines AS OL ON OL.OrderID=O.OrderID
INNER JOIN Warehouse.StockItems AS I ON I.StockItemID=OL.StockItemID
WHERE O.PickingCompletedWhen IS NOT NULL
	AND (COALESCE(OL.UnitPrice, I.UnitPrice) > 100 OR OL.Quantity > 20)
ORDER BY [Квартал], [Треть], O.OrderDate OFFSET 1000 ROWS FETCH NEXT 100 ROWS ONLY

/* 4. Заказы поставщикам, которые были исполнены за 2014й год с доставкой Road Freight или Post, добавьте название поставщика, имя контактного 
лица принимавшего заказ */

SELECT S.SupplierName AS [Поставщик], P.FullName AS [Принимавший заказ]
FROM Purchasing.PurchaseOrders AS PO
INNER JOIN Application.DeliveryMethods AS DM ON PO.DeliveryMethodID=DM.DeliveryMethodID
INNER JOIN Purchasing.Suppliers AS S ON S.SupplierID=PO.SupplierID
INNER JOIN Application.People AS P ON P.PersonID=PO.ContactPersonID
INNER JOIN Purchasing.SupplierTransactions AS ST ON ST.PurchaseOrderID=PO.PurchaseOrderID
WHERE (DM.DeliveryMethodName = 'Road Freight' OR DM.DeliveryMethodName = 'Post')
	AND DATEPART(YEAR, ST.FinalizationDate) = 2014


-- 5. 10 последних по дате продаж с именем клиента и именем сотрудника, который оформил заказ.
SELECT TOP 10 Customer.CustomerName AS [Клиент], Salesperson.FullName AS [Сотрудник], O.OrderDate
FROM Sales.Orders AS O
INNER JOIN Sales.Customers AS Customer ON Customer.CustomerID=O.CustomerID
INNER JOIN Application.People AS Salesperson ON Salesperson.PersonID=O.SalespersonPersonID
ORDER BY O.OrderDate DESC


-- 6. Все ид и имена клиентов и их контактные телефоны, которые покупали товар Chocolate frogs 250g
SELECT DISTINCT C.CustomerID AS [ИД клиента], C.CustomerName AS [Клиент], C.PhoneNumber AS [Контактный телефон]
FROM Warehouse.StockItems AS I
INNER JOIN Sales.OrderLines AS OL ON OL.StockItemID=I.StockItemID
INNER JOIN Sales.Orders AS O ON O.OrderID=OL.OrderID
INNER JOIN Sales.Customers AS C ON C.CustomerID=O.CustomerID
WHERE I.StockItemName='Chocolate frogs 250g'