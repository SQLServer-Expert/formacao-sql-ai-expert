/**********************************************************************
 Autor: Landry

 Consutlas T-SQL Eficientes
***********************************************************************/
USE Aula
go

/******************************
 Cria tabelas para o Hands On
*******************************/
DROP TABLE IF exists dbo.Customer
go
SELECT c.CustomerID as CustomerID,FirstName,MiddleName,Lastname,PersonType,
EmailPromotion,'RJ' as Region, dateadd(d,-BusinessEntityID,getdate()) DataCadastro 
INTO dbo.Customer
FROM AdventureWorks.Sales.Customer c 
JOIN AdventureWorks.Person.Person p ON p.BusinessEntityID = c.PersonID

DROP TABLE IF exists dbo.SalesOrderHeader
go
SELECT SalesOrderID, RevisionNumber, OrderDate, DueDate, DATEADD(hh,1,ShipDate) as ShipDate, Status, OnlineOrderFlag, 
SalesOrderNumber, PurchaseOrderNumber, AccountNumber, CustomerID, SalesPersonID, 
SubTotal, TaxAmt, Freight, TotalDue, Comment, ModifiedDate
INTO dbo.SalesOrderHeader
FROM AdventureWorks.Sales.SalesOrderHeader

DROP TABLE IF exists dbo.SalesOrderDetail
go
SELECT SalesOrderID, SalesOrderDetailID, CarrierTrackingNumber, OrderQty, ProductID, 
SpecialOfferID, UnitPrice, UnitPriceDiscount, LineTotal, rowguid, ModifiedDate
INTO dbo.SalesOrderDetail
FROM AdventureWorks.Sales.SalesOrderDetail
/********************** Fim Cria Tabelas **************************/


/***********************************************************
 Consultas Dinâmicas
************************************************************/
set statistics io on

CREATE INDEX IX_SalesOrderHeader_OrderDate
ON dbo.SalesOrderHeader (OrderDate)

-- Consulta 1
SELECT * FROM dbo.SalesOrderHeader
WHERE OrderDate >= '20110714' AND OrderDate < '20110715'
-- 4 linhas
-- Index Seek + Lookup: Table 'SalesOrderHeader'. Scan count 1, logical reads 6

-- Consulta dinâmica
DECLARE @DataINI varchar(8), @DataFIM varchar(8)
SET @DataINI = '20110714'
SET @DataFIM = '20110715'

SELECT * FROM dbo.SalesOrderHeader
WHERE OrderDate >= @DataINI AND OrderDate < @DataFIM
-- 4 linhas
-- Table Scan: Table 'SalesOrderHeader'. Scan count 1, logical reads 565
go


/***********************************************************
 OPTIMIZE FOR
************************************************************/
DECLARE @DataINI varchar(8), @DataFIM varchar(8)
SET @DataINI = '20110714'
SET @DataFIM = '20110715'

SELECT * FROM dbo.SalesOrderHeader
WHERE OrderDate >= @DataINI AND OrderDate < @DataFIM
OPTION (OPTIMIZE FOR (@DataINI = '20110714', @DataFIM = '20110715'))
-- Index Seek + Lookup: Table 'SalesOrderHeader'. Scan count 1, logical reads 6
go


/***********************************************************
 sp_executesql
************************************************************/
DECLARE @DataINI varchar(8), @DataFIM varchar(8), @Query nvarchar(2000)
SET @DataINI = '20110714'
SET @DataFIM = '20110715'

SET @Query = N'
SELECT * FROM dbo.SalesOrderHeader
WHERE OrderDate >= @ParamDataINI AND OrderDate < @ParamDataFIM'

EXEC SP_EXECUTESQL @Query,N'@ParamDataINI varchar(8),@ParamDataFIM varchar(8)',
@ParamDataINI = @DataINI, @ParamDataFIM = @DataFIM
-- Table 'SalesOrderHeader'. Scan count 1, logical reads 19
go

DROP INDEX dbo.SalesOrderHeader.IX_SalesOrderHeader_OrderDate


/***********************************************************
 Parameter Sniffing
************************************************************/
-- Atualiza uma linha da tabela Customer para 'SP' o restante ficou com 'RJ'
UPDATE TOP(1) dbo.Customer SET Region = 'SP'

CREATE INDEX IX_Customer_Region ON dbo.Customer (Region)
-- Total de linhas na tabela Customer: 19.119 

SELECT Region, count(*) as QtdLinhas
FROM dbo.Customer 
GROUP BY Region
ORDER BY 1

-- Consulta 1
SELECT * FROM dbo.Customer --with(index(IX_Customer_Region)) 
WHERE Region = 'RJ'
-- 19.118 linhas com valor 'RJ'
-- Table Scan: Table 'Customer'. Scan count 1, logical reads 155
--             Table 'Customer'. Scan count 1, logical reads 19168

-- Consulta 2
SELECT * FROM dbo.Customer WHERE Region = 'SP'
-- 1 linha com valor 'SP'
-- Index Seek + Bookmark Lookup: Table 'Customer'. Scan count 1, logical reads 3


/***********************************************************
 - Parameter Sniffing: Stored Procedure
************************************************************/
DROP PROCEDURE IF exists spu_CustomerRegion
go
CREATE or ALTER PROCEDURE spu_CustomerRegion
@Region varchar(2)
as  
SELECT * FROM dbo.Customer WHERE Region = @Region
go

/***********************************************************
 - Parameter Sniffing: Stored Procedure
************************************************************/
EXEC spu_CustomerRegion 'RJ' --with RECOMPILE
-- 1a exec: Table 'Customer'. Scan count 1, logical reads 155
-- 2a exec: Table 'Customer'. Scan count 1, logical reads 19168
-- Table Scan

EXEC spu_CustomerRegion 'SP' --with RECOMPILE
-- 2a exec: Table 'Customer'. Scan count 1, logical reads 155
-- 1a exec: Table 'Customer'. Scan count 1, logical reads 3
-- Index Seek + Bookmark Loopup

-- 1 linha com valor 'SP'
-- Index Seek + Bookmark Lookup: Table 'Customer'. Scan count 1, logical reads 3

/***********************************************************
 - Parameter Sniffing: Stored Procedure
************************************************************/
EXEC spu_CustomerRegion 'RJ'
-- 19.118 linhas com valor 'RJ'
-- Index Seek + Bookmark Lookup: Table 'Customer'. Scan count 1, logical reads 19168


/***********************************************************
 - Parameter Sniffing: Stored Procedure
************************************************************/
go
ALTER PROCEDURE spu_CustomerRegion
@Region varchar(2)
WITH RECOMPILE
as  
SELECT * FROM dbo.Customer WHERE Region = @Region
go

/***********************************************************
 - Parameter Sniffing: Stored Procedure
************************************************************/
EXEC spu_CustomerRegion 'SP'
-- 1 linha com valor 'SP'
-- Index Seek + Bookmark Lookup: Table 'Customer'. Scan count 1, logical reads 3

EXEC spu_CustomerRegion 'RJ'
-- 19.118 linhas com valor 'RJ'
-- Table Scan: Table 'Customer'. Scan count 1, logical reads 155

DROP INDEX dbo.Customer.IX_Customer_Region

