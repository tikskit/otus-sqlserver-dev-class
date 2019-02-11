-- 1. ��� ������, � ������� � �������� ���� ������� urgent ��� �������� ���������� � Animal
SELECT *
FROM Warehouse.StockItems
WHERE StockItemName LIKE '%urgent%' OR StockItemName LIKE 'Animal%'

-- 2. �����������, � ������� �� ���� ������� �� ������ ������ (����� ������� ��� ��� ������ ����� ���������, ������ �������� ����� JOIN)
SELECT S.*
FROM Purchasing.Suppliers AS S
LEFT JOIN Purchasing.PurchaseOrders AS O ON S.SupplierID=O.SupplierID
WHERE O.PurchaseOrderID IS NULL

/* 3. ������� � ��������� ������, � ������� ���� �������, ������� ��������, � �������� ��������� �������, �������� ����� � ����� ����� ���� 
��������� ���� - ������ ����� �� 4 ������, ���� ������ ������ ������ ���� ������, � ����� ������ ����� 100$ ���� ���������� ������ ������ ����� 20.*/

SELECT FORMAT(O.OrderDate, 'MMMM', 'RU-ru') AS [�����]
	, DATEPART(QUARTER, O.OrderDate) AS [�������]
	, CEILING(CONVERT(FLOAT, DATEPART(M, O.OrderDate)) / 4) AS [�����]
	, COALESCE(OL.UnitPrice, I.UnitPrice) AS [����]
	, OL.Quantity AS [����������]
FROM Sales.Orders AS O
INNER JOIN Sales.OrderLines AS OL ON OL.OrderID=O.OrderID
INNER JOIN Warehouse.StockItems AS I ON I.StockItemID=OL.StockItemID
WHERE O.PickingCompletedWhen IS NOT NULL
	AND (COALESCE(OL.UnitPrice, I.UnitPrice) > 100 OR OL.Quantity > 20)


/* �������� ������� ����� ������� � ������������ �������� ��������� ������ 1000 � ��������� ��������� 100 �������. ���������� ������ ���� �� 
������ ��������, ����� ����, ���� �������. */
SELECT FORMAT(O.OrderDate, 'MMMM', 'RU-ru') AS [�����]
	, DATEPART(QUARTER, O.OrderDate) AS [�������]
	, CEILING(CONVERT(FLOAT, DATEPART(M, O.OrderDate)) / 4) AS [�����]
	, COALESCE(OL.UnitPrice, I.UnitPrice) AS [����]
	, OL.Quantity AS [����������]
FROM Sales.Orders AS O
INNER JOIN Sales.OrderLines AS OL ON OL.OrderID=O.OrderID
INNER JOIN Warehouse.StockItems AS I ON I.StockItemID=OL.StockItemID
WHERE O.PickingCompletedWhen IS NOT NULL
	AND (COALESCE(OL.UnitPrice, I.UnitPrice) > 100 OR OL.Quantity > 20)
ORDER BY [�������], [�����], O.OrderDate OFFSET 1000 ROWS FETCH NEXT 100 ROWS ONLY

/* 4. ������ �����������, ������� ���� ��������� �� 2014� ��� � ��������� Road Freight ��� Post, �������� �������� ����������, ��� ����������� 
���� ������������ ����� */

SELECT S.SupplierName AS [���������], P.FullName AS [����������� �����]
FROM Purchasing.PurchaseOrders AS PO
INNER JOIN Application.DeliveryMethods AS DM ON PO.DeliveryMethodID=DM.DeliveryMethodID
INNER JOIN Purchasing.Suppliers AS S ON S.SupplierID=PO.SupplierID
INNER JOIN Application.People AS P ON P.PersonID=PO.ContactPersonID
INNER JOIN Purchasing.SupplierTransactions AS ST ON ST.PurchaseOrderID=PO.PurchaseOrderID
WHERE (DM.DeliveryMethodName = 'Road Freight' OR DM.DeliveryMethodName = 'Post')
	AND DATEPART(YEAR, ST.FinalizationDate) = 2014


-- 5. 10 ��������� �� ���� ������ � ������ ������� � ������ ����������, ������� ������� �����.
SELECT TOP 10 Client.FullName AS [������], Salesperson.FullName AS [���������], O.OrderDate
FROM Sales.Orders AS O
INNER JOIN Application.People AS Client ON Client.PersonID=O.ContactPersonID
INNER JOIN Application.People AS Salesperson ON Salesperson.PersonID=O.SalespersonPersonID
ORDER BY O.OrderDate DESC


-- 6. ��� �� � ����� �������� � �� ���������� ��������, ������� �������� ����� Chocolate frogs 250g

SELECT DISTINCT Client.PersonID, Client.PhoneNumber
FROM Warehouse.StockItems AS I
INNER JOIN Sales.OrderLines AS OL ON OL.StockItemID=I.StockItemID
INNER JOIN Sales.Orders AS O ON O.OrderID=OL.OrderID
INNER JOIN Application.People AS Client ON Client.PersonID=O.ContactPersonID
WHERE I.StockItemName='Chocolate frogs 250g'