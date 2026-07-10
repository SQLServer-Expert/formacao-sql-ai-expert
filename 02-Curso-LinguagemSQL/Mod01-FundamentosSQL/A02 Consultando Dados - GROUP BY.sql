/*******************************
 Autor: Landry Duailibe
 
 Hands On: GROUP BY
********************************/
use AdventureWorks
go

/*********************************
 Funcao de Agregacao
**********************************/ 
SELECT COUNT(*) as TotLinhas, COUNT(SalesPersonID) as TotSalesPerson,
AVG(SalesPersonID) as MediaComNULL, AVG(isnull(SalesPersonID,0)) as MediaSemNULL
FROM Sales.SalesOrderHeader

SELECT COUNT(*) as TotLinhas
FROM Sales.SalesOrderHeader
-- 31.465 linhas

SELECT COUNT(CurrencyRateID) as TotLinhas
FROM Sales.SalesOrderHeader
-- 13.976 linhas com NOT NULL na coluna CurrencyRateID

/**************************
 GROUP BY
***************************/ 
SELECT SalesPersonID,sum(TotalDue) as Total
FROM Sales.SalesOrderHeader
GROUP BY SalesPersonID
ORDER BY SalesPersonID

-- Ordena pelos vendedores que venderam mais
SELECT SalesPersonID,sum(TotalDue) as Total
FROM Sales.SalesOrderHeader
GROUP BY SalesPersonID
ORDER BY Total DESC

-- WHERE para remover o NULL
SELECT SalesPersonID,sum(TotalDue) as Total
FROM Sales.SalesOrderHeader
WHERE SalesPersonID is not null
GROUP BY SalesPersonID
ORDER BY Total desc

-- HAVING filtro após o GROUP BY
SELECT SalesPersonID,sum(TotalDue) as Total
FROM Sales.SalesOrderHeader
WHERE SalesPersonID is not null
GROUP BY SalesPersonID
HAVING sum(TotalDue) > 5000000 
ORDER BY Total desc
