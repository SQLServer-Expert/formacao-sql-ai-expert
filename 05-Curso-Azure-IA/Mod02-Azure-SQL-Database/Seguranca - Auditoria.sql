/**************************************
 Autor: Landry Duailibe

 Hands On: Auditoria
***************************************/

/***********************************
 Provocando eventos de Auditoria
************************************/
-- Executar na MASTER: cria Login do tipo SQL
CREATE LOGIN Teste WITH PASSWORD = 'Pa$$w0rd'
-- DROP LOGIN Teste

-- Executar no Banco de Dados que deseja fornecer acesso
CREATE USER Teste FROM LOGIN Teste 
-- DROP USER Teste


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

INSERT dbo.Cliente (Cliente_PK, Nome, Telefone) VALUES (4,'Paula','2334-9987')

UPDATE dbo.Cliente SET Nome = 'Paula Pereira' WHERE Cliente_PK = 4

DELETE dbo.Cliente WHERE Cliente_PK = 4

SELECT * FROM dbo.Cliente ORDER BY 1

TRUNCATE TABLE dbo.Cliente

DROP TABLE IF EXISTS dbo.Cliente


DROP USER Teste

-- Retornar para Master
DROP LOGIN Teste

/********************************
 Consultando Log de Auditoria
*********************************/
SELECT TOP 100 event_time, server_instance_name, database_name, server_principal_name, client_ip, statement, succeeded, action_id, class_type, additional_information
FROM sys.fn_get_audit_file('https://staulasql.blob.core.windows.net/sqldbauditlogs/srv-aula-sql/AulaDB/SqlDbAuditing_ServerAudit/2024-10-13', default, default)
WHERE (event_time >= '2024-10-13')
/* additional WHERE clause conditions/filters can be added here */
ORDER BY event_time DESC


-- Criando novo Banco
CREATE DATABASE DB02

CREATE DATABASE DB03 (MAXSIZE = 10 GB, EDITION = 'Standard', SERVICE_OBJECTIVE = 'S2')
WITH BACKUP_STORAGE_REDUNDANCY = 'LOCAL'

-- DB02
DROP TABLE IF EXISTS dbo.Cliente
go
CREATE TABLE dbo.Cliente (
Cliente_PK int not null primary key,
Nome varchar(40) not null,
Telefone varchar(20) null)
go

INSERT dbo.Cliente (Cliente_PK, Nome, Telefone) VALUES (1,'Jose','2343-2289')
go
DROP TABLE IF EXISTS dbo.Cliente

SELECT TOP 100 event_time, server_instance_name, database_name, server_principal_name, client_ip, statement, succeeded, action_id, class_type, additional_information
FROM sys.fn_get_audit_file('https://staulasql.blob.core.windows.net/sqldbauditlogs/srv-aula-sql/DB02/SqlDbAuditing_ServerAudit/2024-10-13', default, default)
WHERE (event_time >= '2024-10-13')
/* additional WHERE clause conditions/filters can be added here */
ORDER BY event_time DESC

-- DB03
DROP TABLE IF EXISTS dbo.Cliente
go
CREATE TABLE dbo.Cliente (
Cliente_PK int not null primary key,
Nome varchar(40) not null,
Telefone varchar(20) null)
go

INSERT dbo.Cliente (Cliente_PK, Nome, Telefone) VALUES (2,'Ana','3432-2184')
go
DROP TABLE IF EXISTS dbo.Cliente

SELECT TOP 100 event_time, server_instance_name, database_name, server_principal_name, client_ip, statement, succeeded, action_id, class_type, additional_information
FROM sys.fn_get_audit_file('https://staulasql.blob.core.windows.net/sqldbauditlogs/srv-aula-sql/DB03/SqlDbAuditing_ServerAudit/2024-10-13', default, default)
WHERE (event_time >= '2024-10-13')
/* additional WHERE clause conditions/filters can be added here */
ORDER BY event_time DESC

