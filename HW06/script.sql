/*
1.Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года (в рамках одного месяца он будет одинаковый, нарастать будет в течение 
времени выборки)

Выведите id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом
*/
SELECT
	Invoices.InvoiceID
	, Customers.CustomerName
	, Invoices.InvoiceDate
	, SUM(InvoiceLines.Quantity * InvoiceLines.UnitPrice) OVER (PARTITION BY Invoices.InvoiceID) [Сумма продажи]
	, SUM(InvoiceLines.Quantity * InvoiceLines.UnitPrice) 
		OVER(ORDER BY DATEPART(YEAR, Invoices.InvoiceDate), DATEPART(MONTH, Invoices.InvoiceDate)) [Сумма нарастающим итогом]
FROM Sales.Invoices
INNER JOIN Sales.Customers ON Customers.CustomerID=Invoices.CustomerID
INNER JOIN Sales.InvoiceLines ON InvoiceLines.InvoiceID=Invoices.InvoiceID
WHERE InvoiceDate >= '20150101'
ORDER BY Invoices.InvoiceDate, Invoices.CUstomerID


-- Сделать 2 варианта запроса - через windows function и без них.

-- То же самое без оконных функций

SELECT
	I.InvoiceID
	, Customers.CustomerName
	, I.InvoiceDate
	, (
		SELECT SUM(IL.Quantity * IL.UnitPrice) 
		FROM Sales.InvoiceLines AS IL 
		WHERE IL.InvoiceID=I.InvoiceID
	) AS [Сумма продажи]
	, (
		SELECT SUM(IL.Quantity * IL.UnitPrice) 
		FROM Sales.InvoiceLines AS IL 
		INNER JOIN Sales.Invoices AS IInr ON IInr.InvoiceID=IL.InvoiceID
		WHERE IInr.InvoiceDate <= EOMONTH(I.InvoiceDate)
			AND IInr.InvoiceDate >= '20150101'
	) [Сумма нарастающим итогом]
FROM Sales.Invoices AS I
INNER JOIN Sales.Customers ON Customers.CustomerID=I.CustomerID
INNER JOIN Sales.InvoiceLines ON InvoiceLines.InvoiceID=I.InvoiceID
WHERE InvoiceDate >= '20150101'
ORDER BY I.InvoiceDate, I.CUstomerID



--Написать какой быстрее выполняется, сравнить по set statistics time on;
/*
Время выполнение первого запроса:
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.

Второго:
 SQL Server Execution Times:
   CPU time = 125 ms,  elapsed time = 1145 ms.
*/


-- 2. Вывести список 2х самых популярных продуктов (по кол-ву проданных) в каждом месяце за 2016й год (по 2 самых популярных продукта в каждом месяце)

; WITH ItemPerMonthCount(MonthNo, StockItemID, Cnt) AS
(
	SELECT MONTH(Invoices.InvoiceDate), InvoiceLines.StockItemID, COUNT(*)
	FROM Sales.InvoiceLines
	INNER JOIN Sales.Invoices ON Invoices.InvoiceID=InvoiceLines.InvoiceID
	WHERE YEAR(Invoices.InvoiceDate) = 2016
	GROUP BY MONTH(Invoices.InvoiceDate), InvoiceLines.StockItemID
), 
RangedSales(StockItemID, MonthNo, RN) AS
(
	SELECT ItemPerMonthCount.StockItemID
		, ItemPerMonthCount.MonthNo
		, ROW_NUMBER() OVER(PARTITION BY ItemPerMonthCount.MonthNo ORDER BY Cnt DESC) AS RN
	FROM ItemPerMonthCount
)
SELECT RangedSales.MonthNo, StockItems.StockItemName
FROM RangedSales
INNER JOIN Warehouse.StockItems ON StockItems.StockItemID=RangedSales.StockItemID
WHERE RangedSales.RN <= 2


/*
3. Функции одним запросом
Посчитайте по таблице товаров, в вывод также должен попасть ид товара, название, брэнд и цена
пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
посчитайте общее количество товаров и выведете полем в этом же запросе
посчитайте общее количество товаров в зависимости от первой буквы названия товара
отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
предыдущий ид товара с тем же порядком отображения (по имени)
названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
сформируйте 30 групп товаров по полю вес товара на 1 шт
Для этой задачи НЕ нужно писать аналог без аналитических функций
*/


SELECT StockItemID, StockItemName, Brand
	, ROW_NUMBER() OVER(PARTITION BY LEFT(StockItemName, 1) ORDER BY StockItemName) [Нумерация с группировкой по первой букве]
	, COUNT(*) OVER() [Общее количество товаров]
	, COUNT(*) OVER(PARTITION BY LEFT(StockItemName, 1)) [Количество в звисимости от первой буквы]
	, LEAD(StockItemID) OVER(ORDER BY StockItemName) [ID следующей строки при сортировке по StockItemName]
	, LAG(StockItemID) OVER(ORDER BY StockItemName) [ID предыдущей строки при сортировке по StockItemName]
	, ISNULL(LAG(StockItemName, 2) OVER(ORDER BY StockItemName), 'No items') [Название товара 2 строки назад]
	, NTILE(30) OVER(ORDER BY TypicalWeightPerUnit) [TypicalWeightPerUnitGroups]
FROM Warehouse.StockItems
ORDER BY StockItemName


/*
4. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал
В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки
*/

SELECT People.PersonID, People.FullName, Customers.CustomerID, Customers.CustomerName, R.TransactionDate [Дата продажи], 
	R.TransactionAmount [Сумма сделки]
FROM (
	SELECT CustomerTransactions.CustomerID, Invoices.SalespersonPersonID, TransactionDate, TransactionAmount
		, ROW_NUMBER() OVER(PARTITION BY SalespersonPersonID ORDER BY TransactionDate DESC) AS RN
	
	FROM Sales.CustomerTransactions 
	INNER JOIN Sales.Invoices ON Invoices.InvoiceID=CustomerTransactions.InvoiceID
) AS R
INNER JOIN Application.People ON R.SalespersonPersonID=People.PersonID
INNER JOIN Sales.Customers ON Customers.CustomerID=R.CustomerID
WHERE R.RN=1


/*
5. Выберите по каждому клиенту 2 самых дорогих товара, которые он покупал
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки
*/

/*Оставлю в таком виде, но в условии задания есть неоднозначность. Клиент мог купить один и тот же товар несколько
раз. По идее, такой товар нужно отобразить в выборке только 1 раз, потому что нужно выбрать 2 самых дорогих, а это значит, что все товары должны быть 
разные. Но тогда не понятно какую из дат покупки отображать */

SELECT Customers.CustomerID, Customers.CustomerName, R.StockItemID, R.StockItemName, R.UnitPrice, R.InvoiceDate, R.RN
FROM (
	SELECT Invoices.CustomerID, InvoiceLines.StockItemID, StockItems.StockItemName, StockItems.UnitPrice, Invoices.InvoiceDate
		, ROW_NUMBER() OVER (PARTITION BY Invoices.CustomerID ORDER BY StockItems.UnitPrice DESC) AS RN
	FROM Sales.InvoiceLines
	INNER JOIN Sales.Invoices ON Invoices.InvoiceID=InvoiceLines.InvoiceLineID
	INNER JOIN Warehouse.StockItems ON InvoiceLines.StockItemID=StockItems.StockItemID
) AS R
INNER JOIN Sales.Customers ON Customers.CustomerID=R.CustomerID
WHERE R.RN <= 2

-- Попробуйте, как вариант, написать запрос, что в случае нескольких покупок одного товара, выводилась информация обо всех этих покупках.

/*
Ну вот, мне было интересно построить такой запрос. Он в поле "Даты покупок товара" выводит через запятую даты, когда покупатель покупал этот товар. 
Товары, купленные несколько раз одним покуптелем, отображаются в единичном экземпляре, как и должно быть.
Честно говоря, надеялся, что STRING_AGG тоже является аналитической функцией, но пришлось поместить её в подзапрос.
*/
SELECT Customers.CustomerID, Customers.CustomerName
	, R.StockItemID, R.StockItemName, R.UnitPrice
	, R.D_RNK [Ранг по стоимости у покупателя]
	, R.PurchasesCount [Количество покупок товара]
	, (
		SELECT STRING_AGG(I1.InvoiceDate, ', ') WITHIN GROUP (ORDER BY I1.InvoiceDate) 
		FROM Sales.InvoiceLines AS IL1
		INNER JOIN Sales.Invoices AS I1 ON I1.InvoiceID=IL1.InvoiceLineID
		WHERE IL1.StockItemID=R.StockItemID AND I1.CustomerID=R.CustomerID
	) [Даты покупок товара]
FROM (
	SELECT DISTINCT Invoices.CustomerID, InvoiceLines.StockItemID, StockItems.StockItemName, StockItems.UnitPrice--, Invoices.InvoiceDate
		, DENSE_RANK() OVER (PARTITION BY Invoices.CustomerID ORDER BY StockItems.UnitPrice DESC, InvoiceLines.StockItemID ASC) AS D_RNK
		, COUNT(*) OVER(PARTITION BY Invoices.CustomerID, InvoiceLines.StockItemID) AS PurchasesCount
	FROM Sales.InvoiceLines
	INNER JOIN Sales.Invoices ON Invoices.InvoiceID=InvoiceLines.InvoiceLineID
	INNER JOIN Warehouse.StockItems ON InvoiceLines.StockItemID=StockItems.StockItemID
) AS R
INNER JOIN Sales.Customers ON Customers.CustomerID=R.CustomerID
WHERE R.D_RNK <= 2
ORDER BY R.CustomerID, D_RNK, R.StockItemID