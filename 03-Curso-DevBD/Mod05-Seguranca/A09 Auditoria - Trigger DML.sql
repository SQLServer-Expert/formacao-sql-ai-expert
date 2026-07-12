/*********************************************
 Autor: Landry Duailibe

 Hands On: Auditoria com Trigger DML
**********************************************/
use Aula
go

/****************************
 Tabela Cliente
*****************************/
CREATE TABLE dbo.Cliente (
Cliente_ID int not null IDENTITY CONSTRAINT pk_Cliente PRIMARY KEY,
Nome varchar(100) not null,  
Telefone varchar(40) null,
Email varchar(200) null)
go

/**********************
 Tabela de Auditoria
***********************/ 
DROP TABLE IF exists dbo.Cliente_Hist
go
CREATE TABLE dbo.Cliente_Hist (
Cliente_Hist_ID int not null IDENTITY CONSTRAINT pk_Cliente_Hist PRIMARY KEY,
Operacao varchar(20) not null,
Operacao_DataHora datetime not null,
Operacao_Login sysname null,
Operacao_User sysname null,
Operação_App sysname null,
Operação_Host sysname null,

Cliente_ID int not null,
Nome varchar(100) not null,  
Telefone varchar(40) null,
Email varchar(200) null,
Email_Anterior varchar(200) null) 
go


/*********************************************
 Uma Trigger para cada operação
**********************************************/
-- Auditoria DML INSERT
CREATE or ALTER Trigger trg_audit_Cliente_INSERT ON dbo.Cliente 
FOR INSERT
AS
set nocount on

INSERT dbo.Cliente_Hist
(Operacao, Operacao_DataHora, Operacao_Login, Operacao_User, Operação_App, Operação_Host, Cliente_ID, Nome, Telefone, Email)
SELECT 'INSERT', getdate(), suser_sname(), user_name(), app_name(),host_name(), Cliente_ID, Nome, Telefone, Email
FROM Inserted
go

-- Auditoria DML UPDATE
CREATE or ALTER Trigger trg_audit_Cliente_UPDATE ON dbo.Cliente 
FOR UPDATE
AS
set nocount on

INSERT dbo.Cliente_Hist
(Operacao, Operacao_DataHora, Operacao_Login, Operacao_User, Operação_App, Operação_Host, Cliente_ID, Nome, Telefone, Email, Email_Anterior)
SELECT 'UPDATE', getdate(), suser_sname(), user_name(), app_name(),host_name(), i.Cliente_ID, i.Nome, i.Telefone, i.Email, d.Email
FROM Inserted i
JOIN Deleted d on i.Cliente_ID = d.Cliente_ID
go

-- Auditoria DML DELETE
CREATE or ALTER Trigger trg_audit_Cliente_DELETE ON dbo.Cliente 
FOR DELETE
AS
set nocount on

INSERT dbo.Cliente_Hist
(Operacao, Operacao_DataHora, Operacao_Login, Operacao_User, Operação_App, Operação_Host, Cliente_ID, Nome, Telefone, Email)
SELECT 'DELETE', getdate(), suser_sname(), user_name(), app_name(),host_name(), Cliente_ID, Nome, Telefone, Email
FROM Deleted
go

/***************************
 Testando Triggers
***************************/

INSERT dbo.Cliente (Nome, Telefone, Email)
VALUES ('José', '91111-1111','jose@google.com')

INSERT dbo.Cliente (Nome, Telefone, Email) VALUES
('Ana', '92222-2222','ana@google.com'),
('Landry', '93333-3333','landry@google.com'),
('Marina', '94444-4444','marina@google.com')

UPDATE dbo.Cliente SET Email = 'marinasoares@google.com'
WHERE Nome = 'Marina'

UPDATE dbo.Cliente SET Email = 'xxx@google.com'

DELETE dbo.Cliente WHERE Nome = 'Marina'

DELETE dbo.Cliente 

-- Consulta Tabela de Auditoria
SELECT * FROM dbo.Cliente_Hist

-- Exclui as 3 Triggers
DROP Trigger trg_audit_Cliente_INSERT
DROP Trigger trg_audit_Cliente_UPDATE
DROP Trigger trg_audit_Cliente_DELETE
go




/*************************************************
 Uma Trigger para as 3 operações
**************************************************/
-- Tabela de Auditoria
DROP TABLE IF exists dbo.Cliente_Hist
go
CREATE TABLE dbo.Cliente_Hist (
Cliente_Hist_ID int not null IDENTITY CONSTRAINT pk_Cliente_Hist PRIMARY KEY,
Operacao varchar(20) not null,
Operacao_DataHora datetime not null,
Operacao_Login sysname null,
Operacao_User sysname null,
Operação_App sysname null,
Operação_Host sysname null,

Registro_Atual xml null,
Registro_Anterior xml null) 
go

-- Trigger INSERT, UPDATE e DELETE
go
CREATE or ALTER Trigger trg_audit_Cliente ON dbo.Cliente 
FOR INSERT,UPDATE,DELETE
AS
set nocount on

DECLARE @Operacao varchar(20)
IF EXISTS (SELECT * FROM inserted)
	IF EXISTS (SELECT * FROM deleted)
		SELECT @Operacao = 'UPDATE'
	ELSE
		SELECT @Operacao = 'INSERT'
ELSE
	SELECT @Operacao = 'DELETE'

declare @Registro_Atual xml, @Registro_Anterior xml 
SET @Registro_Atual = (SELECT * FROM inserted FOR XML PATH)
SET @Registro_Anterior = (SELECT * FROM deleted FOR XML PATH)

INSERT dbo.Cliente_Hist
(Operacao, Operacao_DataHora, Operacao_Login, Operacao_User, Operação_App, Operação_Host, Registro_Atual, Registro_Anterior)
SELECT @Operacao, getdate(), suser_sname(), user_name(), app_name(),host_name(), @Registro_Atual, @Registro_Anterior
go
/******************** FIM Trigger ***************************/


/***************************
 Testando Trigger
***************************/
TRUNCATE TABLE dbo.Cliente

INSERT dbo.Cliente (Nome, Telefone, Email)
VALUES ('José', '91111-1111','jose@google.com')

INSERT dbo.Cliente (Nome, Telefone, Email) VALUES
('Ana', '92222-2222','ana@google.com'),
('Landry', '93333-3333','landry@google.com'),
('Marina', '94444-4444','marina@google.com')

UPDATE dbo.Cliente SET Email = 'marinasoares@google.com'
WHERE Nome = 'Marina'

UPDATE dbo.Cliente SET Email = 'xxx@google.com'

DELETE dbo.Cliente WHERE Nome = 'Marina'

DELETE dbo.Cliente 

-- Consulta Tabela de Auditoria
SELECT * FROM dbo.Cliente
SELECT * FROM dbo.Cliente_Hist

-- Exclui Objetos
DROP TABLE IF exists dbo.Cliente
DROP TABLE IF exists dbo.Cliente_Hist

