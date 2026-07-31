/*************************************************
 Curso T-SQL
 Autor: Landry

 Demonstração Consultas Eficientes:
 - Função em coluna String
 - Função em coluna DataHora
 - Tipo de Dado e conversão Implícita
 - Expressão aritmética em Coluna

*************************************************/
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
[Status], OnlineOrderFlag, replace(SalesOrderNumber,'SO','') as SalesOrderNumber, cast(PurchaseOrderNumber as nchar(3000)) as PurchaseOrderNumber, 
AccountNumber, CustomerID, SubTotal, TaxAmt, Freight, TotalDue, Comment, ModifiedDate
INTO dbo.SalesOrderHeader
FROM AdventureWorksLT.SalesLT.SalesOrderHeader
go

DECLARE @i int = 5
DECLARE @SalesID int = 1000
SET IDENTITY_INSERT dbo.SalesOrderHeader ON
WHILE @i < 200 BEGIN
	INSERT dbo.SalesOrderHeader
	([SalesOrderID], [RevisionNumber], [OrderDate], [DueDate], [ShipDate], [Status], [OnlineOrderFlag], [SalesOrderNumber], [PurchaseOrderNumber], [AccountNumber], [CustomerID], [SubTotal], [TaxAmt], [Freight], [TotalDue], [Comment], [ModifiedDate])
	SELECT SalesOrderID + @SalesID as SalesOrderID, RevisionNumber, 
	(DATEADD(day, ROUND(DATEDIFF(day, OrderDate + @i, OrderDate + @i) 
	* RAND(CHECKSUM(NEWID())), 5),DATEADD(second, abs(CHECKSUM(NEWID())) % 86400, 
	OrderDate + @i))) as OrderDate, 
	DueDate, ShipDate, 
	[Status], OnlineOrderFlag, replace(SalesOrderNumber,'SO','') as SalesOrderNumber, cast(PurchaseOrderNumber as nchar(3000)) as PurchaseOrderNumber, 
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
	([SalesOrderID], [SalesOrderDetailID], [OrderQty], [ProductID], [UnitPrice], [UnitPriceDiscount], [LineTotal], [rowguid], [ModifiedDate])
	SELECT SalesOrderID + @SalesID as SalesOrderID, SalesOrderDetailID + @SalesID as SalesOrderDetailID, OrderQty, ProductID, 
	UnitPrice, UnitPriceDiscount, LineTotal, rowguid, ModifiedDate
	FROM AdventureWorksLT.SalesLT.SalesOrderDetail

	SET @i = @i + 5
	SET @SalesID = @SalesID + 1000
END
SET IDENTITY_INSERT dbo.SalesOrderDetail OFF
go
/************************ FIM Cria Tabelas *****************************/


/***********************************************************
 - Uso de Função em coluna: LEFT, UPPER
************************************************************/

-- Verifica se existe índice na tabela "Customer"
EXEC sp_helpindex 'dbo.Customer'

-- Cria índice na tabela "Customer"
CREATE INDEX IX_Customer_FirstName 
ON dbo.Customer (FirstName)
INCLUDE (CustomerID, LastName)

-- Habilita estatísticas de IO
-- Habilitar Plano de Execução Gráfico no menu "Query"
-- SET STATISTICS IO OFF
SET STATISTICS IO ON

-- Consulta 1 (Non-Sargable)
SELECT CustomerID, FirstName, LastName
FROM dbo.Customer WHERE left(FirstName,1) = 'O'
-- Index Scan: Table 'Customer'. Scan count 1, logical reads 78

-- Consulta 2 (Sargable)
SELECT CustomerID, FirstName, LastName
FROM dbo.Customer WHERE FirstName like 'O%'
-- Index Seek: Table 'Customer'. Scan count 1, logical reads 2


-- Consulta 3 (Non-Sargable)
SELECT CustomerID, FirstName, LastName
FROM dbo.Customer WHERE upper(FirstName) = 'JOHN'
-- Index Scan: Table 'Customer'. Scan count 1, logical reads 78

-- Consulta 4 (Sargable)
SELECT CustomerID, FirstName, LastName
FROM dbo.Customer WHERE FirstName = 'John'
-- Index Seek: Table 'Customer'. Scan count 1, logical reads 5


DROP INDEX dbo.Customer.IX_Customer_FirstName

/***********************************************************
 - Uso de Função em coluna: CONVERT
************************************************************/

SELECT * FROM dbo.SalesOrderHeader

-- A coluna "OrderDate" tem horários diferentes de meia noite
SELECT count(*)
FROM dbo.SalesOrderHeader
WHERE OrderDate = '20080601'
-- Zero linhas

-- Cria índice na tabela "SalesOrderHeader"
CREATE INDEX IX_SalesOrderHeader_OrderDate 
ON dbo.SalesOrderHeader (OrderDate)
INCLUDE (SalesOrderID, CustomerID, TotalDue,ShipDate)

-- Consulta 1 (Non-Sargable)
SELECT SalesOrderID, CustomerID, TotalDue, OrderDate, ShipDate
FROM dbo.SalesOrderHeader
WHERE convert(varchar(8),OrderDate,112) = '20080904'
-- 32 linhas
-- Index Scan: Table 'SalesOrderHeader'. Scan count 1, logical reads 10

-- Consulta 2 (Sargable)
SELECT SalesOrderID, CustomerID, TotalDue, OrderDate, ShipDate
FROM dbo.SalesOrderHeader
WHERE OrderDate >= '20080904' and OrderDate < '20080905'
-- 32 linhas
-- Index Seek: Table 'SalesOrderHeader'. Scan count 1, logical reads 2

DROP INDEX dbo.SalesOrderHeader.IX_SalesOrderHeader_OrderDate



/***********************************************************
 - Problema de desempenho com conversão implícita
************************************************************/
-- Cria índice na tabela "SalesOrderHeader"
CREATE INDEX IX_SalesOrderHeader_SalesOrderNumber
ON dbo.SalesOrderHeader (SalesOrderNumber)
INCLUDE (SalesOrderID, OrderDate, [Status])

-- Consulta 1 (Non-Sargable)
SELECT SalesOrderID, SalesOrderNumber, OrderDate, [Status]
FROM dbo.SalesOrderHeader
WHERE SalesOrderNumber = 71863
-- Index Scan: Table 'SalesOrderHeader'. Scan count 1, logical reads 11

-- Consulta 2 (Sargable)
SELECT SalesOrderID, OrderDate, Status
FROM dbo.SalesOrderHeader
WHERE SalesOrderNumber = '71863'
-- Index Seek: Table 'SalesOrderHeader'. Scan count 1, logical reads 4

DROP INDEX dbo.SalesOrderHeader.IX_SalesOrderHeader_SalesOrderNumber


/***********************************************************
 - Operação Aritmética em Coluna
************************************************************/
-- Cria índice na tabela "SalesOrderDetail"
CREATE INDEX IX_SalesOrderDetail_LineTotal
ON dbo.SalesOrderDetail (LineTotal)
INCLUDE (SalesOrderID, SalesOrderDetailID, ProductID, OrderQty)

-- Consulta 1
SELECT SalesOrderID, SalesOrderDetailID,ProductID, LineTotal
FROM dbo.SalesOrderDetail
WHERE LineTotal * 0.5 >= 4000
-- 600 linhas
-- Index Scan: Table 'SalesOrderHeader'. Scan count 1, logical reads 124

-- Consulta 2
SELECT SalesOrderID, SalesOrderDetailID,ProductID, LineTotal
FROM dbo.SalesOrderDetail
WHERE LineTotal >= 4000 / 0.5
-- Index Seek: Table 'SalesOrderDetail'. Scan count 1, logical reads 7

DROP INDEX dbo.SalesOrderDetail.IX_SalesOrderDetail_LineTotal


/*******************
 Exclui tabelas
********************/
DROP TABLE dbo.Customer
DROP TABLE dbo.SalesOrderHeader
DROP TABLE dbo.SalesOrderDetail
