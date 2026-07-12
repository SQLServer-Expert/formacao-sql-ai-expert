/********************************************************************************
 Autor: Landry Duailibe

 Hands On: Triger DDL para auditoria Servidor
*********************************************************************************/

/********************************
 Cria tabela de auditoria
*********************************/
USE DBA
go
DROP TABLE IF exists DBA.dbo.DBA_Audit_DDL_SRV
go
CREATE TABLE DBA.dbo.DBA_Audit_DDL_SRV (
DDL_AuditID int IDENTITY(1,1) NOT NULL Primary Key,
DataHora datetime NOT NULL,
NomeBanco varchar(1000) null,
NomeLogin varchar(256) null,
NomeDBUser varchar(256) null,
NomeIPhost varchar(256) null,
Operacao varchar(500) null,
Comando varchar(max) null,
Notificacao char(1) NULL DEFAULT ('N'))
go

SELECT name, object_id, is_disabled
FROM master.sys.server_triggers 

/**************************************************************************
 Cria Trigger DDL no Servidor para alimentar a tabela de auditoria
***************************************************************************/
USE master
go

CREATE or ALTER TRIGGER DBA_AuditDDL ON ALL SERVER
WITH EXECUTE AS 'SRVSQL2022\landry'
FOR DDL_SERVER_LEVEL_EVENTS 
AS

set nocount on  

DECLARE @data XML
DECLARE @cmd VARCHAR(max)
DECLARE @posttime VARCHAR(24)
DECLARE @databasename VARCHAR(1000)
DECLARE @hostname VARCHAR(256)
DECLARE @loginname VARCHAR(256)
DECLARE @username VARCHAR(256)
DECLARE @operacao varchar(500)
SET @data = eventdata()

SET @operacao = CONVERT(VARCHAR(500),@data.query('data(//EventType)'))
SET @cmd = replace(CONVERT(VARCHAR(max),@data.query('data(//TSQLCommand//CommandText)')),'&#x0D;','')
SET @posttime = CONVERT(VARCHAR(24),@data.query('data(//PostTime)'))
SET @databasename = CONVERT(VARCHAR(1000),@data.query('data(//DatabaseName)'))
SET @hostname = left(HOST_NAME(),256)
SET @loginname = CONVERT(VARCHAR(256),@data.query('data(//LoginName)'))
SET @username = left(USER_NAME(),256)

if @loginname <> 'SRVSQL2022\SQLService'
	INSERT dba.dbo.DBA_Audit_DDL_SRV
	(DataHora, NomeBanco, NomeLogin, NomeDBUser, NomeIPhost, Operacao, Comando) VALUES
	(@posttime, @databasename, @loginname, @username,@hostname,@operacao,@cmd)

--SELECT @data
go

-- DISABLE TRIGGER DBA_AuditDDL ON ALL SERVER
-- ENABLE TRIGGER DBA_AuditDDL ON ALL SERVER


/******************** Hands On *******************************/
use master
go

-- Cria Login para Hands On
CREATE LOGIN [TesteAudit] WITH PASSWORD=N'123', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
EXEC master..sp_addsrvrolemember @loginame = N'TesteAudit', @rolename = N'dbcreator'
GO

EXECUTE AS LOGIN = 'TesteAudit'

-- Cria, altera e exclui banco
CREATE DATABASE TesteAudit
go
ALTER DATABASE TesteAudit set recovery simple
go
DROP DATABASE IF exists TesteAudit 
go

REVERT

-- Apaga Login
DROP LOGIN [TesteAudit]

SELECT * FROM DBA.dbo.DBA_Audit_DDL_SRV
TRUNCATE TABLE DBA.dbo.DBA_Audit_DDL_SRV


/*************************
 Exclui Trigger e Tabela
**************************/
use master
go
DROP TRIGGER DBA_AuditDDL ON ALL SERVER
go
DROP TABLE IF exists DBA.dbo.DBA_Audit_DDL_SRV
go

