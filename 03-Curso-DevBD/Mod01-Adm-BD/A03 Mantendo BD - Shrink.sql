/**********************************************
 Autor: Landry Duailibe

 Shrink
***********************************************/
use master
go

CREATE DATABASE DB_Teste
go
ALTER DATABASE DB_Teste SET RECOVERY FULL
go

--  Create tabela no banco DB_Teste
DROP TABLE IF exists DB_Teste.dbo.tb_Teste
go
CREATE TABLE DB_Teste.dbo.tb_Teste ( 
tb_Teste_ID int identity CONSTRAINT pk_tb_Teste PRIMARY KEY,
ColunaGrande nchar(2000),
ColunaBigint bigint)
go

set nocount on

-- Inclui 100.000 linhas
INSERT DB_Teste.dbo.tb_Teste (ColunaGrande,ColunaBigint)
VALUES('Teste',12345)
go 100000

use DB_Teste
go

SELECT name AS Name, size * 8 /1024. as Tamanho_MB,  
FILEPROPERTY(name,'SpaceUsed') * 8 /1024. as Espaco_Utilizado_MB,
CAST(FILEPROPERTY(name,'SpaceUsed') as decimal(10,4))
/ CAST(size as decimal(10,4)) * 100 as Percentual_Utilizado
FROM sys.database_files
/*
Name			Tamanho_MB	Espaco_Utilizado_MB	Percentual_Utilizado
DB_TesteLog		456.000000	395.812500			86.800986842105200
DB_TesteLog_log	328.000000	214.312500			65.339176829268200
*/

-- Reduz mas mantém 10% de espaço livre
DBCC SHRINKDATABASE('DB_Teste', 10 )

-- Exclui metade das linhas
DELETE top(50000) DB_Teste.dbo.tb_Teste


USE DB_TesteLog
go
DBCC SHRINKFILE (N'DB_Teste' , 250)

-- Exclui banco
use master
go
DROP DATABASE IF exists DB_Teste



