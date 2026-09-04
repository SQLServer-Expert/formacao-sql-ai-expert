/***********************************************************************************************************************
 Curso T-SQL
 Autor: Landry

 Exercício Funções de Janela - Cláusula OVER

************************************************************************************************************************/

USE AdventureWorks
GO

/***********************************************************************************************************************
 Exercício 1 – Funções de Classificação: RANK, DENSE_RANK e ROW_NUMBER
 
 Utilize uma CTE chamada CTE_VendasProduto para calcular o total vendido
 (SUM de LineTotal) por subcategoria e produto, fazendo JOINs entre
 Sales.SalesOrderDetail, Production.Product e Production.ProductSubcategory.
 
 Na consulta principal, aplique as três funções de classificação
 com PARTITION BY pelo nome da subcategoria, ordenando pelo total vendido
 de forma decrescente.
 Exiba: Subcategoria, Produto, TotalVendido, Rank, DenseRank e RowNumber.
 Ordene por Subcategoria e TotalVendido DESC.
 
 Observe as diferenças entre as três funções quando há valores iguais.

***********************************************************************************************************************/

;WITH CTE_VendasProduto AS (
SELECT
    ps.Name                   AS Subcategoria,
    p.Name                    AS Produto,
    SUM(sod.LineTotal)        AS TotalVendido
FROM Sales.SalesOrderDetail sod
INNER JOIN Production.Product p          ON p.ProductID          = sod.ProductID
INNER JOIN Production.ProductSubcategory ps ON ps.ProductSubcategoryID = p.ProductSubcategoryID
GROUP BY ps.Name, p.Name
)
SELECT
    Subcategoria,
    Produto,
    TotalVendido,
    RANK()        OVER (PARTITION BY Subcategoria ORDER BY TotalVendido DESC) AS Rank,
    DENSE_RANK()  OVER (PARTITION BY Subcategoria ORDER BY TotalVendido DESC) AS DenseRank,
    ROW_NUMBER()  OVER (PARTITION BY Subcategoria ORDER BY TotalVendido DESC) AS RowNumber
FROM CTE_VendasProduto
ORDER BY Subcategoria, TotalVendido DESC;




/***********************************************************************************************************************
 Exercício 2 – NTILE: Classificação de Clientes por Faixa de Receita

 Escreva uma consulta que calcule o total comprado (SUM de TotalDue) por
 cliente, fazendo JOIN entre Sales.SalesOrderHeader e Person.Person.
 Use NTILE(4) para dividir os clientes em 4 grupos (quartis) com base no
 total de compras, do menor para o maior.
 
 Na consulta principal, exiba: NomeCompleto, TotalCompras e Quartil.
 Adicione uma coluna calculada chamada FaixaCliente que converte o número
 do quartil em texto:
   1 = 'Bronze', 2 = 'Prata', 3 = 'Ouro', 4 = 'Platina'
 Ordene pelo TotalCompras de forma decrescente.

***********************************************************************************************************************/

;WITH CTE_ComprasPorCliente AS (
    SELECT
        CONCAT(pp.FirstName, ' ', pp.LastName)  AS NomeCompleto,
        SUM(soh.TotalDue)                        AS TotalCompras
    FROM Sales.SalesOrderHeader soh
    INNER JOIN Person.Person pp ON pp.BusinessEntityID = soh.CustomerID
    GROUP BY pp.FirstName, pp.LastName
)
SELECT
    NomeCompleto,
    TotalCompras,
    NTILE(4) OVER (ORDER BY TotalCompras)       AS Quartil,
    CASE NTILE(4) OVER (ORDER BY TotalCompras)
        WHEN 1 THEN 'Bronze'
        WHEN 2 THEN 'Prata'
        WHEN 3 THEN 'Ouro'
        WHEN 4 THEN 'Platina'
    END                                          AS FaixaCliente
FROM CTE_ComprasPorCliente
ORDER BY TotalCompras DESC;



/***********************************************************************************************************************
 Exercício 3 – LAG e LEAD: Evolução de Vendas Anuais por Vendedor

 Utilize uma CTE chamada CTE_VendasAnuais para calcular o total vendido
 (SUM de TotalDue) por vendedor e por ano (YEAR de OrderDate), fazendo
 JOIN entre Sales.SalesOrderHeader e Person.Person.
 Considere apenas pedidos com SalesPersonID não nulo.

 Na consulta principal, aplique:
   - LAG(TotalVendas, 1, 0)  para obter o total do ano anterior (TotalAnoAnterior)
   - LEAD(TotalVendas, 1, 0) para obter o total do próximo ano (TotalProximoAno)
   - Uma coluna calculada Variacao = TotalVendas - TotalAnoAnterior
   - Uma coluna PercVariacao = ((TotalVendas - TotalAnoAnterior) / TotalAnoAnterior) * 100
     (use NULLIF no denominador para evitar divisão por zero)

 Todos os OVER devem usar PARTITION BY NomeVendedor ORDER BY AnoVenda.
 Exiba: NomeVendedor, AnoVenda, TotalVendas, TotalAnoAnterior,
        TotalProximoAno, Variacao e PercVariacao.
 Ordene por NomeVendedor e AnoVenda.

***********************************************************************************************************************/

;WITH CTE_VendasAnuais AS (
    SELECT
        CONCAT(pp.FirstName, ' ', pp.LastName)  AS NomeVendedor,
        YEAR(soh.OrderDate)                      AS AnoVenda,
        SUM(soh.TotalDue)                        AS TotalVendas
    FROM Sales.SalesOrderHeader soh
    INNER JOIN Person.Person pp ON pp.BusinessEntityID = soh.SalesPersonID
    WHERE soh.SalesPersonID IS NOT NULL
    GROUP BY pp.FirstName, pp.LastName, YEAR(soh.OrderDate)
)
SELECT
    NomeVendedor,
    AnoVenda,
    TotalVendas,
    LAG(TotalVendas, 1, 0)  OVER (PARTITION BY NomeVendedor ORDER BY AnoVenda) AS TotalAnoAnterior,
    LEAD(TotalVendas, 1, 0) OVER (PARTITION BY NomeVendedor ORDER BY AnoVenda) AS TotalProximoAno,
    TotalVendas - LAG(TotalVendas, 1, 0) OVER (PARTITION BY NomeVendedor ORDER BY AnoVenda) AS Variacao,
    ((TotalVendas - LAG(TotalVendas, 1, 0) OVER (PARTITION BY NomeVendedor ORDER BY AnoVenda))
        / NULLIF(LAG(TotalVendas, 1, 0) OVER (PARTITION BY NomeVendedor ORDER BY AnoVenda), 0)) * 100 AS PercVariacao
FROM CTE_VendasAnuais
ORDER BY NomeVendedor, AnoVenda;




/***********************************************************************************************************************
 Exercício 4 – FIRST_VALUE e LAST_VALUE: Primeiro e Último Pedido por Cliente

 Escreva uma consulta usando a tabela Sales.SalesOrderHeader com JOIN
 em Person.Person para obter o nome do cliente.

 Para cada pedido, utilize funções de análise para exibir:
   - PrimeiroPedidoData  : FIRST_VALUE de OrderDate por cliente (PARTITION BY CustomerID ORDER BY OrderDate)
   - UltimoPedidoData    : LAST_VALUE  de OrderDate por cliente

 ATENÇÃO: LAST_VALUE requer que o frame da janela seja explicitamente
 definido como ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING,
 caso contrário retornará o valor da linha atual.

 Exiba: NomeCompleto, SalesOrderID, OrderDate, TotalDue,
        PrimeiroPedidoData e UltimoPedidoData.
 Ordene por NomeCompleto e OrderDate.

***********************************************************************************************************************/

SELECT
    CONCAT(pp.FirstName, ' ', pp.LastName)   AS NomeCompleto,
    soh.SalesOrderID,
    soh.OrderDate,
    soh.TotalDue,
    FIRST_VALUE(soh.OrderDate) OVER (
        PARTITION BY soh.CustomerID
        ORDER BY soh.OrderDate
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    )                                         AS PrimeiroPedidoData,
    LAST_VALUE(soh.OrderDate)  OVER (
        PARTITION BY soh.CustomerID
        ORDER BY soh.OrderDate
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    )                                         AS UltimoPedidoData
FROM Sales.SalesOrderHeader soh
INNER JOIN Person.Person pp ON pp.BusinessEntityID = soh.CustomerID
ORDER BY NomeCompleto, soh.OrderDate;



/***********************************************************************************************************************
 Exercício 5 – SUM com OVER: Participação Percentual de Cada Território no Total de Vendas

 Escreva uma consulta usando a tabela Sales.SalesOrderHeader com JOIN
 em Sales.SalesTerritory para obter o nome do território.

 Para cada pedido, calcule:
   - TotalTerritorio : SUM(TotalDue) OVER (PARTITION BY TerritoryID) — total do território
   - TotalGeral      : SUM(TotalDue) OVER ()                         — total geral sem partição
   - PercNoTerritorio: participação do pedido no total do território  (TotalDue / TotalTerritorio * 100)
   - PercNoTotal     : participação do território no total geral      (TotalTerritorio / TotalGeral * 100)

 Exiba: Territorio, SalesOrderID, OrderDate, TotalDue,
        TotalTerritorio, TotalGeral, PercNoTerritorio e PercNoTotal.
 Ordene por Territorio e TotalDue DESC.

***********************************************************************************************************************/

SELECT
    st.Name                                                                AS Territorio,
    soh.SalesOrderID,
    soh.OrderDate,
    soh.TotalDue,
    SUM(soh.TotalDue) OVER (PARTITION BY soh.TerritoryID)                 AS TotalTerritorio,
    SUM(soh.TotalDue) OVER ()                                             AS TotalGeral,
    (soh.TotalDue
        / SUM(soh.TotalDue) OVER (PARTITION BY soh.TerritoryID)) * 100   AS PercNoTerritorio,
    (SUM(soh.TotalDue) OVER (PARTITION BY soh.TerritoryID)
        / SUM(soh.TotalDue) OVER ()) * 100                                AS PercNoTotal
FROM Sales.SalesOrderHeader soh
INNER JOIN Sales.SalesTerritory st ON st.TerritoryID = soh.TerritoryID
ORDER BY Territorio, soh.TotalDue DESC;


