/*******************************
 Autor: Landry Duailibe
 
 Hands On: JOIN
********************************/
use Aula
go

-- Cria duas tabelas para Hands On
DROP TABLE IF exists dbo.Vendedor
go
DROP TABLE IF exists dbo.Venda
go
CREATE TABLE dbo.Vendedor (VendedorId int, Vendedor varchar(100))
CREATE TABLE dbo.Venda (VendaID int, VendedorID int, ProdutoID int, Qtd int, Valor decimal(10,2))
go

INSERT dbo.Vendedor VALUES (1,'Jose')
INSERT dbo.Vendedor VALUES (2,'Pedro')
INSERT dbo.Vendedor VALUES (3,'Lucia')
INSERT dbo.Vendedor VALUES (4,'Ana')
go
INSERT dbo.Venda VALUES (100,1,10,5,1000.00)
INSERT dbo.Venda VALUES (101,5,20,3,1500.00)
INSERT dbo.Venda VALUES (101,6,30,2,2500.00)
go


SELECT * FROM dbo.Vendedor 
SELECT * FROM dbo.Venda

SELECT * FROM dbo.Vendedor a JOIN dbo.Venda b on a.VendedorId = b.VendedorID
SELECT * FROM dbo.Vendedor a LEFT JOIN dbo.Venda b on a.VendedorId = b.VendedorID
SELECT * FROM dbo.Vendedor a RIGHT JOIN dbo.Venda b on a.VendedorId = b.VendedorID
SELECT * FROM dbo.Vendedor a FULL JOIN dbo.Venda b on a.VendedorId = b.VendedorID


/**************
 CROSS JOIN 
***************/
DROP TABLE IF exists Campeonato
go
CREATE TABLE Campeonato (Grupo char(1), Time varchar(30))
go
INSERT Campeonato VALUES ('A','Flamengo')
INSERT Campeonato VALUES ('A','Vasco')
INSERT Campeonato VALUES ('A','América')
INSERT Campeonato VALUES ('A','Boavista')
INSERT Campeonato VALUES ('A','Volta Redonda')
INSERT Campeonato VALUES ('A','Nova Iguaçu')
INSERT Campeonato VALUES ('A','Americano')
INSERT Campeonato VALUES ('A','Resende')
go
INSERT Campeonato VALUES ('B','Botafogo')
INSERT Campeonato VALUES ('B','Fluminense')
INSERT Campeonato VALUES ('B','Bangu')
INSERT Campeonato VALUES ('B','Olaria')
INSERT Campeonato VALUES ('B','Madureira')
INSERT Campeonato VALUES ('B','Cabofriense')
INSERT Campeonato VALUES ('B','Macaé')
INSERT Campeonato VALUES ('B','Duque de Caxias')
go

SELECT * FROM Campeonato ORDER BY Grupo

-- Jogos Grupo A
SELECT c1.Time Casa, c2.Time Visitante
FROM Campeonato c1 CROSS JOIN  Campeonato c2
WHERE c1.Time <> c2.Time and c1.Grupo = 'A' and c2.Grupo = 'A'

-- Jogos Grupo B
SELECT c1.Time Casa, c2.Time Visitante
FROM Campeonato c1 CROSS JOIN  Campeonato c2
WHERE c1.Time <> c2.Time and c1.Grupo = 'B' and c2.Grupo = 'B'

/*********************
 Apaga tabelas
**********************/
DROP TABLE IF exists Campeonato
DROP TABLE IF exists dbo.Vendedor
DROP TABLE IF exists dbo.Venda
go

