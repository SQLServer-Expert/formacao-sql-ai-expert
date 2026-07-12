/******************************************
 Autor: Landry Duailibe

 Hands On: Default Trace
*******************************************/
use master
go

-- Acessar dados do Default Trace
SELECT * FROM fn_trace_gettable  
('C:\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Log\log.trc', default)

-- Desabilitar Default Trace
EXEC SP_CONFIGURE 'default trace enabled',0
RECONFIGURE
go

