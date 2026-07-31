/*************************************************
 Curso T-SQL
 Autor: Landry

 Demonstração:
 - Subconsulta Tab Derivada
 - Subconsulta expressão
 - Subconsulta no IN
 - Subconsulta correlacionada
 - EXISTS e NOT EXISTS
*************************************************/
use AdventureWorksLT
go

/*********************************************************************
 SELECT - 1 linha e 1 coluna (expressao)
 FROM   - N linhas e N colunas (tabela derivada)
 WHERE  - Operadores >,<,>=,<=,...    1 linha e 1 coluna (expressao)
        - Operadores ANY,SOME,ALL,IN  N linhas e 1 coluna
**********************************************************************/

/**********************************
 SubConsulta como Expressão
***********************************/
SELECT ProductID,ListPrice FROM SalesLT.Product
SELECT AVG(ListPrice) FROM SalesLT.Product -- 744.5952

-- Diferença do preço unitário de cada produto para a média dos preços unitários de todos os produtos
SELECT [Name], ProductCategoryID, ListPrice, 
(SELECT AVG(ListPrice) FROM SalesLT.Product) As Average, 
ListPrice - (SELECT AVG(ListPrice) FROM SalesLT.Product) AS [Difference]
FROM SalesLT.Product
WHERE ProductCategoryID = 6

-- Produtos com preço unitário maior que a média dos preços unitários
SELECT *
FROM SalesLT.Product
WHERE ListPrice > (SELECT AVG(ListPrice) FROM SalesLT.Product)

/**********************************
 SubConsulta no IN
***********************************/

SELECT *
FROM SalesLT.Product
WHERE ProductModelID in (SELECT ProductModelID FROM SalesLT.ProductModel WHERE [Name] like 'HL%')

/************************************* 
 SubConsulta Correlacionada
**************************************/     

-- Produtos que venderam mais de 50 unidades
SELECT p.[Name], p.ProductCategoryID, p.ListPrice
FROM SalesLT.Product p
WHERE 50 < (SELECT sum(s.OrderQty) as OrderQty FROM SalesLT.SalesOrderDetail s WHERE s.ProductID = p.ProductID )


/***********************************************************************************************************
 EXISTS 
 https://learn.microsoft.com/en-us/sql/t-sql/language-elements/exists-transact-sql?view=sql-server-ver16
************************************************************************************************************/

-- Clientes que compraram
SELECT c.CustomerID, c.FirstName, c.LastName, c.EmailAddress
FROM SalesLT.Customer c
WHERE EXISTS (SELECT * FROM SalesLT.SalesOrderHeader s WHERE s.CustomerID = c.CustomerID and s.OrderDate = '20080601')
-- 32 linhas

-- Clientes que compraram reescrito com JOIN
SELECT distinct c.CustomerID, c.FirstName, c.LastName, c.EmailAddress
FROM SalesLT.Customer c
JOIN SalesLT.SalesOrderHeader s on s.CustomerID = c.CustomerID
WHERE s.OrderDate = '20080601'

-- Clientes que NÃO compraram
SELECT c.CustomerID, c.FirstName, c.LastName, c.EmailAddress
FROM SalesLT.Customer c
WHERE NOT EXISTS (SELECT * FROM SalesLT.SalesOrderHeader s WHERE s.CustomerID = c.CustomerID and s.OrderDate = '20080601')
-- 815 linhas

-- Clientes que NÃO compraram reescrito com JOIN
SELECT distinct c.CustomerID, c.FirstName, c.LastName, c.EmailAddress
FROM SalesLT.Customer c
LEFT JOIN SalesLT.SalesOrderHeader s on c.CustomerID = s.CustomerID
WHERE s.OrderDate = '20080601'
and s.CustomerID is null
-- Zero linhas

-- Clientes que NÃO compraram reescrito com JOIN
SELECT distinct c.CustomerID, c.FirstName, c.LastName, c.EmailAddress
FROM SalesLT.Customer c
LEFT JOIN SalesLT.SalesOrderHeader s on c.CustomerID = s.CustomerID and s.OrderDate = '20080601'
WHERE s.CustomerID is null
-- 815 linhas

