/********************************************************************************************************************
 Curso T-SQL
 Autor: Landry

 Demonstração:
 - Tratamento de erro em Transações
 - XACT_ABORT
 - Blocking

 https://learn.microsoft.com/en-us/sql/t-sql/language-elements/transactions-transact-sql?view=sql-server-ver16
 https://learn.microsoft.com/pt-br/sql/t-sql/language-elements/begin-transaction-transact-sql?view=sql-server-ver16
*********************************************************************************************************************/
use Aula
go

-- Cria Tabela para demonstração Snapshot Isolation Level
if object_id('Funcionario') is not null
   drop table Funcionario
go
create table Funcionario (PK int primary key, Nome varchar(50), Descricao varchar(100), Status char(1),Salario decimal(10,2))
insert Funcionario values (1,'Fernando','Gerente','B',5600.00)
insert Funcionario values (2,'Ana Maria','Diretor','A',7500.00)
insert Funcionario values (3,'Lucia','Gerente','B',5600.00)
insert Funcionario values (4,'Pedro','Operacional','C',2600.00)
insert Funcionario values (5,'Carlos','Diretor','A',7500.00)
insert Funcionario values (6,'Carol','Operacional','C',2600.00)
insert Funcionario values (7,'Luana','Operacional','C',2600.00)
insert Funcionario values (8,'Lula','Diretor','A',7500.00)
insert Funcionario values (9,'Erick','Operacional','C',2600.00)
insert Funcionario values (10,'Joana','Operacional','C',2600.00)
go

/*************************************
 Transacao SEM tratamento de erro
**************************************/ 
select * from Funcionario where PK in (9,10)
select @@TRANCOUNT

begin tran
	update Funcionario set Salario = 3000.00 where PK = 9 -- 2600.00
	insert Funcionario values (10,'Joana','Operacional','C',2600.00) -- ERRO PK
commit
/*
Msg 2627, Level 14, State 1, Line 34
Violation of PRIMARY KEY constraint 'PK__TB_Trans__32150787A70B2D30'. Cannot insert duplicate key in object 'dbo.Funcionario'. The duplicate key value is (10).
The statement has been terminated.
*/


/***********************************************************************************************************
 Transacao XACT_ABORT
 https://learn.microsoft.com/en-us/sql/t-sql/statements/set-xact-abort-transact-sql?view=sql-server-ver16
************************************************************************************************************/ 
select * from Funcionario where PK in (9,10)
select @@TRANCOUNT

SET XACT_ABORT ON
begin tran
	update Funcionario set Salario = 8500.00 where PK = 9 -- 3000.00
	insert Funcionario values (10,'Joana','Operacional','C',2600.00) --ERRO PK
commit
SET XACT_ABORT OFF


/*************************************
 Transacao COM tratamento de erro
**************************************/ 
select * from Funcionario where PK in (8,10)

begin try
	begin tran
		update Funcionario set Salario = 9000.00 where PK = 8 -- 7500.00
		insert Funcionario values (10,'Joana','Operacional','C',2600.00) --ERRO PK
	commit
end try
begin catch
	select ERROR_NUMBER(),ERROR_MESSAGE()
	if @@trancount > 0
	    	rollback
end catch
go


/****************************************************************************************
 Demonstração 1: READ_COMMITTED padrão
  
  - Leitura bloqueia escrita.
*****************************************************************************************/
-- *** Conexão A ***
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
begin tran
  update Funcionario set Salario = 3000.00 where PK = 10
  select * from Funcionario where PK = 10 -- Salario = 2600.00

rollback

-- *** Conexão B ***
select * from Aula.dbo.Funcionario where PK = 10 -- Salario = 3000.00

-- *** Conexão C ***
-- SQL 2000
exec sp_who2
exec sp_lock 53
exec sp_lock 54
DBCC INPUTBUFFER (53)
DBCC INPUTBUFFER (54)

-- SQL 2008
-- SP_WHO no SQL 2000
select * from sys.dm_exec_connections

-- Processos de usuário abertos
select * from sys.dm_exec_sessions where session_id > 50

-- Em execução
select * from sys.dm_exec_requests where session_id > 50 and session_id <> @@spid

-- Para pegar a instrução
-- Parâmetro coluna sql_handle do sys.dm_exec_requests e 
SELECT * FROM sys.dm_exec_sql_text(0x02000000B5BB8A0D52DAE74382B9972DFC292A98C6A63128);
SELECT * FROM sys.dm_exec_sql_text(0x02000000D0AF75072F185FB122718D72499D4E69233FD990);


