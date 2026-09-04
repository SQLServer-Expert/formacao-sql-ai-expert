/********************************************
 Autor: Landry
 
 Coleta Contadores Performance Monitor
*********************************************/
DROP DATABASE IF exists DBA
go
CREATE DATABASE DBA
go
ALTER DATABASE DBA SET RECOVERY simple
go
USE DBA
go

/*********************************
 Tabela tb_DBA_Coleta_Contadores
*********************************/
-- DROP TABLE dbo.tb_DBA_Coleta_Contadores
-- TRUNCATE TABLE dbo.tb_DBA_Coleta_Contadores
DROP TABLE IF exists dbo.tb_DBA_Coleta_Contadores
go
CREATE TABLE dbo.tb_DBA_Coleta_Contadores (
DBA_Coleta_Contadores_ID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
NomeServidor varchar(200) NOT NULL,
DataColeta datetime NOT NULL,

MEM_RAM_GB decimal(16, 2) NULL,
MEM_Livre_GB decimal(16, 2) NULL,

[Forwarded Records/sec] int NULL,
[Full Scans/sec] int NULL,
[Index Searches/sec] int NULL,
[Page Splits/sec] int NULL,
[Transactions/sec] int NULL,
[Lock Waits/sec] int NULL,
[Number of Deadlocks/sec] int NULL,
[Batch Requests/sec] int NULL,
[Page life expectancy] int NULL,
[Total Server Memory (KB)] int NULL,
[Target Server Memory (KB)] int NULL,
[Database pages] int NULL,
[User Connections] int NULL,
Processado bit not null default (0))
go

/**************************************************
 Stored Procedure: spu_DBA_Coleta_Contadores
 - Coleta de informações de desempenho
 - Criar JOB e agendar execução a cada 30 segundos
   EXEC dbo.spu_DBA_Coleta_Contadores
***************************************************/
-- DROP PROCEDURE spu_DBA_Coleta_Contadores
CREATE or ALTER PROC dbo.spu_DBA_Coleta_Contadores
as
set nocount on

DECLARE @DataColeta datetime

/****************************************************************
 Valor Acumulado
 cntr_type = 272696576

 - Aferir dois valores, subtrair e dividir pelo tempo em segundos
   (V2 - V1) / Intervalo Seg
*****************************************************************/

-- 1a coleta
SELECT counter_name as Contador,cntr_value as Valor
INTO #PrimeiraColeta
FROM sys.dm_os_performance_counters
WHERE cntr_type = 272696576
and instance_name in ('_Total','')
and counter_name in (
'Lock Waits/sec',
'Number of Deadlocks/sec',
'Transactions/sec',
'Full Scans/sec',
'Index Searches/sec',
'Forwarded Records/sec',
'Page Splits/sec',
'Batch Requests/sec')
ORDER BY 1,2

WAITFOR DELAY '00:00:10'

-- 2a Coleta
SELECT counter_name as Contador,cntr_value as Valor
INTO #SegundaColeta
FROM sys.dm_os_performance_counters
WHERE cntr_type = 272696576
and instance_name in ('_Total','')
and counter_name in (
'Lock Waits/sec',
'Number of Deadlocks/sec',
'Transactions/sec',
'Full Scans/sec',
'Index Searches/sec',
'Forwarded Records/sec',
'Page Splits/sec',
'Batch Requests/sec')
ORDER BY 1,2

SET @DataColeta = getdate()

/****************************
 CTE Duas Coletas
*****************************/
;WITH CTE_DuasColetas as (
SELECT @@SERVERNAME as NomeServidor,
@DataColeta as DataColeta,*
FROM (
SELECT a.Contador, (b.Valor - a.Valor) / 10 as Valor
FROM #PrimeiraColeta a
JOIN #SegundaColeta b ON a.Contador = b.Contador) a
PIVOT (max(Valor) FOR Contador in 
([Forwarded Records/sec],[Full Scans/sec],[Index Searches/sec],[Page Splits/sec],
[Transactions/sec],[Lock Waits/sec],[Number of Deadlocks/sec],[Batch Requests/sec]) ) b),

/***********************
 CTE Valor direto
************************/
CTE_UmaColeta as (
SELECT @@SERVERNAME as NomeServidor,
@DataColeta as DataColeta,
(select 
cast((total_physical_memory_kb/1024.00)/1024.00 as decimal(16,2)) as MEM_RAM_GB
from sys.dm_os_sys_memory) as MEM_RAM_GB,
(select 
cast((available_physical_memory_kb/1024.00)/1024.00 as decimal(16,2)) as MEM_Livre_GB
from sys.dm_os_sys_memory) as MEM_Livre_GB,* 

FROM (
SELECT counter_name,cntr_value
FROM sys.dm_os_performance_counters
WHERE cntr_type = 65792
and instance_name in ('_Total','')
and counter_name in ('Page life expectancy',
'Total Server Memory (KB)','Target Server Memory (KB)',
'Database pages','User Connections')) a
PIVOT (max(cntr_value) FOR counter_name in 
([Page life expectancy],[Total Server Memory (KB)],[Target Server Memory (KB)],
[Database pages],[User Connections]) ) b)


/*****************************
 Inclusão dados de contadores
******************************/
INSERT dbo.tb_DBA_Coleta_Contadores
(NomeServidor, DataColeta, MEM_RAM_GB, MEM_Livre_GB, 
[Forwarded Records/sec], [Full Scans/sec], [Index Searches/sec], [Page Splits/sec], 
[Transactions/sec], [Lock Waits/sec], 
[Number of Deadlocks/sec], [Batch Requests/sec], [Page life expectancy], 
[Total Server Memory (KB)], [Target Server Memory (KB)], [Database pages], [User Connections])

SELECT a.NomeServidor,a.DataColeta, a.MEM_RAM_GB, a.MEM_Livre_GB,
[Forwarded Records/sec], [Full Scans/sec], [Index Searches/sec], [Page Splits/sec], 
[Transactions/sec], [Lock Waits/sec], 
[Number of Deadlocks/sec], [Batch Requests/sec], [Page life expectancy], 
[Total Server Memory (KB)], [Target Server Memory (KB)], [Database pages],[User Connections]

FROM CTE_UmaColeta a 
JOIN CTE_DuasColetas b ON b.NomeServidor = a.NomeServidor and b.DataColeta = a.DataColeta

DROP TABLE #PrimeiraColeta
DROP TABLE #SegundaColeta

go
/******************************************** FIM SP ******************************************/

SELECT * FROM DBA.dbo.tb_DBA_Coleta_Contadores

SELECT NomeServidor,
cast(DataColeta as date) as Dia, 
convert(char(2),DataColeta,108) as Hora,

avg(MEM_RAM_GB) as MEM_RAM_GB,
avg(MEM_Livre_GB) as MEM_Livre_GB,

avg([User Connections]) as UserConnections_AVG,
max([User Connections]) as UserConnections_MAX,

avg([Batch Requests/sec]) as BatchRequests_AVG,
max([Batch Requests/sec]) as BatchRequests_MAX,

avg([Transactions/sec]) as Transactions_AVG,
max([Transactions/sec]) as Transactions_MAX,

(max([Total Server Memory (KB)])/1024.00)/1024.00 as TotalServerMemory_GB_MAX,
(max([Target Server Memory (KB)])/1024.00)/1024.00 as TargetServerMemory_GB_MAX,
avg(((cast([Database pages] as decimal(16,2)) * 8.00)/1024.00)/1024.00) as BufferPool_GB,

-- Ideal 20 Page Splits a cada 100 Batch Requests no maximo
avg([Page Splits/sec]) as PageSplits_AVG,
avg(([Batch Requests/sec] / 100.00)) * 20.00 as PageSplits_Ideal,

-- Ideal 10 Forwarded Records a cada 100 Batch Requests no máximo
avg([Forwarded Records/sec]) as ForwardedRecords_AVG,
avg(([Batch Requests/sec] / 100.00)) * 10.00 as ForwardedRecords_Ideal,

-- (Index Searches/sec) / (Full Scans/sec) deve ser superior a 500
avg([Full Scans/sec]) as FullScans_AVG, 
avg([Index Searches/sec]) as IndexSearches_AVG, 
max([Full Scans/sec]) as FullScans_MAX, 
max([Index Searches/sec]) as IndexSearches_MAX, 
avg([Index Searches/sec]) / case when avg([Full Scans/sec]) = 0 then 1 else avg([Full Scans/sec]) end as ProporcaoSearcheScan_AVG,
max([Index Searches/sec]) / case when max([Full Scans/sec]) = 0 then 1 else max([Full Scans/sec]) end as ProporcaoSearcheScan_MAX,
500.00 as ProporcaoSearcheScan_Ideal,

--  Page life expectancy deve ser superior a (Total Server Memory em GB) / 4 * 300
avg([Page life expectancy]) as PageLifeExpectancy_AVG,
avg(((([Total Server Memory (KB)]/1024.00)/1024.00) / 4.00)) * 300.00 as PageLifeExpectancy_Ideal,

-- 2 / 4 * 300
-- Vaor ideal inferior a 1.00
avg([Lock Waits/sec]) as LockWaitsSec_AVG,
max([Lock Waits/sec]) as LockWaitsSec_MAX,
1.00 as LockWaitsSec_Ideal,

max([Number of Deadlocks/sec]) as Deadlocks_sec

FROM DBA.dbo.tb_DBA_Coleta_Contadores
WHERE DataColeta >= '20240304' and DataColeta < '20240305'
GROUP BY NomeServidor,cast(DataColeta as date), convert(char(2),DataColeta,108)
ORDER BY NomeServidor,Dia,Hora

