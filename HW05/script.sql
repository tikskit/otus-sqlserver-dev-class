-- 1. Посчитать среднюю цену товара

SELECT AVG(UnitPrice)
FROM Warehouse.StockItems

-- общую сумму продажи по месяцам
SELECT DATEPART(MONTH, Invoices.InvoiceDate), SUM(InvoiceLines.UnitPrice * InvoiceLines.Quantity)
FROM Sales.InvoiceLines 
INNER JOIN Sales.Invoices ON Invoices.InvoiceID = InvoiceLines.InvoiceID
GROUP BY DATEPART(MONTH, Invoices.InvoiceDate)


-- 2. Отобразить все месяцы, где общая сумма продаж превысила 10 000 
SELECT DATEPART(MONTH, Invoices.InvoiceDate)
FROM Sales.InvoiceLines 
INNER JOIN Sales.Invoices ON Invoices.InvoiceID = InvoiceLines.InvoiceID
GROUP BY DATEPART(MONTH, Invoices.InvoiceDate)
HAVING SUM(InvoiceLines.Quantity * InvoiceLines.UnitPrice) > 10000


-- 3. Вывести сумму продаж, дату первой продажи и количество проданного 
--по месяцам, по товарам, продажи которых менее 50 ед в месяц.
SELECT DATEPART(MONTH, Invoices.InvoiceDate) AS [MonthNo]
	, InvoiceLines.StockItemID
	, SUM(InvoiceLines.Quantity * InvoiceLines.UnitPrice) AS [Сумма продаж]
	, MIN(Invoices.InvoiceDate) AS [Дата первой продажи]
	, SUM (InvoiceLines.Quantity) AS [Количество проданного]
	, CASE WHEN GROUPING(DATEPART(MONTH, Invoices.InvoiceDate)) = 1 THEN 'Overall'
		WHEN GROUPING(InvoiceLines.StockItemID) = 1 THEN 'In the month'
		ELSE 'For the item in the month'
	END AS [Note]
FROM Sales.InvoiceLines
INNER JOIN Sales.Invoices ON Invoices.InvoiceID=InvoiceLines.InvoiceID
GROUP BY ROLLUP (DATEPART(MONTH, Invoices.InvoiceDate), InvoiceLines.StockItemID)
HAVING (SUM(InvoiceLines.Quantity) < 500) 
	OR (GROUPING(DATEPART(MONTH, Invoices.InvoiceDate)) = 1 
	OR GROUPING(InvoiceLines.StockItemID) = 1)
ORDER BY 1, 2

