-- 1.

/*
1. Требуется написать запрос, который в результате своего выполнения формирует таблицу следующего вида:
Название клиента
МесяцГод Количество покупок

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys
имя клиента нужно поменять так чтобы осталось только уточнение 
например исходное Tailspin Toys (Gasport, NY) - вы выводите в имени только Gasport,NY
дата должна иметь формат dd.mm.yyyy например 25.12.2019

Например, как должны выглядеть результаты:
InvoiceMonth	Peeples Valley, AZ	Medicine Lodge, KS	Gasport, NY	Sylvanite, MT	Jessie, ND
01.01.2013	3	1	4	2	2
01.02.2013	7	3	4	2	1
*/

SELECT InvoiceMonth, [Sylvanite, MT], [Peeples Valley, AZ], [Medicine Lodge, KS], [Gasport, NY], [Jessie, ND]
FROM (
	SELECT Dates.InvoiceMonth, SName.SpecName, Invoices.InvoiceID
	FROM Sales.Customers AS C
	INNER JOIN Sales.Invoices ON Invoices.CustomerID=C.CustomerID
	CROSS APPLY (SELECT FirstBracketPos=CHARINDEX('(', C.CustomerName)) AS FBP
	CROSS APPLY (SELECT LastBracketPos=CHARINDEX(')', C.CustomerName, FirstBracketPos + 1)) AS LBP
	CROSS APPLY (SELECT SpecName=SUBSTRING(C.CustomerName, FirstBracketPos + 1, LastBracketPos - FirstBracketPos - 1)) AS SName
	CROSS APPLY (SELECT InvoiceMonth=FORMAT(DATEADD(MM, DATEDIFF(MM, 0, Invoices.InvoiceDate), 0), 'dd.MM.yyyy')) AS Dates
	WHERE C.CustomerID BETWEEN 2 AND 6
) AS D
PIVOT(COUNT([InvoiceID]) FOR D.SpecName IN([Sylvanite, MT], [Peeples Valley, AZ], [Medicine Lodge, KS], [Gasport, NY], [Jessie, ND]) ) AS P
ORDER BY CAST(InvoiceMonth AS DATE)


/*
2. Для всех клиентов с именем, в котором есть Tailspin Toys
вывести все адреса, которые есть в таблице в одной колоке
*/

SELECT SpecName, AddrSrc, Addr
FROM (
	SELECT SName.SpecName, DeliveryAddressLine1, DeliveryAddressLine2, PostalAddressLine1, PostalAddressLine2
	FROM Sales.Customers AS C
	CROSS APPLY (SELECT FirstBracketPos=CHARINDEX('(', C.CustomerName)) AS FBP
	CROSS APPLY (SELECT LastBracketPos=CHARINDEX(')', C.CustomerName, FirstBracketPos + 1)) AS LBP
	CROSS APPLY (SELECT SpecName=SUBSTRING(C.CustomerName, FirstBracketPos + 1, LastBracketPos - FirstBracketPos - 1)) AS SName
	WHERE C.CustomerID BETWEEN 2 AND 6
) AS S
UNPIVOT(Addr FOR AddrSrc IN (DeliveryAddressLine1, DeliveryAddressLine2, PostalAddressLine1, PostalAddressLine2)) AS U


/*

3. В таблице стран есть поля с кодом страны цифровым и буквенным
сделайте выборку ИД страны, название, код - чтобы в поле был либо цифровой либо буквенный код
Пример выдачи

CountryId	CountryName	Code
1	Afghanistan	AFG
1	Afghanistan	4
3	Albania	ALB
3	Albania	8

*/

SELECT CountryID, CountryName, CodeType, Code
FROM (
	SELECT CountryID, CountryName, CAST(IsoAlpha3Code AS NVARCHAR) IsoAlpha3Code, CAST(IsoNumericCode AS NVARCHAR) IsoNumericCode
		FROM Application.Countries
) AS S
UNPIVOT(Code FOR CodeType IN ([IsoAlpha3Code], [IsoNumericCode])) AS U


/*
4. Перепишите ДЗ из оконных функций через CROSS APPLY 
Выберите по каждому клиенту 2 самых дорогих товара, которые он покупал
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки*/

SELECT Customers.CustomerID, Customers.CustomerName
	, R1.StockItemID, R1.StockItemName, R1.UnitPrice--, R1.InvoiceDate
	, (
		SELECT STRING_AGG(I1.InvoiceDate, ', ') WITHIN GROUP (ORDER BY I1.InvoiceDate) 
		FROM Sales.InvoiceLines AS IL1
		INNER JOIN Sales.Invoices AS I1 ON I1.InvoiceID=IL1.InvoiceLineID
		WHERE IL1.StockItemID=R1.StockItemID AND I1.CustomerID=Customers.CustomerID
	) [Даты покупок товара]
	
FROM  Sales.Customers 
CROSS APPLY (
	SELECT DISTINCT TOP 2 InvoiceLines.StockItemID
		, StockItems.StockItemName, StockItems.UnitPrice
		--, Invoices.InvoiceDate
	FROM Sales.InvoiceLines
	INNER JOIN Sales.Invoices ON Invoices.InvoiceID=InvoiceLines.InvoiceLineID
	INNER JOIN Warehouse.StockItems ON InvoiceLines.StockItemID=StockItems.StockItemID
	WHERE Invoices.CustomerID=Customers.CustomerID
	ORDER BY StockItems.UnitPrice DESC
) AS R1
