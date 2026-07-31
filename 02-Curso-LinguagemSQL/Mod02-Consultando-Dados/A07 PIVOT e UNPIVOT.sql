/*************************************************
 Curso T-SQL
 Autor: Landry

 Demonstração:
 - PIVOT
 - UNPIVOT
*************************************************/
use Aula
go

/********************************************************************************************************
 PIVOT e UNPIVOT
 https://learn.microsoft.com/en-us/sql/t-sql/queries/from-using-pivot-and-unpivot?view=sql-server-ver16
*********************************************************************************************************/
if OBJECT_ID('Vendas') is not null
   DROP TABLE Vendas
go
CREATE TABLE Vendas (Cliente VARCHAR(25), Produto VARCHAR(20), Qtd INT)
go
INSERT Vendas(Cliente, Produto, Qtd) VALUES('ANA','CERVEJA',2)
INSERT Vendas(Cliente, Produto, Qtd) VALUES('ANA','SODA',6)
INSERT Vendas(Cliente, Produto, Qtd) VALUES('ANA','LEITE',1)
INSERT Vendas(Cliente, Produto, Qtd) VALUES('ANA','SUCO',12)
INSERT Vendas(Cliente, Produto, Qtd) VALUES('FRED','LEITE',3)
INSERT Vendas(Cliente, Produto, Qtd) VALUES('FRED','SUCO',24)
INSERT Vendas(Cliente, Produto, Qtd) VALUES('ANA','CERVEJA',3)
go
SELECT * FROM Vendas

-- PIVOT coluna Cliente
SELECT * FROM Vendas order by Cliente,Produto
go
SELECT Produto, FRED, ANA
FROM (SELECT Cliente, Produto, Qtd FROM Vendas) s
PIVOT (SUM(Qtd) FOR Cliente IN (FRED, ANA)) AS p
ORDER BY Produto

/***************************************
 PIVOT dinâmico SQL 2017 ou posterior
 Função STRING_AGG
 - Concatena strings com separador
 https://learn.microsoft.com/en-us/sql/t-sql/functions/string-agg-transact-sql?view=sql-server-ver16
****************************************/
DECLARE @Prod varchar(50)
SELECT @Prod = string_agg(isnull(Cliente, ' '), ',') FROM (SELECT distinct Cliente FROM Vendas) a
--SELECT @Prod

DECLARE @Comando varchar(5000)

SET @Comando = 'SELECT Produto,' + @Prod +
' FROM (SELECT Cliente, Produto, Qtd FROM Vendas) s
PIVOT (SUM(Qtd) FOR Cliente IN (' + @Prod + ')) AS p
ORDER BY Produto'

EXEC (@Comando)
go

/***************************************
 PIVOT dinâmico até SQL 2016
****************************************/
DECLARE @Prod varchar(50)
SELECT @Prod = coalesce(@Prod + ', ' + Cliente,Cliente) FROM (SELECT distinct Cliente FROM Vendas) a
--SELECT @Prod

DECLARE @Comando varchar(5000)

SET @Comando = 'SELECT Produto,' + @Prod +
' FROM (SELECT Cliente, Produto, Qtd FROM Vendas) s
PIVOT (SUM(Qtd) FOR Cliente IN (' + @Prod + ')) AS p
ORDER BY Produto'

EXEC (@Comando)
go


/*****************************
 UNPIVOT
******************************/
SELECT Cliente, Produto, Qtd
FROM

-- Consulta que faz o PIVOT
(SELECT Cliente, CERVEJA, SODA, LEITE, SUCO, CHIPS
FROM (SELECT Cliente, Produto, Qtd FROM Vendas) s
PIVOT (SUM(Qtd) FOR Produto IN (CERVEJA, SODA, LEITE, SUCO, CHIPS)) AS p) pv

UNPIVOT(Qtd FOR Produto IN (CERVEJA, SODA, LEITE, SUCO, CHIPS)) AS Upv


-- Exclui tabelas
DROP TABLE Vendas
