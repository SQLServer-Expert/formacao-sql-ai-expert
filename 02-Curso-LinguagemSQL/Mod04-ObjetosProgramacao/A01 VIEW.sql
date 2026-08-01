/*******************************************************************************************************
 Autor: Landry D. Salles Filho
 
 VIEW
 https://learn.microsoft.com/pt-br/sql/t-sql/statements/create-view-transact-sql?view=sql-server-ver16
********************************************************************************************************/
use AdventureWorksLT
go

CREATE or ALTER VIEW SalesLT.vw_CustomerOrders
AS
SELECT C.CustomerID, O.OrderDate, O.SubTotal, O.TotalDue 
FROM SalesLT.Customer AS C
JOIN SalesLT.SalesOrderHeader as O ON C.CustomerID =O.CustomerID
go


SELECT * FROM SalesLT.vw_CustomerOrders

SELECT * FROM SalesLT.vw_CustomerOrders
ORDER BY TotalDue Desc

-- Acessado a definição original da View
SELECT OBJECT_DEFINITION(OBJECT_ID('SalesLT.vw_CustomerOrders','V'))

EXEC sp_helptext 'SalesLT.vw_CustomerOrders'

-- Criptografando a View
go
ALTER VIEW SalesLT.vw_CustomerOrders
WITH ENCRYPTION
AS
SELECT C.CustomerID, O.OrderDate, O.SubTotal, O.TotalDue 
FROM SalesLT.Customer AS C
JOIN SalesLT.SalesOrderHeader as O ON C.CustomerID =O.CustomerID
go

-- Não retorna nada, devido ao WITH ENCRYPTION
SELECT OBJECT_DEFINITION(OBJECT_ID(N'SalesLT.vw_CustomerOrders',N'V'))

-- No Object Explorer não aparece para gerar script de CREATE

-- Exclui a View
DROP VIEW SalesLT.vw_CustomerOrders
go

/**********************************************
 Atualizando dados através de uma View
***********************************************/
use Aula
go

-- DROP TABLE Cliente
CREATE TABLE Cliente (
ClienteID int not null primary key,
Nome varchar(50) not null,
Telefone varchar(20) null,
Ativo char(1) null default 'S')
go

INSERT Cliente VALUES 
(1,'Jose','2234-5466','S'),
(2,'Ana','1445-4788','S'),
(3,'Paula','2543-1166','S'),
(4,'Antonio','3234-5766','S'),
(5,'Marcos','9934-5466','S'),
(6,'Carla','3545-4788','S'),
(7,'Patricia','9943-1166','N'),
(8,'Artur','9934-5766','N')
go

-- Cria View filtrando apenas clientes Ativo = 'S'
CREATE VIEW vw_Cliente
AS
SELECT ClienteID, Nome, Telefone, Ativo
FROM Cliente
WHERE Ativo = 'S'
go

SELECT * FROM vw_Cliente

-- Inclui cliente novo Ativo = 'N'
INSERT vw_Cliente VALUES (9,'Luana','99456-5466','N')

-- Cliente novo não aparece na View
SELECT * FROM vw_Cliente
SELECT * FROM Cliente

-- Altera a View acrescentando WITH CHECK OPTION
go
CREATE OR ALTER VIEW vw_Cliente
AS
SELECT ClienteID, Nome, Telefone, Ativo
FROM Cliente
WHERE Ativo = 'S'
WITH CHECK OPTION
go

INSERT vw_Cliente VALUES (10,'Laura','33546-5466','N')
/*
Msg 550, Level 16, State 1, Line 98
The attempted insert or update failed because the target view either specifies WITH CHECK OPTION or spans a view 
that specifies WITH CHECK OPTION and one or more rows resulting from the operation did not qualify under the CHECK OPTION constraint.
*/

SELECT * FROM vw_Cliente
SELECT * FROM Cliente


-- Exclui objetos
DROP VIEW vw_Cliente
DROP TABLE Cliente

