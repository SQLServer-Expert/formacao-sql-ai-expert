/*************************************************
 Curso T-SQL
 Autor: Landry

 Módulo 4 - Exercício 3
 - DELETE e MERGE
*************************************************/
use master
go

IF not exists (SELECT * FROM sys.databases WHERE [Name] = 'ExerciciosBD') BEGIN
	CREATE DATABASE ExerciciosBD
	ALTER DATABASE ExerciciosBD SET RECOVERY simple
END
go

use ExerciciosBD
go

/******************************************************************************
 Execute o Script abaixo para criar as tabelas necessárias para este exercício
*******************************************************************************/
IF object_id('Cliente') is not null
	DROP TABLE Cliente
go

CREATE TABLE Cliente (
ClienteID int not null identity primary key, 
Nome varchar(50) null, 
Telefone varchar(30) null,
Pais varchar(100) null)
go

INSERT Cliente (Nome,Telefone,Pais) VALUES
('Anderson Silva','(21) 2238-4432','Brasil'),
('Paula Souza','(21) 3845-6635','Brasil'),
('Luana Carvalho','(11) 3556-6698','Brasil'),
('Luciano Melo','(71) 4885-2213','Brasil'),
('André Cunha','(82) 3876-2123','Brasil')
go
INSERT Cliente (Nome,Telefone,Pais)
SELECT a.FirstName + ' ' + a.LastName as Nome, b.PhoneNumber as Telefone,
'USA' as Pais
FROM AdventureWorks.Person.Person a
JOIN AdventureWorks.Person.PersonPhone b on b.BusinessEntityID = a.BusinessEntityID
WHERE a.PersonType = 'GC'
ORDER BY Nome
go

IF object_id('Itens_Origem') is not null
	DROP TABLE Itens_Origem
go
CREATE TABLE Itens_Origem (
ItensID int not null primary key,
Descricao varchar(50) not null,
Valor_Unitario decimal(10,2) null)
go

INSERT Itens_Origem (ItensID,Descricao,Valor_Unitario) VALUES
(1,'Mouse sem fio', 120.10),
(2,'Microfone USB', 250.20),
(3,'Caixa de som Bluetooth', 425.00),
(4,'Webcam Full HD', 380.90),
(5,'Hub USB 4 portas', 68.10)
go

IF object_id('Itens_Destino') is not null
	DROP TABLE Itens_Destino
go
CREATE TABLE Itens_Destino (
ItensID int not null primary key,
Descricao varchar(50) not null,
Valor_Unitario decimal(10,2) null)
go

INSERT Itens_Destino (ItensID,Descricao,Valor_Unitario) VALUES
(1,'Mouse sem fio', 120.10),
(2,'Microfone USB', 300.00),
(5,'Hub USB 4 portas', 68.10)
go

/************************************************
 Exercício 1 - UPDATE
**************************************************/

-- Item 3
SELECT * FROM Cliente WHERE Telefone like '(21)%'

DELETE Cliente WHERE Telefone like '(21)%'

-- Item 4
SELECT * FROM Cliente WHERE Nome like 'Amy%'

DELETE Cliente 
OUTPUT deleted.*
WHERE Nome like 'Amy%'

/************************************************
 Exercício 2 - MERGE
**************************************************/

-- Item 1
SELECT * FROM Itens_Origem ORDER BY ItensID
SELECT * FROM Itens_Destino ORDER BY ItensID

-- Item 2
MERGE Itens_Destino t 
USING Itens_Origem s 
ON (s.ItensID = t.ItensID)
WHEN MATCHED AND (t.Descricao <> s.Descricao OR t.Valor_Unitario <> s.Valor_Unitario) 
	THEN UPDATE SET t.Descricao = s.Descricao,
			   t.Valor_Unitario = s.Valor_Unitario
WHEN NOT MATCHED BY TARGET THEN 
	INSERT (ItensID, Descricao, Valor_Unitario)
	VALUES (s.ItensID, s.Descricao, s.Valor_Unitario)
WHEN NOT MATCHED BY SOURCE THEN DELETE
OUTPUT $action as Operacao, Inserted.ItensID as ItensID_Novo, Deleted.ItensID as ItensID_Anterior,
Inserted.Descricao,Inserted.Valor_Unitario;

-- Item 3
SELECT * FROM Itens_Origem ORDER BY ItensID
SELECT * FROM Itens_Destino ORDER BY ItensID
