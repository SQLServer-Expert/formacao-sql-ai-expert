/**********************************************************************
 Autor: Landry

 - Missing Index
 - Database Engine Tuning Advisor (DTA)
***********************************************************************/
use Aula
go

/***********************************************************
 Cria Tabelas para o Hands On
************************************************************/
set nocount on

DROP TABLE IF exists dbo.Customer
go
SELECT c.CustomerID as CustomerID,FirstName,MiddleName,Lastname,Title,PersonType,
EmailPromotion,case when c.CustomerID < 20000 then 'RJ' else 'SP' end as Region, 
s.[Name] as Store, t.[Name] as Territory,
dateadd(d,-p.BusinessEntityID,getdate()) DataCadastro 
INTO dbo.Customer
FROM AdventureWorks.Sales.Customer c 
JOIN AdventureWorks.Sales.Store s ON s.BusinessEntityID = c.StoreID
JOIN AdventureWorks.Sales.SalesTerritory t ON t.TerritoryID = c.TerritoryID
JOIN AdventureWorks.Person.Person p ON p.BusinessEntityID = c.PersonID
go

DECLARE @CustomerID int
SELECT @CustomerID = max(CustomerID) + 1 FROM dbo.Customer

INSERT dbo.Customer
SELECT ROW_NUMBER() OVER (ORDER BY CustomerID) + @CustomerID as CustomerID,FirstName,MiddleName,Lastname,Title,PersonType,
EmailPromotion,case when c.CustomerID < 20000 then 'RJ' else 'SP' end as Region, 
s.[Name] as Store, t.[Name] as Territory,
dateadd(d,-p.BusinessEntityID,getdate()) DataCadastro 
FROM AdventureWorks.Sales.Customer c 
JOIN AdventureWorks.Sales.Store s ON s.BusinessEntityID = c.StoreID
JOIN AdventureWorks.Sales.SalesTerritory t ON t.TerritoryID = c.TerritoryID
JOIN AdventureWorks.Person.Person p ON p.BusinessEntityID = c.PersonID
go 100

ALTER TABLE dbo.Customer ADD CONSTRAINT pk_Customer PRIMARY KEY (CustomerID)

DROP TABLE IF exists dbo.SalesOrderHeader
go
SELECT SalesOrderID, RevisionNumber, OrderDate, DueDate, ShipDate, Status, OnlineOrderFlag, 
SalesOrderNumber, PurchaseOrderNumber, AccountNumber, CustomerID, SalesPersonID, 
SubTotal, TaxAmt, Freight, TotalDue, Comment, ModifiedDate
INTO dbo.SalesOrderHeader
FROM AdventureWorks.Sales.SalesOrderHeader
/********************************** FIM Cria tabelas *******************************/


/*********************************************
 - Missing index
 - Database Engine Tuning Advisor (DTA)
**********************************************/
set statistics io on


-- Consulta 1
SELECT c.Store, h.CustomerID, c.FirstName, c.LastName,
h.SalesOrderID, h.OrderDate, h.[Status]
FROM Customer c
JOIN SalesOrderHeader h ON c.CustomerID = h.CustomerID
WHERE h.OrderDate >= '20120101' and h.OrderDate < '20130101'
and c.Territory = 'Southeast'
-- Table 'Customer'. Scan count 0, logical reads 11998
-- Table 'SalesOrderHeader'. Scan count 1, logical reads 565
go 4


-- Consulta 2
SELECT top 100 c.Store, h.CustomerID, c.FirstName, c.LastName,
h.SalesOrderID, h.OrderDate, h.[Status]

FROM Customer c
JOIN SalesOrderHeader h ON c.CustomerID = h.CustomerID
WHERE c.Territory = 'Southeast'
ORDER BY c.Store desc
-- Table 'SalesOrderHeader'. Scan count 1, logical reads 565
-- Table 'Customer'. Scan count 1, logical reads 1102
go 9

/**********************************
 Missing Index
***********************************/
-- Obter todos os Missing Index
SELECT d.statement as table_name,
d.equality_columns,
d.inequality_columns,
d.included_columns,
s.avg_total_user_cost as avg_est_plan_cost,
s.avg_user_impact as avg_est_cost_reduction,
s.user_scans + s.user_seeks as times_requested
FROM sys.dm_db_missing_index_groups AS g
JOIN sys.dm_db_missing_index_group_stats as s on g.index_group_handle=s.group_handle
JOIN sys.dm_db_missing_index_details as d on g.index_handle=d.index_handle
JOIN sys.databases as db on d.database_id=db.database_id
WHERE db.database_id=DB_ID()

/********************
table_name							equality_columns	inequality_columns	included_columns						avg_est_plan_cost	avg_est_cost_reduction	times_requested
[Aula].[dbo].[SalesOrderHeader]		NULL				[OrderDate]			[SalesOrderID], [Status], [CustomerID]	1.15500125010848	39.21					5
[Aula].[dbo].[SalesOrderHeader]		[CustomerID]		NULL				[SalesOrderID], [OrderDate], [Status]	2.22067737035959	56.85					10
[Aula].[dbo].[Customer]				[Territory]			NULL				[FirstName], [Lastname], [Store]		2.22067737035959	35.29					10
*********************/

/******************************************
 Database Engine Tuning Advisor (DTA)
*******************************************/
CREATE NONCLUSTERED INDEX ix_dta_Customer_Store_Territory
ON dbo.Customer (Store DESC,Territory ASC)
INCLUDE(CustomerID,FirstName,Lastname)
go

CREATE NONCLUSTERED INDEX ix_dta_Customer_Territory_CustomerID 
ON dbo.Customer (Territory ASC,CustomerID ASC)
INCLUDE(FirstName,Lastname,Store)
go

CREATE NONCLUSTERED INDEX ix_dta_SalesOrderHeader_CustomerID 
ON dbo.SalesOrderHeader (CustomerID ASC)
INCLUDE(SalesOrderID,OrderDate,[Status])
go

CREATE NONCLUSTERED INDEX ix_dta_SalesOrderHeader_OrderDate_CustomerID
ON dbo.SalesOrderHeader (OrderDate ASC,CustomerID ASC)
INCLUDE(SalesOrderID,[Status])
go



exec msdb.dbo.sp_DTA_help_session -- Identificar a sessão em execução
exec msdb.dbo.sp_DTA_delete_session 22 -- Derrubar a sessão


/***********************************
 Indices Corretos
************************************/
CREATE NONCLUSTERED INDEX ix_SalesOrderHeader_CustomerID 
ON dbo.SalesOrderHeader (CustomerID ASC)
INCLUDE(SalesOrderID,OrderDate,[Status])
go

CREATE NONCLUSTERED INDEX ix_SalesOrderHeader_OrderDate_CustomerID
ON dbo.SalesOrderHeader (OrderDate ASC,CustomerID ASC)
INCLUDE(SalesOrderID,[Status])
go

--CREATE NONCLUSTERED INDEX ix_dta_Customer_Store_Territory
--ON dbo.Customer (Store DESC,Territory ASC)
--INCLUDE(CustomerID,FirstName,Lastname)

CREATE NONCLUSTERED INDEX ix_Customer_Territory_Store
ON dbo.Customer (Territory ASC,Store DESC)
INCLUDE(CustomerID,FirstName,Lastname)


/***************************
 Apaga Tabelas
****************************/
DROP TABLE IF exists dbo.Customer
DROP TABLE IF exists dbo.SalesOrderHeader

