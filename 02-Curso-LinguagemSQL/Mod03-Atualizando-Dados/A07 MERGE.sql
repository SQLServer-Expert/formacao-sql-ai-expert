/***********************************************************************************************
 Autor: Landry D. Salles Filho
 
 MERGE
 https://learn.microsoft.com/en-us/sql/t-sql/statements/merge-transact-sql?view=sql-server-ver16
************************************************************************************************/
USE Aula
go

/********************************
 Cria tabelas para demonstração
*********************************/
IF object_id('dbo.Product_Site ') is not null
   DROP TABLE dbo.Product_Site 

CREATE TABLE dbo.Product_Site (
ProductID int NOT NULL primary key,
[Name] nvarchar(50) NOT NULL,
ProductNumber nvarchar(25) NOT NULL,
Color nvarchar(15) NULL,
StandardCost money NOT NULL,
ListPrice money NOT NULL,
Size nvarchar(5) NULL,
[Weight] decimal(8, 2) NULL,
ProductCategoryID int NULL,
ProductModelID int NULL,
SellStartDate datetime NOT NULL,
SellEndDate datetime NULL,
DiscontinuedDate datetime NULL)
go

IF object_id('dbo.Product ') is not null
   DROP TABLE dbo.Product 

CREATE TABLE dbo.Product (
ProductID int NOT NULL primary key,
[Name] nvarchar(50) NOT NULL,
ProductNumber nvarchar(25) NOT NULL,
Color nvarchar(15) NULL,
StandardCost money NOT NULL,
ListPrice money NOT NULL,
Size nvarchar(5) NULL,
[Weight] decimal(8, 2) NULL,
ProductCategoryID int NULL,
ProductModelID int NULL,
SellStartDate datetime NOT NULL,
SellEndDate datetime NULL,
DiscontinuedDate datetime NULL)
go

INSERT Product
SELECT ProductID, [Name], ProductNumber, Color, StandardCost, ListPrice, Size, [Weight], ProductCategoryID, ProductModelID, SellStartDate, SellEndDate, DiscontinuedDate
FROM AdventureWorksLT.SalesLT.Product
go
/***************************** FIM Cria Tabelas **************************************/

SELECT * FROM Product
SELECT * FROM Product_Site

MERGE Product_Site d 
USING (SELECT * FROM Product) o 
ON (o.ProductID = d.ProductID)

-- UPDATE
WHEN MATCHED AND (o.[Name] <> d.[Name] or o.ProductNumber <> d.ProductNumber or o.Color <> d.Color or o.StandardCost <> d.StandardCost 
or o.ListPrice <> d.ListPrice or o.Size <> d.Size or o.[Weight] <> d.[Weight] or o.ProductCategoryID <> d.ProductCategoryID 
or o.ProductModelID <> d.ProductModelID or o.SellStartDate <> d.SellStartDate or o.SellEndDate <> d.SellEndDate or o.DiscontinuedDate <> d.DiscontinuedDate) 
THEN UPDATE SET d.[Name] = o.[Name], d.ProductNumber = o.ProductNumber, d.Color = o.Color, d.StandardCost = o.StandardCost, 
d.ListPrice = o.ListPrice, d.Size = o.Size, d.[Weight] = o.[Weight], d.ProductCategoryID = o.ProductCategoryID,
d.ProductModelID = o.ProductModelID, d.SellStartDate = o.SellStartDate, d.SellEndDate = o.SellEndDate, d.DiscontinuedDate = o.DiscontinuedDate

-- INSERT
WHEN NOT MATCHED BY TARGET THEN 
	INSERT (ProductID, [Name], ProductNumber, Color, StandardCost, ListPrice, Size, [Weight], ProductCategoryID, ProductModelID, SellStartDate, SellEndDate, DiscontinuedDate)
	VALUES (o.ProductID, o.[Name], o.ProductNumber, o.Color, o.StandardCost, o.ListPrice, o.Size, o.[Weight], o.ProductCategoryID, o.ProductModelID, o.SellStartDate, o.SellEndDate, o.DiscontinuedDate)

-- DELETE
WHEN NOT MATCHED BY SOURCE THEN DELETE;

/**************************************
 MERGE com OUTPUT
***************************************/
-- Alterações para testar INSERT, UPDATE e DELETE do MERGE
SELECT * FROM Product WHERE ProductID in (997,998,999,1000) ORDER BY ProductID
SELECT * FROM Product_Site WHERE ProductID in (997,998,999,1000) ORDER BY ProductID

-- Road-750 Red, 52
INSERT Product (ProductID,[Name], ProductNumber, Color, StandardCost, ListPrice, Size, [Weight], ProductCategoryID, ProductModelID, SellStartDate, SellEndDate, DiscontinuedDate)
VALUES (1000,'Road-750 Red, 52','BK-R19R-52','Red',343.6496,539.99,52,9262.31,6,31,'20120701',null,null)

-- Road-750 Black, 48
UPDATE Product SET [Name] = 'Road-750 Red, 48',
ProductNumber = 'BK-R19R-48', Color = 'Red'
WHERE ProductID = 998

-- Road-750 Black, 44
DELETE Product WHERE ProductID = 997 
go

-- Comando MERGE com OUTPUT
MERGE Product_Site d 
USING (SELECT * FROM Product) o 
ON (o.ProductID = d.ProductID)

-- UPDATE
WHEN MATCHED AND (o.[Name] <> d.[Name] or o.ProductNumber <> d.ProductNumber or o.Color <> d.Color or o.StandardCost <> d.StandardCost 
or o.ListPrice <> d.ListPrice or o.Size <> d.Size or o.[Weight] <> d.[Weight] or o.ProductCategoryID <> d.ProductCategoryID 
or o.ProductModelID <> d.ProductModelID or o.SellStartDate <> d.SellStartDate or o.SellEndDate <> d.SellEndDate or o.DiscontinuedDate <> d.DiscontinuedDate) 
THEN UPDATE SET d.[Name] = o.[Name], d.ProductNumber = o.ProductNumber, d.Color = o.Color, d.StandardCost = o.StandardCost, 
d.ListPrice = o.ListPrice, d.Size = o.Size, d.[Weight] = o.[Weight], d.ProductCategoryID = o.ProductCategoryID,
d.ProductModelID = o.ProductModelID, d.SellStartDate = o.SellStartDate, d.SellEndDate = o.SellEndDate, d.DiscontinuedDate = o.DiscontinuedDate

-- INSERT
WHEN NOT MATCHED BY TARGET THEN 
	INSERT (ProductID, [Name], ProductNumber, Color, StandardCost, ListPrice, Size, [Weight], ProductCategoryID, ProductModelID, SellStartDate, SellEndDate, DiscontinuedDate)
	VALUES (o.ProductID, o.[Name], o.ProductNumber, o.Color, o.StandardCost, o.ListPrice, o.Size, o.[Weight], o.ProductCategoryID, o.ProductModelID, o.SellStartDate, o.SellEndDate, o.DiscontinuedDate)

-- DELETE
WHEN NOT MATCHED BY SOURCE THEN DELETE

OUTPUT $action as Comando, inserted.ProductID as ProductID_INSERT, deleted.ProductID as ProductID_DELETE,
inserted.[Name] as Name_Novo, deleted.[Name] as Name_Anterior, 
inserted.ProductNumber as ProductNumber_Novo, deleted.ProductNumber as ProductNumber_Anterior,
inserted.Color as Color_Novo, deleted.Color as Color_Anterior;


-- Exclui tabelas
DROP TABLE dbo.Product
DROP TABLE dbo.Product_Site
