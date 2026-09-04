/*************************************************
 Curso T-SQL
 Autor: Landry

 Módulo 4 - Exercício 2
 - UPDATE
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

/****************************************************************
 Se não completou o exercício de INSERT ou  se a tabela Cliente 
 não existe mais na TEMPDB execute o Script abaixo
*****************************************************************/
IF object_id('Cliente') is not null
	DROP TABLE Cliente
go

CREATE TABLE Cliente (
ClienteID int not null identity primary key, 
Nome varchar(50) null, 
Telefone varchar(30) null)
go

INSERT Cliente (Nome,Telefone) VALUES
('Anderson Silva','(21) 2238-4432'),
('Paula Souza','(21) 3845-6635'),
('Luana Carvalho','(11) 3556-6698'),
('Luciano Melo','(71) 4885-2213'),
('André Cunha','(82) 3876-2123')
go
INSERT Cliente (Nome,Telefone)
SELECT a.FirstName + ' ' + a.LastName as Nome, b.PhoneNumber as Telefone
FROM AdventureWorks.Person.Person a
JOIN AdventureWorks.Person.PersonPhone b on b.BusinessEntityID = a.BusinessEntityID
WHERE a.PersonType = 'GC'
ORDER BY Nome
go

/************************************************
 Exercício 1 - UPDATE
**************************************************/

-- Item 3
UPDATE Cliente SET Telefone = '(54) 4560-9987' WHERE ClienteId = 4

SELECT * FROM Cliente WHERE ClienteId = 4

-- Item 4
ALTER TABLE CLIENTE ADD Pais varchar(100) null

-- Item 4.1
SELECT * FROM Cliente WHERE Telefone like '(%'

UPDATE Cliente SET Pais = 'Brasil' 
OUTPUT inserted.Nome, inserted.Pais as Pais_Alterado, deleted.Pais as Pais_Anterior
WHERE Telefone like '(%'

-- Item 4.2
UPDATE Cliente SET Pais = 'EUA' WHERE Pais is null

-- Item 4.3
SELECT Pais, count(*) as QtdLinhas
FROM Cliente
GROUP BY Pais
ORDER BY Pais
