/*************************************************
 Curso T-SQL
 Autor: Landry

 Demonstração:
 - TOP
 - TABLESAMPLE
 - Amostragem de linhas
*************************************************/
use Aula
go


/*********************************************************************************************
 TOP()
 https://learn.microsoft.com/en-us/sql/t-sql/queries/top-transact-sql?view=sql-server-ver16
**********************************************************************************************/ 
-- DROP TABLE vendas
CREATE TABLE Vendas (
VendedorID varchar(20) not null, 
TotalVenda decimal(10,2) null)
go
INSERT vendas VALUES ('Jose',50000.00)
INSERT vendas VALUES ('Ana',40000.00)
INSERT vendas VALUES ('Maria',30000.00)
INSERT vendas VALUES ('Carlos',20000.00)
INSERT vendas VALUES ('Landry',20000.00)
INSERT vendas VALUES ('Paula',18000.00)
INSERT vendas VALUES ('Luana',15000.00)
go

SELECT * FROM vendas 
ORDER BY TotalVenda desc, VendedorID desc

-- 4 primeiras linhas com maiores valores na coluna "TotalVenda"

SELECT top 4 * 
FROM vendas 
ORDER BY TotalVenda desc

-- Ou

SELECT top(4) * 
FROM vendas 
ORDER BY TotalVenda desc

-- "with ties" continua retornando se encontrar mesmo valor
SELECT top(4) with ties * 
FROM vendas 
ORDER BY TotalVenda desc

-- Exclui tabela
DROP TABLE vendas

/*************************
 TOP com PERCENT
**************************/
use AdventureWorksLT
go

SELECT count(*) FROM SalesLT.Product 
-- 295 linhas

-- retorna 10% das linhas da tabela "Product"
SELECT TOP 10 PERCENT ProductID, [Name], Color, StandardCost
FROM SalesLT.Product
-- 30 linhas, 10% de 295 = 29.5

/**************************************************************************************************************
 TABLESAMPLE()
 - Com TABLESAMPLE de 10% retorna quantidades de linhas diferentes
 - Não é percentual de linhas e sim de Paginas de Dados, por isso a quantidade de linhas muda
 https://learn.microsoft.com/en-us/azure/databricks/sql/language-manual/sql-ref-syntax-qry-select-sampling
***************************************************************************************************************/
SELECT ProductID, [Name], Color, StandardCost
FROM SalesLT.Product
TABLESAMPLE (10 PERCENT)
-- 42 linhas

-- Amostragem real
SELECT TOP 10 ProductID, [Name], Color, StandardCost
FROM SalesLT.Product
ORDER BY NEWID()
