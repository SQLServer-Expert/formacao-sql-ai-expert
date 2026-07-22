/**********************************************************************
 Autor: Landry

 Estratégias de Indexação
 - JOINs
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
 Hash JOIN
************************************************************/
set statistics io on

-- Hash
SELECT h.SalesOrderID, h.OrderDate, h.[Status], h.CustomerID, c.FirstName,c.LastName
FROM dbo.SalesOrderHeader h 
JOIN dbo.Customer c ON h.CustomerID = c.CustomerID
WHERE OrderDate BETWEEN '20130801' AND '20130831'
-- 1.789 linhas
-- Table 'Customer'. Scan count 1, logical reads 155
-- Table 'SalesOrderHeader'. Scan count 1, logical reads 565
-- Total de IO: 720 x 8 kb = 5760 kb = 5.6 MB


/***********************************************************
 Estratégia Indexação para Nested Loop JOIN
************************************************************/
CREATE INDEX IX_Customer_CustomerID
ON dbo.Customer (CustomerID)
INCLUDE (FirstName,LastName)

CREATE INDEX IX_SalesOrderHeader_OrderDate
ON dbo.SalesOrderHeader (OrderDate)
INCLUDE (CustomerID,SalesOrderID,[Status],SubTotal)

-- Hash
SELECT h.SalesOrderID, h.OrderDate, h.[Status], h.CustomerID, c.FirstName,c.LastName
FROM dbo.SalesOrderHeader h 
JOIN dbo.Customer c ON h.CustomerID = c.CustomerID
WHERE OrderDate BETWEEN '20130801' AND '20130831'
-- 1.789 linhas
-- Table 'Customer'. Scan count 1, logical reads 114
-- Table 'SalesOrderHeader'. Scan count 1, logical reads 11

-- Neste Loop
SELECT h.SalesOrderID, h.OrderDate, h.[Status], h.CustomerID, c.FirstName,c.LastName
FROM dbo.SalesOrderHeader h 
INNER LOOP JOIN dbo.Customer c ON h.CustomerID = c.CustomerID
WHERE OrderDate BETWEEN '20130801' AND '20130831'
-- 1.789 linhas
-- Table 'Customer'. Scan count 1789, logical reads 3828
-- Table 'SalesOrderHeader'. Scan count 1, logical reads 11

-- Neste Loop invertendo as tabelas
SELECT h.SalesOrderID, h.OrderDate, h.[Status], h.CustomerID, c.FirstName,c.LastName
FROM dbo.Customer c
INNER LOOP JOIN dbo.SalesOrderHeader h  ON h.CustomerID = c.CustomerID
WHERE OrderDate BETWEEN '20130801' AND '20130831'
-- 1.789 linhas
-- Table 'SalesOrderHeader'. Scan count 2, logical reads 22
-- Table 'Worktable'. Scan count 2, logical reads 179279
-- Table 'Customer'. Scan count 3, logical reads 337

/**************************************************************************
 Para o Nested Loop ser considerado a Outer Table precisa ser pequena 
 ou filtro de alta seletividade
**************************************************************************/
-- Nested Loop (filtro de 1 dia)
SELECT h.SalesOrderID, h.OrderDate, h.[Status], h.CustomerID, c.FirstName,c.LastName
FROM dbo.SalesOrderHeader h 
JOIN dbo.Customer c ON h.CustomerID = c.CustomerID
WHERE OrderDate >= '20130819' AND OrderDate < '20130820'
-- 59 linhas
-- Table 'Customer'. Scan count 59, logical reads 143
-- Table 'SalesOrderHeader'. Scan count 1, logical reads 2

DROP INDEX dbo.Customer.IX_Customer_CustomerID 
DROP INDEX dbo.SalesOrderHeader.IX_SalesOrderHeader_OrderDate


/***********************************************************
 Estratégia Indexação para Merge JOIN
************************************************************/
CREATE INDEX IX_Customer_CustomerID
ON dbo.Customer (CustomerID)
INCLUDE (FirstName,LastName)

CREATE INDEX IX_SalesOrderHeader_CustomerID
ON dbo.SalesOrderHeader (CustomerID)
INCLUDE (SalesOrderID,OrderDate,[Status],SubTotal)

-- Não utilizou MERGE, utilizando Hash (31%)
SELECT h.SalesOrderID, h.OrderDate, h.[Status], h.CustomerID, c.FirstName,c.LastName
FROM dbo.SalesOrderHeader h JOIN dbo.Customer c ON h.CustomerID = c.CustomerID
WHERE OrderDate BETWEEN '20130801' AND '20130831'
-- 1.789 linhas
-- Table 'Customer'. Scan count 1, logical reads 114
-- Table 'SalesOrderHeader'. Scan count 1, logical reads 155

-- Hint para utilizar MERGE (69%)
SELECT h.SalesOrderID, h.OrderDate, h.[Status], h.CustomerID, c.FirstName,c.LastName
FROM dbo.SalesOrderHeader h 
INNER MERGE JOIN dbo.Customer c ON h.CustomerID = c.CustomerID
WHERE OrderDate BETWEEN '20130801' AND '20130831'
-- Table 'Customer'. Scan count 1, logical reads 114
-- Table 'SalesOrderHeader'. Scan count 1, logical reads 155

/*************************************************************************************
 Sem UNIQUE em um dos lados o SQL Server identifica como sendo relacionamento N x N,
 Sendo necerrário utilizar tabela temporária, aumentando muito o custo do MERGE!
**************************************************************************************/
CREATE UNIQUE INDEX IX_Customer_CustomerID
ON dbo.Customer (CustomerID)
INCLUDE (FirstName,LastName)
WITH DROP_EXISTING

-- utilizou MERGE (44%)
SELECT h.SalesOrderID, h.OrderDate, h.[Status], h.CustomerID, c.FirstName,c.LastName
FROM dbo.SalesOrderHeader h JOIN dbo.Customer c ON h.CustomerID = c.CustomerID
WHERE OrderDate BETWEEN '20130801' AND '20130831'
-- Table 'SalesOrderHeader'. Scan count 1, logical reads 155
-- Table 'Customer'. Scan count 1, logical reads 114

-- Hint para utilizar HASH (56%)
SELECT h.SalesOrderID, h.OrderDate, h.[Status], h.CustomerID, c.FirstName,c.LastName
FROM dbo.SalesOrderHeader h 
INNER HASH JOIN dbo.Customer c ON h.CustomerID = c.CustomerID
WHERE OrderDate BETWEEN '20130801' AND '20130831'
-- Table 'SalesOrderHeader'. Scan count 1, logical reads 155
-- Table 'Customer'. Scan count 1, logical reads 114

-- Exclui tabelas
DROP TABLE IF exists dbo.SalesOrderHeader
DROP TABLE IF exists dbo.Customer

