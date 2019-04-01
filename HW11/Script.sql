-- 1. Загрузить данные из файла StockItems.xml в таблицу StockItems.
DECLARE @XML XML

SET @XML = (
	SELECT * 
	FROM OPENROWSET (
		BULK 'E:\OTUS\MS SQL Server\Artifacts\otus-sqlserver-dev-class\HW11\StockItems.xml', SINGLE_BLOB
		) AS D
	)

--SELECT @XML
DECLARE @docHandle int

EXEC sp_xml_preparedocument @docHandle OUTPUT, @XML

MERGE Warehouse.StockItems AS Target
USING(
	SELECT SupplierID, StockItemName, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, 3 AS LastEditedBy
	FROM OPENXML(@docHandle, N'/StockItems/Item/Package', 3)
	WITH ( 
		[SupplierID] INT '../SupplierID',
		[StockItemName] NVARCHAR(100) '../@Name',
		[LeadTimeDays] INT '../LeadTimeDays',
		[IsChillerStock] INT '../IsChillerStock',
		[TaxRate] MONEY '../TaxRate',
		[UnitPrice] MONEY '../UnitPrice',
		[UnitPackageID] INT,
		[OuterPackageID] INT,
		[QuantityPerOuter] INT,
		[TypicalWeightPerUnit] DECIMAL (18,3)
	)
) AS Source (SupplierID, StockItemName, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LastEditedBy)
ON (Target.StockItemName=Source.StockItemName)
WHEN MATCHED THEN
	UPDATE SET
		SupplierID = Source.SupplierID, 
		StockItemName = Source.StockItemName, 
		LeadTimeDays = Source.LeadTimeDays, 
		IsChillerStock = Source.IsChillerStock, 
		TaxRate = Source.TaxRate, 
		UnitPrice = Source.UnitPrice, 
		UnitPackageID = Source.UnitPackageID, 
		OuterPackageID = Source.OuterPackageID, 
		QuantityPerOuter = Source.QuantityPerOuter, 
		TypicalWeightPerUnit = Source.TypicalWeightPerUnit, 
		LastEditedBy = Source.LastEditedBy
WHEN NOT MATCHED THEN
	INSERT (SupplierID, StockItemName, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LastEditedBy)
	VALUES(Source.SupplierID, Source.StockItemName, Source.LeadTimeDays, Source.IsChillerStock, Source.TaxRate, Source.UnitPrice, Source.UnitPackageID, Source.OuterPackageID, 
		Source.QuantityPerOuter, Source.TypicalWeightPerUnit, Source.LastEditedBy)
OUTPUT deleted.*, $action, inserted.*;

EXEC sp_xml_removedocument @docHandle


-- 2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
SELECT StockItemName AS '@Item', 
	SupplierID,
	UnitPackageID AS 'Package/UnitPackageID', 
	OuterPackageID AS 'Package/OuterPackageID', 
	QuantityPerOuter AS 'Package/QuantityPerOuter', 
	TypicalWeightPerUnit AS 'Package/TypicalWeightPerUnit', 
	LeadTimeDays, IsChillerStock, TaxRate, UnitPrice
FROM Warehouse.StockItems
FOR XML PATH('Item'), ROOT('StockItems')
	, ELEMENTS
/*
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

*/

--Следующее вообще-то работает, но оно выводит в файл XML без переносов строк и форматирования
--EXEC xp_cmdshell 'bcp "SELECT StockItemName AS [@Item], SupplierID, UnitPackageID AS [Package/UnitPackageID], OuterPackageID AS [Package/OuterPackageID], QuantityPerOuter AS [Package/QuantityPerOuter], TypicalWeightPerUnit AS [Package/TypicalWeightPerUnit], LeadTimeDays, IsChillerStock, TaxRate, UnitPrice FROM Warehouse.StockItems FOR XML PATH(''Item''), ROOT(''StockItems''), ELEMENTS" queryout "E:\OTUS\MS SQL Server\Artifacts\otus-sqlserver-dev-class\HW11\StockItems1.xml" -d WideWorldImporters -T -c -t  -S TIKSKIT-PC\SQLSERVER2017'


/*
3. В таблице StockItems в колонке CustomFields есть данные в json.
Написать select для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- Range (из CustomFields)
*/

SELECT StockItemID, StockItemName,
	JSON_VALUE(CustomFields, '$.CountryOfManufacture') AS CountryOfManufacture,
	JSON_VALUE(CustomFields, '$.Range') AS Range
FROM Warehouse.StockItems


/*
4. Найти в StockItems строки, где есть тэг "Vintage"
Запрос написать через функции работы с JSON.
Тэги искать в поле CustomFields, а не в Tags.
*/

SELECT StockItemID, StockItemName,
	JSON_VALUE(CustomFields, '$.CountryOfManufacture') AS CountryOfManufacture,
	JSON_QUERY(CustomFields, '$.Tags') AS Tags
	, S.Value
FROM Warehouse.StockItems
OUTER APPLY (
		SELECT Value 
		FROM OPENJSON(CustomFields, '$.Tags')
	) AS S
WHERE S.Value = 'Vintage'

/*
5. Пишем динамический PIVOT. 
По заданию из 8го занятия про CROSS APPLY и PIVOT 
Требуется написать запрос, который в результате своего выполнения формирует таблицу следующего вида:
Название клиента
МесяцГод Количество покупок

Нужно написать запрос, который будет генерировать результаты для всех клиентов 
имя клиента указывать полностью из CustomerName
дата должна иметь формат dd.mm.yyyy например 25.12.2019
*/
-- Получаем строку, содержащую наименования всех клиентов через запятую. STRING_AGG тут не работает, потому что строка больше 8000 символов
DECLARE @ClientStr VARCHAR(MAX)
SELECT @ClientStr = STUFF(
						CAST((SELECT [text()] = '], [' + CustomerName FROM Sales.Customers FOR XML PATH(''), TYPE) AS VARCHAR(MAX))
						, 1, 2, SPACE(0))

IF @ClientStr <> ''
	SET @ClientStr = @ClientStr + ']'

DECLARE @SQL NVARCHAR(MAX) = N'
SELECT InvoiceMonth, ' + @ClientStr + 
'
FROM (
	SELECT Dates.InvoiceMonth, C.CustomerName, Invoices.InvoiceID
	FROM Sales.Customers AS C
	INNER JOIN Sales.Invoices ON Invoices.CustomerID=C.CustomerID
	CROSS APPLY (SELECT FirstBracketPos=CHARINDEX(''('', C.CustomerName)) AS FBP
	CROSS APPLY (SELECT LastBracketPos=CHARINDEX('')'', C.CustomerName, FirstBracketPos + 1)) AS LBP
	CROSS APPLY (SELECT InvoiceMonth=FORMAT(DATEADD(MM, DATEDIFF(MM, 0, Invoices.InvoiceDate), 0), ''dd.MM.yyyy'')) AS Dates
	WHERE C.CustomerID BETWEEN 2 AND 6
) AS D
PIVOT(COUNT([InvoiceID]) FOR CustomerName IN(' + @ClientStr + ') ) AS P
ORDER BY CAST(InvoiceMonth AS DATE)
'

EXEC(@SQL)