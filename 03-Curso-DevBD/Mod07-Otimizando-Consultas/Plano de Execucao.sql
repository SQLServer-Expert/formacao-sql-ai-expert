/**********************************************************************
 Autor: Landry

 Hands On: Plano de Execução
***********************************************************************/
USE Aula
go

/*******************
 Plano de Execução
********************/
-- Texto
SET STATISTICS IO ON
SET STATISTICS IO OFF

SET STATISTICS TIME ON
SET STATISTICS TIME OFF

SET STATISTICS PROFILE ON
SET STATISTICS PROFILE OFF

-- XML
SET STATISTICS XML ON
SET STATISTICS XML OFF

/*******************
 Plano Estimado
********************/
-- Texto
SET SHOWPLAN_ALL ON 
SET SHOWPLAN_ALL OFF

-- XML
SET SHOWPLAN_XML ON
SET SHOWPLAN_XML ON

/**************************
 Plano de Execução
***************************/
-- Texto
SET STATISTICS IO ON
SET STATISTICS IO OFF

SET STATISTICS TIME ON
SET STATISTICS TIME OFF

SET STATISTICS PROFILE ON
SET STATISTICS PROFILE OFF

-- XML
SET STATISTICS XML ON
SET STATISTICS XML OFF


SELECT h.SalesOrderID, h.OrderDate, h.[Status], 
h.CustomerID, p.FirstName, p.LastName
FROM AdventureWorks.Sales.Customer c
JOIN AdventureWorks.Sales.SalesOrderHeader h ON c.CustomerID = h.CustomerID
JOIN AdventureWorks.Person.Person p ON p.BusinessEntityID = c.PersonID
WHERE h.OrderDate = '20080604'
/*
Table 'Person'. Scan count 0, logical reads 183
Table 'Customer'. Scan count 0, logical reads 126
Table 'SalesOrderHeader'. Scan count 1, logical reads 689

Total IO: 998 x 8Kb = 7984 Kb = 7,79 MB
*/

/**************************
 Plano Estimado
***************************/
-- Texto
SET SHOWPLAN_ALL ON 
SET SHOWPLAN_ALL OFF

-- XML
SET SHOWPLAN_XML ON
SET SHOWPLAN_XML ON

SELECT h.SalesOrderID, h.OrderDate, h.[Status], 
h.CustomerID, p.FirstName, p.LastName
FROM AdventureWorks.Sales.Customer c
JOIN AdventureWorks.Sales.SalesOrderHeader h ON c.CustomerID = h.CustomerID
JOIN AdventureWorks.Person.Person p ON p.BusinessEntityID = c.PersonID
WHERE h.OrderDate = '20080604'


/******************************
 Cria tabelas no Banco Aula
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
SELECT SalesOrderID, RevisionNumber, OrderDate, DueDate, ShipDate, Status, OnlineOrderFlag, 
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

/**********************************************
 - Algumas Etapas Importantes
***********************************************/
SET STATISTICS IO ON

-- Tabela Heap -> Table Scan
SELECT CustomerID,FirstName,MiddleName,Lastname,PersonType,EmailPromotion,Region,DataCadastro
FROM dbo.Customer

-- Tabela com Índice Clustered -> Clustered Index Scan = Table Scan
CREATE UNIQUE CLUSTERED INDEX IX_Customer_CustomerID ON dbo.Customer(CustomerID)

SELECT CustomerID,FirstName,MiddleName,Lastname,PersonType,EmailPromotion,Region,DataCadastro
FROM dbo.Customer

-- Clustered Index Seek
SELECT CustomerID,FirstName,MiddleName,Lastname,PersonType,EmailPromotion,Region,DataCadastro
FROM dbo.Customer
WHERE CustomerID = 11000

-- NonClustered Index Seek
CREATE INDEX IX_Customer_FirstName ON dbo.Customer(FirstName)

SELECT CustomerID,FirstName,MiddleName,Lastname,PersonType,EmailPromotion,Region,DataCadastro
FROM dbo.Customer
WHERE FirstName = 'John'
-- Table 'Customer'. Scan count 1, logical reads 45

DROP INDEX dbo.Customer.IX_Customer_FirstName
DROP INDEX dbo.Customer.IX_Customer_CustomerID

-- Bookmark Lookup com RID Lookup
CREATE INDEX IX_Customer_FirstName ON dbo.Customer(FirstName)

SELECT CustomerID,FirstName,MiddleName,Lastname,PersonType,EmailPromotion,Region,DataCadastro
FROM dbo.Customer
WHERE FirstName = 'John'
-- Table 'Customer'. Scan count 1, logical reads 45

-- Bookmark Lookup com Key Lookup
CREATE UNIQUE CLUSTERED INDEX IX_Customer_CustomerID ON dbo.Customer(CustomerID)

SELECT CustomerID,FirstName,MiddleName,Lastname,PersonType,EmailPromotion,Region,DataCadastro
FROM dbo.Customer
WHERE FirstName = 'John'
-- Table 'Customer'. Scan count 1, logical reads 99

DROP INDEX dbo.Customer.IX_Customer_FirstName
DROP INDEX dbo.Customer.IX_Customer_CustomerID

