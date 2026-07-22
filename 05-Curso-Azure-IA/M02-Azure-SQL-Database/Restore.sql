/**************************************
 Autor: Landry Duailibe

 HandsOn: Restore
***************************************/

/***********************************************
 sys.dm_database_backups
 - Status de operações como Restore, Clone, etc.
 https://learn.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-operation-status-azure-sql-database?view=azuresqldb-current
************************************************/
SELECT operation as Operacao, major_resource_id as Banco,
state_desc [Status], percent_complete as [% Completo],
start_time as DataHora_Inicio, 
last_modify_time as DataHora_Alteracao,
start_time AT TIME ZONE 'UTC' AT TIME ZONE 'Bahia Standard Time' as DataHora_Inicio_Local, 
last_modify_time AT TIME ZONE 'UTC' AT TIME ZONE 'Bahia Standard Time' as DataHora_Alteracao_Local
FROM sys.dm_operation_status 
ORDER BY last_modify_time desc

/******************************************
 Restore num ponto no tempo
*******************************************/
-- Somente Backup Log
SELECT logical_database_name as Banco, backup_finish_date as DataHora_UTC,
backup_finish_date AT TIME ZONE 'UTC' AT TIME ZONE 'Bahia Standard Time' as DataHora_Local
FROM sys.dm_database_backups
WHERE 1=1
and backup_type = 'L'
and backup_finish_date >= '20241010 21:00:00.000'
ORDER BY backup_start_date DESC

-- Criar tabela no Banco AulaDB
DROP TABLE IF EXISTS dbo.Cliente
go
CREATE TABLE dbo.Cliente (
Cliente_PK int not null primary key,
Nome varchar(40) not null,
Telefone varchar(20) null)
go

INSERT dbo.Cliente (Cliente_PK, Nome, Telefone) VALUES 
(1,'Jose','2343-2289'),
(2,'Ana','3432-2184'),
(3,'Maria','5449-2580')
go
-- Antes de criar tabela -> 21:20:00.0000000 (UTC) - 18:20:00.0000000 -03:00 (LOCAL)
-- Após criar a tabela ---> 21:32:00.0000000 (UTC) - 21:32:00.0000000 -03:00 (LOCAL)

-- Incluir linhas 4 e aguardar o próximo Backup Log
INSERT dbo.Cliente (Cliente_PK, Nome, Telefone) VALUES (4,'Paula','2334-9987')


SELECT * FROM dbo.Cliente ORDER BY 1








