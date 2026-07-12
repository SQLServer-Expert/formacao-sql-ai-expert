/**********************************************
 Autor: Landry Duailibe

 Propriedades de Bancos de Dados
***********************************************/
use master
go

/**********************************
 sys.databases
***********************************/ 
SELECT * FROM sys.databases

SELECT [name] as Banco,collation_name as Collation,
CASE [compatibility_level]
WHEN 80 THEN 'SQL2000'
WHEN 90 THEN 'SQL2005'
WHEN 100 THEN 'SQL2008' 
WHEN 110 THEN 'SQL2012'
WHEN 120 THEN 'SQL2014' 
WHEN 130 THEN 'SQL2016'
WHEN 140 THEN 'SQL2017'
WHEN 150 THEN 'SQL2019'
WHEN 160 THEN 'SQL2022'
ELSE ltrim(str(compatibility_level)) END as VersaoSQL,
recovery_model_desc as RecoveryModel,
page_verify_option_desc as PageVerify,
case when is_auto_close_on = 1 then 'ON' else 'OFF' end as [Auto_Close],
case when is_auto_shrink_on = 1 then 'ON' else 'OFF' end as [Auto_Shrink],
case when is_read_committed_snapshot_on = 1 then 'ON' else 'OFF' end as [Read_Committed_Snapshot]

FROM MASTER.sys.databases
WHERE database_id > 4
ORDER BY 1


/**********************************
 sys.databases + sys.master_files
***********************************/
SELECT * FROM sys.databases
SELECT * FROM sys.master_files

;WITH CTE_TamanhoBD_Dados as (
SELECT b.name as Banco, sum((a.size * 8) / 1024) as TamanhoMB_Dados
FROM sys.master_files a
JOIN sys.databases b ON a.database_id = b.database_id
WHERE a.type_desc <> 'LOG'
GROUP BY b.name),

CTE_TamanhoBD_Log as (
SELECT b.name as Banco, sum((a.size * 8) / 1024) as TamanhoMB_Log
FROM sys.master_files a
JOIN sys.databases b ON a.database_id = b.database_id
WHERE a.type_desc = 'LOG'
GROUP BY b.name)

SELECT a.name as Banco,a.recovery_model_desc as [Recovery],
CASE a.compatibility_level
WHEN 80 THEN 'SQL2000'
WHEN 90 THEN 'SQL2005'
WHEN 100 THEN 'SQL2008' 
WHEN 110 THEN 'SQL2012' 
WHEN 120 THEN 'SQL2014' 
WHEN 130 THEN 'SQL2016'
WHEN 140 THEN 'SQL2017'
WHEN 150 THEN 'SQL2019'
WHEN 160 THEN 'SQL2022'
ELSE ltrim(str(compatibility_level)) END as Versão,
a.collation_name as Collation, 
b.TamanhoMB_Dados, c.TamanhoMB_Log

FROM master.sys.databases a
JOIN CTE_TamanhoBD_Dados b ON a.name = b.Banco
JOIN CTE_TamanhoBD_Log c ON a.name = c.Banco
WHERE database_id > 4
ORDER BY TamanhoMB_Dados desc

/**********************************
 Função DATABASEPROPERTYEX
 https://learn.microsoft.com/en-us/sql/t-sql/functions/databasepropertyex-transact-sql?view=sql-server-ver16
***********************************/
SELECT DATABASEPROPERTYEX('AdventureWorks', 'Collation')
SELECT DATABASEPROPERTYEX('AdventureWorks', 'Recovery')
SELECT DATABASEPROPERTYEX('AdventureWorks', 'Status')
/*
ONLINE: Banco liberado para uso.
OFFLINE: Banco fora do ar, arquivos liberados no disco.
RESTORING: No meio do processo de Restore.
RECOVERING: Em processo de recuperação.
SUSPECT: Banco corrompido.
EMERGENCY: Acesso restrito ao administrador, normalmente utilizado em recuperações.
*/
SELECT DATABASEPROPERTYEX('AdventureWorks', 'IsAutoShrink')


