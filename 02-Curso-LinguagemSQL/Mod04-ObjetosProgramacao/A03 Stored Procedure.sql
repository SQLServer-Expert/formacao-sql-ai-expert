/************************************************************************************************************
 Autor: Landry D. Salles Filho
 
 Stored Procedure
 - CREATE, DROP, ALTER
 https://learn.microsoft.com/en-us/sql/t-sql/statements/create-procedure-transact-sql?view=sql-server-ver16
**************************************************************************************************************/
use Aula
go

/**************************
 Cria tabelas
***************************/
IF object_id('dbo.SalesOrderHeader') is not null
   DROP TABLE dbo.SalesOrderHeader

SELECT SalesOrderID, RevisionNumber, 
(DATEADD(day, ROUND(DATEDIFF(day, OrderDate, OrderDate) 
* RAND(CHECKSUM(NEWID())), 5),DATEADD(second, abs(CHECKSUM(NEWID())) % 86400, 
OrderDate))) as OrderDate, 
DueDate, ShipDate, 
Status, OnlineOrderFlag, replace(SalesOrderNumber,'SO','') as SalesOrderNumber, cast(PurchaseOrderNumber as nchar(3000)) as PurchaseOrderNumber, 
AccountNumber, CustomerID, SubTotal, TaxAmt, Freight, TotalDue, Comment, ModifiedDate, cast(0 as bit) as FlagDelete
INTO dbo.SalesOrderHeader
FROM AdventureWorksLT.SalesLT.SalesOrderHeader
go

IF object_id('dbo.SalesOrderDetail') is not null
   DROP TABLE dbo.SalesOrderDetail

SELECT SalesOrderID, SalesOrderDetailID, OrderQty, ProductID, 
UnitPrice, UnitPriceDiscount, LineTotal, rowguid, ModifiedDate, cast(0 as bit) as FlagDelete 
INTO dbo.SalesOrderDetail
FROM AdventureWorksLT.SalesLT.SalesOrderDetail
go
/************************ FIM Cria Tabelas *****************************/


/***********************************************
 Coluna para exclusão lógica "FlagDelete"
***********************************************/
SELECT * FROM dbo.SalesOrderHeader
SELECT * FROM dbo.SalesOrderDetail

/******************************************************
 Stored Procedure para exclusão lógica de uma compra
*******************************************************/
go
CREATE or ALTER PROC dbo.spu_DropOrder
@SalesOrderID int 
as
SET NOCOUNT ON

UPDATE dbo.SalesOrderHeader SET FlagDelete = 1 
WHERE SalesOrderID = @SalesOrderID

UPDATE dbo.SalesOrderDetail SET FlagDelete = 1 
WHERE SalesOrderID = @SalesOrderID
go

-- Exclusão lógica da compra 71780
SELECT * FROM dbo.SalesOrderHeader WHERE SalesOrderID = 71780
SELECT * FROM dbo.SalesOrderDetail WHERE SalesOrderID = 71780

-- Executando a Stored procedure "dbo.spu_DropOrder"
EXEC dbo.spu_DropOrder @SalesOrderID = 71780


/******************************************************
 Stored Procedure para exclusão lógica de uma compra,
 com transação e tratamento de erro
*******************************************************/
go
CREATE or ALTER PROC dbo.spu_DropOrder
@SalesOrderID int 
as
SET NOCOUNT ON

BEGIN TRY
	BEGIN TRAN
		UPDATE dbo.SalesOrderHeader SET FlagDelete = 1 
		WHERE SalesOrderID = @SalesOrderID

		UPDATE dbo.SalesOrderDetail SET FlagDelete = 1 -- 'a' 
		WHERE SalesOrderID = @SalesOrderID
    COMMIT
	--RETURN 0
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK
	
	PRINT 'Erro na atualização: ' + ERROR_MESSAGE()
	--RETURN 1
END CATCH
go

-- Exclusão lógica da compra 71776
SELECT * FROM dbo.SalesOrderHeader WHERE SalesOrderID = 71776
SELECT * FROM dbo.SalesOrderDetail WHERE SalesOrderID = 71776

-- Executando a Stored procedure "dbo.spu_DropOrder"
DECLARE @Retorno int
EXEC @Retorno = dbo.spu_DropOrder @SalesOrderID = 71776
SELECT @Retorno

/********************************
 Criptografando SPs
*********************************/
go
CREATE or ALTER PROC dbo.spu_DropOrder
@SalesOrderID int 
WITH ENCRYPTION
as
SET NOCOUNT ON

BEGIN TRY
	BEGIN TRAN
		UPDATE dbo.SalesOrderHeader SET FlagDelete = 1 
		WHERE SalesOrderID = @SalesOrderID

		UPDATE dbo.SalesOrderDetail SET FlagDelete = 1
		WHERE SalesOrderID = @SalesOrderID
    COMMIT
	RETURN 0
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK
	
	PRINT 'Erro na atualização: ' + ERROR_MESSAGE()
	RETURN 1
END CATCH
go

EXEC sp_helptext 'dbo.spu_DropOrder'

-- Exclui Stored Procedure
DROP PROC dbo.spu_DropOrder

/**************************************************************************************************************
 EXECUTE AS
 { EXEC | EXECUTE } AS { CALLER | SELF | OWNER | 'user_name' }
 - CALLER: quem está executando a Stored Procedure
 - SELF: quem criou (CREATE) ou alterou (ALTER) a Stored Procedure
 - OWNER: dono da Stored Procedure
 https://learn.microsoft.com/en-us/sql/t-sql/statements/execute-as-clause-transact-sql?view=sql-server-ver16
**************************************************************************************************************/

-- CALLER
go
CREATE or ALTER PROC spu_Contexto
WITH EXECUTE AS CALLER
as
SET NOCOUNT ON

SELECT USER_NAME()
go

EXEC spu_Contexto
-- dbo

-- Cria Usuário para teste
CREATE USER TesteSP WITHOUT LOGIN

-- Atribui permissão na SP
GRANT EXECUTE ON dbo.spu_Contexto TO TesteSP

-- Troca o contexto da conexão para o usuário "TesteSP"
EXECUTE AS User = 'TesteSP'

EXEC spu_Contexto
-- TesteSP

-- Retorna o contexto da conexão para DBO
REVERT

-- CALLER
go
CREATE or ALTER PROC spu_Contexto
WITH EXECUTE AS SELF
as
SET NOCOUNT ON

SELECT USER_NAME()
go

EXEC spu_Contexto
-- dbo

-- Troca o contexto da conexão para o usuário "TesteSP"
EXECUTE AS User = 'TesteSP'

EXEC spu_Contexto
-- dbo

-- Retorna o contexto da conexão para DBO
REVERT

/********************
 Exclui Objetos
*********************/
DROP USER TesteSP
DROP PROC dbo.spu_Contexto
DROP TABLE dbo.SalesOrderHeader
DROP TABLE dbo.SalesOrderDetail
