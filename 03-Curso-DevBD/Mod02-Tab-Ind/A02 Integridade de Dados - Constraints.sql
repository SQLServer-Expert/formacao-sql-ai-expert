/********************************************************************
 Autor: Landry Duailibe

 Hands On: Constraint
*********************************************************************/
USE Aula
go

/*******************************
 DEFAULT
********************************/
DROP TABLE IF exists dbo.Cliente
go
CREATE TABLE dbo.Cliente (
Cliente_ID int not null,
Nome varchar(50) not null,
CPF varchar(11) not null,
Idade smallint null,

Data_Inclusao datetime not null 
constraint df_Cliente_Data_Inclusao default getdate(),

Ativo bit not null
constraint df_Cliente_Ativo default 1)
go

exec sp_helpconstraint 'dbo.Cliente'
go
SELECT * FROM sys.default_constraints

INSERT dbo.Cliente (Cliente_ID,Nome,CPF,Idade,Data_Inclusao,Ativo)
VALUES (1,'Jose','11111',35,default,default)
-- OU
INSERT dbo.Cliente (Cliente_ID,Nome,CPF,Idade)
VALUES (2,'Ana','22222',45)

SELECT * FROM dbo.Cliente

-- DEFAULT
ALTER TABLE dbo.Cliente add constraint df_Cliente_Data_Inclusao 
default getdate() for Data_Inclusao

/*******************************
 CHECK
********************************/
DROP TABLE IF exists dbo.Cliente
go
CREATE TABLE dbo.Cliente (
Cliente_ID int not null,
Nome varchar(50) not null,
CPF varchar(11) not null,
Idade smallint null constraint ck_Cliente_Idade check (Idade > 0),

Data_Inclusao datetime not null 
constraint df_Cliente_Data_Inclusao default getdate(),

Ativo bit not null
constraint df_Cliente_Ativo default 1)
go

INSERT dbo.Cliente (Cliente_ID,Nome,CPF,Idade)
VALUES (1,'Jose','11111',35)

INSERT dbo.Cliente (Cliente_ID,Nome,CPF,Idade)
VALUES (2,'Ana','22222',0)
/*
Msg 547, Level 16, State 0, Line 59
The INSERT statement conflicted with the CHECK constraint "ck_Cliente_Idade". The conflict occurred in database "Aula", table "dbo.Cliente", column 'Idade'.
*/

INSERT dbo.Cliente (Cliente_ID,Nome,CPF,Idade)
VALUES (2,'Ana','22222',null)

SELECT * FROM dbo.Cliente

-- CHECK
ALTER TABLE dbo.Cliente add constraint ck_Cliente_Idade 
check (Idade > 0) 

/*******************************
 PRIMARY KEY e UNIQUE
********************************/
DROP TABLE If exists dbo.Cliente
go
CREATE TABLE dbo.Cliente (

Cliente_ID int not null constraint pk_Cliente primary key,

Nome varchar(50) not null,
CPF varchar(11) null constraint unq_Cliente_Cliente_ID unique)
go

INSERT dbo.Cliente (Cliente_ID,Nome,CPF)
VALUES (1,'Jose','11111')

INSERT dbo.Cliente (Cliente_ID,Nome,CPF)
VALUES (2,'Ana','22222')
go

SELECT * FROM dbo.Cliente

-- PK
INSERT dbo.Cliente (Cliente_ID,Nome,CPF)
VALUES (2,'Carlos','11222')
/*
Msg 2627, Level 14, State 1, Line 93
Violation of PRIMARY KEY constraint 'pk_Cliente_Cliente_ID'. Cannot insert duplicate key in object 'dbo.Cliente'. The duplicate key value is (2).
*/

-- UNIQUE
INSERT dbo.Cliente (Cliente_ID,Nome,CPF)
VALUES (3,'Carlos','22222')
/*
Msg 2627, Level 14, State 1, Line 101
Violation of UNIQUE KEY constraint 'unq_Cliente_Cliente_ID'. Cannot insert duplicate key in object 'dbo.Cliente'. The duplicate key value is (22222).
*/

-- UNIQUE pode aceitar NULL, mas somente uma linha
INSERT dbo.Cliente (Cliente_ID,Nome,CPF)
VALUES (3,'Carlos',null)

-- Segunda linha com NULL gera erro
INSERT dbo.Cliente (Cliente_ID,Nome,CPF)
VALUES (4,'Paula',null)
/*
Msg 2627, Level 14, State 1, Line 111
Violation of UNIQUE KEY constraint 'unq_Cliente_Cliente_ID'. Cannot insert duplicate key in object 'dbo.Cliente'. The duplicate key value is (<NULL>).
*/

-- PRIMARY KEY
ALTER TABLE dbo.Cliente drop constraint pk_Cliente 

ALTER TABLE dbo.Cliente ADD constraint pk_Cliente PRIMARY KEY (Cliente_ID)

-- UNIQUE
ALTER TABLE dbo.Cliente DROP CONSTRAINT unq_Cliente_Cliente_ID 

ALTER TABLE dbo.Cliente ADD CONSTRAINT unq_Cliente_Cliente_ID UNIQUE (CPF)


/*******************************
 FOREIGN KEY
********************************/
DROP TABLE IF exists dbo.Venda
go
CREATE TABLE dbo.Venda (
Venda_ID int not null CONSTRAINT pk_Venda PRIMARY KEY,
Data_Venda datetime not null,

Cliente_ID int not null CONSTRAINT fk_Venda_Cliente_Cliente_ID FOREIGN KEY
REFERENCES dbo.Cliente (Cliente_ID),

Total_Venda decimal(9,2) not null)
go

SELECT * FROM dbo.Cliente

INSERT dbo.Venda (Venda_ID,Data_Venda,Cliente_ID,Total_Venda)
VALUES (1001,'20100116',1,15000.10)

-- Erro FK Cliente_ID não existe
INSERT dbo.Venda (Venda_ID,Data_Venda,Cliente_ID,Total_Venda)
VALUES (1002,'20100126',9,2000.50)
/*
Msg 547, Level 16, State 0, Line 153
The INSERT statement conflicted with the FOREIGN KEY constraint "fk_Venda_Cliente_Cliente_ID". The conflict occurred in database "Aula", table "dbo.Cliente", column 'Cliente_ID'.
*/

-- DROP FK
ALTER TABLE dbo.Venda DROP CONSTRAINT fk_Venda_Cliente_Cliente_ID 

-- ADD FK
ALTER TABLE dbo.Venda ADD CONSTRAINT fk_Venda_Cliente_Cliente_ID FOREIGN KEY (Cliente_ID) 
REFERENCES dbo.Cliente (Cliente_ID)

/*********************************
 FOREIGN KEY Auto relacionamento
**********************************/
DROP TABLE IF exists dbo.Funcionario
go
CREATE TABLE dbo.Funcionario (
Funcionario_ID int not null CONSTRAINT pk_Funcionario PRIMARY KEY,
Nome varchar(50) not null,
Cargo varchar(50) not null,

Chefe_ID int null CONSTRAINT fk_Funcionario_Funcionario_ID FOREIGN KEY
REFERENCES dbo.Funcionario (Funcionario_ID))
go

INSERT dbo.Funcionario VALUES
(1,'Jose','Presidente',null),
(2,'Ana','Diretor',1),
(3,'Paulo','Diretor',1),
(4,'Carla','Gerente',2),
(5,'Erick','Gerente',2),
(6,'Antonio','Gerente',3)
go

SELECT * FROM dbo.Funcionario

INSERT dbo.Funcionario VALUES
(7,'Jose','Gerente',15)
/*
Msg 547, Level 16, State 0, Line 191
The INSERT statement conflicted with the FOREIGN KEY SAME TABLE constraint "fk_Funcionario_Funcionario_ID". The conflict occurred in database "Aula", table "dbo.Funcionario", column 'Funcionario_ID'.
*/

/*******************************
 FOREIGN KEY
 - UPDATE CASCADE
 - DELETE CASCADE
********************************/
DROP TABLE If exists dbo.Venda
go
CREATE TABLE dbo.Venda (
Venda_ID int not null CONSTRAINT pk_Venda PRIMARY KEY,
Data_Venda datetime not null,
Cliente_ID int null CONSTRAINT df_Venda_Cliente_ID DEFAULT -1,
Total_Venda decimal(9,2) not null)
go

ALTER TABLE dbo.Venda ADD CONSTRAINT fk_Venda_Cliente_Cliente_ID FOREIGN KEY (Cliente_ID) 
REFERENCES dbo.Cliente (Cliente_ID)
ON DELETE NO ACTION
ON UPDATE NO ACTION

-- INSERT dbo.Cliente (Cliente_ID,Nome,CPF) VALUES (1,'Jose','11111')
-- INSERT dbo.Cliente (Cliente_ID,Nome,CPF) VALUES (2,'Carlos','22222')
-- INSERT dbo.Cliente (Cliente_ID,Nome,CPF) VALUES (3,'Carlos','33333')

INSERT dbo.Venda (Venda_ID,Data_Venda,Cliente_ID,Total_Venda) VALUES 
(1001,'20100116',1,15000.10),
(1002,'20100408',1,5000.00),
(1003,'20100410',2,100.00),
(1004,'20100515',2,1400.00),
(1005,'20100605',3,5100.00),
(1006,'20100725',3,2100.00)
go


SELECT * FROM dbo.Venda ORDER BY Cliente_ID
SELECT * FROM dbo.Cliente
-- Clientes 1, 2 e 3

UPDATE dbo.Cliente SET Cliente_ID = 12 WHERE Cliente_ID = 2
/*
Msg 547, Level 16, State 0, Line 237
The UPDATE statement conflicted with the REFERENCE constraint "fk_Venda_Cliente_Cliente_ID". The conflict occurred in database "Aula", table "dbo.Venda", column 'Cliente_ID'.
*/

/*********************
 CASCADE
**********************/
ALTER TABLE dbo.Venda DROP CONSTRAINT fk_Venda_Cliente_Cliente_ID
go

ALTER TABLE dbo.Venda ADD CONSTRAINT fk_Venda_Cliente_Cliente_ID FOREIGN KEY (Cliente_ID) 
REFERENCES dbo.Cliente (Cliente_ID)
ON UPDATE CASCADE
ON DELETE CASCADE

UPDATE dbo.Cliente SET Cliente_ID = 12 WHERE Cliente_ID = 2
DELETE dbo.Cliente WHERE Cliente_ID = 12

SELECT * FROM dbo.Cliente
SELECT * FROM dbo.Venda

-- Exclui tabelas
DROP TABLE IF exists dbo.Venda
DROP TABLE If exists dbo.Cliente
DROP TABLE IF exists dbo.Funcionario
