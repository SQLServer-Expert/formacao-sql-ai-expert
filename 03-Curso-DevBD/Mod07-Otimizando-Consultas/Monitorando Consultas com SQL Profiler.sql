/**********************************************************
 Autor: Landry

 Stored Procedure para monitorar consultas 
 utilizando o SQL Server Profiler
***********************************************************/
use master
go

/***********************************************************
 Cria Stored Procedure na master para ativar trace em banco
************************************************************/
-- DROP PROC spu_CriaTrace
CREATE or ALTER PROC dbo.spu_CriaTrace
@Banco varchar(1000), -- Nome do Banco de dados para capturar as consultas
@Caminho nvarchar(128), -- local de escrita do arquivo
@FiltroTempo bigint = 120000, -- valor em Milissegundo (ms), captura consultas acima deste tempo
@TamArq bigint = 100 -- valor em MB, tamanho do arquivo para criar outro
as
declare @IDtrace int, @PathFile nvarchar(128), @Retorno int, @FiltroBanco int;
declare @Data nvarchar(128)
set @Data = convert(nvarchar(30),getdate(),112)

set @PathFile = @Caminho + N'\Trace_' + @@SERVERNAME + ' ' + @Data;
set @FiltroBanco = db_id(@Banco)

-- Cria trace
EXEC @Retorno = sp_trace_create @traceid = @IDtrace OUTPUT, @options = 2, @tracefile = @PathFile, @maxfilesize = @TamArq, @stoptime = null;

if @Retorno <> 0 begin
   print 'Erro Criando Trace: ' + str(@Retorno)
   return
end
print 'ID Trace: ' + str(@IDtrace);

/* Retorno:
0 No error. 
1 Unknown error. 
10 Invalid options. Returned when options specified are incompatible. 
12 File not created. 
13 Out of memory. Returned when there is not enough memory to perform the specified action. 
14 Invalid stop time. Returned when the stop time specified has already happened. 
15 Invalid parameters. Returned when the user supplied incompatible parameters. 
*/

/*********************************************** 
 Cria Eventos
 https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-trace-setevent-transact-sql?view=sql-server-ver16

 - 1 Minuto = 60 Segundos = 60.000 Milissegundos = 60.000.000 Microsegundos
 - Duração em Milissegundo (ms)
 - CPU em Milissegundo (ms)
***********************************************/
declare @bit bit
set @bit = 1
-- SQL:BatchCompleted
exec sp_trace_setevent @traceid = @IDtrace, @eventid = 12, @columnid =  1, @on = @bit -- TextData
exec sp_trace_setevent @traceid = @IDtrace, @eventid = 12, @columnid = 10, @on = @bit -- ApplicationName
exec sp_trace_setevent @traceid = @IDtrace, @eventid = 12, @columnid = 11, @on = @bit -- SQLSecurityLoginName
exec sp_trace_setevent @traceid = @IDtrace, @eventid = 12, @columnid = 12, @on = @bit -- SPID
exec sp_trace_setevent @traceid = @IDtrace, @eventid = 12, @columnid = 13, @on = @bit -- Duration
exec sp_trace_setevent @traceid = @IDtrace, @eventid = 12, @columnid = 16, @on = @bit -- Reads
exec sp_trace_setevent @traceid = @IDtrace, @eventid = 12, @columnid = 17, @on = @bit -- Writes
exec sp_trace_setevent @traceid = @IDtrace, @eventid = 12, @columnid = 18, @on = @bit -- CPU
exec sp_trace_setevent @traceid = @IDtrace, @eventid = 12, @columnid =  3, @on = @bit -- DatabaseID
exec sp_trace_setevent @traceid = @IDtrace, @eventid = 12, @columnid = 35, @on = @bit -- DatabaseName
exec sp_trace_setevent @traceid = @IDtrace, @eventid = 12, @columnid = 15, @on = @bit -- End Time
-- SQL:StmtCompleted
exec sp_trace_setevent @traceid = @IDtrace, @eventid = 41, @columnid =  1, @on = @bit -- TextData
exec sp_trace_setevent @traceid = @IDtrace, @eventid = 41, @columnid = 10, @on = @bit -- ApplicationName
exec sp_trace_setevent @traceid = @IDtrace, @eventid = 41, @columnid = 11, @on = @bit -- SQLSecurityLoginName
exec sp_trace_setevent @traceid = @IDtrace, @eventid = 41, @columnid = 12, @on = @bit -- SPID
exec sp_trace_setevent @traceid = @IDtrace, @eventid = 41, @columnid = 13, @on = @bit -- Duration
exec sp_trace_setevent @traceid = @IDtrace, @eventid = 41, @columnid = 16, @on = @bit -- Reads
exec sp_trace_setevent @traceid = @IDtrace, @eventid = 41, @columnid = 17, @on = @bit -- Writes
exec sp_trace_setevent @traceid = @IDtrace, @eventid = 41, @columnid = 18, @on = @bit -- CPU
exec sp_trace_setevent @traceid = @IDtrace, @eventid = 41, @columnid =  3, @on = @bit -- DatabaseID
exec sp_trace_setevent @traceid = @IDtrace, @eventid = 41, @columnid = 35, @on = @bit -- DatabaseName
exec sp_trace_setevent @traceid = @IDtrace, @eventid = 41, @columnid = 15, @on = @bit -- End Time
-- SP:Completed
exec sp_trace_setevent @traceid = @IDtrace, @eventid = 43, @columnid =  1, @on = @bit -- TextData
exec sp_trace_setevent @traceid = @IDtrace, @eventid = 43, @columnid = 10, @on = @bit -- ApplicationName
exec sp_trace_setevent @traceid = @IDtrace, @eventid = 43, @columnid = 11, @on = @bit -- SQLSecurityLoginName
exec sp_trace_setevent @traceid = @IDtrace, @eventid = 43, @columnid = 12, @on = @bit -- SPID
exec sp_trace_setevent @traceid = @IDtrace, @eventid = 43, @columnid = 13, @on = @bit -- Duration
exec sp_trace_setevent @traceid = @IDtrace, @eventid = 43, @columnid = 16, @on = @bit -- Reads
exec sp_trace_setevent @traceid = @IDtrace, @eventid = 43, @columnid = 17, @on = @bit -- Writes
exec sp_trace_setevent @traceid = @IDtrace, @eventid = 43, @columnid = 18, @on = @bit -- CPU
exec sp_trace_setevent @traceid = @IDtrace, @eventid = 43, @columnid =  3, @on = @bit -- DatabaseID
exec sp_trace_setevent @traceid = @IDtrace, @eventid = 43, @columnid = 35, @on = @bit -- DatabaseName
exec sp_trace_setevent @traceid = @IDtrace, @eventid = 43, @columnid = 15, @on = @bit -- End Time

-- ****************** Cria FILTRO
-- Filtro do banco
exec sp_trace_setfilter @traceid = @IDtrace, @columnid = 3,@logical_operator = 0,@comparison_operator = 0,@value = @FiltroBanco

-- Filtro no tempo de duração
exec sp_trace_setfilter @traceid = @IDtrace, @columnid = 13,@logical_operator = 0,@comparison_operator = 4,@value = @FiltroTempo

-- Filtro em Object_id > 100
exec sp_trace_setfilter @traceid = @IDtrace, @columnid = 22,@logical_operator = 0,@comparison_operator = 2,@value = 100

/*
@logical_operator -> AND (0) or OR (1)

@comparison_operator :
0 = (Equal) 
1 <> (Not Equal) 
2 > (Greater Than) 
3 < (Less Than) 
4 >= (Greater Than Or Equal) 
5 <= (Less Than Or Equal) 
6 LIKE  
7 NOT LIKE  
*/

exec sp_trace_setstatus @traceid = @IDtrace, @status = 1 
-- exec sp_trace_setstatus @traceid = 1, @status = 2 

/* @status
0 Stops the specified trace. 
1 Starts the specified trace. 
2 Closes the specified trace and deletes its definition from the server. 
*/

/* Retorno:
0 No error. 
1 Unknown error. 
8 The specified Status is not valid. 
9 The specified Trace Handle is not valid. 
13 Out of memory. Returned when there is not enough memory to perform the specified action. 
*/
go
/****************************************** FIM SP *******************************************/


-- Ativa trace executando a SP (retorna o ID do trace)
exec spu_CriaTrace 'AdventureWorks',N'C:\_HandsOn\Profiler'

-- Informações do Trace
SELECT * FROM sys.traces

SELECT ei.eventid EventID,e.name EventName,c.trace_column_id ColumnID,c.name ColumnName
FROM fn_trace_geteventinfo(1) ei JOIN sys.trace_events e ON ei.eventid = e.trace_event_id
JOIN sys.trace_columns c ON ei.columnid = c.trace_column_id

/* @status
0 Stops the specified trace. 
1 Starts the specified trace. 
2 Closes the specified trace and deletes its definition from the server. 
*/
go
DECLARE @ID int
SELECT @ID = id FROM sys.traces where path like 'C:\_HandsOn\Profiler%'
exec sp_trace_setstatus @traceid = @ID, @status = 0 -- Stop
exec sp_trace_setstatus @traceid = @ID, @status = 2 -- Close
go

-- Importar Resultado para tabela
DROP TABLE IF exists aula.dbo.tmp_Trace
go
SELECT * 
INTO aula.dbo.tmp_Trace 
FROM fn_trace_gettable('C:\_HandsOn\Profiler\Trace_SRVSQL2022 20240304.trc', default)

SELECT * FROM aula.dbo.tmp_Trace ORDER BY duration DESC

-- As 10 consultas com maior tempo de execução
SELECT top 10 
TextData, EndTime, Duration, Reads, Writes, CPU, 
DatabaseName, ApplicationName, HostName
FROM aula.dbo.tmp_Trace 
ORDER BY duration DESC

-- Comando T-SQL em XML
SELECT ApplicationName, LoginName,Duration/1000000 as Duracao_Seg,TextData,
CAST('<A><![CDATA[' + CAST(TextData as nvarchar(max)) + ']]></A>' AS xml) as Comando
FROM aula.dbo.tmp_Trace
ORDER BY cast(TextData as varchar(max)), Duration DESC

