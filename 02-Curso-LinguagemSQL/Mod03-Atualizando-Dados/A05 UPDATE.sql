/**********************************************************************************************
 Curso T-SQL
 Autor: Landry

 Demonstração:
 - Sintaxe UPDATE
 - UPDATE com OUTPUT
 - UPDATE com JOIN

 https://learn.microsoft.com/pt-br/sql/t-sql/queries/update-transact-sql?view=sql-server-ver16
***********************************************************************************************/
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
 Sintaxe UPDATE
****************************************/
SELECT * FROM Cliente

UPDATE Cliente SET Bairro = 'Ipanema', Credito = 'C'
WHERE Nome = 'Paula'

BEGIN TRAN
	UPDATE Cliente SET Bairro = 'Leblon'
	SELECT * FROM Cliente
ROLLBACK

/**********************
 UPDATE com OUTPUT
***********************/
UPDATE Cliente SET Bairro = 'Leme'
OUTPUT inserted.Nome, inserted.Bairro as Bairro_Novo, deleted.Bairro as Bairro_Anterior
WHERE Nome = 'Bruna'

/**********************
 UPDATE com JOIN
***********************/
SELECT * FROM Cliente
SELECT * FROM Vendas

-- Alterar o Credito para "B" dos Cliente que nao compraram
UPDATE c SET Credito = 'B'
FROM Cliente c 
LEFT JOIN Vendas v on c.ClienteID = v.ClienteID
WHERE v.VendaID is null
 
UPDATE c SET Credito = 'B'
FROM Cliente c 
where not exists (SELECT * FROM Vendas v WHERE c.ClienteID = v.ClienteID)
 
 -- Apaga as tabelas
DROP TABLE dbo.Cliente
DROP TABLE dbo.Vendas
