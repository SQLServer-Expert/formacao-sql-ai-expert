/*************************************************
 Curso T-SQL
 Autor: Landry

 Módulo 3 - Exercício 1
 - TOP, TABLESAMPLE, GROUP BY
*************************************************/
use AdventureWorks
go

/************************************************
 Exercício 1 - Utilizando TOP e TABLESAMPLE
**************************************************/

-- Item 3
SELECT top(10) * FROM Production.Product ORDER BY ListPrice desc
-- ou
SELECT top 10 * FROM Production.Product ORDER BY ListPrice desc

-- Item 4
DECLARE @top int
SET @top = 5

SELECT top(@top) * FROM Production.Product ORDER BY ListPrice desc

-- Item 5
SELECT * 
FROM Production.Product
TABLESAMPLE (30 PERCENT)

/***************************************************
 Exercício 2 - Utilizando GROUP BY
****************************************************/
-- Item 1
SELECT SalesPersonID, sum(TotalDue) as Total
FROM Sales.SalesOrderHeader
GROUP BY SalesPersonID
ORDER BY SalesPersonID

-- Item 2
SELECT SalesPersonID, sum(TotalDue) as Total
FROM Sales.SalesOrderHeader
WHERE SalesPersonID is not null
GROUP BY SalesPersonID
ORDER BY SalesPersonID

-- Item 3
SELECT SalesPersonID, sum(TotalDue) as Total
FROM Sales.SalesOrderHeader
WHERE SalesPersonID is not null
GROUP BY GROUPING SETS ((SalesPersonID),())
ORDER BY Total desc

-- Item 4
SELECT PersonType, count(*) as QtdLinhas
FROM Person.Person
GROUP BY PersonType
HAVING count(*) > 200
ORDER BY 2 desc

-- Item 5
SELECT year(QuotaDate) as Ano,BusinessEntityID as VendedorID, sum(SalesQuota) as TotalVenda
FROM Sales.SalesPersonQuotaHistory
GROUP BY year(QuotaDate),BusinessEntityID
ORDER BY Ano,VendedorID

-- Item 6
SELECT BusinessEntityID as VendedorID, year(QuotaDate) as Ano, sum(SalesQuota) as TotalVenda
FROM Sales.SalesPersonQuotaHistory
WHERE QuotaDate >= '20120101'
GROUP BY BusinessEntityID, year(QuotaDate)
ORDER BY Ano,VendedorID

-- Item 7
SELECT BusinessEntityID as VendedorID, year(QuotaDate) as Ano, sum(SalesQuota) as TotalVenda
FROM Sales.SalesPersonQuotaHistory
WHERE QuotaDate >= '20120101'
GROUP BY BusinessEntityID, year(QuotaDate)
HAVING sum(SalesQuota) > 3000000
ORDER BY Ano,TotalVenda desc
