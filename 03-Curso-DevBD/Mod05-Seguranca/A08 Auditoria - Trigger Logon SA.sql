/*******************************************************************
 Autor: Landry Duailibe
 
 Hands On: Trigger Logon para Auditoria Login com SA
********************************************************************/
USE master
go

DROP TABLE IF exists msdb.dbo.DBA_AutitLogin
go
CREATE TABLE msdb.dbo.DBA_AutitLogin (
Data datetime null,
SPIDid int null,
LoginName sysname null,
HostName sysname null,
ProgramName sysname null,
AuthScheme sysname null,
NetTransport sysname null,
ClienteAddress sysname null,
LocalAddress sysname null)
go

--select SUSER_NAME(),app_name()
go

/*******************************
 Cria trigger de Login
********************************/
CREATE or ALTER TRIGGER trg_AuditLogin on all server FOR logon
as

IF (ORIGINAL_LOGIN() = 'sa') and @@spid > 50 BEGIN

      INSERT msdb.dbo.DBA_AutitLogin
	  ([Data], SPIDid, LoginName, HostName, ProgramName, AuthScheme, NetTransport, ClienteAddress, LocalAddress)

      SELECT getdate(),@@spid,s.login_name,s.[host_name],
      s.program_name,c.auth_scheme,c.net_transport,
      c.client_net_address,c.local_net_address
      FROM sys.dm_exec_sessions s 
	  join sys.dm_exec_connections c on s.session_id = c.session_id
      WHERE s.session_id = @@spid
       
END 
go
/********************** FIM Trigger de Login ************************/

SELECT * FROM msdb.dbo.DBA_AutitLogin

/*****************************
 Exclui Trigger e tabela
******************************/
DROP TRIGGER trg_AuditLogin on all server
DROP TABLE IF exists msdb.dbo.DBA_AutitLogin

