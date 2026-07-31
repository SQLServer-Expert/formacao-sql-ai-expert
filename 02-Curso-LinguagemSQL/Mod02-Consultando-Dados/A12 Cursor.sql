/*******************************************************************************************************************
 Curso T-SQL
 Autor: Landry

 Demonstração:
 - Cursor
 https://learn.microsoft.com/pt-br/sql/t-sql/language-elements/declare-cursor-transact-sql?view=sql-server-ver16
********************************************************************************************************************/
use Aula
go

/***************************************
 Cria tabelas para demonstração
****************************************/
IF object_id('dbo.SalesOrderDetail ') is not null
   DROP TABLE dbo.SalesOrderDetail 

SELECT * INTO dbo.SalesOrderDetail
FROM AdventureWorksLT.SalesLT.SalesOrderDetail
go

SELECT b.ListPrice,a.*
FROM dbo.SalesOrderDetail a
JOIN AdventureWorksLT.SalesLT.Product b on b.ProductID = a.ProductID
JOIN AdventureWorksLT.SalesLT.ProductModel c on c.ProductModelID = b.ProductModelID
WHERE c.Name = 'Touring-3000'
ORDER BY a.SalesOrderID, a.SalesOrderDetailID
/*
SalesOrderID = 71782 | ProductID = 959 | ListPrice = 742.35 | UnitPrice = 445.41 | UnitPriceDiscount = 0 | LineTotal = 1781.640000
                                                                          816.585                                      3266.340000
*/

/*************************************
 Uso do Cursor em aplicações: EVITAR
**************************************/
DECLARE @ProductID int
DECLARE @ListPrice money
DECLARE @ProductModelID int 

DECLARE cursor_product CURSOR
FOR SELECT ProductID, ProductModelID, ListPrice
    FROM AdventureWorksLT.SalesLT.Product

OPEN cursor_product

FETCH NEXT FROM cursor_product INTO @ProductID, @ProductModelID, @ListPrice
 
WHILE @@FETCH_STATUS = 0 BEGIN
	
	-- Verifica se o modelo do produto corrente é "Touring-3000"
	IF exists (SELECT * FROM AdventureWorksLT.SalesLT.ProductModel WHERE [Name] = 'Touring-3000' and ProductModelID = @ProductModelID)
	BEGIN
		-- Aumenta o Valor unitário do Produto em todas as vendas em 10%
		UPDATE dbo.SalesOrderDetail SET UnitPrice = @ListPrice * 1.1,
		LineTotal = (OrderQty * (@ListPrice * 1.1)) - UnitPriceDiscount
		WHERE ProductID = @ProductID
	END
    
	FETCH NEXT FROM cursor_product INTO @ProductID, @ProductModelID, @ListPrice

END
CLOSE cursor_product
DEALLOCATE cursor_product
go

/*********************************
 Reescrevendo o Cursor com JOINs
**********************************/
UPDATE a SET a.UnitPrice = b.ListPrice * 1.1,
a.LineTotal = (a.OrderQty * (b.ListPrice * 1.1)) - a.UnitPriceDiscount
FROM dbo.SalesOrderDetail a
JOIN AdventureWorksLT.SalesLT.Product b on b.ProductID = a.ProductID
JOIN AdventureWorksLT.SalesLT.ProductModel c on c.ProductModelID = b.ProductModelID
WHERE c.Name = 'Touring-3000'


/**************************************
 Uso na Administração do SQL Server
***************************************/

DECLARE @Caminho varchar(4000), @Banco varchar(500), @Arquivo varchar(4000)
DECLARE @state_desc varchar(200)
SET @Caminho = 'C:\Backup\FULL\' 
SET NOCOUNT ON

IF object_id('tempdb..#tmpBancosBackupFULL') is not null DROP TABLE #tmpBancosBackupFULL

SELECT db_name(database_id) as name,state_desc 
INTO #tmpBancosBackupFULL 
FROM sys.databases 
WHERE source_database_id is null
and state_desc = 'ONLINE'
and name not in ('tempdb','model') 

DECLARE vCursor CURSOR FOR
SELECT name,state_desc FROM #tmpBancosBackupFULL ORDER BY name

OPEN vCursor
FETCH NEXT FROM vCursor INTO @Banco, @state_desc
WHILE @@FETCH_STATUS = 0
BEGIN

   PRINT 'Backup do Banco de Dados: ' + @Banco 
   set @Arquivo = @Banco + '_' + convert(char(8),getdate(),112) + '_H' + replace(convert(char(8),getdate(),108),':','')

   EXEC('BACKUP DATABASE [' + @Banco + ']  TO DISK = ''' + @Caminho + @Arquivo + '.bak'' WITH FORMAT, COMPRESSION')

   IF @@ERROR <> 0 BEGIN
      PRINT '*** ERRO: backup do banco ' + @Banco + ' - Código de erro: ' + ltrim(str(@@error))
      FETCH NEXT FROM vCursor INTO @Banco, @state_desc
      CONTINUE
   END   
   FETCH NEXT FROM vCursor INTO @Banco, @state_desc
end
CLOSE vCursor
DEALLOCATE vCursor
IF object_id('tempdb..#tmpBancosBackupFULL') is not null DROP TABLE #tmpBancosBackupFULL
go









