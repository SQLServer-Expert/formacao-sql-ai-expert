/**********************************************************************
 Autor: Landry

 Estratégias de Indexação
 - Covering Index
 - AND
 - OR
***********************************************************************/
use Aula
go

/***********************************************************
 - Indice não atende por completo a consulta
************************************************************/
DROP TABLE IF exists dbo.SalesOrderHeader
go
SELECT SalesOrderID, RevisionNumber, OrderDate, DueDate, ShipDate, Status, OnlineOrderFlag, 
SalesOrderNumber, PurchaseOrderNumber, AccountNumber, CustomerID, SalesPersonID, 
SubTotal, TaxAmt, Freight, TotalDue, Comment, ModifiedDate
INTO dbo.SalesOrderHeader
FROM AdventureWorks.Sales.SalesOrderHeader

set statistics io on

-- Índice não atente por completo a consulta
CREATE INDEX IX_SalesOrderHeader_OrderDate 
ON dbo.SalesOrderHeader (OrderDate)

SELECT OrderDate,SalesOrderID,Status,SubTotal
FROM dbo.SalesOrderHeader --with (index(IX_SalesOrderHeader_OrderDate))
WHERE OrderDate BETWEEN '20130101' AND '20230131'
-- 25.943 linhas
-- TABLE SCAN -> Table 'SalesOrderHeader'. Scan count 1, logical reads 565
-- INDEX SEEK + LOOKUP -> Table 'SalesOrderHeader'. Scan count 1, logical reads 26016

-- Estratégia Covering Index
CREATE INDEX IX_SalesOrderHeader_OrderDate 
ON dbo.SalesOrderHeader (OrderDate)
INCLUDE (SalesOrderID,[Status],SubTotal)
WITH DROP_EXISTING

SELECT OrderDate,SalesOrderID,Status,SubTotal
FROM dbo.SalesOrderHeader --WITH(INDEX(0))
WHERE OrderDate BETWEEN '20130101' AND '20230131'
-- INDEX SEEK -> Table 'SalesOrderHeader'. Scan count 1, logical reads 116
-- TABLE SCAN -> Table 'SalesOrderHeader'. Scan count 1, logical reads 565

DROP INDEX dbo.SalesOrderHeader.IX_SalesOrderHeader_OrderDate 

/***********************************************************
 Estratégia de Indexação para AND
************************************************************/
CREATE INDEX IX_SalesOrderHeader_SalesPersonID
ON dbo.SalesOrderHeader (SalesPersonID)
INCLUDE (CustomerID,OrderDate,SalesOrderID,SubTotal)

CREATE INDEX IX_SalesOrderHeader_CustomerID
ON dbo.SalesOrderHeader (CustomerID)
INCLUDE (SalesPersonID,OrderDate,SalesOrderID,SubTotal)

SELECT OrderDate,SalesOrderID,SalesPersonID,SubTotal
FROM dbo.SalesOrderHeader --WITH(INDEX(IX_SalesOrderHeader_SalesPersonID))
WHERE SalesPersonID = 282 AND CustomerID = 29510
-- 4 linhas
-- INDEX SEEK: Table 'SalesOrderHeader'. Scan count 1, logical reads 2
-- Utilizou o índice IX_SalesOrderHeader_CustomerID


SELECT OrderDate,SalesOrderID,SalesPersonID,SubTotal
FROM dbo.SalesOrderHeader
WHERE SalesPersonID = 282
-- 271 linhas

SELECT OrderDate,SalesOrderID,SalesPersonID,SubTotal
FROM dbo.SalesOrderHeader
WHERE CustomerID = 29510
-- 4 linhas

DROP INDEX dbo.SalesOrderHeader.IX_SalesOrderHeader_SalesPersonID 
DROP INDEX dbo.SalesOrderHeader.IX_SalesOrderHeader_CustomerID 


/***********************************************************
 Estratégia de Indexação para OR
************************************************************/

-- Estratégia Indexação para AND
CREATE INDEX IX_SalesOrderHeader_CustomerID
ON dbo.SalesOrderHeader (CustomerID)
INCLUDE (SalesPersonID,OrderDate,SalesOrderID,SubTotal)

-- Estratégia Indexação para OR
CREATE INDEX IX_SalesOrderHeader_SalesPersonID
ON dbo.SalesOrderHeader (SalesPersonID)
INCLUDE (CustomerID,OrderDate,SalesOrderID,SubTotal)

SELECT OrderDate,SalesOrderID,SalesPersonID,SubTotal
FROM dbo.SalesOrderHeader --with(index(0))
WHERE SalesPersonID = 282 OR CustomerID = 29510
-- TABLE SCAN: Table 'SalesOrderHeader'. Scan count 1, logical reads 565
-- INDEX SCAN: Table 'SalesOrderHeader'. Scan count 1, logical reads 166
-- INDEX SEEK: Table 'SalesOrderHeader'. Scan count 2, logical reads 6

-- Remove Tabela
DROP TABLE IF exists dbo.SalesOrderHeader
