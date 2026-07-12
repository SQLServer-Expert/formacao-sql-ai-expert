/*******************************************************************
 Autor: Landry Duailibe
 
 Hands On: DDL Trigger para Auditoria Banco de Dados
********************************************************************/
USE master
go
CREATE DATABASE HandsOn
go
USE HandsOn
go

CREATE TABLE dbo.AuditLog (
Command NVARCHAR(1000),
PostTime NVARCHAR(24),
HostName NVARCHAR(100),
LoginName NVARCHAR(100))
go

/*********************************
 DDL Trigger Auditoria
**********************************/
CREATE TRIGGER AuditOperations ON DATABASE
FOR DDL_DATABASE_LEVEL_EVENTS
AS
DECLARE @data XML
DECLARE @cmd NVARCHAR(1000)
DECLARE @posttime NVARCHAR(24)
DECLARE @spid NVARCHAR(6)
DECLARE @hostname NVARCHAR(100)
DECLARE @loginname NVARCHAR(100)
SET @data = eventdata()

SET @cmd = REPLACE(CONVERT(NVARCHAR(1000),@data.query('data(//TSQLCommand//CommandText)')),'&#x0D;','')
SET @posttime = CONVERT(NVARCHAR(24),@data.query('data(//PostTime)'))
SET @spid = CONVERT(NVARCHAR(6),@data.query('data(//SPID)'))
SET @hostname = HOST_NAME()
SET @loginname = SYSTEM_USER

INSERT dbo.AuditLog(Command,PostTime,HostName,LoginName)
VALUES(@cmd, @posttime, @hostname, @loginname)

--SELECT @data
go
/******************** FIM TRIGGER ************************/

-- Teste
CREATE TABLE dbo.Test(col INT)
GO
DROP TABLE dbo.Test
GO
SELECT * FROM dbo.AuditLog

-- Apagar tabela e DDL Trigger
DROP TRIGGER AuditOperations ON DATABASE
DROP TABLE dbo.AuditLog
