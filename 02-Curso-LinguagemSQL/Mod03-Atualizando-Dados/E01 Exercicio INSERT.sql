/*************************************************
 Curso T-SQL
 Autor: Landry

 Módulo 4 - Exercício 1
 - INSERT
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
/************************************************
 Exercício 1 - INSERT
**************************************************/

-- Item 3
-- DROP TABLE Cliente
CREATE TABLE Cliente (
ClienteID int not null identity primary key, 
Nome varchar(50) null, 
Telefone varchar(30) null)
go

-- Item 4
INSERT Cliente (Nome,Telefone)
VALUES ('Anderson Silva','(21) 2238-4432')
go

SELECT * FROM Cliente

-- Item 5
INSERT Cliente (Nome,Telefone) VALUES
('Paula Souza','(21) 3845-6635'),
('Luana Carvalho','(11) 3556-6698'),
('Luciano Melo','(71) 4885-2213')
go

SELECT * FROM Cliente

-- Item 6
INSERT Cliente (Nome,Telefone)
OUTPUT inserted.ClienteID
VALUES ('André Cunha','(82) 3876-2123')
go

-- Item 7.1
SELECT a.FirstName + ' ' + a.LastName as Nome, b.PhoneNumber as Telefone
FROM AdventureWorks.Person.Person a
JOIN AdventureWorks.Person.PersonPhone b on b.BusinessEntityID = a.BusinessEntityID
WHERE a.PersonType = 'GC'
ORDER BY Nome

-- Item 7.2
INSERT Cliente (Nome,Telefone)
SELECT a.FirstName + ' ' + a.LastName as Nome, b.PhoneNumber as Telefone
FROM AdventureWorks.Person.Person a
JOIN AdventureWorks.Person.PersonPhone b on b.BusinessEntityID = a.BusinessEntityID
WHERE a.PersonType = 'GC'
ORDER BY Nome

SELECT count(*) as QtdLinhas FROM Cliente

