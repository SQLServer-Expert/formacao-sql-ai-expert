/*************************************************
 Curso T-SQL
 Autor: Landry

 Demonstração:
 - Mensagens de erros de sistema e SYS.MESSAGES
 - TRY...CATCH
 - RAISERROR
 - THROW
*************************************************/
use Aula
go


SELECT * FROM master.sys.messages

SELECT distinct severity FROM master.sys.messages ORDER BY 1

/********************************************************************************************************************************
 https://learn.microsoft.com/en-us/sql/relational-databases/errors-events/database-engine-error-severities?view=sql-server-ver16

 <= 16   - Mensagens informativas
 17      - Operações que esgotam recursos do SQL Server, por exemplo esgotou espaço em disco ou tempo de blocking
 18 e 19 - Erros não fatais, não ocorre desconexão com o servidor 
 20 a 24 - Erros fatais!
*********************************************************************************************************************************/

/****************************************
 Tratamento de erro TRY...CATCH
*****************************************/
BEGIN TRY
	SELECT 10/0 as 'Provoca erro de divisão por zero.'
END TRY
BEGIN CATCH
	print ltrim(str(error_number())) + ' - ' + error_message()
END CATCH
go

/***********************************************************************************************************
 Tratamento de erro TRY...CATCH
 - RAISERROR
 https://learn.microsoft.com/en-us/sql/t-sql/language-elements/raiserror-transact-sql?view=sql-server-ver16
************************************************************************************************************/
BEGIN TRY
	SELECT 10/0 as 'Provoca erro de divisão por zero.'
END TRY
BEGIN CATCH
	DECLARE @Banco nvarchar(200)
	SET @Banco = db_name()
	RAISERROR (N'Erro de divisão por zero no Banco de Dados %s', 10, 1,@Banco)
END CATCH
go

/***********************************************************************************************************
 Tratamento de erro TRY...CATCH
 - THROW
 https://learn.microsoft.com/pt-br/sql/t-sql/language-elements/throw-transact-sql?view=sql-server-ver16
************************************************************************************************************/

-- Sem parâmetro repassa erro original
BEGIN TRY
	SELECT 10/0 as 'Provoca erro de divisão por zero.'
END TRY
BEGIN CATCH
	THROW
END CATCH
go

-- Com parâmetro retorna erro específico
BEGIN TRY
	SELECT 10/0 as 'Provoca erro de divisão por zero.'
END TRY
BEGIN CATCH
	DECLARE @Erro nvarchar(200)
	SET @Erro = N'Erro de divisão por zero no Banco de Dados ' + db_name()
	;THROW 51000, @Erro, 1
END CATCH







