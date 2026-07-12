/*******************************************
 Autor: Landry Duailibe
 
 Hands On: Segurança de linha
********************************************/
use Aula
go

-- Cria tabela Pedidos
DROP TABLE IF exists dbo.Pedidos
go
CREATE TABLE dbo.Pedidos (
Pedido_ID int not null identity primary key,
Item_ID int,
Item_COD varchar(10),
DataPedido datetime,
Qtd int,
Vendedor_COD Varchar(10))           
go
 
INSERT dbo.Pedidos VALUES (101,'AXP Inc','2015-08-11 00:34:51:090',1789,'LAX')
INSERT dbo.Pedidos VALUES (102,'VFG Inc','2014-01-08 19:44:51:090',767,'AURA')
INSERT dbo.Pedidos VALUES (103,'ZAD Inc','2015-08-19 19:44:51:090',500,'ZAP')
INSERT dbo.Pedidos VALUES (102,'VFG Inc','2014-08-19 19:44:51:090',1099,'ZAP')
INSERT dbo.Pedidos VALUES (101,'AXP Inc','2014-08-04 19:44:51:090',654,'LAX')
INSERT dbo.Pedidos VALUES (103,'ZAD Inc','2015-08-10 19:44:51:090',498,'LAX')
INSERT dbo.Pedidos VALUES (102,'VFG Inc','2015-04-17 19:44:51:090',999,'LAX')
INSERT dbo.Pedidos VALUES (101,'AXP Inc','2015-08-21 19:44:51:090',543,'AURA')
INSERT dbo.Pedidos VALUES (103,'ZAD Inc','2015-08-06 19:44:51:090',876,'LAX')
INSERT dbo.Pedidos VALUES (102,'VFG Inc','2015-08-26 19:44:51:090',665,'AURA')
go

-- Cria usuários para teste
CREATE USER LAX WITHOUT LOGIN
CREATE USER AURA WITHOUT LOGIN
CREATE USER ZAP WITHOUT LOGIN
go

-- Atribui permissão SELECT para os usuários
GRANT SELECT,INSERT,UPDATE,DELETE ON dbo.Pedidos TO LAX
GRANT SELECT,INSERT,UPDATE,DELETE ON dbo.Pedidos TO AURA
GRANT SELECT,INSERT,UPDATE,DELETE ON dbo.Pedidos TO ZAP
go

-- Cria função de filtro
CREATE FUNCTION fn_Security_Pedidos (@Vendedor sysname)
RETURNS table
WITH SCHEMABINDING
as
RETURN SELECT 1 as [fn_Security_Pedidos_Result] FROM dbo.Pedidos
WHERE @Vendedor = user_name() or user_name() = 'DBO'
go

-- Cria regra de segurança associada a fulção de filtro
CREATE SECURITY POLICY sec_Security_Pedidos
ADD FILTER PREDICATE dbo.fn_Security_Pedidos(Vendedor_COD) ON dbo.Pedidos
WITH (STATE = ON)
go

/***************************
 Teste SELECT
****************************/
SELECT * FROM dbo.Pedidos -- 10 linhas

EXECUTE AS USER = 'LAX'
SELECT * FROM dbo.Pedidos -- 5 linhas
REVERT

EXECUTE AS USER = 'AURA'
SELECT * FROM dbo.Pedidos -- 3 linhas
REVERT

EXECUTE AS USER = 'ZAP'
SELECT * FROM dbo.Pedidos -- 2 linhas

INSERT dbo.Pedidos VALUES (102,'VFG Inc','2017-01-08 19:44:51:090',110,'AURA')

SELECT * FROM dbo.Pedidos -- permanecem 2 linhas

REVERT

EXECUTE AS USER = 'AURA'
SELECT * FROM dbo.Pedidos -- 4 linhas
REVERT


-- Cria regra de segurança associada a função de filtro
ALTER SECURITY POLICY sec_Security_Pedidos
ADD BLOCK PREDICATE dbo.fn_Security_Pedidos(Vendedor_COD) ON dbo.Pedidos AFTER INSERT,
ADD BLOCK PREDICATE dbo.fn_Security_Pedidos(Vendedor_COD) ON dbo.Pedidos AFTER UPDATE
go


EXECUTE AS USER = 'ZAP'

SELECT * FROM dbo.Pedidos -- 2 linhas

INSERT dbo.Pedidos VALUES (102,'VFG Inc','2017-02-08 19:44:51:090',220,'ZAP')

SELECT * FROM dbo.Pedidos -- 3 linhas

-- Erro INSERT
INSERT dbo.Pedidos VALUES (102,'VFG Inc','2017-02-08 19:44:51:090',220,'AURA')

-- Erro UPDATE
UPDATE dbo.Pedidos SET Vendedor_COD = 'LAX' WHERE Pedido_ID = 12

REVERT


-- Desligando Row Level Security
ALTER SECURITY POLICY sec_Security_Pedidos WITH (STATE = OFF)
go

-- Excluindo Row Level Security
DROP SECURITY POLICY sec_Security_Pedidos
DROP FUNCTION dbo.fn_Security_Pedidos 
DROP TABLE IF exists dbo.Pedidos
DROP USER LAX
DROP USER AURA
DROP USER ZAP
go



