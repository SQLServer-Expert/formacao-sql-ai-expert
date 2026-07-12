/*********************************************
 Autor: Landry Duailibe

 Hands On: Auditoria com OUTPUT
**********************************************/
use Aula
go

/**********************
 Tabela Funcionario
***********************/ 
DROP TABLE IF exists dbo.Funcionario
go
CREATE TABLE dbo.Funcionario (
Funcionario_ID int not null IDENTITY CONSTRAINT pk_Funcionario PRIMARY KEY,
Nome varchar(100) not null,
Cargo varchar(50) null,
Data_Admissao date null,
Data_Demissao date null,
Salario decimal (19,2) null) 
go

INSERT dbo.Funcionario (Nome,Cargo,Data_Admissao,Salario) VALUES 
('Erick','Presidente','20120314',114000.00),
('Paula','Gerente Vendas','20190506',23000.00),
('Luana','Vendedor','20221202',5000.00),
('José','Diretor Vendas','20140518',55000.00)
go

/**********************
 Tabela de Auditoria
***********************/ 
DROP TABLE IF exists dbo.Funcionario_Hist
go
CREATE TABLE dbo.Funcionario_Hist (
Funcionario_Hist_ID int not null IDENTITY CONSTRAINT pk_Funcionario_Hist PRIMARY KEY,
Operacao varchar(20) not null,
Operacao_DataHora datetime not null,
Operacao_Login sysname null,
Operacao_User sysname null,

Funcionario_ID int,
Nome varchar(100) not null,
Cargo varchar(50) null,
Data_Admissao datetime null,
Data_Demissao datetime null,
Salario decimal (19,2) null,
Salario_Anterior decimal (19,2) null) 
go

-- INSERT
INSERT dbo.Funcionario (Nome,Cargo,Data_Admissao,Salario) 
OUTPUT 'INSERT',getdate(),suser_sname(),user_name(),
inserted.Funcionario_ID,inserted.Nome,inserted.Cargo,inserted.Data_Admissao,
inserted.Data_Demissao,inserted.Salario,null
INTO Funcionario_Hist
VALUES ('Patricia','Vendedor','20240601',4000.00)

-- UPDATE
UPDATE Funcionario SET Salario = 5500.00
OUTPUT 'UPDATE',getdate(),suser_sname(),user_name(),
inserted.Funcionario_ID,inserted.Nome,inserted.Cargo,inserted.Data_Admissao,
inserted.Data_Demissao,inserted.Salario,deleted.Salario
INTO Funcionario_Hist
WHERE Funcionario_ID = 3

-- DELETE
DELETE Funcionario 
OUTPUT 'DELETE',getdate(),suser_sname(),user_name(),
deleted.Funcionario_ID,deleted.Nome,deleted.Cargo,deleted.Data_Admissao,
deleted.Data_Demissao,deleted.Salario,null
INTO Funcionario_Hist
WHERE Funcionario_ID = 2
go

SELECT * FROM Funcionario
SELECT * FROM Funcionario_Hist

-- Exclui tabelas
DROP TABLE IF exists dbo.Funcionario
DROP TABLE IF exists dbo.Funcionario_Hist
