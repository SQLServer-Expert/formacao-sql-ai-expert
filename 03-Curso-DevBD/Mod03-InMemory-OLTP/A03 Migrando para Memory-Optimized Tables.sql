/********************************************************************************
 Autor: Landry Duailibe

 Hands On: Migrando para Tabelas Memory-Optimized
*********************************************************************************/
use MemoryDB
go

DROP TABLE IF exists dbo.Venda
go
CREATE TABLE dbo.Venda
(Venda_ID int NOT NULL,
DataVenda datetime NOT NULL,
Cliente_ID int NULL,
Vendedor_ID int NULL,
Valor_Total decimal(12,2) NULL)
go

-- inclui 10.000 linhas
DECLARE @i int = 1
WHILE @i <= 10000 BEGIN
	INSERT dbo.Venda (Venda_ID,DataVenda,Cliente_ID,Vendedor_ID,Valor_Total)
	VALUES (@i,getdate(),11,21,10.00 + @i)

	SET @i += 1
END
go

SELECT count(*) FROM dbo.Venda

SELECT * FROM dbo.Venda
SELECT * FROM dbo.Venda_old

/***************************************************************
 Hash Bucket
 - Tamanho do índice hash está relacionado ao valor do Bucket!
 - [Tamanho do ídice] = 8 * [bucket count] (Bytes)
 - Recomendado ter de 1x a 2x a quantidade de valores distintos.

 https://learn.microsoft.com/en-us/sql/relational-databases/sql-server-index-design-guide?view=sql-server-ver16#hash_index
****************************************************************/

-- Valor ideal
SELECT POWER(2,CEILING( LOG( COUNT( 0)) / LOG( 2))) AS 'BUCKET_COUNT'
FROM (SELECT DISTINCT Venda_ID FROM Venda) T

-- Alterando o Bucket
ALTER TABLE dbo.Venda
ALTER INDEX imPK_Venda_Venda_ID
REBUILD WITH (BUCKET_COUNT=67108864)  
GO

-- Lista tabelas Memory-Optimized
SELECT b.[name] as Tabela, a.*
FROM MemoryDB.sys.dm_db_xtp_table_memory_stats a
JOIN MemoryDB.sys.tables b ON a.[object_id] = b.[object_id]


-- Exclui Banco
use master
go
ALTER DATABASE MemoryDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE
DROP DATABASE IF exists MemoryDB





