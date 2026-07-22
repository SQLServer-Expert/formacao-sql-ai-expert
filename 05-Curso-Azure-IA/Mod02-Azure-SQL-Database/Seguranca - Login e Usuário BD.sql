/**************************************
 Autor: Landry Duailibe

 Hands On: Segurança Login e Usuario BD
***************************************/

/*****************************************
 Informações de Metadata de segurança
******************************************/
-- Executar na MASTER
SELECT type_desc as Tipo, name as Login_Nome,principal_id as Login_ID,
is_disabled,create_date as Data_Criacao, modify_date as Data_Alteracao,
default_database_name
FROM sys.sql_logins
ORDER BY Tipo,Login_Nome

-- Executar em cada banco
SELECT [type_desc] Tipo, 
[name] as Usuario_Nome,principal_id as Usuario_ID,
authentication_type_desc as Tipo_Autenticacao,
create_date as Data_Criacao, modify_date as Data_Alteracao
FROM sys.database_principals
WHERE [type] <> 'R'
ORDER BY Tipo,Usuario_Nome


/*******************************************
 1) Criar um Login + Usuário de Banco
 - Ideal para Administradores
********************************************/
-- Executar na MASTER: cria Login do tipo SQL
CREATE LOGIN Teste WITH PASSWORD = 'Pa$$w0rd'
-- DROP LOGIN Teste

-- Executar no Banco de Dados que deseja fornecer acesso
CREATE USER Teste FROM LOGIN Teste 
-- DROP USER Teste

-- Login Entra ID
CREATE LOGIN [pedro@landrydsaicom.onmicrosoft.com] FROM EXTERNAL PROVIDER
/*
- Só consegue criar conectado com Login Entra ID
Msg 33159, Level 16, State 1, Line 1
Principal 'pedro@landrydsaicom.onmicrosoft.com' could not be created. Only connections established with Active Directory accounts can create other Active Directory users.
*/

-- Desabilita conexão
ALTER LOGIN [pedro@landrydsaicom.onmicrosoft.com] DISABLE

-- Exclui Login
DROP LOGIN [pedro@landrydsaicom.onmicrosoft.com]

/***************************************************
 2) Criar Usuário de Banco com Autenticação direta
 - Ideal para Aplicações
****************************************************/
-- Executar no Banco de Dados que deseja fornecer acesso
CREATE USER AppVendas WITH PASSWORD = 'Pa$$w0rd'


/*******************************************************************************
 Server Roles
 - Permissões no nível do Servidor Lógico

 https://learn.microsoft.com/en-us/azure/azure-sql/database/security-server-roles?view=azuresql

 ##MS_DatabaseConnector## -> pode se conectar a qualquer banco de dados 

 ##MS_DatabaseManager## -> pode criar e excluir bancos de dados, só acessa 
                           os bancos que criou por ser o Owner.  utilizar 
						   no lugar do Role de Banco de Dados DBMANAGER 

 ##MS_DefinitionReader## -> pode ler todas as Views de Catálogo cobertas
                            pelas as permissões VIEW ANY DEFINITION e
							VIEW DEFINITION

 ##MS_LoginManager## -> pode criar e excluir logins, utilizar no lugar
                        do Role de Banco de Dados LOGINMANAGER

 ##MS_SecurityDefinitionReader## -> pode ler todas as Views de Catálogo cobertas
                                    pelas permissões VIEW ANY SECURITY DEFINITION
									e VIEW SECURITY DEFINITION

 ##MS_ServerStateReader## -> pode ler todas as Views e funções DMVs cobertas pelas
                             permissões VIEW SERVER STATE e VIEW DATABASE STATE

 ##MS_ServerStateManager## -> pode ler todas as Views e funções DMVs cobertas pela
                              permissão ALTER SERVER STATE

********************************************************************************/
SELECT principal_id as Login_ID, [name] as Login_Nome, [type_desc] as Tipo, [SID]
FROM sys.server_principals
WHERE type = 'E'

UNION ALL

SELECT principal_id as Login_ID, [name] as Login_Nome, [type_desc] as Tipo, [SID]
FROM sys.sql_logins

/*****************************************
 - ALTER SERVER ROLE
   https://learn.microsoft.com/en-us/sql/t-sql/statements/alter-server-role-transact-sql?view=sql-server-ver16
******************************************/

-- Login Windows
ALTER SERVER ROLE [##MS_LoginManager##] ADD MEMBER [Pedro@landrydsaicom.onmicrosoft.com]
ALTER SERVER ROLE [##MS_LoginManager##] DROP MEMBER [Pedro@landrydsaicom.onmicrosoft.com]

-- Login SQL
-- Conectar no banco MASTER com Login Teste / Pa$$w0rd
-- Executar SELECT em sys.dm_exec_connections
SELECT * FROM sys.dm_exec_connections

ALTER SERVER ROLE [##MS_DatabaseConnector##] ADD MEMBER [Teste]
ALTER SERVER ROLE [##MS_ServerStateReader##] ADD MEMBER [Teste]

ALTER SERVER ROLE [##MS_DatabaseConnector##] DROP MEMBER [Teste]
ALTER SERVER ROLE [##MS_ServerStateReader##] DROP MEMBER [Teste]


/*****************************************
 sys.server_role_members
 https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-server-role-members-transact-sql?view=sql-server-ver16
******************************************/
SELECT * FROM sys.server_role_members

SELECT rp.principal_id as RoleID, rp.[name] as RoleName,
r.member_principal_id as LoginID, 
isnull(rl.[name],rls.[name]) as LoginName,
isnull(rl.[type_desc],rls.[type_desc]) as LoginTipo
FROM sys.server_role_members r
LEFT JOIN sys.server_principals rp ON r.role_principal_id = rp.principal_id
LEFT JOIN sys.server_principals rl ON r.member_principal_id = rl.principal_id
LEFT JOIN sys.sql_logins rls ON r.member_principal_id = rls.principal_id
ORDER BY RoleName


/*******************************************************************************
 - Roles Específicos do Azure SQL Database, que não existem no On Premises

 dbmanager -> Pode criar e excluir Bancos de Dados, ao criar se torna o Owner e tem plenos poderes no Banco.
              Não acessa Bancos que não é Owner.

 loginmanager -> Pode criar e excluir Logins no Banco MASTER.

********************************************************************************/

-- Executar no Banco
DROP USER Teste
DROP USER AppVendas


-- Trocar para MASTER
DROP LOGIN Teste
DROP LOGIN [pedro@landrydsaicom.onmicrosoft.com]





