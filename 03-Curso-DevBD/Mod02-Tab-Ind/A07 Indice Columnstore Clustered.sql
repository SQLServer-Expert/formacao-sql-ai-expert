/********************************************************************
 Autor: Landry Duailibe

 Hands On: Clustered Columnstore Index
*********************************************************************/
use master
go
CREATE DATABASE DB_Columnstore
go
ALTER DATABASE DB_Columnstore SET RECOVERY simple
go
use DB_Columnstore
go

/********************************************************
 Cria Tabela e importa do banco AdventureWorks
********************************************************/
DROP TABLE IF exists dbo.SalesOrderDetail_Clustered
go
CREATE TABLE dbo.SalesOrderDetail_Clustered (
SalesOrderID int NOT NULL,
SalesOrderDetailID int NOT NULL,
CarrierTrackingNumber nvarchar(25) NULL,
OrderQty smallint NOT NULL,
ProductID int NOT NULL,
SpecialOfferID int NOT NULL,
UnitPrice money NOT NULL,
UnitPriceDiscount money NOT NULL,
LineTotal numeric(38, 6) NOT NULL,
rowguid uniqueidentifier NOT NULL,
ModifiedDate datetime NOT NULL)
go

-- Importa linhas do banco AdventureWorks
-- ATENÇÃO: esta Query poe levar até 10 minutos
INSERT dbo.SalesOrderDetail_Clustered
SELECT S1.* FROM AdventureWorks.Sales.SalesOrderDetail S1
go 100

SELECT * INTO dbo.SalesOrderDetail_ColumstoreClustered
FROM dbo.SalesOrderDetail_Clustered
go

/**********************************
 Cria Indice Btree Custered
***********************************/
CREATE CLUSTERED INDEX ix_SalesOrderDetail_Clustered 
ON dbo.SalesOrderDetail_Clustered (SalesOrderID,SalesOrderDetailID)
go

/**********************************
 Cria Indice Columnstore Custered
***********************************/
CREATE CLUSTERED COLUMNSTORE INDEX ixc_SalesOrderDetail_ColumstoreClustered
ON dbo.SalesOrderDetail_ColumstoreClustered 
go

/**********************************
 Comprando a ocupação
***********************************/
EXEC sp_spaceused 'dbo.SalesOrderDetail_Clustered'
EXEC sp_spaceused 'dbo.SalesOrderDetail_ColumstoreClustered'

/*
name									rows		reserved	data		index_size	unused
SalesOrderDetail_Clustered				12131700    1276184 KB	1.272.096 KB KB	3984 KB		112 KB

SalesOrderDetail_ColumstoreClustered	12131700     129864 KB	  128.072 KB KB	    0 KB	 88 KB
*/

-- Exclui banco
use master
go
DROP DATABASE IF exists DB_Columnstore

