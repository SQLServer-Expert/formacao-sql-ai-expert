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
 Uso de Função em coluna: LEFT, RIGHT
************************************************************/
set statistics io on

CREATE INDEX IX_Customer_FirstName ON dbo.Customer (FirstName)
INCLUDE (CustomerID, LastName)

-- Consulta 1
SELECT CustomerID, FirstName, LastName
FROM dbo.Customer WHERE left(FirstName,1) = 'G'
-- Index Scan: Table 'Customer'. Scan count 1, logical reads 114

-- Consulta 2
SELECT CustomerID, FirstName, LastName
FROM dbo.Customer WHERE FirstName like 'G%'
-- Index Seek: Table 'Customer'. Scan count 1, logical reads 7

SELECT CustomerID, FirstName, LastName--, DataCadastro
FROM dbo.Customer WHERE FirstName like '%G%'
-- Index Scan: Table 'Customer'. Scan count 1, logical reads 114
-- Table Scan: Table 'Customer'. Scan count 1, logical reads 155

DROP INDEX dbo.Customer.IX_Customer_FirstName

/***********************************************************
 - Uso de Função em coluna: CONVERT
************************************************************/
CREATE INDEX IX_SalesOrderHeader_DataCadastro 
ON dbo.SalesOrderHeader (ShipDate)
INCLUDE (SalesOrderID, CustomerID, TotalDue, OrderDate)

SELECT SalesOrderID, CustomerID, TotalDue, OrderDate, ShipDate
FROM dbo.SalesOrderHeader
WHERE ShipDate = '20110607'
-- Zero linhas

SELECT SalesOrderID, CustomerID, TotalDue, OrderDate, ShipDate
FROM dbo.SalesOrderHeader
WHERE convert(varchar(8),ShipDate,112) = '20110607'
-- 43 linhas
-- Table 'SalesOrderHeader'. Scan count 1, logical reads 181

SELECT SalesOrderID, CustomerID, TotalDue, OrderDate, ShipDate
FROM dbo.SalesOrderHeader
WHERE ShipDate >= '20110607' and ShipDate < '20110608'
-- 43 linhas
-- Table 'SalesOrderHeader'. Scan count 1, logical reads 2


SELECT SalesOrderID, CustomerID, TotalDue, OrderDate, ShipDate
FROM dbo.SalesOrderHeader
WHERE year(ShipDate) = 2011
-- 1.566 linhas
-- Index Scan: Table 'SalesOrderHeader'. Scan count 1, logical reads 181

SELECT SalesOrderID, CustomerID, TotalDue, OrderDate, ShipDate
FROM dbo.SalesOrderHeader
WHERE ShipDate >= '20110101' and ShipDate < '20120101'
-- 1.566 linhas
-- Index Seek: Table 'SalesOrderHeader'. Scan count 1, logical reads 11

DROP INDEX dbo.SalesOrderHeader.IX_SalesOrderHeader_DataCadastro


/***********************************************************
 - Problema de desempenho com conversão implícita
************************************************************/
UPDATE dbo.SalesOrderHeader set SalesOrderNumber = replace(SalesOrderNumber,'SO','')

CREATE INDEX IX_SalesOrderHeader_SalesOrderNumber
ON dbo.SalesOrderHeader (SalesOrderNumber)
INCLUDE (SalesOrderID, OrderDate, [Status])

SELECT SalesOrderID, OrderDate, Status
FROM dbo.SalesOrderHeader
WHERE SalesOrderNumber = 53683
-- Index Scan: Table 'SalesOrderHeader'. Scan count 1, logical reads 162

SELECT SalesOrderID, OrderDate, [Status]
FROM dbo.SalesOrderHeader
WHERE SalesOrderNumber = '53683'
-- Index Seek: Table 'SalesOrderHeader'. Scan count 1, logical reads 2
/*
nvarchar - UNICODE  2 bytes
varchar - Code Page 1 byte
*/

DROP INDEX dbo.SalesOrderHeader.IX_SalesOrderHeader_SalesOrderNumber


/***********************************************************
 Operação Aritmética em Coluna
************************************************************/
CREATE INDEX IX_SalesOrderHeader_SalesOrderID
ON dbo.SalesOrderHeader (SalesOrderID)
INCLUDE (SalesOrderNumber, OrderDate, [Status])

--ALTER TABLE dbo.SalesOrderHeader ADD SalesOrderIDx2 as (SalesOrderID * 2) persisted

-- Consulta 1
SELECT SalesOrderID, SalesOrderID * 2 as SalesOrderIDx2,SalesOrderNumber, 
OrderDate, [Status]
FROM dbo.SalesOrderHeader
WHERE SalesOrderID * 2 >= 144480
-- 2.884 linhas
-- Index Scan: Table 'SalesOrderHeader'. Scan count 1, logical reads 162

-- Consulta 2
SELECT SalesOrderID, SalesOrderID * 2 as SalesOrderIDx2,SalesOrderNumber, 
OrderDate, [Status]
FROM dbo.SalesOrderHeader
WHERE SalesOrderID >= 144480 / 2
-- 2.884 linhas
-- Index Seek: Table 'SalesOrderHeader'. Scan count 1, logical reads 17

DROP INDEX dbo.SalesOrderHeader.IX_SalesOrderHeader_SalesOrderID


/**************************************
 BETWEEN x IN
***************************************/
CREATE INDEX IX_Customer_CustomerID 
ON dbo.Customer(CustomerID)
INCLUDE (FirstName,Lastname,DataCadastro)

-- Consulta 1 (IN)
SELECT CustomerID,FirstName,Lastname,DataCadastro 
FROM dbo.Customer
WHERE CustomerID IN (11000,11001,11002,11003,11004,11005)
-- 6 linhas
-- Index Seek: Table 'Customer'. Scan count 6, logical reads 12

-- Consulta 2 (BETWEEN)
SELECT CustomerID,FirstName,Lastname,DataCadastro 
FROM dbo.Customer 
WHERE CustomerID BETWEEN 11000 and 11005
-- 6 linhas
-- Index Seek: Table 'Customer'. Scan count 1, logical reads 2

DROP INDEX dbo.Customer.IX_Customer_CustomerID

