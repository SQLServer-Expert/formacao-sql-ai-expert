/*********************************************************************************************
 Autor: Landry Duailibe

 Hands On Tipos de Dados Numéricos: 
   - int, bigint, smallint, tinyint
   - decimal, numeric
   - money smallmoney
   - float, real
   - bit

   https://learn.microsoft.com/en-us/sql/t-sql/data-types/numeric-types?view=sql-server-ver16
***********************************************************************************************/
use Aula
go

/**************************************************************
 Inteiros
 - bigint	(8 bytes inteiro de -9223372036854775808 a 9223372036854775807)
 - int		(4 bytes inteiro de -2147483648 a 2147483647)
 - smallint	(2 bytes inteiro de -32768 a 32767)
 - tinyint	(1 byte inteiro  de 0 a 255)

 https://learn.microsoft.com/en-us/sql/t-sql/data-types/int-bigint-smallint-and-tinyint-transact-sql?view=sql-server-ver16
***************************************************************/
DECLARE @Teste1 int = 2147483647
DECLARE @Teste2 smallint = 32767
DECLARE @Teste3 tinyint = 255
SELECT @Teste1, @Teste2, @Teste3
go

DECLARE @Teste1 int = 2147483647
SELECT @Teste1 + 1
/*
Msg 8115, Level 16, State 2, Line 32
Arithmetic overflow error converting expression to data type int.
*/
go

/**************************************************************************************************************
 decimal e numeric (sinônimo de decimal)
 decimal[ (p[ ,s] )]
 numeric[ (p[ ,s] )]

 Precisão	Armazenamento (bytes)
 --------------------------------
  1 - 9			5
  10-19			9
  20-28			13
  29-38			17
 --------------------------------
 https://learn.microsoft.com/en-us/sql/t-sql/data-types/decimal-and-numeric-transact-sql?view=sql-server-ver16
***************************************************************************************************************/
-- decimal(12,4) = 99999999.9999
DECLARE @Teste1 decimal(12,4) = 2300.2445
DECLARE @Teste2 numeric(12,4) = 2300.2445
SELECT @Teste1, @Teste2
go

-- Arredonda se ultrapassar as casas decimais
DECLARE @Teste1 decimal(12,4) = 2300.244569
SELECT @Teste1
-- 2300.244569 -> 2300.2446
go

/**************************************************************************************************************
 money      -922337203685477.5808 a 922337203685477.5807
 smallmoney -214748.3648 a 214748.3647

 https://learn.microsoft.com/en-us/sql/t-sql/data-types/money-and-smallmoney-transact-sql?view=sql-server-ver16
***************************************************************************************************************/
-- Máximo de precisão 4 casas decimais
DECLARE @Teste1 money = 2300.244567
DECLARE @Teste2 smallmoney = 2300.244567
SELECT @Teste1, @Teste2
-- 2300.244567 -> 2300.2446
go

/***********************************************************************************************
 bit 1 (TRUE) ou 0 (FALSE)
 https://learn.microsoft.com/en-us/sql/t-sql/data-types/bit-transact-sql?view=sql-server-ver16
************************************************************************************************/
DECLARE @Teste1 bit = 1
DECLARE @Teste2 char(5) = 'FALSE'
SELECT @Teste1, cast(@Teste2 as bit), cast('TRUE' as bit)
go

/*************************************************************************************************************
 Numéricos aproximados
 float [ (n) ] - default 53 (quantidade de Bits)
 real

 https://learn.microsoft.com/en-us/sql/t-sql/data-types/float-and-real-transact-sql?view=sql-server-ver16
**************************************************************************************************************/
DECLARE @Teste1 float(25) = 10.12345678901234567891
DECLARE @Teste2 real = 10.12345678901234567891
SELECT @Teste1, @Teste2
go

/***************************************************************
 CUIDADO: não é preciso quando utiliza operador de comparação
          pois o SQL Server armazena uma aproximação do número!
****************************************************************/
DECLARE @Teste1 float = 0.1
DECLARE @Teste2 float = 0.2

SELECT CASE WHEN @Teste1 + @Teste2 = 0.3 THEN 1 ELSE 0 END
go

-- Com DECIMAL funciona
DECLARE @Teste1 decimal(10,1) = 0.1
DECLARE @Teste2 decimal(10,1) = 0.2

SELECT CASE WHEN @Teste1 + @Teste2 = 0.3 THEN 1 ELSE 0 END
go

