/*************************************************************************************************************
 Curso T-SQL
 Autor: Landry

 - Conversão de Tabular em XML
 - Cláusula FOR XML:
	 - RAW
	 - AUTO
	 - EXPLICIT
	 - PATH
 https://learn.microsoft.com/pt-br/sql/relational-databases/xml/for-xml-sql-server?view=sql-server-ver16
**************************************************************************************************************/
use AdventureWorksLT
go

/**************
 FOR XML RAW
***************/
SELECT top 4 CustomerID, FirstName, LastName
FROM SalesLT.Customer
FOR XML RAW

-- Elementos
SELECT top 4 CustomerID, FirstName, LastName
FROM SalesLT.Customer
FOR XML RAW, ELEMENTS

-- Root
SELECT top 4 CustomerID, FirstName, LastName
FROM SalesLT.Customer
FOR XML RAW, ROOT('Customers')

/****************************
 RAW x AUTO
*****************************/
-- FOR XML RAW
SELECT top 5 H.SalesOrderID, D.ProductID, D.OrderQty, D.LineTotal
FROM SalesLT.SalesOrderHeader H
JOIN SalesLT.SalesOrderDetail D on D.SalesOrderID = H.SalesOrderID
ORDER BY H.SalesOrderID, D.ProductID
FOR XML RAW

-- FOR XML AUTO
SELECT top 5 H.SalesOrderID, D.ProductID, D.OrderQty, D.LineTotal
FROM SalesLT.SalesOrderHeader H
JOIN SalesLT.SalesOrderDetail D on D.SalesOrderID = H.SalesOrderID
ORDER BY H.SalesOrderID, D.ProductID
FOR XML AUTO

/***********************
 FOR XML EXPLICIT
************************/
SELECT 1 as Tag, NULL as Parent,
SalesOrderID as [Sales!1!OrderID],
SalesOrderNumber as [Sales!1!SalesOrderNumber],
OrderDate as [Sales!1!Date!Element],
TotalDue as [Sales!1!TotalDue!Element]

FROM SalesLT.SalesOrderHeader 
FOR XML EXPLICIT, ROOT('Orders')

-- Com Hierarquia
SELECT 1 AS Tag, NULL AS Parent,
Customer.CustomerID as [Customer!1!CustomerID],  
Customer.FirstName as [Customer!1!FirstName],
null as [Sales!2!SalesOrderID], 
null as [Sales!2!OrderDate]
FROM SalesLT.Customer Customer
WHERE Customer.CustomerID in (29612,29877,29929)

UNION ALL

SELECT 2 AS Tag, 1 AS Parent,
Sales.CustomerID as [Customer!1!CustomerID], 
null as [Customer!1!FirstName],
Sales.SalesOrderID,
Sales.OrderDate
FROM SalesLT.SalesOrderHeader Sales
WHERE Sales.CustomerID in (29612,29877,29929)

ORDER BY [Customer!1!CustomerID], [Sales!2!SalesOrderID]
FOR XML EXPLICIT,ROOT('Rows')

/*******************
 FOR XML PATH
 @ Atributo
 .../ Elemento
********************/
SELECT 
CustomerID "@CustomerID",
CompanyName "@CompanyName",
FirstName  "CustomerName/First", 
LastName   "CustomerName/Last"
FROM SalesLT.Customer
FOR XML PATH('Emp'),ROOT('Rows')

