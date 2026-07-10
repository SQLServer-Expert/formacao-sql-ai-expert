/*************************************************************************************************************************************
 Autor: Landry Duailibe

 Hands On Tipo de Dados Data e Hora:
 - Tipos de dados: datetime, date, time, datetime2, datetimeoffset
 - DATEADD (datepart , number , date )
 - DATEDIFF ( datepart , startdate , enddate )
 - SET DATEFORMAT { format | @format_var }
 - CONVERT ( data_type [ ( length ) ] , expression [ , style ] )
 - FORMAT( value, format [, culture ] )

   https://learn.microsoft.com/en-us/sql/t-sql/functions/date-and-time-data-types-and-functions-transact-sql?view=sql-server-ver16
**************************************************************************************************************************************/
use Aula
go

/*********************************************************
 Datetime
 - 1753-01-01 a 9999-12-31 precisão de 3.33 milisegundos

 SmallDatetime
 - 1900-01-01 a 2079-06-06 precisão de 1 minute

 Date, Datetime2 e datetimeoffset
 - 0001-01-01 a 9999-12-31 precisão de um dia
*********************************************************/ 
-- DROP TABLE Vendas
CREATE TABLE Vendas (
IDVenda int not null,
DataHoraVenda datetime not null, 
DataVenda date null,
HoraVenda time null,
Cliente char(4000) not null,
TotalVenda decimal(10,2))
go
INSERT Vendas VALUES (1,'20070323 12:59:00.000','20070323','12:59:00.000','Ana',320.00)
INSERT Vendas VALUES (2,'20070315 18:43:00.000','20070315','18:43:00.000','Pedro',120.00)
INSERT Vendas VALUES (3,'20080112','20080112','00:00:00.000','Landry',540.00)
go

SELECT IDVenda, DataHoraVenda, DataVenda, HoraVenda
FROM Vendas
--DROP TABLE Vendas

/*******************
 DATETIME2
********************/
DECLARE @DataHora_datetime datetime
SET @DataHora_datetime = '17000101'
/*
Msg 242, Level 16, State 3, Line 34
The conversion of a varchar data type to a datetime data type resulted in an out-of-range value.
*/

DECLARE @DataHora_date date
SET @DataHora_date = '17000101'
SELECT @DataHora_date

DECLARE @DataHora_datetime2 datetime2(3)
SET @DataHora_datetime2 = '17000101'
SELECT @DataHora_datetime2

-- Precisão hora
DECLARE @DataHora3 datetime2(3)
SET @DataHora3 = '2004-02-27 16:14:00.1234567'
SELECT [datetime2(3)] = @DataHora3
-- 2004-02-27 16:14:00.123

DECLARE @DataHora7 datetime2(7)
SET @DataHora7 = '2004-02-27 16:14:00.1234567'
SELECT [datetime2(7)] = @DataHora7
-- 2004-02-27 16:14:00.1234567


/*******************
 DATETIMEOFFSET
********************/
DECLARE @dt datetimeoffset(0)
SET @dt = '20080415 22:00:00 -3:00' -- Brasilia
-- 2008-04-15 22:00:00 -03:00
 
DECLARE @dt1 datetimeoffset(0)
SET @dt1 = '20080415 22:00:00 +9:00' -- Tokio
-- 2008-04-15 22:00:00 +09:00

SELECT @dt,@dt1,DATEDIFF(hh,@dt,@Dt1) 'Diferença Fuso Brasilia e Tokio -12'

/**************************************************************************************************
 DATEADD (datepart , number , date ) 
 https://learn.microsoft.com/pt-br/sql/t-sql/functions/dateadd-transact-sql?view=sql-server-ver16
***************************************************************************************************/
SELECT IDVenda, DataHoraVenda, 
dateadd(yy,-2,DataHoraVenda) as Menos_2anos,
dateadd(mm,3,DataHoraVenda) as Mais_3meses,
dateadd(dd,20,DataHoraVenda) as Mais_20dias
FROM Vendas

/**************************************************************************************************
 DATEDIFF ( datepart , startdate , enddate )  
 https://learn.microsoft.com/en-us/sql/t-sql/functions/datediff-transact-sql?view=sql-server-ver16
***************************************************************************************************/
DECLARE @Data_Venda datetime = '20180510'
DECLARE @Data_Entrega datetime = '20180621'

SELECT datediff(day,@Data_Venda,@Data_Entrega) as Dif_Dias,
datediff(month,@Data_Venda,@Data_Entrega) as Dif_Mes


/********************************************************************************************************
 SET DATEFORMAT { format | @format_var }  
 - mdy, dmy, ymd, ydm, myd, and dym
 https://learn.microsoft.com/en-us/sql/t-sql/statements/set-dateformat-transact-sql?view=sql-server-ver16
********************************************************************************************************/
-- Padrão mdy
DECLARE @Teste1 date = '20/12/2018'
SELECT @Teste1
/*
Msg 241, Level 16, State 1, Line 92
Conversion failed when converting date and/or time from character string.
*/

DECLARE @Teste2 date = '12/20/2018'
SELECT @Teste2
go

-- Troca para dmy
SET DATEFORMAT dmy

DECLARE @Teste1 date = '20/12/2018'
SELECT @Teste1

DECLARE @Teste2 date = '12/20/2018'
SELECT @Teste2
/*
Msg 241, Level 16, State 1, Line 92
Conversion failed when converting date and/or time from character string.
*/

DECLARE @Teste3 date = '20231218' -- ANSI sempre funciona ymd
SELECT @Teste3
go

-- Retorna para o padrão
SET DATEFORMAT mdy

/***********************************************************************************************************
 CONVERT ( data_type [ ( length ) ] , expression [ , style ] )
 https://learn.microsoft.com/en-us/sql/t-sql/functions/cast-and-convert-transact-sql?view=sql-server-ver16
************************************************************************************************************/

SELECT IDVenda, DataHoraVenda, 
convert(varchar(20),DataHoraVenda,112), -- yyyymmdd
convert(varchar(20),DataHoraVenda,103), -- dd/mm/yyyy
convert(varchar(20),DataHoraVenda,108), -- hh:mi:ss
convert(varchar(30),DataHoraVenda,131)  -- dd/mm/yyyy hh:mi:ss:mmmAM
FROM Vendas

/**************************************************************************************************
 FORMAT( value, format [, culture ] ) 
 - Disponível a partir do SQL Server 2016
 https://learn.microsoft.com/en-us/sql/t-sql/functions/format-transact-sql?view=sql-server-ver16
***************************************************************************************************/
SELECT IDVenda, DataHoraVenda, 
format(DataHoraVenda,'d','pt-br'),
format(DataHoraVenda,'dd-MM-yyyy','pt-br')
FROM Vendas
-- 2007-03-03 12:00:00.000

/*******************
 Exclui Tabelas
********************/
DROP TABLE Vendas


