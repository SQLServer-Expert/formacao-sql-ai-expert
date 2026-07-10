/***********************************
 Autor: Landry Duailibe
 
 Hands On: INSERT, UPDATE e DELETE
***********************************/
use Aula
go


/***************************************
 Hands On: INSERT
****************************************/

-- Cria tabelas para Hands On
DROP TABLE IF exists dbo.Clientes 
go
CREATE TABLE Clientes (
ClienteID int not null identity primary key,
Nome varchar(50) not null,
Bairro varchar(40) null,
Sexo char(1) not null default 'M',
Credito char(1) not null default 'A')
go

INSERT Clientes (Nome,Bairro,Sexo,Credito)
VALUES ('Jose','Copacabana','M','A')

SELECT * FROM Clientes

-- DEFAULT
INSERT Clientes (Nome,Bairro)
VALUES ('Maria','Barra da Tijuca')

INSERT Clientes (Nome,Bairro,Sexo)
VALUES ('Paula','Ipanema',DEFAULT)

-- Tabela Temporária LOCAL
SELECT * 
INTO #tmp_Clientes
FROM Clientes

SELECT * FROM #tmp_Clientes

DROP TABLE #tmp_Clientes

-- Tabela Temporária GLOBAL
SELECT * 
INTO ##tmp_Clientes
FROM Clientes

SELECT * FROM ##tmp_Clientes

DROP TABLE ##tmp_Clientes


/***************************
 Hands On: UPDATE
****************************/
UPDATE Clientes SET Sexo = 'F'
WHERE Nome = 'Maria'

UPDATE Clientes SET Bairro = 'Leblon'

-- UPDATE com JOIN
DROP TABLE IF exists dbo.Vendas 
go
CREATE TABLE Vendas (
VendaID int not null identity primary key,
ClienteID int not null,
Vendedor varchar(50) not null,
TotalVenda decimal(10,2) null)
go

TRUNCATE TABLE Clientes

INSERT Clientes (Nome,Bairro,Sexo) VALUES ('Jose','Copacabana','M')
INSERT Clientes (Nome,Bairro,Sexo) VALUES ('Maria','Barra da Tijuca','F')
INSERT Clientes (Nome,Bairro,Sexo) VALUES ('Paula','Ipanema','F')

INSERT Vendas (ClienteID,Vendedor,TotalVenda) VALUES (1,'Paulo',5000.00)
INSERT Vendas (ClienteID,Vendedor,TotalVenda) VALUES (1,'Antonio',10000.00)
INSERT Vendas (ClienteID,Vendedor,TotalVenda) VALUES (2,'Paulo',2000.00)
INSERT Vendas (ClienteID,Vendedor,TotalVenda) VALUES (2,'Antonio',30000.00)

SELECT * FROM Clientes
SELECT * FROM Vendas

-- Alterar o Credito para "B" dos clientes que nao compraram
UPDATE c SET Credito = 'B'
FROM Clientes c LEFT JOIN Vendas v
ON c.ClienteID = v.ClienteID
WHERE v.VendaID is null
 
 
/*************************
 Demonstracao DELETE
**************************/

DELETE Vendas WHERE Vendedor = 'Paulo'

SELECT * FROM Clientes
SELECT * FROM Vendas


-- Excluir Clientes que nao compraram
DELETE c
FROM Clientes c left join Vendas v
ON c.ClienteID = v.ClienteID
WHERE v.VendaID is null
 
/**********************
  Exclui tabelas
************************/
DROP TABLE IF exists dbo.Clientes 
DROP TABLE IF exists dbo.Vendas 
go