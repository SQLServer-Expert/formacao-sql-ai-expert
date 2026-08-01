/*************************************************************************************************************
 Curso T-SQL
 Autor: Landry

 Trigger DML
 https://learn.microsoft.com/en-us/sql/relational-databases/triggers/dml-triggers?view=sql-server-ver16
**************************************************************************************************************/
USE Aula
go

/**************************
 Cria tabelas
***************************/
IF object_id('dbo.Customer') is not null
   DROP TABLE dbo.Customer

SELECT c.CustomerID as CustomerID,FirstName,MiddleName,Lastname,CompanyName,
dateadd(d,-CustomerID,getdate()) DataCadastro 
INTO dbo.Customer
FROM AdventureWorksLT.SalesLT.Customer c 

/*******************************
 Cria tabela para Auditoria
********************************/
-- DROP TABLE dbo.AuditCustomer
-- TRUNCATE TABLE dbo.AuditCustomer
CREATE TABLE dbo.AuditCustomer (
AuditCustomer_ID int NOT NULL IDENTITY(1,1) PRIMARY KEY,
TipoAtualizacao varchar(20) NOT NULL,
UserLogin varchar(100) NULL,
Host varchar(100) NULL,
CustomerID int NOT NULL,
FirstName nvarchar(50) NOT NULL,
MiddleName nvarchar(50) NULL,
Lastname nvarchar(50) NULL,
CompanyName nvarchar(128) NULL,
DataCadastro datetime NULL)
go
-- SELECT * FROM dbo.AuditCustomers

/*******************************
 Trigger INSERT/UPDATE
********************************/
-- DROP TRIGGER trg_Customer_Audit
go
CREATE or ALTER TRIGGER trg_Customer_Audit
ON dbo.Customer AFTER INSERT, UPDATE
as
set nocount on

DECLARE @TipoAtualizacao varchar(20)

IF exists (SELECT * FROM deleted)
	SET @TipoAtualizacao = 'UPDATE'
ELSE
	SET @TipoAtualizacao = 'INSERT'

INSERT dbo.AuditCustomer
(TipoAtualizacao, UserLogin, Host, 
CustomerID, FirstName, MiddleName, Lastname, CompanyName, DataCadastro)

SELECT @TipoAtualizacao,system_user as UserLogin, host_name() as Host,
CustomerID, FirstName, MiddleName, Lastname, CompanyName, DataCadastro
FROM Inserted
go

-- Teste

SELECT * FROM dbo.Customer ORDER BY CustomerID desc

-- Provoca disparo da Trigger operação INSERT
INSERT dbo.Customer (FirstName, MiddleName, Lastname, CompanyName, DataCadastro)
VALUES ('Jose','M.','da Silva','XPTO SA',getdate())

-- Provoca disparo da Trigger operação UPDATE
UPDATE  dbo.Customer SET CompanyName = 'XPTO Ltda.'
WHERE CustomerID = 30119

-- Verifica tabela de Auditoria
SELECT * FROM dbo.AuditCustomer


/*************************
 Metadata Triggers
**************************/
SELECT * FROM sys.triggers

SELECT * FROM sys.trigger_events

-- Obter CREATE TRIGGER
SELECT definition   
FROM sys.sql_modules  
WHERE object_id = OBJECT_ID('dbo.trg_Customer_Audit') 

EXEC sp_helptext 'dbo.trg_Customer_Audit'

/************************************
DROP TABLE dbo.AuditCustomer
DROP TABLE dbo.Customer
*************************************/