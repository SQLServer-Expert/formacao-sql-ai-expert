/*************************************************
 Curso T-SQL
 Autor: Landry

 Demonstração:
 - Funções de Agregação
 - GROUP BY
 - HAVING
 - ROLLUP
 - CUBE
 - GROUPING SETS
*************************************************/
use AdventureWorksLT
go

/*
SELECT count(*) as QtdLinhas 
FROM SalesLT.SalesOrderHeader

SELECT sum(TotalDue) as TotalVendas 
FROM SalesLT.SalesOrderHeader
*/
/********************************************************
 Funções de Agregação
*********************************************************/
-- diferença entre COUNT(*) e COUNT(<coluna>)
SELECT count(*) as Qtd_Linhas, 
count([Weight]) as Qtd_Linhas_Weight_IsNotNull
FROM SalesLT.Product
/*
 - 295 Quantidade de linhas na tabela
 - 198 Quantidade de linhas com valores na coluna "Weight",
   existem 97 linhas com NULL na coluna "Weight"
*/

-- AVG() não leva em consideração linhas com NULL
SELECT sum([Weight]) as Soma_Weight,
avg([Weight]) as Media_Weight_Null,
avg(isnull([Weight],0.0)) as Media_Weight_Null_Zero
FROM SalesLT.Product
-- 5483.705606 Média sem levar em consideração linhas com NULL
-- 3680.588847 Média transformando NULL em zero

/*******************************************************************************************************
 GROUP BY
 https://learn.microsoft.com/en-us/sql/t-sql/queries/select-group-by-transact-sql?view=sql-server-ver16
********************************************************************************************************/ 
-- GROUP BY
SELECT ProductID, 
sum(LineTotal) as Soma_Vendas

FROM SalesLT.SalesOrderDetail
GROUP BY ProductID
ORDER BY ProductID
-- 142 linhas

SELECT * FROM SalesLT.Customer

-- WHERE: Apenas Produto 715 (Long-Sleeve Logo Jersey, L)
SELECT * FROM SalesLT.Product WHERE ProductID = 715
SELECT * FROM SalesLT.SalesOrderDetail WHERE ProductID = 715

SELECT ProductID, 
sum(LineTotal) as Soma_Vendas

FROM SalesLT.SalesOrderDetail
WHERE ProductID = 715
GROUP BY ProductID
ORDER BY ProductID

-- HAVING
SELECT ProductID, 
sum(LineTotal) as Soma_Vendas

FROM SalesLT.SalesOrderDetail
GROUP BY ProductID
HAVING sum(LineTotal) >= 20000.0
ORDER BY ProductID
-- 8 linhas

-- GROUP BY 2 colunas
SELECT CustomerID, year(OrderDate) as Ano,
sum(TotalDue) as Soma_Vendas

FROM SalesLT.SalesOrderHeader
GROUP BY CustomerID, year(OrderDate)
ORDER BY CustomerID, Ano


-- Consulta para descobrir se existem linhas com valor repetido em uma chave
SELECT Color, count(*) as QtdLinhas
FROM SalesLT.Product
GROUP BY Color
HAVING count(*) > 1
ORDER BY 2 desc

-- PK zero linhas
SELECT ProductID, count(*) as QtdLinhas
FROM SalesLT.Product
GROUP BY ProductID
HAVING count(*) > 1
ORDER BY 2 desc

/**************************************************************************************************
 ROLLUP, CUBE e GROUPING SETS
 - Gera total geral e subtotal no resultado
 - GROUPING SETS disponível a partir do SQL Server 2016  
***************************************************************************************************/
use Aula
go

-- DROP TABLE dbo.Vendas
CREATE TABLE dbo.Vendas (VendaID int identity, VendedorID int, Ano smallint, Valor decimal(10,2))
go

INSERT dbo.Vendas VALUES(1, 2005, 12000)
INSERT dbo.Vendas VALUES(1, 2005,  5000)
INSERT dbo.Vendas VALUES(1, 2005, 32000)

INSERT dbo.Vendas VALUES(1, 2006, 54000)
INSERT dbo.Vendas VALUES(1, 2006, 18000)

INSERT dbo.Vendas VALUES(1, 2007,  2000)
INSERT dbo.Vendas VALUES(1, 2007,   500)
INSERT dbo.Vendas VALUES(1, 2007, 87000)
INSERT dbo.Vendas VALUES(1, 2007, 14000) 

INSERT dbo.Vendas VALUES(2, 2005,  5000)
INSERT dbo.Vendas VALUES(2, 2005, 18000)
INSERT dbo.Vendas VALUES(2, 2005, 54000)

INSERT dbo.Vendas VALUES(2, 2006,   600)
INSERT dbo.Vendas VALUES(2, 2006, 19000)

INSERT dbo.Vendas VALUES(3, 2005,   200)
INSERT dbo.Vendas VALUES(3, 2005, 23000)

INSERT dbo.Vendas VALUES(3, 2006, 45000)
INSERT dbo.Vendas VALUES(3, 2006,  2000)
INSERT dbo.Vendas VALUES(3, 2006, 34000)

INSERT dbo.Vendas VALUES(3, 2007, 85000)
INSERT dbo.Vendas VALUES(3, 2007,  4000)
go

-- ROLLUP
SELECT * FROM dbo.Vendas order by VendedorID, Ano

SELECT VendedorID, Ano, SUM(Valor) AS Valor
FROM dbo.Vendas
GROUP BY VendedorID, Ano WITH ROLLUP
ORDER BY VendedorID, Ano

-- GROUPING SET = ROLLUP
SELECT VendedorID, Ano, SUM(Valor) AS Valor
FROM dbo.Vendas
GROUP BY GROUPING SETS((VendedorID, Ano),(VendedorID),())
ORDER BY VendedorID, Ano

SELECT VendedorID, Ano, SUM(Valor) AS Valor
FROM dbo.Vendas
GROUP BY GROUPING SETS((VendedorID, Ano),())
ORDER BY VendedorID, Ano

-- CUBE
SELECT VendedorID, Ano, SUM(Valor) AS Valor
FROM dbo.Vendas
GROUP BY VendedorID, Ano WITH CUBE
ORDER BY VendedorID, Ano

-- Exclui tabelas
DROP TABLE dbo.Vendas
