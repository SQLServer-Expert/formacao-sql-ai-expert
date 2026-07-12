/*********************************************
 Autor: Landry Duailibe

 Hands On: Criptografia de dados
**********************************************/
USE master
go

/***************************************************************
 Backup e Restore Service Master Key
 - Criada automaticamente quando cria a 1a Database Master Key
****************************************************************/
BACKUP SERVICE MASTER KEY TO FILE = 'C:\_LIVE\ServiceMaster.Key'
ENCRYPTION BY PASSWORD = 'Pa$$w0rd'

RESTORE SERVICE MASTER KEY FROM FILE = 'C:\_LIVE\ServiceMaster.Key'   
DECRYPTION BY PASSWORD = 'Pa$$w0rd'

/***********************
 Cria Banco
************************/
CREATE LOGIN Teste WITH PASSWORD = N'Pa$$w0rd', CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
go

DROP DATABASE IF exists HandsOn
go
CREATE DATABASE HandsOn
go

-- Cria Tabela para demonstração
USE HandsOn
go
DROP TABLE IF exists dbo.Funcionario
go
CREATE TABLE dbo.Funcionario (
FuncionarioID int not null,
DataCadastro datetime DEFAULT getdate() not null,
CPF varbinary(max) not null)

-- Cria usuário de banco de dados com acesso a tabela
CREATE USER Teste FOR LOGIN Teste
GRANT SELECT, INSERT, UPDATE ON dbo.Funcionario TO Teste


-- Cria Database Master key
-- DROP MASTER KEY
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Pa$$w0rd'

SELECT [name] NomeDaChave, symmetric_key_id, key_length, algorithm_desc
FROM sys.symmetric_keys

-- Cria Certificado
-- DROP CERTIFICATE Cert_Dados
CREATE CERTIFICATE Cert_Dados WITH SUBJECT = 'Certificado para criptografia dos dados', EXPIRY_DATE = '99991231'

SELECT [name] NomeDoCertificado, certificate_id, pvt_key_encryption_type_desc, 
issuer_name, [start_date], [expiry_date]
FROM sys.certificates

-- Cria Chave Simétrica, criptografada no banco utilizando o Certificado
-- DROP SYMMETRIC KEY Key_Dados
CREATE SYMMETRIC KEY Key_Dados WITH ALGORITHM = AES_256 
ENCRYPTION BY CERTIFICATE Cert_Dados

SELECT [name] NomeDaChave, symmetric_key_id, key_length, algorithm_desc
FROM sys.symmetric_keys

/************************************
 Incluindo dados criptografados
*************************************/
OPEN SYMMETRIC KEY Key_Dados DECRYPTION BY CERTIFICATE Cert_Dados

INSERT dbo.Funcionario (FuncionarioID, CPF)
VALUES (1, EncryptByKey(Key_GUID('Key_Dados'),'26899712234'))

CLOSE ALL SYMMETRIC KEYS

/************************************
 Consultando dados criptografados
*************************************/
SELECT * FROM dbo.Funcionario

OPEN SYMMETRIC KEY Key_Dados DECRYPTION BY CERTIFICATE Cert_Dados

SELECT FuncionarioID,DataCadastro,
CONVERT(varchar,DecryptByKey(CPF)) AS CPF 
FROM dbo.Funcionario

CLOSE ALL SYMMETRIC KEYS

/******************************************
 Tentando acessar com outro usuário
*******************************************/
EXECUTE AS USER = 'Teste'
REVERT

OPEN SYMMETRIC KEY Key_Dados DECRYPTION BY CERTIFICATE Cert_Dados
/*
Msg 15151, Level 16, State 1, Line 83
Cannot find the symmetric key 'Key_Dados', because it does not exist or you do not have permission.
*/

GRANT CONTROL ON CERTIFICATE::Cert_Dados TO Teste
GRANT VIEW DEFINITION ON SYMMETRIC KEY::Key_Dados to Teste

SELECT FuncionarioID,DataCadastro,
CONVERT(varchar,DecryptByKey(CPF)) AS CPF 
FROM dbo.Funcionario

CLOSE ALL SYMMETRIC KEYS



/*************************************
 Excluindo Objetos do Hands On
**************************************/
DROP TABLE dbo.Funcionario
DROP SYMMETRIC KEY Key_Dados
DROP CERTIFICATE Cert_Dados
DROP MASTER KEY
DROP USER Teste

USE master
go
DROP LOGIN Teste
go
DROP DATABASE IF exists HandsOn




