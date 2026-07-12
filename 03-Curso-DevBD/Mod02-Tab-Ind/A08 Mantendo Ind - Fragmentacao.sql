/**********************************************************
 Autor: Landry Duailibe

 Hands On: PK Clustered sequencial ou não sequencial?
***********************************************************/ 
USE Aula
go

/******************************************
 Cria tabela com PK sequencial IDENTITY
*******************************************/
DROP TABLE IF exists dbo.Cliente_PkSequencial
go
CREATE TABLE dbo.Cliente_PkSequencial (
Cliente_ID int not null identity CONSTRAINT pk_Cliente_PkSequencial PRIMARY KEY,
CPF varchar(14) not null,
Nome varchar(50) not null,
DataAniversario date not null,
Obs char(3000) not null)
go

/******************************************
 Cria tabela com PK não sequencial CPF
*******************************************/
DROP TABLE IF exists dbo.Cliente_PkCPF
go
CREATE TABLE dbo.Cliente_PkCPF (
Cliente_ID int not null identity,
CPF varchar(14) not null CONSTRAINT pk_Cliente_PkCPF PRIMARY KEY,
Nome varchar(50) not null,
DataAniversario date not null,
Obs char(3000) not null)
go

/************************************
 Inclui 80 mil em ambas as tabelas
*************************************/
-- Inclui 80 mil linhas em PK sequencial IDENTITY (14 segundos)
DECLARE @i int = 20000

WHILE @i <= 100000 BEGIN
	INSERT dbo.Cliente_PkSequencial (CPF, Nome, DataAniversario, Obs)
	VALUES (ltrim(str(cast(rand(@i)*1000000000 as int))),'Teste Fragmentação',getdate(),'Ocupa 3000 bytes')

	SET @i += 1
END
go


-- Inclui 80 mil linhas em PK Não sequencial CPF (32 segundos)
DECLARE @i int = 20000

WHILE @i <= 100000 BEGIN
	INSERT dbo.Cliente_PkCPF (CPF, Nome, DataAniversario, Obs)
	VALUES (ltrim(str(cast(rand(@i)*1000000000 as int))),'Teste Fragmentação',getdate(),'Ocupa 3000 bytes')

	SET @i += 1
END
go

/********************************************
 Analisa Fragmentação
*********************************************/

SELECT a.index_type_desc, a.index_level ,a.page_count,
a.record_count, a.avg_page_space_used_in_percent,
a.forwarded_record_count,
a.avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats(DB_ID(),
OBJECT_ID('dbo.Cliente_PkSequencial', 'U'),NULL,NULL,'DETAILED') as a
-- Fragmentação Externa: 0.37%

SELECT a.index_type_desc, a.index_level ,a.page_count,
a.record_count, a.avg_page_space_used_in_percent,
a.forwarded_record_count,
a.avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats(DB_ID(),
OBJECT_ID('dbo.Cliente_PkCPF', 'U'),NULL,NULL,'DETAILED') as a
-- Fragmentação Externa: 80.00%

ALTER INDEX pk_Cliente_PkCPF ON dbo.Cliente_PkCPF REBUILD WITH (FILLFACTOR = 60)
-- Fragmentação Externa: 0.01%

DECLARE @i int = 100001

WHILE @i <= 101000 BEGIN
	INSERT dbo.Cliente_PkCPF (CPF, Nome, DataAniversario, Obs)
	VALUES (ltrim(str(cast(rand(@i)*1000000000 as int))),'Teste Fragmentação',getdate(),'Ocupa 3000 bytes')

	SET @i += 1
END
go


-- Exclui tabelas
DROP TABLE IF exists dbo.Cliente_PkSequencial
DROP TABLE IF exists dbo.Cliente_PkCPF


