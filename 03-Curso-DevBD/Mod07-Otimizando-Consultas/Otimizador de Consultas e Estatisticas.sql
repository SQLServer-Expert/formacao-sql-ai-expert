/**********************************************************************
 Autor: Landry

 Hands On:
 - Plano trivial
 - Estatisticas de Banco de Dados
***********************************************************************/
USE Aula
go

/***********************************************************
 - Trivial Plan
************************************************************/

-- Aba Messages
DBCC TRACEON(3604) -- Habilita saída em "Messages"
DBCC TRACEON(8605) -- Mostra a árvore de otimização da consulta Otimizador
DBCC TRACEON(8675) -- Habilita mostrar as fases do Otimizador

DBCC TRACEOFF(3604)
DBCC TRACEOFF(8605)
DBCC TRACEOFF(8675)

-- consultas executadas com Trivial Plan
SELECT * FROM sys.dm_exec_query_optimizer_info 
WHERE counter='trivial plan'

-- Trivial Plan
SELECT * FROM AdventureWorks.Person.Person

SELECT * FROM AdventureWorks.Person.Person
OPTION (RECOMPILE, QUERYTRACEON 3604, QUERYTRACEON 8605, QUERYTRACEON 8675)

-- Full Plan
SELECT BusinessEntityID as CustomerID,FirstName,MiddleName,Lastname,PhoneNumber,
EmailAddress,AddressLine1 as Address,'RJ' as Region, dateadd(d,-BusinessEntityID,getdate()) DataCadastro 
FROM AdventureWorks.Sales.vIndividualCustomer
OPTION (RECOMPILE, QUERYTRACEON 3604, QUERYTRACEON 8605, QUERYTRACEON 8675)


/***********************************************************
 - Uso Estatísticas de Banco de Dados
************************************************************/
DROP TABLE IF exists dbo.Customer
go
SELECT BusinessEntityID as CustomerID,FirstName,MiddleName,Lastname,PhoneNumber,
EmailAddress,AddressLine1 as Address,'RJ' as Region, dateadd(d,-BusinessEntityID,getdate()) DataCadastro 
INTO dbo.Customer
FROM AdventureWorks.Sales.vIndividualCustomer

UPDATE dbo.Customer SET Region = 'SP' WHERE CustomerID = 11000

CREATE INDEX IX_Customer_Region ON dbo.Customer(Region)

SET STATISTICS IO ON

SELECT * FROM dbo.Customer --with(index(IX_Customer_Region))
WHERE Region = 'RJ'
-- Table 'Customer'. Scan count 1, logical reads 155





-- Plano 1) Table Scan

SELECT rows as QtdLinhas, data_pages Paginas8k 
FROM sys.partitions p join sys.allocation_units a ON p.hobt_id = a.container_id
WHERE p.[object_id] = object_id('dbo.Customer') and index_id < 2
-- QtdLinhas	Paginas8k
-- 18508		429

-- Plano 2) Index Seek + Booknark Lookup

DBCC SHOW_STATISTICS ("dbo.Customer", IX_Customer_Region)


/***********************************
 Atualizando Estatísticas
************************************/
-- Atualiza todas as estatísticas da tabela Customer
UPDATE STATISTICS dbo.Customer

-- Atualiza a estatística do índice IX_Customer_Region na tabela Customer com SAMPLE
UPDATE STATISTICS dbo.Customer(IX_Customer_Region) WITH SAMPLE 50 PERCENT

-- Atualiza a estatística do índice IX_Customer_Region na tabela Customer com FULLSCAN
UPDATE STATISTICS dbo.Customer(IX_Customer_Region) WITH FULLSCAN




