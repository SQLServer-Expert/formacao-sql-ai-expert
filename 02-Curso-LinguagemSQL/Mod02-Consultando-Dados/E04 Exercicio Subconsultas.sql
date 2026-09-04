/*************************************************
 Curso T-SQL
 Autor: Landry

 Módulo 3 - Exercício 4
 Subconsulta
*************************************************/
use AdventureWorks
go

/***************************************************
 Exercício 1 - Subconsulta
****************************************************/
-- Item 3
SELECT ProductID, [Name], ListPrice,
ListPrice - (SELECT avg(ListPrice) FROM Production.Product) as ListPrice_AVG
FROM Production.Product
WHERE ListPrice > 200

-- Item 4
SELECT ProductID, [Name], ListPrice,
ListPrice - (SELECT avg(ListPrice) FROM Production.Product) as ListPrice_AVG,
ListPrice - (select stdev(ListPrice) from Production.Product) as ListPrice_STDEV
FROM Production.Product
WHERE ListPrice > 200

-- Item 5

-- 5.1
SELECT sum(TotalDue) as TotalDue_2012 FROM Sales.SalesOrderHeader WHERE OrderDate >= '20120101' and OrderDate < '20130101'

-- 5.2
SELECT b.FirstName + isnull(' ' + b.MiddleName,'') + ' ' + b.LastName as SalesPerson, sum(a.TotalDue) as TotalDue
FROM Sales.SalesOrderHeader a
JOIN Person.Person b on b.BusinessEntityID = a.SalesPersonID
WHERE OrderDate >= '20120101' and OrderDate < '20130101'
GROUP BY b.FirstName + isnull(' ' + b.MiddleName,'') + ' ' + b.LastName


-- 5.3
SELECT b.FirstName + isnull(' ' + b.MiddleName,'') + ' ' + b.LastName as SalesPerson, sum(a.TotalDue) as TotalDue,
(sum(a.TotalDue) / (SELECT sum(TotalDue) as TotalDue_2012 FROM Sales.SalesOrderHeader WHERE OrderDate >= '20120101' and OrderDate < '20130101')) * 100 as 'TotalDue_%'

FROM Sales.SalesOrderHeader a
JOIN Person.Person b on b.BusinessEntityID = a.SalesPersonID
WHERE OrderDate >= '20120101' and OrderDate < '20130101'
GROUP BY b.FirstName + isnull(' ' + b.MiddleName,'') + ' ' + b.LastName
ORDER BY 'TotalDue_%' desc



