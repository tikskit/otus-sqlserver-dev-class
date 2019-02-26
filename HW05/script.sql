-- 1. Посчитать среднюю цену товара, общую сумму продажи по месяцам
SELECT MONTH(Invoices.InvoiceDate) [Номер месяца]
	, AVG(InvoiceLines.UnitPrice) [Средняя цена товара]
	, SUM(InvoiceLines.UnitPrice * InvoiceLines.Quantity) [Общая сумма продажи по месяцам]
FROM Sales.InvoiceLines 
INNER JOIN Sales.Invoices ON Invoices.InvoiceID = InvoiceLines.InvoiceID
GROUP BY MONTH(Invoices.InvoiceDate)
ORDER BY MONTH(Invoices.InvoiceDate)


-- 2. Отобразить все месяцы, где общая сумма продаж превысила 10 000 
SELECT MONTH(Invoices.InvoiceDate)
FROM Sales.InvoiceLines 
INNER JOIN Sales.Invoices ON Invoices.InvoiceID = InvoiceLines.InvoiceID
GROUP BY MONTH(Invoices.InvoiceDate)
HAVING SUM(InvoiceLines.Quantity * InvoiceLines.UnitPrice) > 10000
ORDER BY MONTH(Invoices.InvoiceDate)


-- 3. Вывести сумму продаж, дату первой продажи и количество проданного 
--по месяцам, по товарам, продажи которых менее 50 ед в месяц.
SELECT MONTH(Invoices.InvoiceDate) AS [MonthNo]
	, InvoiceLines.StockItemID
	, SUM(InvoiceLines.Quantity * InvoiceLines.UnitPrice) AS [Сумма продаж]
	, MIN(Invoices.InvoiceDate) AS [Дата первой продажи]
	, SUM (InvoiceLines.Quantity) AS [Количество проданного]
	, CASE WHEN GROUPING(MONTH(Invoices.InvoiceDate)) = 1 THEN 'Overall'
		WHEN GROUPING(InvoiceLines.StockItemID) = 1 THEN 'In the month'
		ELSE 'For the item in the month'
	END AS [Note]
FROM Sales.InvoiceLines
INNER JOIN Sales.Invoices ON Invoices.InvoiceID=InvoiceLines.InvoiceID
GROUP BY ROLLUP (MONTH(Invoices.InvoiceDate), InvoiceLines.StockItemID)
HAVING (SUM(InvoiceLines.Quantity) < 50) 
	OR (GROUPING(MONTH(Invoices.InvoiceDate)) = 1 
	OR GROUPING(InvoiceLines.StockItemID) = 1)
ORDER BY [MonthNo], InvoiceLines.StockItemID

