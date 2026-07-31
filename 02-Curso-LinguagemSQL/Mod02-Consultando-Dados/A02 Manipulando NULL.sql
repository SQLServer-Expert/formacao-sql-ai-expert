/*************************************************
 Curso T-SQL
 Autor: Landry

 Demonstração:
 - Comparando NULL
 - ISNULL()
 - NULLIF()
 - COALESCE()
*************************************************/
use AdventureWorksLT
go

/********************************************************
 Comparando NULL
 - Não pode utilizar operador de comparação com NULL
 - Utilizar IS NULL ou IS NOT NULL
*********************************************************/
-- Muitas linhas com NULL na coluna Color
SELECT ProductID, [Name], Color
FROM SalesLT.Product
ORDER BY Color

-- Não pode utilizar operador de comparação com NULL
SELECT ProductID, [Name], Color
FROM SalesLT.Product
WHERE Color = null
ORDER BY Color
-- Zero linhas

-- Retorna todos os Produtos com NULL na coluna Color
SELECT ProductID, [Name], Color
FROM SalesLT.Product
WHERE Color is null
ORDER BY Color

-- Retorna todos os Produtos com valores na coluna Color
SELECT ProductID, [Name], Color
FROM SalesLT.Product
WHERE Color is not null
ORDER BY Color

/**************************************************************************************************
  Função ISNULL()
  - Sintaxe: ISNULL ( check_expression , replacement_value )
  - Testa a 1a expressão se for NULL, retorna a 2a expressão, senão retorna a 1a expressão
  https://learn.microsoft.com/en-us/sql/t-sql/functions/isnull-transact-sql?view=sql-server-ver16
***************************************************************************************************/
-- Troca NULL por outro valor
SELECT ProductID, [Name], isnull(Color,'') as Color
FROM SalesLT.Product
ORDER BY Color

/**********************************************************************************************************
  Função NULLIF()
  - Sintaxe: NULLIF ( expression , expression )
  - Retorna NULL se as duas expressões forem iguais, e a 1a expressão se forem diferentes
  https://learn.microsoft.com/pt-br/sql/t-sql/language-elements/nullif-transact-sql?view=sql-server-ver16
***********************************************************************************************************/
SELECT nullif(10, 10) -- NULL
SELECT nullif(10, 15) -- 10

-- Quantidade de produtos com cores diferente de "Black"
SELECT count(*) as Qtd_Color_Black 
FROM SalesLT.Product WHERE Color <> 'Black'
-- 156

-- Reescrevendo com NULLIF()
SELECT count(nullif(Color,'Black')) as Qtd_Color_Black
FROM SalesLT.Product
-- 156

-- Reescrevendo com CASE
SELECT count(case when Color <> 'Black' then 1 else null end) as Qtd_Color_Black
FROM SalesLT.Product
-- 156

/**********************************************************************************************************
 Função COALESCE()
 - Sintaxe: COALESCE ( expression [ ,...n ] )
 - Testa cada expressão retornando o valor da 1a que for diferente de NULL
 https://learn.microsoft.com/en-us/sql/t-sql/language-elements/coalesce-transact-sql?view=sql-server-ver16
***********************************************************************************************************/
use Aula
go

-- Propriedade IDENTITY auto numeração
-- DROP TABLE Salarios
CREATE TABLE Salarios (
Funcionario_ID int identity,
Qtd_Horas decimal(9,2) null,
Salario decimal(9,2) null,
Comissao decimal(9,2) null,
Qtd_Vendas int null)
go

INSERT Salarios VALUES(10.00, NULL, NULL, NULL)
INSERT Salarios VALUES(20.00, NULL, NULL, NULL)
INSERT Salarios VALUES(30.00, NULL, NULL, NULL)
INSERT Salarios VALUES(40.00, NULL, NULL, NULL)
INSERT Salarios VALUES(NULL, 10000.00, NULL, NULL)
INSERT Salarios VALUES(NULL, 20000.00, NULL, NULL)
INSERT Salarios VALUES(NULL, 30000.00, NULL, NULL)
INSERT Salarios VALUES(NULL, 40000.00, NULL, NULL)
INSERT Salarios VALUES(NULL, NULL, 15000, 3)
INSERT Salarios VALUES(NULL, NULL, 25000, 2)
INSERT Salarios VALUES(NULL, NULL, 20000, 6)
INSERT Salarios VALUES(NULL, NULL, 14000, 4)
go

-- Consulta com COALESCE e CASE
SELECT Funcionario_ID, Qtd_Horas, Salario, Comissao, Qtd_Vendas, 

CAST(COALESCE(Qtd_Horas * 40 * 52,  Salario, Comissao * Qtd_Vendas) as decimal(9,2)) as Salario_Coalesce,

CASE
WHEN Qtd_Horas is not null THEN Qtd_Horas * 40 * 52
WHEN Salario is not null THEN Salario
WHEN Comissao is not null THEN Comissao * Qtd_Vendas
END as Salario_Case

FROM Salarios

-- Exclui tabelas
DROP TABLE Salarios
