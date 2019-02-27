/*

Сравниваем временные таблицы и табличные переменные
Напишите запрос с временной таблицей и перепишите его с табличной переменной. Сравните планы.

*/


/*Выбираем данные рекурсивно с разделинелем */
;WITH Rec(EmployeeID, ManagerID, Title, EmployeeLevel) AS
(
	SELECT EmployeeID, ManagerID, CAST(Title AS NVARCHAR), 0
	FROM dbo.MyEmployees
	WHERE ManagerID IS NULL
	UNION ALL
	SELECT E.EmployeeID, E.ManagerID, CAST(REPLICATE('|   ', EmployeeLevel + 1) + E.Title AS NVARCHAR), EmployeeLevel + 1
	FROM Rec
	INNER JOIN dbo.MyEmployees AS E ON E.ManagerID=Rec.EmployeeID
)
SELECT EmployeeID, ManagerID, Title, EmployeeLevel
FROM Rec
WHERE EmployeeLevel <= 2

/*Выбираем данные рекурсивно в табличную переменную*/
DECLARE @Tree TABLE(EmployeeID SMALLINT PRIMARY KEY, ManagerID INT, Title NVARCHAR(50), EmployeeLevel SMALLINT)

;WITH Rec(EmployeeID, ManagerID, Title, EmployeeLevel) AS
(
	SELECT EmployeeID, ManagerID, CAST(Title AS NVARCHAR), 0
	FROM dbo.MyEmployees
	WHERE ManagerID IS NULL
	UNION ALL
	SELECT E.EmployeeID, E.ManagerID, CAST(REPLICATE('|   ', EmployeeLevel + 1) + E.Title AS NVARCHAR), EmployeeLevel + 1
	FROM Rec
	INNER JOIN dbo.MyEmployees AS E ON E.ManagerID=Rec.EmployeeID
)
INSERT INTO @Tree(EmployeeID, ManagerID, Title, EmployeeLevel)
OUTPUT inserted.*
SELECT EmployeeID, ManagerID, Title, EmployeeLevel
FROM Rec
WHERE EmployeeLevel <= 2



IF OBJECT_ID('tempdb.dbo.#Tree') IS NOT NULL DROP TABLE #Tree

/*Выбираем данные рекурсивно во временную таблицу*/
CREATE TABLE #Tree(EmployeeID SMALLINT PRIMARY KEY, ManagerID INT, Title NVARCHAR(50), EmployeeLevel SMALLINT)
;WITH Rec(EmployeeID, ManagerID, Title, EmployeeLevel) AS
(
	SELECT EmployeeID, ManagerID, CAST(Title AS NVARCHAR), 0
	FROM dbo.MyEmployees
	WHERE ManagerID IS NULL
	UNION ALL
	SELECT E.EmployeeID, E.ManagerID, CAST(REPLICATE('|   ', EmployeeLevel + 1) + E.Title AS NVARCHAR), EmployeeLevel + 1
	FROM Rec
	INNER JOIN dbo.MyEmployees AS E ON E.ManagerID=Rec.EmployeeID
)
INSERT INTO #Tree(EmployeeID, ManagerID, Title, EmployeeLevel)
OUTPUT inserted.*
SELECT EmployeeID, ManagerID, Title, EmployeeLevel
FROM Rec
WHERE EmployeeLevel <= 2


/*
Планы выполнения совершенно одинаковые (находятся в файлах TempTable.sqlplan VarTable.sqlplan)
*/