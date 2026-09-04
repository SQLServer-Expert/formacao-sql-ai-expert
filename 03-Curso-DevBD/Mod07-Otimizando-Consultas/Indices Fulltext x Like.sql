CREATE DATABASE HandsOn
go
ALTER DATABASE HandsOn SET RECOVERY simple
go

use HandsOn
go

/******************************************************
 Cria tabela Cliente e popula com 7.404.203 linhas
*******************************************************/
set nocount on

DROP TABLE IF exists dbo.Cliente
go
CREATE TABLE dbo.Cliente (
ClienteID int NOT NULL identity CONSTRAINT ix_Cliente PRIMARY KEY,
Nome varchar(150) NOT NULL,
Telefone varchar(25) NULL,
Email varchar(50) NULL,
Endereco varchar(60) NOT NULL,
DataCadastro datetime NULL)
go

INSERT dbo.Cliente VALUES ('João Duailibe da Silva', '(22)99567-4822','joao@sqlserver-expert.com.br','Rua A 1234',getdate())
INSERT dbo.Cliente VALUES ('Claudio Duailibe', '(24)98776-9821','claudio@sqlserver-expert.com.br','Rua B 1234',getdate())
INSERT dbo.Cliente VALUES ('Duailibe Carvalho', '(21)95764-12989','duailibe@sqlserver-expert.com.br','Rua C 1234',getdate())
go

INSERT dbo.Cliente
SELECT top 1000 FirstName + ' Duailibe' + isnull(' ' + Lastname,'') as Nome,
PhoneNumber as Telefone, EmailAddress as Email,AddressLine1 as Endereco, 
dateadd(minute,- scope_identity(),getdate()) DataCadastro 
FROM AdventureWorks.Sales.vIndividualCustomer
go

INSERT dbo.Cliente
SELECT FirstName + isnull(' ' + MiddleName,'') + isnull(' ' + Lastname,'') as Nome,
PhoneNumber as Telefone, EmailAddress as Email,AddressLine1 as Endereco, 
dateadd(minute,- scope_identity(),getdate()) DataCadastro 
FROM AdventureWorks.Sales.vIndividualCustomer
go 400
/************************* FIM Cria Tabela - Leva +- 2 minutos *****************************/

SELECT count(*) FROM dbo.Cliente -- 7.404.203 linhas

CREATE INDEX ix_Cliente_Nome ON dbo.Cliente (Nome)

set statistics io on
set statistics io off

SELECT * FROM dbo.Cliente
WHERE Nome like 'Duailibe%'
-- 1 linha em zero segundos
-- Index Seek + Bookmark Lookup
-- Table 'Cliente'. Scan count 1, logical reads 8

SELECT * FROM dbo.Cliente
WHERE Nome like '%Duailibe%'
-- 1.003 linhas em 4 segundos
-- Index Scan + Bookmark Lookup com paralelismo
-- Table 'Cliente'. Scan count 3, logical reads 29088
-- Total IO = 29088 * 8 k = 232704 K = 227 MB

/********************************************************************************
 Fulltext Index
 https://learn.microsoft.com/en-us/sql/relational-databases/search/full-text-search?view=sql-server-ver16
 https://learn.microsoft.com/en-us/sql/relational-databases/search/create-and-manage-full-text-indexes?view=sql-server-ver16

 - Requisitos para criar Indice Fulltext
   - Criar Catalogo Fulltext no Banco.
   - Tabela precisa de índice UNIQUE NOT NULL com chave contendo uma coluna.

*********************************************************************************/

SELECT * FROM sys.fulltext_languages
-- Português 2070

-- 1o Passo: Criar um Catalogo
CREATE FULLTEXT CATALOG HandsOn  --WITH ACCENT_SENSITIVITY = OFF -- Padrão é ON
AS DEFAULT
-- DROP FULLTEXT CATALOG HandsOn 

/*
 ItemCount - Quantidade de índices Fulltext dentro do Catálogo
 IndexSize - Tamanho do Catálogo em MB
*/
-- Verificar status da atualização

SELECT db_name(database_id) as Banco, object_name(table_id) as Tabela,
population_type_description, status_description, start_time
FROM sys.dm_fts_index_population 
WHERE db_name(database_id) = 'HandsOn'

-- ou

DECLARE @NomeCatalogo varchar(100) = 'HandsOn'
SELECT 
fulltextcatalogproperty('HandsOn', 'ItemCount') as ItemCount, -- Quantidade de índices Fulltext dentro do Catálogo
fulltextcatalogproperty('HandsOn', 'IndexSize') as IndexSize_MB,  -- Tamanho do Catálogo em MB
fulltextcatalogproperty(@NomeCatalogo,'PopulateCompletionAge'),
DATEADD(ss, fulltextcatalogproperty(@NomeCatalogo,'PopulateCompletionAge'), '1/1/1990') AS LastPopulated,
(SELECT CASE fulltextcatalogproperty(@NomeCatalogo,'PopulateStatus')
WHEN 0 THEN 'Idle'
WHEN 1 THEN 'Full Population In Progress'
WHEN 2 THEN 'Paused'
WHEN 3 THEN 'Throttled'
WHEN 4 THEN 'Recovering'
WHEN 5 THEN 'Shutdown'
WHEN 6 THEN 'Incremental Population In Progress'
WHEN 7 THEN 'Building Index'
WHEN 8 THEN 'Disk Full.  Paused'
WHEN 9 THEN 'Change Tracking' END) AS PopulateStatus

-- 2o Passo: Criar um Índice Fulltext por tabela
CREATE FULLTEXT INDEX ON dbo.Cliente (Nome LANGUAGE 2070)
KEY INDEX ix_Cliente
WITH STOPLIST = SYSTEM

DROP FULLTEXT INDEX ON dbo.Cliente

CREATE FULLTEXT INDEX ON dbo.Cliente (Nome LANGUAGE 2070,Email LANGUAGE 2070)
KEY INDEX ix_Cliente
WITH STOPLIST = SYSTEM


-- Checar se um índice está sendo utilizado como Key na criação de um Índice Fulltext
SELECT INDEXPROPERTY(OBJECT_ID('Cliente'), 'ix_Cliente',  'IsFulltextKey')


SELECT * FROM dbo.Cliente
WHERE Nome like '%Duailibe%'
-- 1.003 linhas em 5 segundos
-- Table 'Cliente'. Scan count 3, logical reads 28643

SELECT * FROM dbo.Cliente
WHERE contains(Nome,'Duailibe')
-- 1.003 linhas em zero segundos
-- Table 'Cliente'. Scan count 0, logical reads 3080


/*************************
 Função CONTAINS
 https://learn.microsoft.com/en-us/sql/t-sql/queries/contains-transact-sql?view=sql-server-ver16
**************************/

SELECT * FROM dbo.Cliente
WHERE contains(Nome,'Duailibe')

SELECT * FROM dbo.Cliente
WHERE contains(Nome,'João and Duailibe')

SELECT * FROM dbo.Cliente
WHERE contains(Nome,'João or Duailibe')

SELECT * FROM dbo.Cliente
WHERE contains(Nome,'"João Duailibe"')

-- Duas colunas
SELECT * FROM dbo.Cliente
WHERE contains((Nome,Email),'João')

/****************************************************************
 Função FREETEXT
 https://learn.microsoft.com/en-us/sql/t-sql/queries/freetext-transact-sql?view=sql-server-ver16

 - Funciona como um CONTAINS separando cada palavra com OR
*****************************************************************/
SELECT * FROM dbo.Cliente
WHERE freetext(Nome,'Duailibe')



/************************************
 Atualização de índices Fulltext
*************************************/
INSERT dbo.Cliente VALUES ('Landry Duailibe', '(21)9765-12989','landry@sqlserver-expert.com.br','Rua D 1234',getdate())
go

-- Não encontra a linha nova
-- Padrão é não ter atualização automática!
SELECT * FROM dbo.Cliente
WHERE contains(Nome,'"Landry Duailibe"')

-- Atualização manual ou agendada "FULL POPULATION"
ALTER FULLTEXT INDEX ON dbo.Cliente START FULL POPULATION

-- Atualização automática "CHANGE_TRACKING"
ALTER FULLTEXT INDEX ON dbo.Cliente SET CHANGE_TRACKING AUTO

INSERT dbo.Cliente VALUES ('Paula Duailibe', '(21)945-12921','Paula@sqlserver-expert.com.br','Rua E 1234',getdate())
go

SELECT * FROM dbo.Cliente
WHERE contains(Nome,'"Paula Duailibe"')


use Master
go
DROP DATABASE If exists HandsOn




