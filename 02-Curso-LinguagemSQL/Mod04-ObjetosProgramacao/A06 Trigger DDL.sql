/*************************************************************************************************************
 Curso T-SQL
 Autor: Landry

 Trigger DDL
 https://learn.microsoft.com/en-us/sql/relational-databases/triggers/ddl-triggers?view=sql-server-ver16
**************************************************************************************************************/

/********************************
 Cria tabela de auditoria
*********************************/
USE master
go
CREATE TABLE dbo.DBA_Audit_DDL_SRV(
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

/**************************************************************************
 Cria Trigger DDL no Servidor para alimentar a tabela de auditoria
***************************************************************************/
go
CREATE TRIGGER DBA_AuditDDL ON ALL SERVER
WITH EXECUTE AS 'SRVSQL2022\Landry'
FOR DDL_SERVER_LEVEL_EVENTS 
AS
--set ANSI_WARNINGS on  
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

if @loginname <> 'BI_SSIS'
	INSERT master.dbo.DBA_Audit_DDL_SRV
	(DataHora, NomeBanco, NomeLogin, NomeDBUser, NomeIPhost, Operacao, Comando) VALUES
	(@posttime, @databasename, @loginname, @username,@hostname,@operacao,@cmd)
--SELECT @data
go

-- DISABLE TRIGGER DBA_AuditDDL ON ALL SERVER
-- ENABLE TRIGGER DBA_AuditDDL ON ALL SERVER


SELECT t.name, t.object_id, t.is_disabled
FROM sys.server_triggers t 


-- Provoca disparo da Trigger
CREATE DATABASE TesteAudit
go
ALTER DATABASE TesteAudit set recovery simple
go
DROP DATABASE TesteAudit
go

-- Verifica tabela de auditoria
SELECT * FROM dbo.DBA_Audit_DDL_SRV

-- Exclui objetos
DROP TRIGGER DBA_AuditDDL ON ALL SERVER
DROP TABLE dbo.DBA_Audit_DDL_SRV
