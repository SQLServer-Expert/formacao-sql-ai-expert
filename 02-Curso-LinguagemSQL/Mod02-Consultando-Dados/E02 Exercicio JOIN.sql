/*************************************************
 Curso T-SQL
 Autor: Landry

 Módulo 3 - Exercício 2
 - JOIN
*************************************************/
use AdventureWorks
go

/***************************************************
 Exercício 1 - Utilizando JOIN
****************************************************/
-- Item 3
SELECT s.Name as SubCategory, p.Name as Product, p.ProductNumber, p.Color,p.ListPrice
FROM Production.Product p 
JOIN Production.ProductSubcategory s on p.ProductSubcategoryID = s.ProductSubcategoryID
WHERE s.Name like 'C%' 
ORDER BY SubCategory,Product

-- Item 4
SELECT c.Name as Category,s.Name as SubCategory, p.Name as Product, p.ProductNumber,
p.Color,p.ListPrice
FROM Production.Product p 
JOIN Production.ProductSubcategory s on p.ProductSubcategoryID = s.ProductSubcategoryID
JOIN Production.ProductCategory c on c.ProductCategoryID = s.ProductCategoryID
WHERE c.Name = 'Bikes' 
ORDER BY Category,SubCategory,Product

-- Item 5.1
SELECT c.FirstName,c.MiddleName,c.LastName,sum(b.TotalDue) TotalDue
FROM Sales.Customer a 
JOIN Sales.SalesOrderHeader b on a.CustomerID = b.CustomerID
JOIN Person.Person c on c.BusinessEntityID = a.PersonID
GROUP BY c.FirstName,c.MiddleName,c.LastName
ORDER BY TotalDue desc

-- Item 5.2
SELECT c.FirstName + isnull(' ' + c.MiddleName, '') + isnull(' ' + c.LastName,'') as Cliente,sum(b.TotalDue) TotalDue
FROM Sales.Customer a 
JOIN Sales.SalesOrderHeader b on a.CustomerID = b.CustomerID
JOIN Person.Person c on c.BusinessEntityID = a.PersonID
GROUP BY c.FirstName + isnull(' ' + c.MiddleName, '') + isnull(' ' + c.LastName,'')
HAVING sum(b.TotalDue) >= 50000
ORDER BY TotalDue desc
