/**********************************************************
 Autor: Landry

 Monitora Consultas
 - Cria tabela para armazenar dados capturados
 - Cria Extende Events
 - Importa dados 
***********************************************************/
use master
go

/*******************************************
 Cria Tabela para receber dados monitorados
 - 1 minuto = 60 segundos = 60.000 Milissegundos = 60.000.000 microsegundos
 - Duration em microsegundos
 - CPU em milesegundos
********************************************/
DROP TABLE IF exists Aula.dbo.DBA_Query_Tuning
go
CREATE TABLE Aula.dbo.DBA_Query_Tuning (
Evento_ID int not null identity primary key,
DataHora datetime NULL,
Evento varchar(200) NULL,
TempoExec bigint NULL,
TempoExec_Seg bigint NULL,
TempoCPU bigint NULL,
TempoCPU_Seg bigint NULL,
QtdLinhas int NULL,
LeiturasLogicas_Kb bigint NULL,
LeiturasFisicas_Kb bigint NULL,
Escritas_Kb int NULL,
Usuario varchar(200) NULL,
Host varchar(200) NULL,
Aplicacao varchar(200) NULL,
SPID int NULL,
EventoID int NULL,
Instancia varchar(200) NULL,
Banco varchar(200) NULL,
Comando varchar(max) NULL,
Comando_XML xml NULL)
go


/**************************************************
 Stored Procedure spu_DBA_Query_Tuning_Start
 - Cria Captura de Consultas
***************************************************/
go
CREATE or ALTER PROC spu_DBA_Query_Tuning_Start
@Caminho nvarchar(1000) = N'C:\_HandsOn\ExtendedEvents',
@Tempo nvarchar(50) = '10000', -- microseconds 60000000 = minuto 1
@Banco nvarchar(128) = null,
@Arquivo nvarchar(2000) = null 
as
set nocount on

SET @Arquivo = @Caminho + '\MonitoraConsultas' + convert(varchar(8),getdate(),112) + '.xel'

-- DROP EVENT SESSION DBA_Monitora_Consultas ON SERVER 
DECLARE @TSQL nvarchar(2000)

IF exists (SELECT * FROM sys.server_event_sessions WHERE name = 'DBA_Monitora_Consultas') BEGIN
	ALTER EVENT SESSION DBA_Monitora_Consultas ON SERVER STATE = STOP
	DROP EVENT SESSION DBA_Monitora_Consultas ON SERVER
END

IF @Banco is null
SET @TSQL = N'CREATE EVENT SESSION DBA_Monitora_Consultas ON SERVER 
ADD EVENT sqlserver.rpc_completed(

    ACTION(package0.collect_cpu_cycle_time,package0.collect_system_time,package0.event_sequence,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_connection_id,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_name,sqlserver.nt_username,sqlserver.server_instance_name,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.sql_text,sqlserver.username)
	WHERE sqlserver.database_name <> ''master'' AND sqlserver.database_name <> ''msdb'' AND sqlserver.database_name <> ''tempdb'' 
	AND sqlserver.database_name <> ''ReportServer'' AND sqlserver.database_name <> ''ReportServerTempDB'' AND duration >= ' + @Tempo + '),

ADD EVENT sqlserver.sql_statement_completed(
    ACTION(package0.collect_cpu_cycle_time,package0.collect_system_time,package0.event_sequence,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_connection_id,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_name,sqlserver.nt_username,sqlserver.server_instance_name,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.sql_text,sqlserver.username)
	WHERE sqlserver.database_name <> ''master'' AND sqlserver.database_name <> ''msdb'' AND sqlserver.database_name <> ''tempdb'' 
	AND sqlserver.database_name <> ''ReportServer'' AND sqlserver.database_name <> ''ReportServerTempDB''  AND duration >= ' + @Tempo + ')

ADD TARGET package0.event_file(SET filename=N''' + @Arquivo + ''',max_file_size=(100),max_rollover_files=(20))
WITH (STARTUP_STATE=OFF)'

ELSE
SET @TSQL = N'CREATE EVENT SESSION DBA_Monitora_Consultas ON SERVER 
ADD EVENT sqlserver.rpc_completed(

    ACTION(package0.collect_cpu_cycle_time,package0.collect_system_time,package0.event_sequence,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_connection_id,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_name,sqlserver.nt_username,sqlserver.server_instance_name,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.sql_text,sqlserver.username)
	WHERE sqlserver.database_name = ''' + @Banco + ''' AND duration >= ' + @Tempo + '),

ADD EVENT sqlserver.sql_statement_completed(
    ACTION(package0.collect_cpu_cycle_time,package0.collect_system_time,package0.event_sequence,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_connection_id,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_name,sqlserver.nt_username,sqlserver.server_instance_name,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.sql_text,sqlserver.username)
	WHERE sqlserver.database_name = ''' + @Banco + ''' AND duration >= ' + @Tempo + ')

ADD TARGET package0.event_file(SET filename=N''' + @Arquivo + ''',max_file_size=(100),max_rollover_files=(20))
WITH (STARTUP_STATE=OFF)'

EXEC (@TSQL)

ALTER EVENT SESSION DBA_Monitora_Consultas ON SERVER STATE = START
go
/******************************* FIM SP *************************************/

/**************************************************
 Stored Procedure spu_DBA_Query_Tuning_Stop
 - Cria Captura de Consultas
***************************************************/
CREATE or ALTER PROC spu_DBA_Query_Tuning_Stop
@Caminho nvarchar(1000) = N'C:\_HandsOn\ExtendedEvents'
as
set nocount on

IF exists (SELECT * FROM sys.server_event_sessions WHERE name = 'DBA_Monitora_Consultas') BEGIN
	ALTER EVENT SESSION DBA_Monitora_Consultas ON SERVER STATE = STOP
	DROP EVENT SESSION DBA_Monitora_Consultas ON SERVER
END

DECLARE @Arquivo nvarchar(2000) = @Caminho + N'\MonitoraConsultas' + convert(varchar(8),getdate(),112) + '*.xel'

INSERT Aula.dbo.DBA_Query_Tuning
(DataHora, Evento, TempoExec, TempoExec_Seg, TempoCPU, TempoCPU_Seg, QtdLinhas, LeiturasLogicas_Kb, LeiturasFisicas_Kb, 
Escritas_Kb, Usuario, Host, Aplicacao, SPID, EventoID, Instancia, Banco, Comando, Comando_XML)

SELECT DataHora =  d.value(N'(/event/action[@name="collect_system_time"]/value)[1]', N'DATETIME')
,Evento = d.value(N'(/event/@name)[1]', N'varchar(200)')
,TempoExec = d.value(N'(/event/data[@name="duration"]/value)[1]', N'bigint') -- Microsegundos
,TempoExec_Seg = d.value(N'(/event/data[@name="duration"]/value)[1]', N'bigint') / 1000000 -- Microsegundos
,TempoCPU = d.value(N'(/event/data[@name="cpu_time"]/value)[1]', N'bigint') -- Microsegundos
,TempoCPU_Seg = d.value(N'(/event/data[@name="cpu_time"]/value)[1]', N'bigint') / 1000000 -- Microsegundos
,QtdLinhas = d.value(N'(/event/data[@name="row_count"]/value)[1]', N'int') 
,LeiturasLogicas_Kb = d.value(N'(/event/data[@name="logical_reads"]/value)[1]', N'bigint') * 8 -- Qtd de paginas 8k
,LeiturasFisicas_Kb = d.value(N'(/event/data[@name="physical_reads"]/value)[1]', N'bigint') * 8 -- Qtd de paginas 8k
,Escritas_Kb = d.value(N'(/event/data[@name="writes"]/value)[1]', N'int') * 8
,Usuario = d.value(N'(/event/action[@name="username"]/value)[1]', N'varchar(200)')
,Host = d.value(N'(/event/action[@name="client_hostname"]/value)[1]', N'varchar(200)')
,Aplicacao = d.value(N'(/event/action[@name="client_app_name"]/value)[1]', N'varchar(200)')
,SPID = d.value(N'(/event/action[@name="session_id"]/value)[1]', N'int')
,EventoID = d.value(N'(/event/action[@name="event_sequence"]/value)[1]', N'int')
,Instancia = d.value(N'(/event/action[@name="server_instance_name"]/value)[1]', N'varchar(200)')
,Banco = d.value(N'(/event/action[@name="database_name"]/value)[1]', N'varchar(200)')
,Comando = d.value(N'(/event/data[@name="statement"]/value)[1]', N'varchar(max)')
,Comando_XML = d.query(N'(/event/data[@name="statement"]/value)[1]')
FROM (
SELECT CONVERT(XML, event_data) 
FROM sys.fn_xe_file_target_read_file(@Arquivo, NULL, NULL, NULL)
WHERE object_name IN (N'sql_statement_completed','rpc_completed')) AS x(d)
go
/******************************* FIM SP *************************************/

/************************************************************
 Gera Atividade no banco AdventureWorks
 Utilizar SQLQueryStress com 100 interações e 4 Threads
*************************************************************/
DECLARE @TabTemp table (
SalesOrderID int NOT NULL,
OrderQty smallint NOT NULL,
OrderDate datetime NOT NULL,
Description char(1000) NULL,
StartDate datetime NOT NULL,
EndDate datetime NOT NULL)

INSERT @TabTemp
SELECT d.SalesOrderID, d.OrderQty, h.OrderDate, cast(o.Description as char(1000)) as Description, o.StartDate, o.EndDate
FROM AdventureWorks.Sales.SalesOrderDetail d
INNER JOIN AdventureWorks.Sales.SalesOrderHeader h ON d.SalesOrderID = h.SalesOrderID
INNER JOIN AdventureWorks.Sales.SpecialOffer o ON d.SpecialOfferID = o.SpecialOfferID
WHERE d.SpecialOfferID <> 1

SELECT * FROM @TabTemp
/*************************** FIM Gera Atividade *********************************/

-- Inicio da Captura de Eventos
EXEC spu_DBA_Query_Tuning_Start @Caminho = N'C:\_HandsOn\ExtendedEvents', @Tempo = N'10000' -- 30seg
EXEC spu_DBA_Query_Tuning_Start @Caminho = N'C:\_HandsOn\ExtendedEvents', @Banco = N'AdventureWorks', @Tempo = N'1000' -- 30seg

-- Final da Captura de Eventos
EXEC spu_DBA_Query_Tuning_Stop @Caminho = N'C:\_HandsOn\ExtendedEvents'

ALTER EVENT SESSION DBA_Monitora_Consultas ON SERVER STATE = START
ALTER EVENT SESSION DBA_Monitora_Consultas ON SERVER STATE = STOP

SELECT * FROM Aula.dbo.DBA_Query_Tuning

SELECT * FROM sys.server_event_sessions
SELECT * FROM sys.dm_xe_sessions

-- Unidades dos eventos
SELECT p.name package_name, o.name event_name, c.name event_field,
CASE WHEN c.description LIKE '%milli%' THEN SUBSTRING(c.description, CHARINDEX('milli', c.description),12)
WHEN c.description LIKE '%micro%' THEN SUBSTRING(c.description, CHARINDEX('micro', c.description),12)
ELSE NULL END as DurationUnit,
c.type_name field_type,c.column_type column_type
FROM sys.dm_xe_objects o
JOIN sys.dm_xe_packages p ON o.package_guid = p.guid
JOIN sys.dm_xe_object_columns c ON o.name = c.object_name
WHERE o.object_type = 'event' AND c.name ='duration'
order by 2

