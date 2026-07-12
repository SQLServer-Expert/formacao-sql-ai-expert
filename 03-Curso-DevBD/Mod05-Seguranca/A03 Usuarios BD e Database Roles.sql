/******************************************************
 Autor: Landry Duailibe

 Hands On: Usuário de Banco de Dados e Database Roles 
*******************************************************/
use master
go

-- Cria login
CREATE LOGIN Teste WITH PASSWORD = 'Pa$$w0rd'

use Aula
go

-- Cria usuário de banco
CREATE USER Teste FOR LOGIN Teste

-- Verifica se usuário pertence a um role
EXECUTE AS USER = 'Teste'
SELECT is_member('public') AS is_public_member
REVERT
GO

-- Adiciona usuário a dois databases roles
ALTER ROLE db_datareader ADD MEMBER Teste
GO
ALTER ROLE db_ddladmin ADD MEMBER Teste
GO

-- Metadata
SELECT rdp.name AS role_name, rdm.name AS member_name
FROM sys.database_role_members AS rm
JOIN sys.database_principals AS rdp
ON rdp.principal_id = rm.role_principal_id
JOIN sys.database_principals AS rdm
ON rdm.principal_id = rm.member_principal_id
WHERE rdm.name = 'Teste'
ORDER BY role_name, member_name


/*********************************
 Apaga objetos
**********************************/
use Aula
go
DROP USER Teste

use master
go
DROP LOGIN Teste


