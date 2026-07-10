/***************************************************************************
 Autor: Landry Duailibe

 Hands On Tipo de Dados String:
 - Diferença entre VARCHAR/NVARCHAR e CHAR/NCHAR
 - Funções para manipulação de Strings
***************************************************************************/
use Aula
go

/************************
 String CHAR e VARCHAR
*************************/ 
DROP TABLE IF exists Produto
go
CREATE TABLE Produto (
ProdutoID int not null,
Produto_Varchar varchar(50) null,
Produto_Char char(50) null,
Valor_Unitario decimal(10,2) null)
go

INSERT Produto VALUES (1,'Monitor LCD 21"','Monitor LCD 21"', 780.00)

SELECT ProdutoID, Produto_Varchar,Produto_Char
FROM Produto
-- Monitor LCD 21"
-- Monitor LCD 21"                                   

/**************************************************************************************************************
 Funções String
 https://learn.microsoft.com/en-us/sql/t-sql/functions/string-functions-transact-sql?view=sql-server-ver16
***************************************************************************************************************/

/***************************************************
 LEFT ( character_expression , integer_expression ) 
 RIGHT ( character_expression , integer_expression )
 SUBSTRING ( expression ,start , length )
****************************************************/
DECLARE @Produto varchar(50) = 'Impressora HP Jato de Tinta'

SELECT @Produto, left(@Produto,3), right(@Produto,5), substring(@Produto,12,2)

/****************************************
 Funções que removem espaço em branco:
 LTRIM ( character_expression )
 RTRIM ( character_expression )
 TRIM ( [ characters FROM ] string )
*****************************************/
DECLARE @Nome varchar(50) = '    Landry    '
DECLARE @Sobrenome varchar(50) = '    Duailibe Salles'

SELECT @Nome + ' ' + @Sobrenome, trim(@Nome) + ' ' + ltrim(@Sobrenome)


/**************
 Exclui Tabela
***************/
DROP TABLE Produto
