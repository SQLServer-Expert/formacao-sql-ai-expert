/***********************************************************************************************************************
 Curso T-SQL
 Autor: Landry

 Demonstração:
 - Sintaxe
 - Funções de Classificação
 - Funções de Análise

 https://learn.microsoft.com/en-us/azure/databricks/sql/language-manual/sql-ref-window-functions
 https://learn.microsoft.com/en-us/sql/t-sql/queries/select-window-transact-sql?view=sql-server-ver16
************************************************************************************************************************/
use AdventureWorksLT
go


/**************************
Funções de Classificação
***************************/

-- RANK
SELECT ProductCategoryID, Productid, [name] as ProductName, ListPrice,
RANK() OVER(ORDER BY ListPrice DESC) AS ListPrice_Rank
FROM SalesLT.Product 
WHERE ProductCategoryID is not null
ORDER BY ListPrice DESC

-- RANK com PARTITION BY
SELECT ProductCategoryID, Productid, [name] as ProductName, ListPrice,
RANK() OVER(PARTITION BY ProductCategoryID ORDER BY ListPrice DESC) AS ListPrice_Rank
FROM SalesLT.Product 
WHERE ProductCategoryID is not null
ORDER BY ProductCategoryID,ListPrice DESC


-- Diferença RANK, DENSE_RANK, ROW_NUMBER
SELECT c.Name as Category, b.Name as Product, sum(a.LineTotal) as LineTotal
FROM SalesLT.SalesOrderDetail a
JOIN SalesLT.Product b on b.ProductID = a.ProductID
JOIN SalesLT.ProductCategory c on c.ProductCategoryID = b.ProductCategoryID
GROUP BY c.Name, b.Name
ORDER BY Category, Product

;WITH CTE_ProductSales as (
SELECT c.Name as Category, b.Name as Product, sum(a.LineTotal) as LineTotal
FROM SalesLT.SalesOrderDetail a
JOIN SalesLT.Product b on b.ProductID = a.ProductID
JOIN SalesLT.ProductCategory c on c.ProductCategoryID = b.ProductCategoryID
GROUP BY c.Name, b.Name
UNION ALL
SELECT 'Handlebars', 'HH Mountain Handlebars',216.486000)

SELECT Category, Product, LineTotal,
RANK()       OVER(PARTITION BY Category ORDER BY LineTotal DESC) as LineTotal_RANK,
DENSE_RANK() OVER(PARTITION BY Category ORDER BY LineTotal DESC) as LineTotal_DENSE_RANK,
ROW_NUMBER() OVER(PARTITION BY Category ORDER BY LineTotal DESC) as LineTotal_ROW_NUMBER
FROM CTE_ProductSales
ORDER BY Category, LineTotal DESC

-- NTITLE
;WITH CTE_ProductSales as (
SELECT c.Name as Category, b.Name as Product, sum(a.LineTotal) as LineTotal
FROM SalesLT.SalesOrderDetail a
JOIN SalesLT.Product b on b.ProductID = a.ProductID
JOIN SalesLT.ProductCategory c on c.ProductCategoryID = b.ProductCategoryID
GROUP BY c.Name, b.Name
UNION ALL
SELECT 'Handlebars', 'HH Mountain Handlebars',216.486000)

SELECT Category, Product, LineTotal,
NTILE(3) OVER(ORDER BY LineTotal) as LineTotal_NTILE
FROM CTE_ProductSales
ORDER BY LineTotal


/**************************
Funções de Análise
***************************/
use Aula
go

-- DROP TABLE SalesOrderHeader
CREATE TABLE SalesOrderHeader (
SalesOrderID int,
OrderDate datetime,
FirstName nvarchar(50),
SalesPerson nvarchar(50),
TotalDue decimal (16,4))
go

-- Carrega com vendas de vários anos
DECLARE @i int = 2, @Valor decimal(16,4) = 300.0

WHILE @i < 6 BEGIN
	INSERT SalesOrderHeader
	SELECT a.SalesOrderID + year(dateadd(yy,@i,a.OrderDate)) as SalesOrderID,
	dateadd(yy,@i,a.OrderDate) as OrderDate, 
	b.FirstName, b.SalesPerson,
	a.TotalDue * @Valor as TotalDue
	FROM AdventureWorksLT.SalesLT.SalesOrderHeader a
	JOIN AdventureWorksLT.SalesLT.Customer b on b.CustomerID = a.CustomerID

	SET @i += 1
	SET @Valor = @Valor * @i
END
go

-- LAG
;WITH CTE_Orders as (
SELECT SalesPerson, year(OrderDate) as OrderDate_Year, sum(TotalDue) as TotalDue
FROM SalesOrderHeader
GROUP BY SalesPerson, year(OrderDate))

SELECT SalesPerson, OrderDate_Year,TotalDue,
LAG(TotalDue, 1,0) OVER (PARTITION BY SalesPerson ORDER BY OrderDate_Year) as TotalDue_LAG,
LEAD(TotalDue, 1,0) OVER (PARTITION BY SalesPerson ORDER BY OrderDate_Year) as TotalDue_LEAD,
FIRST_VALUE(TotalDue) OVER (PARTITION BY SalesPerson ORDER BY OrderDate_Year) as TotalDue_FIRST_VALUE,
LAST_VALUE(TotalDue) OVER (PARTITION BY SalesPerson ORDER BY OrderDate_Year) as TotalDue_LAST_VALUE

FROM CTE_Orders
ORDER BY SalesPerson, OrderDate_Year


-- Diferença entre anos
;WITH CTE_Orders as (
SELECT SalesPerson, year(OrderDate) as OrderDate_Year, sum(TotalDue) as TotalDue
FROM SalesOrderHeader
GROUP BY SalesPerson, year(OrderDate))

SELECT SalesPerson, OrderDate_Year,TotalDue,
LAG(TotalDue, 1,0) OVER (PARTITION BY SalesPerson ORDER BY OrderDate_Year) as TotalDue_LAG,
TotalDue - LAG(TotalDue, 1,0) OVER (PARTITION BY SalesPerson ORDER BY OrderDate_Year) as TotalDue_Dif
FROM CTE_Orders
ORDER BY SalesPerson, OrderDate_Year


-- % do Total por SalesPerson
SELECT SalesOrderID, SalesPerson, TotalDue,

SUM(TotalDue) OVER (PARTITION BY SalesPerson) as TotalDue_SUM,

(TotalDue / SUM(TotalDue) OVER (PARTITION BY SalesPerson)) * 100 as TotalDue_Perc

FROM SalesOrderHeader
ORDER BY SalesPerson,TotalDue_Perc DESC


-- Exclui tabela
DROP TABLE SalesOrderHeader
