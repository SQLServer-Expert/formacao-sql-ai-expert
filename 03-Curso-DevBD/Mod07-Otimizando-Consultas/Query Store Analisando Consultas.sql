/*************************************************
 Autor: Landry Duailibe

 Hands On: Query Store - Analisando Consultas
**************************************************/
use master
go

/***********************************
 Prepara Hands On
************************************/
CREATE DATABASE DB_HandsOn
go
ALTER DATABASE DB_HandsOn SET RECOVERY simple
go

use DB_HandsOn
go

-- Tabela Customer
DROP TABLE IF exists dbo.Customer
go
CREATE TABLE dbo.Customer (
CustomerID int not null CONSTRAINT pk_Customer PRIMARY KEY, 
Title nvarchar(8) null, 
FirstName nvarchar(50) null, 
MiddleName nvarchar(50) null, 
LastName nvarchar(50) null,
[Name] nvarchar(160) null) 
go

-- Carrega linhas a partir do AdventureWorks
set nocount on
INSERT dbo.Customer (CustomerID, Title, FirstName, MiddleName, LastName, [Name])
SELECT c.CustomerID, Title, FirstName, MiddleName, LastName, FirstName + isnull(' ' + MiddleName,'') + isnull(' ' + LastName,'') as [Name]
FROM AdventureWorks.Sales.Customer c
JOIN AdventureWorks.Person.Person p on p.BusinessEntityID = c.PersonID
go

-- Tabela SalesOrderHeader
DROP TABLE IF exists dbo.SalesOrderHeader
go
CREATE TABLE dbo.SalesOrderHeader(
SalesOrderID int NOT NULL identity CONSTRAINT pk_SalesOrderHeader PRIMARY KEY,
OrderDate datetime NOT NULL,
Status tinyint NOT NULL,
OnlineOrderFlag bit NOT NULL,
SalesOrderNumber char(200) NOT NULL,
CustomerID int NOT NULL,
SalesPersonID int NULL,
TerritoryID int NULL,
SubTotal money NOT NULL,
TaxAmt money NOT NULL,
Freight money NOT NULL,
TotalDue money NOT NULL,
Comment nvarchar(128) NULL)
go

-- Alimenta tabela com 6.293.000 linhas
set nocount on

INSERT dbo.SalesOrderHeader (OrderDate, [Status], OnlineOrderFlag, SalesOrderNumber, CustomerID, SalesPersonID, TerritoryID, SubTotal, TaxAmt, Freight, TotalDue, Comment)
SELECT OrderDate, Status, OnlineOrderFlag, 
SalesOrderNumber, CustomerID, SalesPersonID, TerritoryID,  
SubTotal, TaxAmt, Freight, TotalDue, Comment
FROM AdventureWorks.Sales.SalesOrderHeader
go 200
-- Leva 1 minuto

set nocount off

-- SELECT count(*) as QtdLinhas FROM dbo.SalesOrderHeader
/************************* FIM Prepara Hands On ******************************/

/***************************************
 Limpar os dados no Query Store
****************************************/
ALTER DATABASE DB_HandsOn SET QUERY_STORE CLEAR ALL

/******************************************************************
 Consulta simples não vai para o Query Store configuração padrão
*******************************************************************/
SELECT * FROM dbo.Customer WHERE CustomerID = 11000

/********************************
 Executar antes de criar índice
*********************************/
SELECT c.Name as Customer, count(*) as Sales_Qty, sum(h.TotalDue) as Total
FROM dbo.SalesOrderHeader h
JOIN dbo.Customer c on c.CustomerID = h.CustomerID
WHERE h.OrderDate >= '20140101' and h.OrderDate < '20150101'
GROUP BY c.Name
ORDER BY Total desc

-- Cria índice para alterar o plano de execução
CREATE NONCLUSTERED INDEX ix_SalesOrderHeader_OrderDate
ON dbo.SalesOrderHeader (OrderDate)
INCLUDE (CustomerID,TotalDue)

-- Para limpar dados de consulta específica
EXEC sp_query_store_remove_query @query_id = 7

/********************************
 Executar após criar índice
*********************************/
SELECT c.Name as Customer, count(*) as Sales_Qty, sum(h.TotalDue) as Total
FROM dbo.SalesOrderHeader h
JOIN dbo.Customer c on c.CustomerID = h.CustomerID
WHERE h.OrderDate >= '20140101' and h.OrderDate < '20150101'
GROUP BY c.Name
ORDER BY Total desc


/*************************
 Exclui o banco
**************************/
use master
go
ALTER DATABASE DB_HandsOn SET READ_ONLY WITH ROLLBACK IMMEDIATE
go
DROP DATABASE IF exists DB_HandsOn




