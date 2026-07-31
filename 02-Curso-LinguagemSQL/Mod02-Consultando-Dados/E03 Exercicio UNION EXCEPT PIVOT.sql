/*************************************************
 Curso T-SQL
 Autor: Landry

 Módulo 3 - Exercício 3
 UNION, EXCEPT, PIVOT e UNPIVOT
*************************************************/
use AdventureWorks
go

/***************************************************
 Exercício 1 - Utilizando UNION e EXCEPT
****************************************************/
-- Item 3
SELECT s.FirstName,s.MiddleName,s.LastName,s.PhoneNumber
FROM Sales.vSalesPerson s
UNION ALL
SELECT e.FirstName,e.MiddleName,e.LastName,e.PhoneNumber
FROM HumanResources.vEmployee e
ORDER BY FirstName,MiddleName,LastName

-- Item 4
SELECT s.FirstName,s.MiddleName,s.LastName,s.PhoneNumber
FROM Sales.vSalesPerson s
UNION
SELECT e.FirstName,e.MiddleName,e.LastName,e.PhoneNumber
FROM HumanResources.vEmployee e
ORDER BY FirstName,MiddleName,LastName

-- Item 5
SELECT e.FirstName,e.MiddleName,e.LastName,e.PhoneNumber
FROM HumanResources.vEmployee e
EXCEPT
SELECT s.FirstName,s.MiddleName,s.LastName,s.PhoneNumber
FROM Sales.vSalesPerson s


/***************************************************
 Exercício 2 - Utilizando PIVOT e UNPIVOT
****************************************************/

-- Item 1.1
SELECT distinct year(OrderDate) as YearOrderDate FROM Sales.SalesOrderHeader
ORDER BY YearOrderDate
/*
2011,2012,2013,2014
*/

-- Item 1.2
SELECT c.FirstName + isnull(' ' + c.MiddleName,'') + ' ' + c.LastName as Customer,
year(a.OrderDate) as YearOrderDate, a.TotalDue
FROM Sales.SalesOrderHeader a
JOIN Sales.Customer b  on b.CustomerID = a.CustomerID
JOIN Person.Person c on c.BusinessEntityID = b.PersonID

-- Item 1.3
SELECT Customer, [2011], [2012], [2013], [2014]
FROM (
SELECT c.FirstName + isnull(' ' + c.MiddleName,'') + ' ' + c.LastName as Customer,
year(a.OrderDate) as YearOrderDate, a.TotalDue
FROM Sales.SalesOrderHeader a
JOIN Sales.Customer b  on b.CustomerID = a.CustomerID
JOIN Person.Person c on c.BusinessEntityID = b.PersonID) s
PIVOT (SUM(TotalDue) FOR YearOrderDate IN ([2011], [2012], [2013], [2014])) AS p
ORDER BY Customer


-- Item 2
SELECT Customer, [2011], [2012], [2013], [2014]
INTO #PivotCustomer 
FROM (
SELECT c.FirstName + isnull(' ' + c.MiddleName,'') + ' ' + c.LastName as Customer,
year(a.OrderDate) as YearOrderDate, a.TotalDue
FROM Sales.SalesOrderHeader a
JOIN Sales.Customer b  on b.CustomerID = a.CustomerID
JOIN Person.Person c on c.BusinessEntityID = b.PersonID) s
PIVOT (SUM(TotalDue) FOR YearOrderDate IN ([2011], [2012], [2013], [2014])) AS p
ORDER BY Customer

SELECT u.Customer, u.Ano, u.TotalDue
FROM #PivotCustomer 
UNPIVOT(TotalDue FOR Ano IN ([2011], [2012], [2013], [2014])) as u
