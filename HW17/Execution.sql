SELECT dbo.GetLevDistance(N'Пирожное', N'Мороженое')

SELECT * FROM Warehouse.Colors WHERE dbo.GetLevDistance(ColorName, N'Blue') <= 3

