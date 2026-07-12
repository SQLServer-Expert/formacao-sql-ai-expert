/*************************************************
 Autor: Landry
 
 Hands On: Forwarded Records
**************************************************/
use master
go

CREATE DATABASE HandsOn
go
ALTER DATABASE HandsOn SET RECOVERY simple
go

use HandsOn
go

DROP TABLE IF exists dbo.Cliente
go
CREATE TABLE dbo.Cliente (
ID int not null IDENTITY,
Nome varchar(8000) not null,
DataAniversario date not null)
go

CREATE NONCLUSTERED INDEX ix_Cliente_DataAniversario 
ON dbo.Cliente (DataAniversario)
go

INSERT dbo.Cliente (Nome,DataAniversario) 
VALUES (REPLICATE('A', 2000),getdate())
INSERT dbo.Cliente (Nome,DataAniversario) 
VALUES (REPLICATE('B', 2000),getdate())
INSERT dbo.Cliente (Nome,DataAniversario) 
VALUES (REPLICATE('C', 2000),getdate())
INSERT dbo.Cliente (Nome,DataAniversario) 
VALUES (REPLICATE('D', 2000),getdate())
INSERT dbo.Cliente (Nome,DataAniversario) 
VALUES (REPLICATE('E', 2000),getdate())
go


-- Quantas páginas o TABLE SCAN consome
SET STATISTICS IO ON

SELECT * FROM dbo.Cliente
-- 1a EXEC: Table 'Cliente'. Scan count 1, logical reads 2


-- Retorna o endereço de todas as páginas que compôe a tabela
SELECT	a.allocation_unit_type_desc,
a.is_allocated,
a.is_iam_page,
a.allocated_page_page_id,
a.page_free_space_percent

FROM sys.dm_db_database_page_allocations(DB_ID(),OBJECT_ID('dbo.Cliente', 'U'),0,NULL,'DETAILED') as a
WHERE a.is_allocated = 1
ORDER BY a.page_type DESC, a.allocated_page_page_id
-- 1a EXEC: Páginas 142(IAM) 256, 257


-- Retorna em que página cada linha está
SELECT b.*, a.*
FROM dbo.Cliente as a
CROSS APPLY sys.fn_PhysLocCracker(%%physloc%%) AS b


-- Mostra a página
DBCC TRACEON (3604)
DBCC PAGE (HandsOn, 1, 256, 3)
DBCC PAGE (HandsOn, 1, 257, 3)

-- Provoca Forwarded Records
UPDATE dbo.Cliente
SET	Nome = REPLICATE('Z', 6500)
WHERE ID = 1

-- Mostra  Forwarded Records
SELECT	a.index_type_desc, a.page_count,
a.avg_page_space_used_in_percent,
a.record_count, a.forwarded_record_count
FROM sys.dm_db_index_physical_stats(DB_ID(),OBJECT_ID('dbo.Cliente', 'U'),0,NULL,'DETAILED') as a

SELECT * FROM dbo.Cliente
-- 1a EXEC: Table 'Cliente'. Scan count 1, logical reads 2
-- 2a EXEC: Table 'Cliente'. Scan count 1, logical reads 4

-- Retorna o endereço de todas as páginas que compôe a tabela
SELECT	a.allocation_unit_type_desc,
a.is_allocated,
a.is_iam_page,
a.allocated_page_page_id,
a.page_free_space_percent

FROM sys.dm_db_database_page_allocations(DB_ID(),OBJECT_ID('dbo.Cliente', 'U'),0,NULL,'DETAILED') as a
WHERE a.is_allocated = 1
ORDER BY a.page_type DESC, a.allocated_page_page_id
-- 1a EXEC: Páginas 142(IAM) 256, 257
-- 2a EXEC: Páginas 142(IAM) 256, 257, 258 (nova)

SELECT b.*, a.*
FROM dbo.Cliente as a
CROSS APPLY sys.fn_PhysLocCracker(%%physloc%%) AS b


DBCC PAGE (HandsOn, 1, 256, 3);
DBCC PAGE (HandsOn, 1, 257, 3);
DBCC PAGE (HandsOn, 1, 258, 3);

/*****************
 DROP
******************/
use master
go

DROP DATABASE IF exists HandsOn
