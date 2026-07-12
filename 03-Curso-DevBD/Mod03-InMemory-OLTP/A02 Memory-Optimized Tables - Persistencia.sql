/********************************************************************************
 Autor: Landry Duailibe

 Hands On:  Persistência dos Dados em Memory-Optimized Tables
*********************************************************************************/
use master
go

-- DROP DATABASE MemoryDB
CREATE DATABASE MemoryDB
ON (name = 'MemoryDB', filename = 'C:\MSSQL_Data\MemoryDB.mdf', size = 100MB, filegrowth = 50MB)
LOG ON (name = 'MemoryDB_log', filename = 'C:\MSSQL_Data\MemoryDB_log.ldf', size = 50MB, filegrowth = 50MB)
go

ALTER DATABASE MemoryDB SET RECOVERY simple
go


-- Preparando o Banco para In-Memory OLTP
ALTER DATABASE MemoryDB
ADD FILEGROUP mem_data CONTAINS MEMORY_OPTIMIZED_DATA
go

ALTER DATABASE MemoryDB
ADD FILE (NAME = 'MemoryDB_MemData', FILENAME = 'C:\MSSQL_Data\MemoryDB_Data')
TO FILEGROUP mem_data
go

/*********************************************
 Criando tabela SEM persistência dos Dados
**********************************************/
DROP TABLE IF exists MemoryDB.dbo.Venda_Schema
go
CREATE TABLE MemoryDB.dbo.Venda_Schema
(Venda_ID int NOT NULL,
DataVenda datetime NOT NULL,
Cliente_ID int NULL,
Vendedor_ID int NULL,
Valor_Total decimal(12,2) NULL
PRIMARY KEY NONCLUSTERED (Venda_ID))
WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_ONLY)
go


INSERT MemoryDB.dbo.Venda_Schema 
(Venda_ID,DataVenda,Cliente_ID,Vendedor_ID,Valor_Total)
VALUES 
(1001,getdate(),11,21,1500.00),
(1002,getdate(),12,22,420.00),
(1003,getdate(),13,23,12400.00)
go

SELECT * FROM MemoryDB.dbo.Venda_Schema

-- Coloca o banco em Off Line para verificar a perda dos dados
use master
go
ALTER DATABASE MemoryDB SET OFFLINE WITH ROLLBACK IMMEDIATE
ALTER DATABASE MemoryDB SET ONLINE

SELECT * FROM MemoryDB.dbo.Venda_Schema
-- Zero linhas

/*********************************************
 Criando tabela COM persistência dos Dados
**********************************************/
DROP TABLE IF exists MemoryDB.dbo.Venda_Data
go
CREATE TABLE MemoryDB.dbo.Venda_Data
(Venda_ID int NOT NULL,
DataVenda datetime NOT NULL,
Cliente_ID int NULL,
Vendedor_ID int NULL,
Valor_Total decimal(12,2) NULL
PRIMARY KEY NONCLUSTERED (Venda_ID))
WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA)
go

INSERT MemoryDB.dbo.Venda_Data 
(Venda_ID,DataVenda,Cliente_ID,Vendedor_ID,Valor_Total)
VALUES 
(1001,getdate(),11,21,1500.00),
(1002,getdate(),12,22,420.00),
(1003,getdate(),13,23,12400.00)
go

SELECT * FROM MemoryDB.dbo.Venda_Data

-- Coloca o banco em Off Line para verificar a perda dos dados
use master
go
ALTER DATABASE MemoryDB SET OFFLINE WITH ROLLBACK IMMEDIATE
ALTER DATABASE MemoryDB SET ONLINE


SELECT * FROM MemoryDB.dbo.Venda_Data WHERE Venda_ID = 1002

-- Lista tabelas Memory-Optimized
SELECT b.[name] as Tabela, a.*
FROM MemoryDB.sys.dm_db_xtp_table_memory_stats a
JOIN MemoryDB.sys.tables b ON a.[object_id] = b.[object_id]

-- Estatísticas de uso dos índices em tabelas Memory-Optimized
SELECT b.[name] as Tabela, c.[name] as Indices,a.*
FROM MemoryDB.sys.dm_db_xtp_index_stats a
JOIN MemoryDB.sys.tables b ON a.[object_id] = b.[object_id]
JOIN MemoryDB.sys.indexes c ON a.[object_id] = c.[object_id] and a.index_id = c.index_id
WHERE a.index_id > 0

-- Manter o banco pois será utilizado nas aulas seguintes