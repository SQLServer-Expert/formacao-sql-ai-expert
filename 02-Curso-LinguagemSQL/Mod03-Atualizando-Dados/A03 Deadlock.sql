/*************************************************************************************************************
 Data: 08/12/2001
 Autor: Landry Duailibe Salles Filho
 Ver: 2.0

 - Deadlock
 https://learn.microsoft.com/en-us/sql/relational-databases/sql-server-deadlocks-guide?view=sql-server-ver16
**************************************************************************************************************/
use Aula
go

if object_id('Funcionario') is not null
   DROP TABLE Funcionario
go
CREATE TABLE Funcionario (PK int Primary key, Nome varchar(50), Descricao varchar(100), Status char(1),Salario decimal(10,2))
INSERT Funcionario VALUES (1,'Fernando','Gerente','B',5600.00)
INSERT Funcionario VALUES (2,'Ana Maria','Diretor','A',7500.00)
INSERT Funcionario VALUES (3,'Lucia','Gerente','B',5600.00)
INSERT Funcionario VALUES (4,'Pedro','Operacional','C',2600.00)
INSERT Funcionario VALUES (5,'Carlos','Diretor','A',7500.00)
INSERT Funcionario VALUES (6,'Carol','Operacional','C',2600.00)
INSERT Funcionario VALUES (7,'Luana','Operacional','C',2600.00)
INSERT Funcionario VALUES (8,'Lula','Diretor','A',7500.00)
INSERT Funcionario VALUES (9,'Erick','Operacional','C',2600.00)
INSERT Funcionario VALUES (10,'Joana','Operacional','C',2600.00)
go

/* Deadlock - A*/
SET DEADLOCK_PRIORITY normal

BEGIN TRAN

  -- PK = 1
  UPDATE Funcionario SET Nome = 'Fernando 1' WHERE PK = 1

  WAITFOR DELAY '00:00:10'

  -- PK = 2
  UPDATE Funcionario SET Nome = 'Ana Maria 2' WHERE PK = 2

ROLLBACK TRAN



/* Deadlock - B*/
SET DEADLOCK_PRIORITY low

BEGIN TRAN

  -- PK = 2
  UPDATE Funcionario SET Nome = 'Ana Maria 2' WHERE PK = 2

  -- PK = 1
  UPDATE Funcionario SET Nome = 'Fernando 1' WHERE PK = 1

ROLLBACK TRAN


/*************************************************
 Alteração para não ocorrer Deadlock
**************************************************/
/* Deadlock - A*/
SET DEADLOCK_PRIORITY normal

BEGIN TRAN

  -- PK = 1
  UPDATE Funcionario SET Nome = 'Fernando 1' WHERE PK = 1

  WAITFOR DELAY '00:00:10'

  -- PK = 2
  UPDATE Funcionario SET Nome = 'Ana Maria 2' WHERE PK = 2

ROLLBACK TRAN



/* Deadlock - B*/
SET DEADLOCK_PRIORITY low

BEGIN TRAN

  -- PK = 1
  UPDATE Funcionario SET Nome = 'Fernando 1' WHERE PK = 1

  -- PK = 2
  UPDATE Funcionario SET Nome = 'Ana Maria 2' WHERE PK = 2

ROLLBACK TRAN

