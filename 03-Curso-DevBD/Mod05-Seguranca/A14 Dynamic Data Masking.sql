/*********************************************
 Autor: Landry Duailibe

 Hands On: Dynamic Data Masking
**********************************************/
use Aula
go

DROP TABLE IF exists Funcionario
go
CREATE TABLE Funcionario(
Funcionario_ID int not null CONSTRAINT pk_Funcionario PRIMARY KEY,
Nome varchar(50) NOT NULL,
Sobrenome varchar(50) MASKED WITH (FUNCTION = 'default()') NOT NULL,
Data_Aniversario date MASKED WITH (FUNCTION = 'default()') NOT NULL,
VendasUltimoAno money MASKED WITH (FUNCTION = 'default()') NOT NULL,
Email varchar(50),
Telefone varchar(25))
go

INSERT INTO Funcionario 
SELECT e.BusinessEntityID as Funcionario_ID,
sp.FirstName as Nome, sp.LastName as Sobrenome,
e.BirthDate as Data_Aniversario, sp.SalesLastYear as VendasUltimoAno,
sp.EmailAddress as Email, sp.PhoneNumber as Telefone
FROM AdventureWorks.HumanResources.Employee e
JOIN AdventureWorks.Sales.vSalesPerson sp ON e.BusinessEntityID = sp.BusinessEntityID
WHERE sp.CountryRegionName = 'United States'

-- Criando Usuário de Banco de Dados e atribuindo permissãona tabela
CREATE USER UsuarioTeste WITHOUT LOGIN
GRANT SELECT ON dbo.Funcionario TO UsuarioTeste 

-- Visualizando os dados
SELECT * FROM FUNCIONARIO 


-- Simulando acesso com UsuarioTeste
EXECUTE AS USER = 'UsuarioTeste'
REVERT

-- Habilitar visualização dos dados MASKED
GRANT UNMASK TO UsuarioTeste
REVOKE UNMASK TO UsuarioTeste


-- Adicionando mascara randomica
ALTER TABLE Funcionario ALTER COLUMN VendasUltimoAno money MASKED WITH (FUNCTION = 'random(101, 999)') NOT NULL

-- Adicionando mascara parcial, começando na 1a posição e mostrando apenas as 5 últimas posições
ALTER TABLE Funcionario ALTER COLUMN Telefone varchar(25) MASKED WITH (FUNCTION = 'partial(0, "xxxxxxx", 5)') NOT NULL

-- Adicionando mascara no email
ALTER TABLE Funcionario ALTER COLUMN Email varchar(50) MASKED WITH (FUNCTION = 'email()') NULL


EXECUTE AS USER = 'UsuarioTeste'

SELECT * FROM Funcionario 

REVERT
/*
238-555-0197
257-555-0154
883-555-0116
*/

-- Lista colunas com Mask habilitado
SELECT OBJECT_NAME(object_id) as Tabela, [name] as Coluna, masking_function MaskFunction
FROM sys.masked_columns
ORDER BY Tabela, Coluna


/*****************************
 Exclui objetos do Hands On
******************************/
DROP USER UsuarioTeste
DROP TABLE IF exists Funcionario





