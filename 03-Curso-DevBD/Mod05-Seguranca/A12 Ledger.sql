/*********************************************
 Autor: Landry Duailibe

 Hands On: Ledger
**********************************************/
use master
go
DROP DATABASE IF exists HandsOn
go
CREATE DATABASE HandsOn
go


/**************************
 Updatable Ledger
***************************/
use HandsOn
go
DROP TABLE If exists Cliente
go 
CREATE TABLE dbo.Cliente (
ClienteID int not null CONSTRAINT pk_Cliente PRIMARY KEY,
Nome varchar(100) not null,
Email varchar(100) null,
Credito decimal(10,2) null)
WITH (SYSTEM_VERSIONING = ON, LEDGER = ON)
--WITH (SYSTEM_VERSIONING = ON, LEDGER = ON (APPEND_ONLY = ON))
go


-- Restorna lista de tabelas Ledger
SELECT 
ts.[name] + '.' + t.[name] AS [ledger_table_name]
, hs.[name] + '.' + h.[name] AS [history_table_name]
, vs.[name] + '.' + v.[name] AS [ledger_view_name]
FROM sys.tables AS t
JOIN sys.tables AS h ON (h.[object_id] = t.[history_table_id])
JOIN sys.views v ON (v.[object_id] = t.[ledger_view_id])
JOIN sys.schemas ts ON (ts.[schema_id] = t.[schema_id])
JOIN sys.schemas hs ON (hs.[schema_id] = h.[schema_id])
JOIN sys.schemas vs ON (vs.[schema_id] = v.[schema_id])

-- Inclui 3 linhas
INSERT dbo.Cliente VALUES (1, 'Landry', 'Landry@sqlserverexpert.com', 20000.00)
INSERT dbo.Cliente VALUES (2, 'Ana Maria', 'amaria@gmail.com', 30000.00)
INSERT dbo.Cliente VALUES (3, 'Paula Carvalho', 'pcarvalho@yahoo.com', 90)

-- Retorna último ID de transação por linha
SELECT * FROM dbo.Cliente

SELECT *,
ledger_start_transaction_id,ledger_end_transaction_id,
ledger_start_sequence_number,ledger_end_sequence_number
FROM dbo.Cliente

-- Altera Valor de Crédito do cliente Landry
UPDATE dbo.Cliente SET Credito = 90000.00 WHERE Nome = 'Landry' -- 1160

-- Retorna último ID de transação por linha
SELECT *,
ledger_start_transaction_id,ledger_end_transaction_id,
ledger_start_sequence_number,ledger_end_sequence_number
FROM dbo.Cliente


SELECT * FROM dbo.MSSQL_LedgerHistoryFor_901578250

SELECT * FROM dbo.Cliente_Ledger ORDER BY ledger_transaction_id

/********************
 Exclui banco
*********************/
use master
go
ALTER DATABASE HandsOn SET SINGLE_USER WITH ROLLBACK IMMEDIATE
go
DROP DATABASE IF exists HandsOn

/********************************************
 Cria Banco com Ledger Habilitado
*********************************************/
CREATE DATABASE HandsOn_Ledger
WITH LEDGER = ON
go
use HandsOn_Ledger
go

-- Cria tabela Cliente
DROP TABLE IF exists Cliente
go 
CREATE TABLE dbo.Cliente (
ClienteID int not null CONSTRAINT pk_Cliente PRIMARY KEY,
Nome varchar(100) not null,
Email varchar(100) null,
Credito decimal(10,2) null)
go

-- Cria tabela Produto
DROP TABLE IF exists Produto
go 
CREATE TABLE dbo.Produto (
ProdutoID int not null CONSTRAINT pk_Produto PRIMARY KEY,
Produto varchar(100) not null,
Tamanho varchar(10) null,
PrecoUnitario decimal(10,2) null)
go

-- Restorna lista de tabelas Ledger
SELECT 
ts.[name] + '.' + t.[name] AS [ledger_table_name]
, hs.[name] + '.' + h.[name] AS [history_table_name]
, vs.[name] + '.' + v.[name] AS [ledger_view_name]
FROM sys.tables AS t
JOIN sys.tables AS h ON (h.[object_id] = t.[history_table_id])
JOIN sys.views v ON (v.[object_id] = t.[ledger_view_id])
JOIN sys.schemas ts ON (ts.[schema_id] = t.[schema_id])
JOIN sys.schemas hs ON (hs.[schema_id] = h.[schema_id])
JOIN sys.schemas vs ON (vs.[schema_id] = v.[schema_id])


/********************
 Exclui banco
*********************/
use master
go
ALTER DATABASE HandsOn_Ledger SET SINGLE_USER WITH ROLLBACK IMMEDIATE
go
DROP DATABASE IF exists HandsOn_Ledger

