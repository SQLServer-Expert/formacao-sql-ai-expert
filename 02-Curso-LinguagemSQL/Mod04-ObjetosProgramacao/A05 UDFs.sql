/*****************************************************************************************************************************************************
 Curso T-SQL
 Autor: Landry

 Funções (User-Defined Functions - UDF)
 https://learn.microsoft.com/en-us/sql/t-sql/statements/create-function-transact-sql?view=sql-server-ver16
 https://learn.microsoft.com/en-us/sql/relational-databases/user-defined-functions/create-user-defined-functions-database-engine?view=sql-server-ver16
******************************************************************************************************************************************************/
USE Aula
go

/**************************
 Cria tabelas
***************************/
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

/*********************
 Função Escalar
*********************/
go
CREATE or ALTER FUNCTION dbo.UltimoDiaMesAnterior (@Data date)
RETURNS date
AS 
BEGIN
  RETURN dateadd(day, - DAY(@Data), @Data)
END
go

SELECT dbo.UltimoDiaMesAnterior(getdate()), getdate()
SELECT dbo.UltimoDiaMesAnterior('2017-01-01')
GO

--Verifica se a função é determinista
SELECT objectproperty(object_id('dbo.UltimoDiaMesAnterior'),'IsDeterministic')
GO
-- Zero não é determinista

-- Exclui
DROP FUNCTION dbo.UltimoDiaMesAnterior
GO


/**********************************
 Função Escalar
 - ATENÇÃO com desempenho
***********************************/
go
CREATE or ALTER FUNCTION dbo.SalesOrdersTotal (@SalesOrderID int)
RETURNS decimal(20,2)
AS 
BEGIN
	DECLARE @OrdersTotal decimal(20,2)

	SELECT @OrdersTotal = sum ((UnitPrice - UnitPriceDiscount) * OrderQty) 
	FROM dbo.SalesOrderDetail
	WHERE SalesOrderID = @SalesOrderID
	GROUP BY SalesOrderID

  RETURN @OrdersTotal
END
go

set statistics io on

SELECT SalesOrderID, OrderDate, 
dbo.SalesOrdersTotal(SalesOrderID) as OrdersTotal
FROM dbo.SalesOrderHeader
-- 1.280 linhas
/*
Table 'Worktable'. Scan count 1280, logical reads 46402
Table 'SalesOrderDetail'. Scan count 1, logical reads 220
Table 'SalesOrderHeader'. Scan count 1, logical reads 1280

Total IO: 47902 x 8Kb = 383216 Kb = 374.23 MB
*/

SELECT a.SalesOrderID, max(a.OrderDate) as OrderDate, 
sum ( (UnitPrice - UnitPriceDiscount) * OrderQty ) as OrdersTotal
FROM dbo.SalesOrderHeader a
JOIN dbo.SalesOrderDetail b on b.SalesOrderID = a.SalesOrderID
GROUP BY a.SalesOrderID
-- 1.280 linhas
/*
Table 'SalesOrderDetail'. Scan count 1, logical reads 220
Table 'SalesOrderHeader'. Scan count 1, logical reads 1280

Total IO: 1500 x 8 Kb = 12000 Kb = 11.71 MB
*/

DROP FUNCTION dbo.SalesOrdersTotal

/*********************************
 Função In-Line Table-Valued
**********************************/
go
CREATE OR ALTER FUNCTION dbo.OrderTotal (@SalesOrderID int)
RETURNS TABLE
AS 
RETURN (
SELECT a.SalesOrderID, max(a.OrderDate) as OrderDate, 
sum ( (UnitPrice - UnitPriceDiscount) * OrderQty ) as OrdersTotal,
count(*) as QtyLines
FROM dbo.SalesOrderHeader a
JOIN dbo.SalesOrderDetail b on b.SalesOrderID = a.SalesOrderID
WHERE a.SalesOrderID = @SalesOrderID
GROUP BY a.SalesOrderID)
go

SELECT * FROM dbo.OrderTotal(110915)

/**************************************
 Função Multi-Statement Table-Valued
***************************************/
go
CREATE OR ALTER FUNCTION dbo.OrderTotal_Multi (@SalesOrderID int)
RETURNS @Resultado TABLE (SalesOrderID int, OrderDate datetime, OrdersTotal decimal(11,2), QtyLines int)
AS 
BEGIN

INSERT @Resultado
SELECT a.SalesOrderID, max(a.OrderDate) as OrderDate, 
sum ( (UnitPrice - UnitPriceDiscount) * OrderQty ) as OrdersTotal,
count(*) as QtyLines
FROM dbo.SalesOrderHeader a
JOIN dbo.SalesOrderDetail b on b.SalesOrderID = a.SalesOrderID
WHERE a.SalesOrderID = @SalesOrderID
GROUP BY a.SalesOrderID

RETURN
END
go

SELECT * FROM dbo.OrderTotal_Multi(110915)

-- Exclui Funções Table-Value
DROP FUNCTION dbo.OrderTotal
DROP FUNCTION dbo.OrderTotal_Multi
DROP TABLE dbo.Customer
DROP TABLE dbo.SalesOrderHeader
DROP TABLE dbo.SalesOrderDetail
