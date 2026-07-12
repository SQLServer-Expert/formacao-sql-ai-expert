/*******************************************************************
 Autor: Landry Duailibe
 
 Hands On: Trigger Logon para restringir acesso
********************************************************************/
USE master
go

/****************************************
 Trigger Logon negar acesso via Excel
*****************************************/
go
CREATE TRIGGER Trigger_Logon_SSMS
ON ALL SERVER FOR LOGON
AS

IF APP_NAME() LIKE 'Microsoft SQL Server Management Studio%' and ORIGINAL_LOGIN() = 'SSRS'
BEGIN
	PRINT 'O Login ' + ORIGINAL_LOGIN() + ' não pode acessar o servidor pela aplicação ' + APP_NAME() + '!'
	ROLLBACK
END
go
/*********************** Fim Trigger ************************/

EXEC sp_readerrorlog

-- Exclui Trigger
use master
go
DROP TRIGGER Trigger_Logon_SSMS ON ALL SERVER
go
