/************************************************************
 Autor: Landry Duailibe

 Hands On: Linguagem SQL
*************************************************************/
use master
go

CREATE DATABASE Aula
go
USE Aula
go

/***************************
 Erro de sintaxe
****************************/
CREATE TABLE TesteErro (Col1 char(10))

-- Exemplo 1
INSERT TesteErro VALUES ('Teste1')
INSERT TesteErro ('Teste2')
INSERT TesteErro VALUES ('Teste3')
go

-- Tabela está vazia
SELECT * FROM TesteErro


-- Exemplo 2
INSERT TesteErro VALUES ('Teste1')
INSERT TesteErro ('Teste2')
go
INSERT TesteErro VALUES ('Teste3')
go

-- Último INSERT executou
SELECT * FROM TesteErro

-- Apaga todas as linhas da tabela
TRUNCATE TABLE TesteErro

/***************************
 Erro de execução
****************************/
SELECT newid()

-- Exemplo 1
INSERT TesteErro VALUES ('Teste1')
INSERT TesteErro VALUES (newid())
INSERT TesteErro VALUES ('Teste3')
go

-- Último INSERT executou
SELECT * FROM TesteErro

-- Exclui tabela
DROP TABLE IF exists TesteErro

/***************************
 Nome de Objetos
****************************/

-- Nome errado
CREATE TABLE Nota Fiscal (Col1 varchar(10))

CREATE TABLE 1NotaFiscal (Col1 varchar(10))

-- Delimitador de nome de Objeto
CREATE TABLE [Nota Fiscal] (Col1 varchar(10))

CREATE TABLE [1NotaFiscal] (Col1 varchar(10))

/***********************************
 Nome do Objeto com 4 partes
************************************/
go
CREATE SCHEMA Vendas
go

CREATE TABLE Cliente (Nome varchar(50), Idade int)

INSERT Cliente VALUES
('Landry', 55),
('Paula',45)


CREATE TABLE Vendas.Cliente (Nome varchar(50), Idade int)

INSERT Vendas.Cliente VALUES ('Pedro', 32)

SELECT * FROM Cliente
SELECT * FROM dbo.Cliente
SELECT * FROM Vendas.Cliente

/**********************
 Exclui objetos
***********************/
DROP TABLE IF exists dbo.Cliente
DROP TABLE IF exists Vendas.Cliente
go
DROP SCHEMA Vendas
go

/**********************************
 Variável
 - Restaurar AdventureWorks antes
***********************************/
SELECT *
FROM AdventureWorks.Person.Person
WHERE FirstName = 'Ken'

-- Exemplo 1
go
DECLARE @Codigo int,@Nome varchar(20)
SET @Nome = 'Ken'

SELECT @Codigo = BusinessEntityID
FROM AdventureWorks.Person.Person
WHERE FirstName = @Nome

SELECT @Codigo as Codigo 

-- Exemplo 2
go
DECLARE @Codigo int,@Nome varchar(20)
SET @Nome = 'Ken'

SET @Codigo = (SELECT BusinessEntityID
               FROM AdventureWorks.Person.Person
               WHERE FirstName = @Nome)

SELECT @Codigo as Codigo 
-- Erro


/*************************************
 Instruções Dinâmicas
**************************************/

-- Exemplo 1
DECLARE @Banco varchar(100), @Tabela varchar(100)
SET @Banco = 'AdventureWorks'
SET @Tabela = 'Production.Product'

EXECUTE('USE ' + @Banco + ' SELECT * FROM ' + @Tabela)
go

-- Exemplo 2
DECLARE @Banco varchar(100), @Tabela varchar(100)
SET @Banco = 'AdventureWorks'
SET @Tabela = 'Person.Person'

EXECUTE('USE ' + @Banco + ' SELECT * FROM ' + @Tabela)
go

/******************************
 CASE
*******************************/
-- https://dataedo.com/samples/html/AdventureWorks/doc/AdventureWorks_2/tables/Production_Product_153.html

SELECT ProductID, Name as Product, ProductLine,
CASE ProductLine
WHEN 'R' THEN 'Road'
WHEN 'M' THEN 'Mountain'
WHEN 'T' THEN 'Touring'
WHEN 'S' THEN 'Standard'
ELSE 'n/a'
END as ProductLine_Desc
FROM AdventureWorks.Production.Product



