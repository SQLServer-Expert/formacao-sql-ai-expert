/********************************************************************
 Autor: Landry

 Hands On: Particionamento de Tabelas
*********************************************************************/
use master
go
-- drop database BDparticao
Create database BDparticao on
primary (name = BDparticao, filename = 'C:\MSSQL_Data\BDparticao.mdf'),
filegroup FG1 (name = BDparticao1, filename = 'C:\MSSQL_Data\BDparticao1.ndf'),
filegroup FG2 (name = BDparticao2, filename = 'C:\MSSQL_Data\BDparticao2.ndf'),
filegroup FG3 (name = BDparticao3, filename = 'C:\MSSQL_Data\BDparticao3.ndf'),
filegroup FG4 (name = BDparticao4, filename = 'C:\MSSQL_Data\BDparticao4.ndf')
log on
(name = BDparticao_log, filename = 'C:\Aula\BDparticao_log.ldf')
go

use BDparticao
go

CREATE PARTITION FUNCTION pf_Particao (int)
AS RANGE LEFT
FOR VALUES (10, 20, 30)

go
/* LEFT
 1) <= 10
 2) > 10 and <= 20
 3) > 20 and <= 30
 4) > 30
*/

/* RIGHT
 1) < 10
 2) >= 10 and < 20
 3) >= 20 and < 30
 4) >= 30
*/

CREATE PARTITION SCHEME ps_Particao
AS PARTITION pf_Particao 
TO (FG1, FG2, FG3, FG4)

/*
CREATE PARTITION SCHEME ps_Particao
AS PARTITION pf_Particao 
ALL TO ([PRIMARY])
*/

-- Create partitioned table

CREATE TABLE dbo.TesteParticao (
ColParticao int NOT NULL,
ColNome varchar(50) NOT NULL)
ON ps_Particao(ColParticao)


/* LEFT
 1) <= 10
 2) > 10 and <= 20
 3) > 20 and <= 30
 4) > 30
*/
insert TesteParticao values (1, 'Nome 01') -- Part 1
insert TesteParticao values (2, 'Nome 02') -- Part 1
insert TesteParticao values (11,'Nome 11') -- Part 2
insert TesteParticao values (12,'Nome 12') -- Part 2
insert TesteParticao values (21,'Nome 21') -- Part 3
insert TesteParticao values (22,'Nome 22') -- Part 3
insert TesteParticao values (31,'Nome 31') -- Part 4
insert TesteParticao values (32,'Nome 32') -- Part 4
go

-- sys.partitions
SELECT * FROM sys.Partitions 
WHERE [object_id] = OBJECT_ID('dbo.TesteParticao')
ORDER BY partition_number

/***********************************
 sys.partition_range_values
 https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-partition-range-values-transact-sql?view=sql-server-ver16

 sys.partition_functions
 https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-partition-functions-transact-sql?view=sql-server-ver16
************************************/
SELECT p.name,boundary_id,value 
FROM sys.partition_range_values r 
join sys.partition_functions p ON r.function_id = p.function_id

-- SELECT na tabela identificando a partição
SELECT ColParticao, ColNome, $Partition.pf_Particao(ColParticao) Particao
FROM dbo.TesteParticao



/*********************************************
 Manutenção nas Partições
**********************************************/
SELECT * FROM sys.Partitions 
WHERE [object_id] = OBJECT_ID('dbo.TesteParticao')
ORDER BY partition_number

SELECT ColParticao, ColNome, $Partition.pf_Particao(ColParticao) Particao
FROM dbo.TesteParticao

-- MERGE

ALTER PARTITION FUNCTION pf_Particao()MERGE RANGE (30)

ALTER PARTITION FUNCTION pf_Particao()MERGE RANGE (20)

-- SPLIT

ALTER PARTITION SCHEME ps_Particao NEXT USED FG3;
ALTER PARTITION FUNCTION pf_Particao()SPLIT RANGE (20)

ALTER PARTITION SCHEME ps_Particao NEXT USED FG4;
ALTER PARTITION FUNCTION pf_Particao()SPLIT RANGE (30)

-- SWITCH: troca partição 1 para tabela não particionada

CREATE TABLE dbo.TesteSWITCH (
ColParticao int NOT NULL,
ColNome varchar(50) NOT NULL)
ON FG1

ALTER TABLE dbo.TesteParticao SWITCH PARTITION 1 TO dbo.TesteSWITCH


SELECT * FROM dbo.TesteParticao

SELECT * FROM dbo.TesteSWITCH

-- DROP
use master
go
DROP DATABASE IF exists BDparticao
