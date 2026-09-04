/***********************************************************************************************************************
 Curso T-SQL
 Autor: Landry

 Demonstração:
 - Common Table Expression (CTE)
 - CTE recursivo

 https://learn.microsoft.com/pt-br/sql/t-sql/queries/with-common-table-expression-transact-sql?view=sql-server-ver16
************************************************************************************************************************/
use Aula
go

/**********************************************
 Cria Tabelas Funcionario e Cargo
***********************************************/
-- DROP TABLE Cargo
CREATE TABLE Cargo (
CargoID int not null primary key, 
Descricao Varchar(40) not null, 
Orcamento decimal(10,2) null)
go

INSERT Cargo VALUES (1,'Presidente',30000.00)
INSERT Cargo VALUES (2,'Diretor',30000.00)
INSERT Cargo VALUES (3,'Gerente',40000.00)
INSERT Cargo VALUES (4,'Supervisor',30000.00)
go


-- DROP TABLE Funcionario
CREATE TABLE Funcionario (
FuncionarioID int not null primary key, 
Nome Varchar(50) not null, 
CargoID int not null, 
Chefe int null, 
Salario decimal(10,2) null)
go
ALTER TABLE Funcionario ADD CONSTRAINT fk_Funcionario_Cargo
FOREIGN KEY (CargoID) REFERENCES Cargo (CargoID)
go

-- Presidente
INSERT Funcionario VALUES (1,'Fernando',1,NULL,25000.00)
-- Diretor
INSERT Funcionario VALUES (2,'Ana Maria',2,1,15000.00)
INSERT Funcionario VALUES (3,'Lucia',2,1,14000.00)
-- Gerente
INSERT Funcionario VALUES (4,'Pedro',3,2,7000.00)
INSERT Funcionario VALUES (5,'Maria',3,2,7000.00)
INSERT Funcionario VALUES (6,'Luana',3,3,6500.00)
INSERT Funcionario VALUES (7,'Erick',3,3,6500.00)
-- Supervisor
INSERT Funcionario VALUES (8,'Fernanda',4,4,3200.00)
INSERT Funcionario VALUES (9,'Marcelo',4,5,3400.00)
INSERT Funcionario VALUES (10,'Joaquim',4,6,3000.00)
INSERT Funcionario VALUES (11,'Manoel',4,7,2900.00)
go

SELECT * FROM Cargo
SELECT * FROM Funcionario


/**********************************************************************************
 Subconsulta 
***********************************************************************************/
select c.Descricao,c.Orcamento,g.SalarioTotal,
(g.SalarioTotal/c.Orcamento)*100 '%Comprometido'
from Cargo c JOIN 
(SELECT CargoID, SUM(Salario) as SalarioTotal 
FROM Funcionario GROUP BY CargoID) as g 
on c.CargoID = g.CargoID

/**********************************************************************************
 Tabela Temporaria 
***********************************************************************************/
SELECT CargoID, SUM(Salario) as SalarioTotal 
INTO #TabTMP
FROM Funcionario GROUP BY CargoID

SELECT c.Descricao,c.Orcamento,g.SalarioTotal,
(g.SalarioTotal/c.Orcamento)*100 '%Comprometido'
FROM Cargo c JOIN #TabTMP g on c.CargoID = g.CargoID

DROP TABLE #TabTMP


/*********************************
 CTE - Common Table Expressions 
**********************************/
;WITH GrpSalario as
(SELECT CargoID, SUM(Salario) as SalarioTotal FROM Funcionario GROUP BY CargoID)

SELECT c.Descricao,c.Orcamento,g.SalarioTotal,
(g.SalarioTotal/c.Orcamento)*100 '%Comprometido'
FROM Cargo c JOIN GrpSalario g on c.CargoID = g.CargoID


/**********************
 CTE recursivo
***********************/
SELECT * FROM Funcionario

;WITH Organograma AS
(SELECT FuncionarioID, Nome, Chefe FROM Funcionario WHERE Chefe IS NULL --PK = 2
 UNION ALL
 SELECT f.FuncionarioID, f.Nome, f.Chefe FROM Funcionario f 
 JOIN Organograma o ON f.Chefe = o.FuncionarioID)

SELECT * FROM Organograma

-- Exclui tabelas
DROP TABLE Funcionario
DROP TABLE Cargo
