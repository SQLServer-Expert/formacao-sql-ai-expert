-- ============================================================
-- Prof. Landry
-- Curso Linguagem Transact-SQL
-- Exercícios Common Table Expressions (CTE)
-- Banco de Dados: AdventureWorks
-- ============================================================

USE AdventureWorks
GO

-- ============================================================
-- Exercício 1 – CTE simples: Top 10 produtos mais vendidos
-- ============================================================
-- Retorna os 10 produtos com maior quantidade total vendida,
-- exibindo o nome do produto e a quantidade total.

WITH CTE_TopProdutos AS (
SELECT p.Name AS Produto,
SUM(sod.OrderQty) AS QuantidadeTotal
FROM Sales.SalesOrderDetail sod
INNER JOIN Production.Product p ON p.ProductID = sod.ProductID
GROUP BY p.Name
)
SELECT TOP 10 Produto, QuantidadeTotal
FROM CTE_TopProdutos
ORDER BY QuantidadeTotal DESC;

-- Resultado esperado: 10 linhas


-- ============================================================
-- Exercício 2 – CTE com filtragem: Funcionários com salário
--               acima da média do seu departamento
-- ============================================================
-- Utilize uma CTE para calcular o salário médio por departamento.
-- Em seguida, retorne os funcionários cujo salário seja superior
-- à média do seu respectivo departamento.
-- Exiba: NomeDepartamento, NomeCompleto, Salário, MédiaDepartamento.

WITH CTE_MediaDepartamento AS (
    SELECT
        d.Name AS NomeDepartamento,
        AVG(eph.Rate) AS MediaSalario
    FROM HumanResources.EmployeeDepartmentHistory edh
    INNER JOIN HumanResources.Department d ON d.DepartmentID = edh.DepartmentID
    INNER JOIN HumanResources.EmployeePayHistory eph ON eph.BusinessEntityID = edh.BusinessEntityID
    WHERE edh.EndDate IS NULL
    GROUP BY d.Name
)
SELECT
    d.Name AS NomeDepartamento,
    CONCAT(pp.FirstName, ' ', pp.LastName) AS NomeCompleto,
    eph.Rate AS Salario,
    cte.MediaSalario AS MediaDepartamento
FROM HumanResources.EmployeeDepartmentHistory edh
INNER JOIN HumanResources.Department d ON d.DepartmentID = edh.DepartmentID
INNER JOIN HumanResources.EmployeePayHistory eph ON eph.BusinessEntityID = edh.BusinessEntityID
INNER JOIN Person.Person pp ON pp.BusinessEntityID = edh.BusinessEntityID
INNER JOIN CTE_MediaDepartamento cte ON cte.NomeDepartamento = d.Name
WHERE edh.EndDate IS NULL
  AND eph.Rate > cte.MediaSalario
ORDER BY d.Name, eph.Rate DESC;

-- Resultado esperado: 118 linhas


-- ============================================================
-- Exercício 3 – Múltiplas CTEs: Comparativo de vendas entre
--               vendedores e a média geral
-- ============================================================
-- Crie duas CTEs:
--   CTE_VendasPorVendedor: total vendido por cada vendedor (TotalVendas).
--   CTE_MediaGeral: média do total vendido entre todos os vendedores.
-- Retorne: NomeVendedor, TotalVendas, MediaGeral e a diferença
-- (TotalVendas - MediaGeral) com o alias Diferenca.
-- Ordene pelo TotalVendas decrescente.

WITH CTE_VendasPorVendedor AS (
    SELECT
        CONCAT(pp.FirstName, ' ', pp.LastName) AS NomeVendedor,
        SUM(soh.TotalDue) AS TotalVendas
    FROM Sales.SalesOrderHeader soh
    INNER JOIN Sales.SalesPerson sp ON sp.BusinessEntityID = soh.SalesPersonID
    INNER JOIN Person.Person pp ON pp.BusinessEntityID = sp.BusinessEntityID
    GROUP BY pp.FirstName, pp.LastName
),
CTE_MediaGeral AS (
    SELECT AVG(TotalVendas) AS MediaGeral
    FROM CTE_VendasPorVendedor
)
SELECT
    v.NomeVendedor,
    v.TotalVendas,
    m.MediaGeral,
    (v.TotalVendas - m.MediaGeral) AS Diferenca
FROM CTE_VendasPorVendedor v
CROSS JOIN CTE_MediaGeral m
ORDER BY v.TotalVendas DESC;

-- Resultado esperado: 17 linhas


-- ============================================================
-- Exercício 4 – CTE com ranking: Produtos mais rentáveis
--               por categoria
-- ============================================================
-- Crie uma CTE que calcule o total arrecadado por produto
-- (UnitPrice * OrderQty) agrupado por categoria e produto.
-- Em seguida, utilize a função ROW_NUMBER() para ranquear os
-- produtos dentro de cada categoria pelo total arrecadado
-- (do maior para o menor).
-- Retorne apenas o TOP 3 de cada categoria.
-- Exiba: Categoria, Ranking, NomeProduto, TotalArrecadado.

WITH CTE_ReceitaProduto AS (
    SELECT
        pc.Name AS Categoria,
        p.Name AS NomeProduto,
        SUM(sod.UnitPrice * sod.OrderQty) AS TotalArrecadado
    FROM Sales.SalesOrderDetail sod
    INNER JOIN Production.Product p ON p.ProductID = sod.ProductID
    INNER JOIN Production.ProductSubcategory psc ON psc.ProductSubcategoryID = p.ProductSubcategoryID
    INNER JOIN Production.ProductCategory pc ON pc.ProductCategoryID = psc.ProductCategoryID
    GROUP BY pc.Name, p.Name
),
CTE_Ranking AS (
    SELECT
        Categoria,
        NomeProduto,
        TotalArrecadado,
        ROW_NUMBER() OVER (PARTITION BY Categoria ORDER BY TotalArrecadado DESC) AS Ranking
    FROM CTE_ReceitaProduto
)
SELECT
    Categoria,
    Ranking,
    NomeProduto,
    TotalArrecadado
FROM CTE_Ranking
WHERE Ranking <= 3
ORDER BY Categoria, Ranking;

-- Resultado esperado: 12 linhas (3 produtos × 4 categorias)
