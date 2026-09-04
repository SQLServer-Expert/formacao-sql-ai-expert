/*************************************************************************************************************
 Curso T-SQL
 Autor: Landry

 View Indexada
 https://learn.microsoft.com/en-us/sql/relational-databases/views/create-indexed-views?view=sql-server-ver16
**************************************************************************************************************/
USE Aula
go

/**************************
 Cria tabelas
***************************/
IF object_id('dbo.Product') is not null
   DROP TABLE dbo.Product

SELECT a.ProductID, a.[Name] as Product, ProductNumber, Color, StandardCost, ListPrice, Size, [Weight], 
a.ProductCategoryID, b.[Name] as ProductCategory
INTO dbo.Product
FROM AdventureWorksLT.SalesLT.Product a
JOIN AdventureWorksLT.SalesLT.ProductCategory b on b.ProductCategoryID = a.ProductCategoryID

IF object_id('dbo.Customer') is not null
   DROP TABLE dbo.Customer

SELECT c.CustomerID as CustomerID,FirstName,MiddleName,Lastname,CompanyName,
EmailAddress,'RJ' as Region, dateadd(d,-CustomerID,getdate()) DataCadastro 
INTO dbo.Customer
FROM AdventureWorksLT.SalesLT.Customer c 

SET IDENTITY_INSERT dbo.Customer ON
DECLARE @i int = 1000 

WHILE @i < 28000 BEGIN
	INSERT dbo.Customer (CustomerID,FirstName,MiddleName,Lastname,CompanyName,EmailAddress,Region,DataCadastro)
	SELECT c.CustomerID + @i as CustomerID,FirstName,MiddleName,Lastname,CompanyName,
	EmailAddress,'RJ' as Region, dateadd(d,-CustomerID,getdate()) DataCadastro 
	FROM AdventureWorksLT.SalesLT.Customer c 
	WHERE FirstName not like 'O%' and CustomerID < 1000

	SET @i = @i + 1000
END
SET IDENTITY_INSERT dbo.Customer OFF
go

IF object_id('dbo.SalesOrderHeader') is not null
   DROP TABLE dbo.SalesOrderHeader

SELECT SalesOrderID, RevisionNumber, 
(DATEADD(day, ROUND(DATEDIFF(day, OrderDate, OrderDate) 
* RAND(CHECKSUM(NEWID())), 5),DATEADD(second, abs(CHECKSUM(NEWID())) % 86400, 
OrderDate))) as OrderDate, 
DueDate, ShipDate, 
Status, OnlineOrderFlag, replace(SalesOrderNumber,'SO','') as SalesOrderNumber, cast(PurchaseOrderNumber as nchar(3000)) as PurchaseOrderNumber, 
AccountNumber, CustomerID, SubTotal, TaxAmt, Freight, TotalDue, Comment, ModifiedDate
INTO dbo.SalesOrderHeader
FROM AdventureWorksLT.SalesLT.SalesOrderHeader
go

DECLARE @i int = 5
DECLARE @SalesID int = 1000
SET IDENTITY_INSERT dbo.SalesOrderHeader ON
WHILE @i < 200 BEGIN
	INSERT dbo.SalesOrderHeader
	(SalesOrderID, RevisionNumber, OrderDate, DueDate, ShipDate, Status, OnlineOrderFlag, SalesOrderNumber, PurchaseOrderNumber, AccountNumber, CustomerID, SubTotal, TaxAmt, Freight, TotalDue, Comment, ModifiedDate)
	SELECT SalesOrderID + @SalesID as SalesOrderID, RevisionNumber, 
	(DATEADD(day, ROUND(DATEDIFF(day, OrderDate + @i, OrderDate + @i) 
	* RAND(CHECKSUM(NEWID())), 5),DATEADD(second, abs(CHECKSUM(NEWID())) % 86400, 
	OrderDate + @i))) as OrderDate, 
	DueDate, ShipDate, 
	Status, OnlineOrderFlag, replace(SalesOrderNumber,'SO','') as SalesOrderNumber, cast(PurchaseOrderNumber as nchar(3000)) as PurchaseOrderNumber, 
	AccountNumber, CustomerID, SubTotal, TaxAmt, Freight, TotalDue, Comment, ModifiedDate	
	FROM AdventureWorksLT.SalesLT.SalesOrderHeader

	SET @i = @i + 5
	SET @SalesID = @SalesID + 1000
END
SET IDENTITY_INSERT dbo.SalesOrderHeader OFF
go

IF object_id('dbo.SalesOrderDetail') is not null
   DROP TABLE dbo.SalesOrderDetail

SELECT SalesOrderID, SalesOrderDetailID, OrderQty, ProductID, 
UnitPrice, UnitPriceDiscount, LineTotal, rowguid, ModifiedDate
INTO dbo.SalesOrderDetail
FROM AdventureWorksLT.SalesLT.SalesOrderDetail
go

DECLARE @i int = 5
DECLARE @SalesID int = 1000
SET IDENTITY_INSERT dbo.SalesOrderDetail ON
WHILE @i < 200 BEGIN
	INSERT dbo.SalesOrderDetail
	(SalesOrderID, SalesOrderDetailID, OrderQty, ProductID, UnitPrice, UnitPriceDiscount, LineTotal, rowguid, ModifiedDate)
	SELECT SalesOrderID + @SalesID as SalesOrderID, SalesOrderDetailID + @SalesID as SalesOrderDetailID, OrderQty, ProductID, 
	UnitPrice, UnitPriceDiscount, LineTotal, rowguid, ModifiedDate
	FROM AdventureWorksLT.SalesLT.SalesOrderDetail

	SET @i = @i + 5
	SET @SalesID = @SalesID + 1000
END
SET IDENTITY_INSERT dbo.SalesOrderDetail OFF
go
/************************ FIM Cria Tabelas *****************************/

SELECT count(*) FROM AdventureWorksLT.SalesLT.Customer -- 847
SELECT count(*) FROM AdventureWorksLT.SalesLT.SalesOrderHeader -- 32
SELECT count(*) FROM AdventureWorksLT.SalesLT.SalesOrderDetail -- 542

SELECT count(*) FROM dbo.Customer -- 12.646
SELECT count(*) FROM dbo.SalesOrderHeader -- 1.280
SELECT count(*) FROM dbo.SalesOrderDetail -- 21.680

set statistics io on

/***********************
 Consulta com GROUP BY
************************/
SELECT c.FirstName, c.LastName, d.ProductCategory,
count(*) as Qtd_Products,
sum(b.LineTotal) as LineTotal_SUM,
avg(b.UnitPrice) as UnitPrice_AVG

FROM dbo.SalesOrderHeader a 
JOIN dbo.SalesOrderDetail b on b.SalesOrderID = a.SalesOrderID
JOIN dbo.Customer c on c.CustomerID = a.CustomerID
JOIN dbo.Product d on d.ProductID = b.ProductID
GROUP BY c.FirstName, c.LastName, d.ProductCategory
ORDER BY c.FirstName, c.LastName, d.ProductCategory
/*
Table 'Customer'. Scan count 1, logical reads 249
Table 'SalesOrderDetail'. Scan count 1, logical reads 220
Table 'SalesOrderHeader'. Scan count 1, logical reads 1280
Table 'Product'. Scan count 1, logical reads 6
*/


/***********************************
 Cria View Indexada
 - count() e avg() não pode indexar
************************************/
go
CREATE or ALTER VIEW dbo.vw_Sales
WITH SCHEMABINDING
as
SELECT c.FirstName, c.LastName, d.ProductCategory,
count(*) as Qtd_Products,
sum(b.LineTotal) as LineTotal_SUM,
avg(b.UnitPrice) as UnitPrice_AVG

FROM dbo.SalesOrderHeader a 
JOIN dbo.SalesOrderDetail b on b.SalesOrderID = a.SalesOrderID
JOIN dbo.Customer c on c.CustomerID = a.CustomerID
JOIN dbo.Product d on d.ProductID = b.ProductID
GROUP BY c.FirstName, c.LastName, d.ProductCategory
go

-- 1o indice tem que ser Clustered
CREATE UNIQUE CLUSTERED INDEX ix_vw_Sales
ON dbo.vw_Sales(FirstName, LastName, ProductCategory)
go
/*
Msg 10136, Level 16, State 1, Line 149
Cannot create index on view "Aula.dbo.vw_Sales" because it uses the aggregate COUNT. Use COUNT_BIG instead.
*/
/*
Msg 10125, Level 16, State 1, Line 152
Cannot create index on view "Aula.dbo.vw_Sales" because it uses aggregate "AVG". Consider eliminating the aggregate, not indexing the view, 
or using alternate aggregates. For example, for AVG substitute SUM and COUNT_BIG, or for COUNT, substitute COUNT_BIG.
*/

SELECT objectproperty(object_id('dbo.vw_Sales'),'IsIndexable')
-- Zero não pode ser indexada!

/***********************************
 Cria View Indexada
 - count() -> count_big()
 - avg() -> count_big() e sum()
************************************/
go
CREATE or ALTER VIEW dbo.vw_Sales
WITH SCHEMABINDING
as
SELECT c.FirstName, c.LastName, d.ProductCategory,
count_big(*) as Qtd_Products,
sum(b.LineTotal) as LineTotal_SUM,
sum(b.UnitPrice) as UnitPrice_SUM

FROM dbo.SalesOrderHeader a 
JOIN dbo.SalesOrderDetail b on b.SalesOrderID = a.SalesOrderID
JOIN dbo.Customer c on c.CustomerID = a.CustomerID
JOIN dbo.Product d on d.ProductID = b.ProductID
GROUP BY c.FirstName, c.LastName, d.ProductCategory
go

CREATE UNIQUE CLUSTERED INDEX ix_vw_Sales
ON dbo.vw_Sales(FirstName, LastName, ProductCategory)
go
/*
Table 'vw_Sales'. Scan count 1, logical reads 5
*/

SELECT c.FirstName, c.LastName, d.ProductCategory,
count(*) as Qtd_Products,
sum(b.LineTotal) as LineTotal_SUM,
avg(b.UnitPrice) as UnitPrice_AVG

FROM dbo.SalesOrderHeader a 
JOIN dbo.SalesOrderDetail b on b.SalesOrderID = a.SalesOrderID
JOIN dbo.Customer c on c.CustomerID = a.CustomerID
JOIN dbo.Product d on d.ProductID = b.ProductID
GROUP BY c.FirstName, c.LastName, d.ProductCategory
ORDER BY c.FirstName, c.LastName, d.ProductCategory

-- Exclui objetos
DROP VIEW dbo.vw_Sales
DROP TABLE dbo.Customer
DROP TABLE dbo.SalesOrderHeader
DROP TABLE dbo.SalesOrderDetail