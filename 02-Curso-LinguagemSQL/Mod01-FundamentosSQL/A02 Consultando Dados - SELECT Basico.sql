/*******************************
 Autor: Landry Duailibe
 
 Hands On: SELECT básico
********************************/
use AdventureWorks
go

SELECT * FROM Person.Person

SELECT BusinessEntityID, LastName, FirstName, Title
FROM Person.Person


/*****************************
 Filtros
******************************/
SELECT BusinessEntityID, LastName, FirstName, Title
FROM Person.Person
WHERE BusinessEntityID = 5

SELECT BusinessEntityID, LastName, FirstName, Title
FROM Person.Person
WHERE Title = 'Ms.'

SELECT ProductID, Name, Color, ListPrice
FROM Production.Product
WHERE ListPrice >= 100

/***********
 LIKE
************/
SELECT ProductID, Name, Color, ListPrice
FROM Production.Product
WHERE Name LIKE '%Ball%'

SELECT ProductID, Name, Color, ListPrice
FROM Production.Product
WHERE Name LIKE '%Ball'

SELECT ProductID, Name, Color, ListPrice
FROM Production.Product
WHERE Name LIKE 'H_a_s%'

SELECT ProductID, Name, Color, ListPrice
FROM Production.Product
WHERE Name LIKE '[AC]%'

SELECT ProductID, Name, Color, ListPrice
FROM Production.Product
WHERE Name LIKE '[A-C]%'

/************ FIM LIKE ***************/


SELECT ProductID, Name, Color, ListPrice
FROM  Production.Product
WHERE (Name LIKE 'C%' OR Color = 'Blue') AND  (ListPrice > 100.00) 

-- BETWEEN
SELECT ProductID, Name, Color, ListPrice
FROM  Production.Product
WHERE ListPrice BETWEEN 100 AND 1000
--WHERE ListPrice >= 100 AND ListPrice <= 1000
-- 128 linhas

-- IN
SELECT ProductID, Name, Color, ListPrice
FROM  Production.Product
WHERE Color IN ('Blue', 'Black')
--WHERE Color = 'Blue' or Color = 'Black'

/***********************
 NULL
************************/
SELECT ProductID, Name, Color, ListPrice
FROM  Production.Product
WHERE Color = null
-- Zero linhas

SELECT ProductID, Name, Color, ListPrice
FROM  Production.Product
WHERE Color is null

SELECT ProductID, Name, Color, ListPrice
FROM  Production.Product
WHERE Color is not null

SELECT ProductID, Name, Color, isnull(Color,'n/a') as Cores, ListPrice
FROM  Production.Product


-- ORDER BY
SELECT ProductSubcategoryID,ProductID, Name, Color, ListPrice
FROM  Production.Product
ORDER BY ProductSubcategoryID, ListPrice DESC

-- DISTINCT
SELECT Color FROM Production.Product

SELECT distinct Color FROM Production.Product






