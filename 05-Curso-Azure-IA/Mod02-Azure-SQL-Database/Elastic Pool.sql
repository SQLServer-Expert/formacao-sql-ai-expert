/**************************************
 Autor: Landry Duailibe

 Hands On: Elastic Pool
***************************************/

-- Converter bancos para um Elastic Pool
ALTER DATABASE DBElastic02 MODIFY (SERVICE_OBJECTIVE = ELASTIC_POOL(NAME = [els-aula-sql]))


/********************************************************
 sys.database_service_objectives

 - Lista Bancos por Elastic Pool
   https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-database-service-objectives-azure-sql-database?view=azuresqldb-current
*********************************************************/
SELECT * FROM sys.database_service_objectives

SELECT @@SERVERNAME as Servidor, b.elastic_pool_name as ElasticPool, a.[name] as Banco, b.edition as Edicao
FROM sys.databases a 
join sys.database_service_objectives b on a.database_id = b.database_id
WHERE a.[name] <> 'master'
ORDER BY b.elastic_pool_name, a.[name]

-- Verifica o progresso
SELECT operation as Operacao, major_resource_id as Banco,
state_desc [Status], percent_complete as [% Completo],
start_time as DataHora_Inicio, 
last_modify_time as DataHora_Alteracao,
start_time AT TIME ZONE 'UTC' AT TIME ZONE 'Bahia Standard Time' as DataHora_Inicio_Local, 
last_modify_time AT TIME ZONE 'UTC' AT TIME ZONE 'Bahia Standard Time' as DataHora_Alteracao_Local
FROM sys.dm_operation_status 
ORDER BY last_modify_time desc


/**************************************************
 sys.elastic_pool_resource_stats

 - Retorna o consumo de recursos
   https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-elastic-pool-resource-stats-azure-sql-database?view=azuresqldb-current
***************************************************/
SELECT * FROM sys.elastic_pool_resource_stats ORDER BY end_time DESC

SELECT start_time, end_time,
(SELECT Max(v) FROM (VALUES (avg_cpu_percent), (avg_data_io_percent), (avg_log_write_percent)) AS value(v)) AS [avg_DTU_percent]
FROM sys.elastic_pool_resource_stats
WHERE elastic_pool_name = 'els-aula-sql-test'
ORDER BY end_time DESC

-- Média por hora
SELECT day(end_time) Dia, datepart(hh,end_time) as Hora,
avg(avg_cpu_percent) as AVG_CPU, 
avg(avg_data_io_percent) as AVG_IO_Dados,
avg(avg_log_write_percent) as AVG_Log
FROM sys.elastic_pool_resource_stats
WHERE elastic_pool_name = 'els-aula-sql-test'
GROUP BY day(end_time), datepart(hh,end_time)
ORDER BY Dia, Hora


/*********************************
 Gera Atividade
**********************************/
DROP TABLE IF exists dbo.Venda
go
CREATE TABLE dbo.Venda (
Venda_ID int not null identity CONSTRAINT pk_Venda PRIMARY KEY,
Data_Venda datetime not null,
Cliente_ID int null,
Produto_ID int null,
Valor_Total decimal(19,2) null,
Obs char(4000) null)
go

DECLARE @i int = 1
WHILE @i < 50000 BEGIN
	INSERT Venda (Data_Venda,Cliente_ID,Produto_ID,Valor_Total,Obs)
    VALUES (getdate(), @i , @i + 100, @i / 0.5, 'Teste Log: ' + ltrim(str(@i)))
	SELECT SUM(CONVERT(BIGINT, o1.object_id) + CONVERT(BIGINT, o2.object_id) + CONVERT(BIGINT, o3.object_id) + CONVERT(BIGINT, o4.object_id))
	FROM sys.objects o1 CROSS JOIN sys.objects o2 CROSS JOIN sys.objects o3	CROSS JOIN sys.objects o4
	SET @i += 1
END
go
