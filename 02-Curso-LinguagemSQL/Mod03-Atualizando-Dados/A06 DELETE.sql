/************************************************************************************************************
 Curso T-SQL
 Autor: Landry

 Demonstração:
 - Sintaxe DELETE
 - DELETE com OUTPUT
 - DELETE com JOIN

 https://learn.microsoft.com/en-us/sql/t-sql/statements/delete-transact-sql?view=sql-server-ver16
 https://learn.microsoft.com/pt-br/sql/t-sql/statements/truncate-table-transact-sql?view=sql-server-ver16
*************************************************************************************************************/
use Aula
go

/***************************************
 Cria tabelas para demonstração
****************************************/
IF object_id('dbo.Cliente ') is not null
   DROP TABLE dbo.Cliente 

CREATE TABLE Cliente (
ClienteID int not null identity primary key,
Nome varchar(50) not null,
Bairro varchar(40) null,
Sexo char(1) not null default 'M',
Credito char(1) not null default 'A')
go

INSERT Cliente (Nome,Bairro,Sexo,Credito) VALUES 
('Jose','Copacabana','M','A'),
('Joao','Copacabana','M','A'),
('Paula','Leme','F','B'),
('Luana','Ipanema','F','A'),
('Roberto','Leme','M','A'),
('Ana','Barra da Tijuca','F','B'),
('Bruna','Recreio','F','A')
go

IF object_id('dbo.Vendas ') is not null
   DROP TABLE dbo.Vendas 

CREATE TABLE Vendas (
VendaID int not null identity primary key,
ClienteID int not null,
Vendedor varchar(50) not null,
TotalVenda decimal(10,2) null)
go

INSERT Vendas (ClienteID,Vendedor,TotalVenda) VALUES 
(1,'Paulo',5000.00),
(1,'Antonio',10000.00),
(2,'Paulo',2000.00),
(2,'Antonio',30000.00)
go


/***************************************
 Sintaxe DELETE
****************************************/
SELECT * FROM Cliente

BEGIN TRAN
	DELETE Cliente WHERE Sexo = 'F'
	SELECT * FROM Cliente
ROLLBACK

-- Apaga todas as linhas da tabela Cliente
BEGIN TRAN
	DELETE Cliente
	SELECT * FROM Cliente
ROLLBACK


BEGIN TRAN
	TRUNCATE TABLE Cliente
	SELECT * FROM Cliente
ROLLBACK

SELECT * FROM Cliente

/**********************************
 DELETE com OUTPUT
***********************************/

DELETE Cliente 
OUTPUT deleted.*
WHERE Nome = 'Bruna'

SELECT * FROM Cliente
WHERE Nome = 'Bruna'

/**********************************
 DELETE com JOIN
***********************************/
SELECT c.*
FROM Cliente c 
WHERE not exists (SELECT * FROM Vendas v WHERE c.ClienteID = v.ClienteID)

-- Exclui Clientes que nao compraram
DELETE c
FROM Cliente c 
LEFT JOIN Vendas v on c.ClienteID = v.ClienteID
WHERE v.VendaID is null
 
DELETE c
FROM Cliente c 
WHERE not exists (SELECT * FROM Vendas v WHERE c.ClienteID = v.ClienteID)

-- Apaga as tabelas
DROP TABLE dbo.Cliente
DROP TABLE dbo.Vendas
