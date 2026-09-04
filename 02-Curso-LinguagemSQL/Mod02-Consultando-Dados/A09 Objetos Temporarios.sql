/***********************************************************************************************************
 Curso T-SQL
 Autor: Landry

 Demonstração:
 - Tabelas temporárias
 - Variável tabela
 - Tabelas Memory-optimized

 https://learn.microsoft.com/en-us/sql/t-sql/data-types/table-transact-sql?view=sql-server-ver16
************************************************************************************************************/
use AdventureWorksLT
go

/*****************************
 Tabela Temporária Local
******************************/
-- 1a Opção
CREATE TABLE #Produto_TMP_1 (
[ProductID] int not null,
[Name] nvarchar(50) not null,
Size nvarchar(5) null)
go

INSERT #Produto_TMP_1
SELECT a.ProductID, a.[Name], a.Size
FROM SalesLT.Product a
JOIN SalesLT.SalesOrderDetail b on b.ProductID = a.ProductID
WHERE a.Color = 'Black'

SELECT * FROM #Produto_TMP_1

-- 2a Opção
SELECT a.ProductID, a.[Name], a.Size
INTO #Produto_TMP_2
FROM SalesLT.Product a
JOIN SalesLT.SalesOrderDetail b on b.ProductID = a.ProductID
WHERE a.Color = 'Black'

SELECT * FROM #Produto_TMP_2

DROP TABLE #Produto_TMP_1
DROP TABLE #Produto_TMP_2

/*******************************
 Tabela Temporária Global
********************************/
SELECT a.ProductID, a.[Name], a.Size
INTO ##Produto_TMP_Global
FROM SalesLT.Product a
JOIN SalesLT.SalesOrderDetail b on b.ProductID = a.ProductID
WHERE a.Color = 'Black'

SELECT * FROM ##Produto_TMP_Global

DROP TABLE ##Produto_TMP_Global


/*******************************
 Variável Tabela
********************************/
DECLARE @Produto_TMP TABLE (
[ProductID] int not null,
[Name] nvarchar(50) not null,
Size nvarchar(5) null)

INSERT @Produto_TMP
SELECT a.ProductID, a.[Name], a.Size
FROM SalesLT.Product a
JOIN SalesLT.SalesOrderDetail b on b.ProductID = a.ProductID
WHERE a.Color = 'Black'

SELECT * FROM @Produto_TMP
go


/****************************************************************
 Tabelas Memory-optimized
 https://learn.microsoft.com/en-us/sql/relational-databases/in-memory-oltp/faster-temp-table-and-table-variable-by-using-memory-optimization?view=sql-server-ver16
*****************************************************************/
USE master
go
CREATE DATABASE MemoryOptimizedTable
go
ALTER DATABASE MemoryOptimizedTable SET RECOVERY SIMPLE
go

ALTER DATABASE MemoryOptimizedTable ADD FILEGROUP fg_Mem CONTAINS MEMORY_OPTIMIZED_DATA
go  
ALTER DATABASE MemoryOptimizedTable 
ADD FILE (NAME = N'MemoryOptimizedTable_Mem',  FILENAME = N'C:\MSSQL_Data\MemoryOptimizedTable_Mem') 
TO FILEGROUP fg_Mem  
go  

/****************************************************
 Trocar Tabela Temporária por Memory-Optimized Table
*****************************************************/
use MemoryOptimizedTable
go

-- Cria tabela Product importando dados do banco AdventureWorksLT
SELECT ProductID, Name, ProductNumber, Color, StandardCost, ListPrice, Size, Weight, ProductCategoryID, 
ProductModelID, SellStartDate, SellEndDate, DiscontinuedDate
INTO Product
FROM AdventureWorksLT.SalesLT.Product


-- Tabela Temporária
CREATE TABLE #temp_Product (  
ProductID int NOT NULL PRIMARY KEY,
[Name] nvarchar(50) NOT NULL,
ProductNumber nvarchar(25) NOT NULL,
Color nvarchar(15) NULL,
StandardCost money NOT NULL,
ListPrice money NOT NULL,
Size nvarchar(5) NULL,
[Weight] decimal(8, 2) NULL,
ProductCategoryID int NULL,
ProductModelID int NULL,
SellStartDate datetime NOT NULL,
SellEndDate datetime NULL,
DiscontinuedDate datetime NULL)
go

INSERT #temp_Product
SELECT ProductID, Name, ProductNumber, Color, StandardCost, ListPrice, Size, Weight, ProductCategoryID, 
ProductModelID, SellStartDate, SellEndDate, DiscontinuedDate
FROM Product

-- Memory-Optimized Table como Tabela Temporária
CREATE TABLE dbo.mot_Product (  
ProductID int NOT NULL INDEX ix_mot_Product NONCLUSTERED,
[Name] nvarchar(50) NOT NULL,
ProductNumber nvarchar(25) NOT NULL,
Color nvarchar(15) NULL,
StandardCost money NOT NULL,
ListPrice money NOT NULL,
Size nvarchar(5) NULL,
[Weight] decimal(8, 2) NULL,
ProductCategoryID int NULL,
ProductModelID int NULL,
SellStartDate datetime NOT NULL,
SellEndDate datetime NULL,
DiscontinuedDate datetime NULL)  
WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_ONLY)

INSERT dbo.mot_Product
SELECT ProductID, Name, ProductNumber, Color, StandardCost, ListPrice, Size, Weight, ProductCategoryID, 
ProductModelID, SellStartDate, SellEndDate, DiscontinuedDate
FROM Product

SELECT * FROM mot_Product



/****************************************************
 Trocar Variável Tabela por Memory-Optimized Table
*****************************************************/
-- Variável Tabela
DECLARE @vTab_Product TABLE ( 
ProductID int NOT NULL PRIMARY KEY,
[Name] nvarchar(50) NOT NULL,
ProductNumber nvarchar(25) NOT NULL,
Color nvarchar(15) NULL,
StandardCost money NOT NULL,
ListPrice money NOT NULL,
Size nvarchar(5) NULL,
[Weight] decimal(8, 2) NULL,
ProductCategoryID int NULL,
ProductModelID int NULL,
SellStartDate datetime NOT NULL,
SellEndDate datetime NULL,
DiscontinuedDate datetime NULL)


INSERT @vTab_Product
SELECT ProductID, Name, ProductNumber, Color, StandardCost, ListPrice, Size, Weight, ProductCategoryID, 
ProductModelID, SellStartDate, SellEndDate, DiscontinuedDate
FROM Product

-- Memory-Optimized Table
CREATE TYPE dbo.TypeProduct  AS TABLE (
ProductID int NOT NULL INDEX ix_Type_Product NONCLUSTERED,
[Name] nvarchar(50) NOT NULL,
ProductNumber nvarchar(25) NOT NULL,
Color nvarchar(15) NULL,
StandardCost money NOT NULL,
ListPrice money NOT NULL,
Size nvarchar(5) NULL,
[Weight] decimal(8, 2) NULL,
ProductCategoryID int NULL,
ProductModelID int NULL,
SellStartDate datetime NOT NULL,
SellEndDate datetime NULL,
DiscontinuedDate datetime NULL)
WITH (MEMORY_OPTIMIZED = ON)        
go

DECLARE @tb_Product dbo.TypeProduct  

INSERT @tb_Product
SELECT ProductID, Name, ProductNumber, Color, StandardCost, ListPrice, Size, Weight, ProductCategoryID, 
ProductModelID, SellStartDate, SellEndDate, DiscontinuedDate
FROM Product


SELECT * FROM @tb_Product


USE master
go
DROP DATABASE MemoryOptimizedTable
go

