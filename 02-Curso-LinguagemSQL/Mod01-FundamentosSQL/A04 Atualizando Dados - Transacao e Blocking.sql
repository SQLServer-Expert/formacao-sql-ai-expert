/********************************************************************************************************************
 Autor: Landry Duailibe

 Hands On:
 - Tratamento de erro em Transações
 - Blocking

*********************************************************************************************************************/
use Aula
go

-- Cria Tabela para demonstração Snapshot Isolation Level
DROP TABLE IF exists Funcionario
go
CREATE TABLE Funcionario (PK int primary key, Nome varchar(50), Descricao varchar(100), [Status] char(1),Salario decimal(10,2))
INSERT Funcionario VALUES (1,'Fernando','Gerente','B',5600.00)
INSERT Funcionario VALUES (2,'Ana Maria','Diretor','A',7500.00)
INSERT Funcionario VALUES (3,'Marina','Gerente','B',5600.00)
INSERT Funcionario VALUES (4,'Pedro','Operacional','C',2600.00)
INSERT Funcionario VALUES (5,'Carlos','Diretor','A',7500.00)
INSERT Funcionario VALUES (6,'Carol','Operacional','C',2600.00)
INSERT Funcionario VALUES (7,'Luana','Operacional','C',2600.00)
INSERT Funcionario VALUES (8,'Paula','Diretor','A',7500.00)
INSERT Funcionario VALUES (9,'Erick','Operacional','C',2600.00)
INSERT Funcionario VALUES (10,'Joana','Operacional','C',2600.00)
go

/*************************************
 Transacao SEM tratamento de erro
**************************************/ 
SELECT * FROM Funcionario WHERE PK in (8,9,10)
SELECT @@TRANCOUNT

BEGIN TRAN
	UPDATE Funcionario SET Salario = 3000.00 WHERE PK = 8 -- 7500.00
	INSERT Funcionario VALUES (10,'Joana','Operacional','C',2600.00) -- ERRO PK
COMMIT
/*
Msg 2627, Level 14, State 1, Line 34
Violation of PRIMARY KEY constraint 'PK__TB_Trans__32150787A70B2D30'. Cannot insert duplicate key in object 'dbo.Funcionario'. The duplicate key value is (10).
The statement has been terminated.
*/

/*************************************
 Transacao COM tratamento de erro
**************************************/ 
SELECT * FROM Funcionario WHERE PK in (8,9,10)

BEGIN TRY
	BEGIN TRAN
		UPDATE Funcionario SET Salario = 9000.00 WHERE PK = 8 -- 3000.00
		INSERT Funcionario VALUES (10,'Joana','Operacional','C',2600.00) --ERRO PK
	COMMIT
END TRY
BEGIN CATCH
	SELECT ERROR_NUMBER(),ERROR_MESSAGE()
	IF @@trancount > 0
	    	ROLLBACK
END CATCH
go


/****************************************************************************************
 Blocking
  - Escrita bloqueia Leitura
  - Leitura Suja
*****************************************************************************************/

/******************
 Conexão 1
*******************/
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

BEGIN TRAN
  UPDATE Funcionario SET Salario = 3000.00 WHERE PK = 10
  SELECT * FROM Funcionario WHERE PK = 10 -- Salario = 2600.00

ROLLBACK

/******************
 Conexão 2
*******************/
SELECT * FROM Aula.dbo.Funcionario -- with (nolock)
WHERE PK = 10 -- Salario = 3000.00


/******************
 Conexão 3
*******************/
-- SQL Server Versões 7.0 e 2000
exec sp_who2
exec sp_lock 53
exec sp_lock 54
DBCC INPUTBUFFER (53)
DBCC INPUTBUFFER (54)


-- SQL Server a partir 2008
SELECT * FROM sys.dm_exec_connections

-- Processos de usuário abertos
SELECT * FROM sys.dm_exec_sessions WHERE session_id > 50

-- Em execução
SELECT * FROM sys.dm_exec_requests WHERE session_id > 50 and session_id <> @@spid


/**************************
 Consulta de Blocking
***************************/
SELECT spid as SPID, blocked, waittime/1000 as TempoEspera_Seg, blocked as SPID_Blocking,
db_name(sp.dbid) Banco,isnull(hostname,'N/A') Computador,
case when sp.nt_domain is null or sp.nt_domain = '' then 'N/A' else rtrim(sp.nt_domain) + '/' + nt_username end as UsuarioWindows, loginame as LoginSQL, 
s.program_name as Aplicacao, 

s.client_interface_name as AppInterface,
open_tran as QtdTransacoes, cmd as TipoComando, last_batch as UltimoTSQL,qt.text as InstrucaoTSQL, 'N' as Email
,qt.encrypted

FROM sys.sysprocesses sp 
LEFT JOIN sys.dm_exec_sessions s ON s.session_id = sp.spid
OUTER APPLY sys.dm_exec_sql_text(sp.sql_handle) AS qt
WHERE spid > 50


/**********************
 Exclui tabela
***********************/
DROP TABLE IF exists Funcionario
