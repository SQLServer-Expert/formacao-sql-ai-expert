/**********************************************************************
 Autor: Landry

 Estratégias de Indexação
 - GROUP BY
***********************************************************************/
use Aula
go

/***********************************************************
 Cria tabelas para Hands On
************************************************************/
DROP TABLE IF exists dbo.SalesOrderHeader
go
SELECT SalesOrderID, RevisionNumber, OrderDate, DueDate, ShipDate, Status, OnlineOrderFlag, 
SalesOrderNumber, PurchaseOrderNumber, AccountNumber, CustomerID, SalesPersonID, 
SubTotal, TaxAmt, Freight, TotalDue, Comment, ModifiedDate
INTO dbo.SalesOrderHeader
FROM AdventureWorks.Sales.SalesOrderHeader

DROP TABLE IF exists dbo.Customer

SELECT c.CustomerID as CustomerID,FirstName,MiddleName,Lastname,PersonType,
EmailPromotion,'RJ' as Region, dateadd(d,-BusinessEntityID,getdate()) DataCadastro 
INTO dbo.Customer
FROM AdventureWorks.Sales.Customer c 
JOIN AdventureWorks.Person.Person p ON p.BusinessEntityID = c.PersonID

/***********************************************************
 GROUP BY com JOIN
************************************************************/
set statistics io on

SELECT c.FirstName,c.LastName, 
sum(h.TotalDue) as TotalDue, count(*) as QtdSales
FROM dbo.SalesOrderHeader h 
JOIN dbo.Customer c ON h.CustomerID = c.CustomerID
WHERE h.OrderDate >= '20130101' AND h.OrderDate < '20140101'
GROUP BY c.FirstName,c.LastName
ORDER BY TotalDue desc
-- Table 'Customer'. Scan count 1, logical reads 155
-- Table 'SalesOrderHeader'. Scan count 1, logical reads 565

CREATE NONCLUSTERED INDEX ix_SalesOrderHeader_OrderDate_CustomerID 
ON dbo.SalesOrderHeader (OrderDate,CustomerID)
INCLUDE(TotalDue)

CREATE NONCLUSTERED INDEX ix_Customer_FirstName_LastName
ON dbo.Customer (FirstName,LastName,CustomerID)

-- Mostrar que o DTA só indica um índice!
/* Stream Aggregate
Table 'Customer'. Scan count 1, logical reads 114
Table 'SalesOrderHeader'. Scan count 1, logical reads 62
*/


CREATE NONCLUSTERED INDEX ix_Customer_CustomerID
ON dbo.Customer (CustomerID,FirstName,LastName)

/*
Table 'Customer'. Scan count 1, logical reads 114
Table 'SalesOrderHeader'. Scan count 1, logical reads 62
*/
-- 50%
SELECT c.FirstName,c.LastName, 
sum(h.TotalDue) as TotalDue, count(*) as QtdSales
FROM dbo.SalesOrderHeader h 
JOIN dbo.Customer c ON h.CustomerID = c.CustomerID
WHERE h.OrderDate >= '20130101' AND h.OrderDate < '20140101'
GROUP BY c.FirstName,c.LastName
ORDER BY TotalDue desc

-- 50%
SELECT c.FirstName,c.LastName, 
sum(h.TotalDue) as TotalDue, count(*) as QtdSales
FROM dbo.SalesOrderHeader h 
JOIN dbo.Customer c with(index(ix_Customer_FirstName_LastName))
ON h.CustomerID = c.CustomerID
WHERE h.OrderDate >= '20130101' AND h.OrderDate < '20140101'
GROUP BY c.FirstName,c.LastName
ORDER BY TotalDue desc

/*****************************************
 GROUP BY uma tabela
******************************************/
SELECT h.CustomerID, 
sum(h.TotalDue) as TotalDue, count(*) as QtdSales
FROM dbo.SalesOrderHeader h 
WHERE h.OrderDate >= '20130101' AND h.OrderDate < '20140101'
GROUP BY h.CustomerID
ORDER BY TotalDue desc
/* Hash Match
Table 'SalesOrderHeader'. Scan count 1, logical reads 62
*/

CREATE NONCLUSTERED INDEX ix_SalesOrderHeader_CustomerID_OrderDate
ON dbo.SalesOrderHeader (CustomerID,OrderDate)
INCLUDE(TotalDue)
/* Stream Aggregate
Table 'SalesOrderHeader'. Scan count 1, logical reads 135
*/

-- 47%
SELECT h.CustomerID, 
sum(h.TotalDue) as TotalDue, count(*) as QtdSales
FROM dbo.SalesOrderHeader h 
WHERE h.OrderDate >= '20130101' AND h.OrderDate < '20140101'
GROUP BY h.CustomerID
ORDER BY TotalDue desc

-- 53%
SELECT h.CustomerID, 
sum(h.TotalDue) as TotalDue, count(*) as QtdSales
FROM dbo.SalesOrderHeader h with(index(ix_SalesOrderHeader_OrderDate_CustomerID))
WHERE h.OrderDate >= '20130101' AND h.OrderDate < '20140101'
GROUP BY h.CustomerID
ORDER BY TotalDue desc



