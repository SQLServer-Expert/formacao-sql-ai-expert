/*******************************************
 Autor: Landry Duailibe

 Hands On: Criando Indice Columnstore
********************************************/ 
use master
go
CREATE DATABASE DB_IndiceColumnstore
go
ALTER DATABASE DB_IndiceColumnstore SET RECOVERY simple
go
use DB_IndiceColumnstore
go

/**********************************************
 Cria Tabela e importa do banco AdventureWorks
 - Indice Btree
***********************************************/
DROP TABLE IF exists dbo.SalesOrderDetail
go
CREATE TABLE dbo.SalesOrderDetail(
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
INSERT INTO dbo.SalesOrderDetail
SELECT S1.* FROM AdventureWorks.Sales.SalesOrderDetail S1
go 100

/**********************************************
 Cria Tabela e importa do banco AdventureWorks
 -- Indice Columnstore
***********************************************/
DROP TABLE IF exists dbo.SalesOrderDetail_Column
go
CREATE TABLE dbo.SalesOrderDetail_Column(
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
INSERT INTO dbo.SalesOrderDetail_Column
SELECT S1.* FROM AdventureWorks.Sales.SalesOrderDetail S1
go 100
/*****************************************************************************/

/*******************************
 Cria indice Btree
********************************/
-- DROP INDEX SalesOrderDetail.ix_SalesOrderDetail
CREATE INDEX ix_SalesOrderDetail ON dbo.SalesOrderDetail (ProductID)
INCLUDE (UnitPrice, OrderQty)
go
/****************************************
 Cria indice Columnstore
*****************************************/
-- DROP INDEX SalesOrderDetail_Column.ix_SalesOrderDetail_Column_ProductID
CREATE NONCLUSTERED COLUMNSTORE INDEX ix_SalesOrderDetail_Column_ProductID
ON SalesOrderDetail_Column (ProductID,UnitPrice, OrderQty)
go

/****************************
 Comparando o Desempenho
*****************************/
SET STATISTICS IO ON
go

SELECT ProductID, SUM(UnitPrice) SumUnitPrice, AVG(UnitPrice) AvgUnitPrice,
SUM(OrderQty) SumOrderQty, AVG(OrderQty) AvgOrderQty
FROM dbo.SalesOrderDetail
GROUP BY ProductID 
ORDER BY ProductID
-- Table 'SalesOrderDetail'. Scan count 4, logical reads 42.529

SELECT ProductID, SUM(UnitPrice) SumUnitPrice, AVG(UnitPrice) AvgUnitPrice,
SUM(OrderQty) SumOrderQty, AVG(OrderQty) AvgOrderQty
FROM dbo.SalesOrderDetail_Column
GROUP BY ProductID 
ORDER BY ProductID
-- Table 'SalesOrderDetail_Column'. Scan count 4, lob logical reads 11.855, lob physical reads 17
-- Table 'SalesOrderDetail_Column'. Segment reads 13, segment skipped 0.


-- Executar junto
-- 92%
SELECT ProductID, SUM(UnitPrice) SumUnitPrice, AVG(UnitPrice) AvgUnitPrice,
SUM(OrderQty) SumOrderQty, AVG(OrderQty) AvgOrderQty
FROM dbo.SalesOrderDetail
GROUP BY ProductID 
ORDER BY ProductID

-- 8%
SELECT ProductID, SUM(UnitPrice) SumUnitPrice, AVG(UnitPrice) AvgUnitPrice,
SUM(OrderQty) SumOrderQty, AVG(OrderQty) AvgOrderQty
FROM dbo.SalesOrderDetail_Column
GROUP BY ProductID 
ORDER BY ProductID


use master
go
DROP DATABASE DB_IndiceColumnstore

