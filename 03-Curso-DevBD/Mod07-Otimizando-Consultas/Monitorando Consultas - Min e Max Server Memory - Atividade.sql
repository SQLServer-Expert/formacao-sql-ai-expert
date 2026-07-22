/**************************************
 Demonstração
 Autor: Landry Duailibe

 - Max e Min Server Memory
***************************************/

/********************** Gera atividade *****************************/
use AdventureWorks
go

-- DROP PROC spu_Stress_Memory
CREATE or ALTER PROC spu_Stress_Memory
@i int = 100
as

DECLARE @TabTemp table (
SalesOrderID int NOT NULL,
OrderQty smallint NOT NULL,
OrderDate datetime NOT NULL,
Description char(1000) NULL,
StartDate datetime NOT NULL,
EndDate datetime NOT NULL)

DECLARE @Contador int = 1
WHILE @Contador <= @i BEGIN
	INSERT @TabTemp
	SELECT d.SalesOrderID, d.OrderQty, h.OrderDate, cast(o.Description as char(1000)) as Description, o.StartDate, o.EndDate
	FROM Sales.SalesOrderDetail d
	INNER JOIN Sales.SalesOrderHeader h ON d.SalesOrderID = h.SalesOrderID
	INNER JOIN Sales.SpecialOffer o ON d.SpecialOfferID = o.SpecialOfferID
	WHERE d.SpecialOfferID <> 1

	SELECT * FROM @TabTemp

	SET @Contador += 1
END
go

EXEC spu_Stress_Memory @i = 100

/********************** FIM Gera atividade *****************************/

-- Exclui Procedure
DROP PROC spu_Stress_Memory




