/************************************************************************************************************
 Curso T-SQL
 Autor: Landry

 OPENXML
 https://learn.microsoft.com/en-us/sql/relational-databases/xml/examples-using-openxml?view=sql-server-ver16

 Shredding XML (Shredding = Destruindo)
 - Conmverão de XML em Formato Tabular
*************************************************************************************************************/
USE Aula
go

/**************************
 Cria tabelas
***************************/
IF object_id('dbo.SalesOrderHeader') is not null
   DROP TABLE dbo.SalesOrderHeader

CREATE TABLE dbo.SalesOrderHeader(
SalesOrderID int NOT NULL primary key,
OrderDate datetime NOT NULL,
CustomerID int NOT NULL) 
go
INSERT dbo.SalesOrderHeader
SELECT SalesOrderID, OrderDate, CustomerID
FROM AdventureWorksLT.SalesLT.SalesOrderHeader
go


IF object_id('dbo.SalesOrderDetail') is not null
   DROP TABLE dbo.SalesOrderDetail

SELECT SalesOrderID, ProductID, OrderQty, LineTotal
INTO dbo.SalesOrderDetail
FROM AdventureWorksLT.SalesLT.SalesOrderDetail
go
/************************ FIM Cria Tabelas *****************************/

SELECT * FROM dbo.SalesOrderHeader WHERE SalesOrderID = 71774
SELECT * FROM dbo.SalesOrderDetail WHERE SalesOrderID = 71774

-- Exemplo de documento XML
DECLARE @xml_Order xml = '
<Order SalesOrderID = "81000" OrderDate = "2018-06-01T00:00:00" CustomerID = "29847">
<Item ProductID="822" OrderQty="1" LineTotal="356.898000"/>
<Item ProductID="836" OrderQty="4" LineTotal="158.100000"/>
</Order>'

SELECT @xml_Order


/************************************************
 Stored Procedure recebe XML e retorna
 duas tabelas 
*************************************************/
go
CREATE or ALTER PROC dbo.Insert_Order
@xml_Order  xml
as
DECLARE @xmldoc AS int
EXEC sp_xml_preparedocument @xmldoc OUTPUT, @xml_Order 

-- SalesOrderHeader
SELECT * FROM OPENXML(@xmldoc, '/Order', 2)
WITH (
SalesOrderID int '@SalesOrderID',
OrderDate datetime '@OrderDate', 
CustomerID int '@CustomerID') 

-- SalesOrderDetail
SELECT * FROM OPENXML(@xmldoc, '/Order/Item', 2)
WITH (
SalesOrderID int '../@SalesOrderID',
ProductID int '@ProductID',
OrderQty int '@OrderQty',
LineTotal decimal(11,2) '@LineTotal') 

EXEC sp_xml_removedocument @xmldoc
go
/****************** FIM SP *********************/

DECLARE @xml_Order xml = '
<Order SalesOrderID = "81000" OrderDate = "2018-06-01T00:00:00" CustomerID = "29847">
<Item ProductID="822" OrderQty="1" LineTotal="356.898000"/>
<Item ProductID="836" OrderQty="4" LineTotal="158.100000"/>
</Order>'

EXEC dbo.Insert_Order @xml_Order


/************************************************
 Stored Procedure recebe XML e atualiza as tabelas:
 - SalesOrderHeader
 - SalesOrderDetail
*************************************************/
go
CREATE or ALTER PROC dbo.Insert_Order
@xml_Order  xml
as
set nocount on

DECLARE @xmldoc AS int
EXEC sp_xml_preparedocument @xmldoc OUTPUT, @xml_Order 

-- SalesOrderHeader
INSERT dbo.SalesOrderHeader
(SalesOrderID,OrderDate,CustomerID)
SELECT * FROM OPENXML(@xmldoc, '/Order', 2)
WITH (
SalesOrderID int '@SalesOrderID',
OrderDate datetime '@OrderDate', 
CustomerID int '@CustomerID') 

-- SalesOrderDetail
INSERT SalesOrderDetail
(SalesOrderID,ProductID,OrderQty,LineTotal)
SELECT * FROM OPENXML(@xmldoc, '/Order/Item', 2)
WITH (
SalesOrderID int '../@SalesOrderID',
ProductID int '@ProductID',
OrderQty int '@OrderQty',
LineTotal decimal(11,2) '@LineTotal') 

EXEC sp_xml_removedocument @xmldoc
go
/****************** FIM SP *********************/

DECLARE @xml_Order xml = '
<Order SalesOrderID = "81000" OrderDate = "2018-06-01T00:00:00" CustomerID = "29847">
<Item ProductID="822" OrderQty="1" LineTotal="356.898000"/>
<Item ProductID="836" OrderQty="4" LineTotal="158.100000"/>
</Order>'

EXEC dbo.Insert_Order @xml_Order

SELECT * FROM dbo.SalesOrderHeader WHERE SalesOrderID = 81000
SELECT * FROM dbo.SalesOrderDetail WHERE SalesOrderID = 81000

-- Exclui objetos
DROP PROC dbo.Insert_Order
DROP TABLE dbo.SalesOrderHeader
DROP TABLE dbo.SalesOrderDetail
