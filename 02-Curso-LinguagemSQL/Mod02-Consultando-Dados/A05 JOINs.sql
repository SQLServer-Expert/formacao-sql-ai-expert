/*************************************************
 Curso T-SQL
 Autor: Landry

 Demonstração:
 - INNER JOIN
 - LEFT JOIN
 - RIGHT JOIN
 - CROSS JOIN
 - JOINs de múltiplas tabelas
 - Auto Relacionamento
*************************************************/
use Aula
go

/****************************************************************************************************
 Tipos de JOINs
 https://learn.microsoft.com/en-us/sql/relational-databases/performance/joins?view=sql-server-ver16
*****************************************************************************************************/
--DROP TABLE dbo.Vendedor
--DROP TABLE dbo.Venda
CREATE TABLE dbo.Vendedor (VendedorId int, Vendedor varchar(100))
CREATE TABLE dbo.Venda (VendaID int, VendedorID int, ProdutoID int, Qtd int, Valor decimal(10,2))
go
INSERT dbo.Vendedor VALUES (1,'Jose')
INSERT dbo.Vendedor VALUES (2,'Pedro')
INSERT dbo.Vendedor VALUES (3,'Lucia')
INSERT dbo.Vendedor VALUES (4,'Ana')
go
INSERT dbo.Venda VALUES (100,1,10,5,1000.00)
INSERT dbo.Venda VALUES (101,5,20,3,1500.00)
INSERT dbo.Venda VALUES (101,6,30,2,2500.00)

SELECT * FROM dbo.Vendedor 
SELECT * FROM dbo.Venda

SELECT * FROM dbo.Vendedor a INNER JOIN dbo.Venda b on a.VendedorId = b.VendedorID
SELECT * FROM dbo.Vendedor a LEFT JOIN dbo.Venda b on a.VendedorId = b.VendedorID
SELECT * FROM dbo.Vendedor a RIGHT JOIN dbo.Venda b on a.VendedorId = b.VendedorID
SELECT * FROM dbo.Vendedor a FULL JOIN dbo.Venda b on a.VendedorId = b.VendedorID
SELECT * FROM dbo.Vendedor a CROSS JOIN dbo.Venda

-- Apaga tabelas
DROP TABLE dbo.Vendedor
DROP TABLE dbo.Venda

/************************ 
 Banco AdventureWorksLT 
*************************/
use AdventureWorksLT
go


SELECT * FROM SalesLT.SalesOrderHeader

SELECT b.FirstName, b.LastName, a.* 
FROM SalesLT.SalesOrderHeader a
JOIN SalesLT.Customer b on b.CustomerID = a.CustomerID


-- Exemplo da aula GROUP BY
SELECT CustomerID, 
sum(TotalDue) as Soma_Vendas

FROM SalesLT.SalesOrderHeader
GROUP BY CustomerID
ORDER BY CustomerID

-- Combinando JOIN
SELECT b.FirstName, b.LastName,
sum(a.TotalDue) as Soma_Vendas

FROM SalesLT.SalesOrderHeader a
JOIN SalesLT.Customer b on b.CustomerID = a.CustomerID
GROUP BY b.FirstName, b.LastName
ORDER BY b.FirstName, b.LastName

-- JOIN de Múltiplas tabelas
SELECT a.SalesOrderID, a.OrderDate, c.FirstName, c.LastName,
e.Name as ProductCategory, d.Name as Product,
b.LineTotal
FROM SalesLT.SalesOrderHeader a
JOIN SalesLT.SalesOrderDetail b on b.SalesOrderID = a.SalesOrderID
JOIN SalesLT.Customer c on c.CustomerID = a.CustomerID
JOIN SalesLT.Product d on d.ProductID = b.ProductID
JOIN SalesLT.ProductCategory e on e.ProductCategoryID = d.ProductCategoryID
ORDER BY SalesOrderID

