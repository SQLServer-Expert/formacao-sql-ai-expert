/***************************************************************************************************
 Curso T-SQL
 Autor: Landry

 Demonstração:
 - Sintaxe do INSERT
 - INSERT ... SELECT
 - SELECT ... INTO
 - IDENTITY
 - INSERT ... OUTPUT
 - SEQUENCE

 https://learn.microsoft.com/pt-br/sql/t-sql/statements/insert-transact-sql?view=sql-server-ver16
***************************************************************************************************/
use Aula
go

/***************************************
 Cria tabelas para demonstração
****************************************/
IF object_id('dbo.Cliente ') is not null
   DROP TABLE dbo.Cliente 

CREATE TABLE Cliente (
ClienteID int not null identity primary key,
Nome varchar(50) not null,
Bairro varchar(40) null,
Sexo char(1) not null default 'M',
Credito char(1) not null default 'A')
go

IF object_id('dbo.Cliente_OnLine ') is not null
   DROP TABLE dbo.Cliente_OnLine 

CREATE TABLE Cliente_OnLine (
ClienteID int not null identity(10,5) primary key,
Nome varchar(50) not null,
Bairro varchar(40) null,
Sexo char(1) not null default 'M',
Credito char(1) not null default 'A')
go


/***************************************
 Sintaxe INSERT
****************************************/

-- INSERT padrão
INSERT Cliente (Nome,Bairro,Sexo,Credito)
VALUES ('Jose','Copacabana','M','A')
go

-- A partir do SQL Server 2008
INSERT Cliente (Nome,Bairro,Sexo,Credito)
VALUES 
('Joao','Copacabana','M','A'),
('Paula','Leme','F','B'),
('Luana','Ipanema','F','A')
go


-- Valor DEFAULT
INSERT Cliente (Nome,Bairro)
VALUES ('Pedro','Barra da Tijuca')

INSERT Cliente (Nome,Bairro,Sexo)
VALUES ('Marcio','Ipanema',DEFAULT)

SELECT * FROM Cliente

/**********************
 SELECT ... INTO
***********************/
SELECT * 
INTO #tmp_Cliente
FROM Cliente

SELECT * FROM #tmp_Cliente

DROP TABLE #tmp_Cliente

/**************************
 INSERT ... SELECT
***************************/
SELECT * FROM Cliente_OnLine

INSERT Cliente_OnLine (Nome,Bairro,Sexo,Credito)
SELECT Nome,Bairro,Sexo,Credito FROM Cliente

/****************************
 INSERT ... SELECT com JOIN
*****************************/
INSERT Cliente (Nome,Bairro,Sexo,Credito)
VALUES 
('Roberto','Leme','M','A'),
('Ana','Barra da Tijuca','F','B'),
('Bruna','Recreio','F','A')
go

SELECT count(*) FROM Cliente -- 9 linhas
SELECT count(*) FROM Cliente_OnLine -- 6 linhas

INSERT Cliente_OnLine (Nome,Bairro,Sexo,Credito)
SELECT a.Nome,a.Bairro,a.Sexo,a.Credito 
FROM Cliente a
WHERE not exists (SELECT * FROM Cliente_OnLine b WHERE b.Nome = a.Nome)


/**************************************************************************************************************************
 IDENTITY
 https://learn.microsoft.com/en-us/sql/t-sql/statements/create-table-transact-sql-identity-property?view=sql-server-ver16
***************************************************************************************************************************/
SELECT * FROM Cliente ORDER BY Nome

INSERT Cliente (ClienteID,Nome,Bairro,Sexo,Credito)
VALUES (1,'Antonio','Leme','M','A')
/*
Msg 544, Level 16, State 1, Line 73
Cannot INSERT explicit value for identity column in table 'Cliente' when IDENTITY_INSERT is set to OFF.
*/

INSERT Cliente (Nome,Bairro,Sexo,Credito)
VALUES ('Antonio','Leme','M','A')
SELECT scope_identity()

SELECT * FROM Cliente ORDER BY 1

-- Valor explícito para IDENTITY
SET IDENTITY_INSERT Cliente ON

INSERT Cliente (ClienteID,Nome,Bairro,Sexo,Credito)
VALUES (15,'Erick','Ipanema','M','B')

SET IDENTITY_INSERT Cliente OFF

-- INSERT com OUTPUT
-- Qual será o próximo valor?
INSERT Cliente (Nome,Bairro)
OUTPUT inserted.ClienteID
VALUES ('Carlos','Tijuca')

SELECT * FROM Cliente

/******************************************
 IDENTITY não garante valores únicos
*******************************************/
IF object_id('dbo.Cliente_SemPK ') is not null
   DROP TABLE dbo.Cliente_SemPK 

CREATE TABLE Cliente_SemPK (
ClienteID int not null identity,
Nome varchar(50) not null,
Bairro varchar(40) null,
Sexo char(1) not null default 'M',
Credito char(1) not null default 'A')
go

INSERT Cliente_SemPK (Nome,Bairro,Sexo,Credito)
VALUES ('Joao','Copacabana','M','A')

INSERT Cliente_SemPK (Nome,Bairro,Sexo,Credito)
VALUES ('Paula','Leme','F','B')

SELECT * FROM Cliente_SemPK

SET IDENTITY_INSERT Cliente_SemPK ON

INSERT Cliente_SemPK (ClienteID,Nome,Bairro,Sexo,Credito)
VALUES (2,'Luana','Ipanema','F','A')

SET IDENTITY_INSERT Cliente_SemPK OFF

/****************************************************************************************************************************
 DBCC CHECKIDENT
 https://learn.microsoft.com/en-us/sql/t-sql/database-console-commands/dbcc-checkident-transact-sql?view=sql-server-ver16
*****************************************************************************************************************************/
-- Valida a integridade da coluna com IDENTITY
DBCC CHECKIDENT ('Cliente')

-- Altera o próximo valor da coluna com IDENTITY
DBCC CHECKIDENT ('Cliente',RESEED,20)


INSERT Cliente (Nome,Bairro)
OUTPUT inserted.ClienteID
VALUES ('Mario','Recreio')

-- DELETE não retorna o valor da coluna com IDENTITY para o valor inicial
DELETE Cliente

INSERT Cliente (Nome,Bairro)
OUTPUT inserted.ClienteID
VALUES ('Mario','Recreio')

-- TRUNCATE retorna o valor da coluna com IDENTITY para o valor inicial
TRUNCATE TABLE Cliente

INSERT Cliente (Nome,Bairro)
OUTPUT inserted.ClienteID
VALUES ('Mario','Recreio')


/***********************************************************************************************************
 SEQUENCE
 https://learn.microsoft.com/en-us/sql/t-sql/statements/create-sequence-transact-sql?view=sql-server-ver16
************************************************************************************************************/
-- DROP SEQUENCE dbo.SEQ_Venda
CREATE SEQUENCE dbo.SEQ_Venda as int 
MINVALUE 1 NO MAXVALUE 
START WITH 1 INCREMENT BY 1
CACHE 5
go

IF object_id('dbo.Venda') is not null
   DROP TABLE dbo.Venda 

CREATE TABLE Venda (
VendaID int not null DEFAULT NEXT VALUE FOR SEQ_Venda,
ClienteID int not null,
DataVenda datetime not null,
ValorTotal decimal(10,2) null)
go

IF object_id('dbo.Venda_Online') is not null
   DROP TABLE dbo.Venda_Online 

CREATE TABLE Venda_Online (
VendaID int not null DEFAULT NEXT VALUE FOR SEQ_Venda,
ClienteID int not null,
DataVenda datetime not null,
ValorTotal decimal(10,2) null)
go

INSERT dbo.Venda        (ClienteID,DataVenda,ValorTotal) VALUES (1,'20180501',1200.30)
INSERT dbo.Venda_Online (ClienteID,DataVenda,ValorTotal) VALUES (2,'20180501', 800.00)

INSERT dbo.Venda        (ClienteID,DataVenda,ValorTotal) VALUES (3,'20180502',4400.10)
INSERT dbo.Venda_Online (ClienteID,DataVenda,ValorTotal) VALUES (8,'20180502',3200.50)

SELECT * FROM dbo.Venda
SELECT * FROM dbo.Venda_Online

SELECT * FROM sys.sequences
-- https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-sequences-transact-sql?view=sql-server-ver16

-- Apaga as tabelas
DROP TABLE dbo.Venda
DROP TABLE dbo.Venda_Online
DROP SEQUENCE dbo.SEQ_Venda
DROP TABLE dbo.Cliente
DROP TABLE dbo.Cliente_OnLine
DROP TABLE dbo.Cliente_SemPK


