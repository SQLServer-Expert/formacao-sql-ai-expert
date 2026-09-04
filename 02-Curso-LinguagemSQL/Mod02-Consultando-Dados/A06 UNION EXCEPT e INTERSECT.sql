/*************************************************
 Curso T-SQL
 Autor: Landry

 Demonstração:
 - UNION
 - EXISTS e NOT EXISTS
 - EXCEPT
 - INTERSECT
*************************************************/
use Aula
go

/**********************************************************************************************************************
 UNION
 https://learn.microsoft.com/en-us/sql/t-sql/language-elements/set-operators-union-transact-sql?view=sql-server-ver16
***********************************************************************************************************************/
CREATE TABLE Cliente_Site (ClienteID int identity, Cliente varchar(50), Cidade varchar(20))
CREATE TABLE Cliente_Loja (ClienteID int identity, Cliente varchar(50), Cidade varchar(20))
go

INSERT Cliente_Site VALUES ('Jose','Rio de Janeiro')
INSERT Cliente_Site VALUES ('Simone','Rio de Janeiro')
INSERT Cliente_Site VALUES ('Paula','Sao Paulo')
INSERT Cliente_Site VALUES ('Claudio','Salvador')
INSERT Cliente_Site VALUES ('Sandro','Salvador')
INSERT Cliente_Site VALUES ('Laura','Sao Luiz')

INSERT Cliente_Loja VALUES ('Ana','Rio de Janeiro')
INSERT Cliente_Loja VALUES ('Erick','Sao Paulo')
INSERT Cliente_Loja VALUES ('Jonas','Sao Paulo')
INSERT Cliente_Loja VALUES ('Luana','Salvador')
INSERT Cliente_Loja VALUES ('Marina','Brasilia')
INSERT Cliente_Loja VALUES ('Rafael','Brasilia')
go

-- UNION
SELECT Cidade FROM Cliente_Site ORDER BY Cidade
SELECT Cidade FROM Cliente_Loja ORDER BY Cidade

SELECT Cidade FROM Cliente_Site
UNION 
SELECT Cidade FROM Cliente_Loja
ORDER BY Cidade

SELECT Cidade FROM Cliente_Site
UNION ALL
SELECT Cidade FROM Cliente_Loja
ORDER BY Cidade

/***************** EXISTS e NOT EXISTS *****************/
-- Obtendo linhas em comum
SELECT * 
FROM Cliente_Site where exists
(SELECT * FROM Cliente_Loja where Cliente_Loja.Cidade = Cliente_Site.Cidade)

-- Obtendo as linhas que existem na tabela Cliente_Site e
-- não existem na tabela Cliente_Loja
SELECT * 
FROM Cliente_Site where not exists
(SELECT * FROM Cliente_Loja where Cliente_Loja.Cidade = Cliente_Site.Cidade)


/***************** INTERSECT e EXCEPT ******************/
-- Obtendo linhas em comum
SELECT distinct Cidade FROM Cliente_Site ORDER BY Cidade
SELECT distinct Cidade FROM Cliente_Loja ORDER BY Cidade

SELECT Cidade FROM Cliente_Site
INTERSECT
SELECT Cidade FROM Cliente_Loja

-- Obtendo as linhas que existem na tabela Cliente_Site e
-- não existem na tabela Cliente_Loja
SELECT Cidade FROM Cliente_Site
EXCEPT
SELECT Cidade FROM Cliente_Loja
--  Sao Luiz

SELECT Cidade FROM Cliente_Loja
EXCEPT
SELECT Cidade FROM Cliente_Site
--  Brasilia


-- Exclui tabelas
DROP TABLE Cliente_Site
DROP TABLE Cliente_Loja
