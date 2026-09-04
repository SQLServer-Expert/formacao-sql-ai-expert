/**********************************************************************
 Autor: Landry Duailibe

 Indices Fulltext Stop Words
***********************************************************************/
use master
go

/************************************
 Prepara Hands On
*************************************/
DROP DATABASE IF exists HandsOn
go
CREATE DATABASE HandsOn
go
ALTER DATABASE HandsOn SET RECOVERY simple
go

use HandsOn
go
DROP TABLE IF exists dbo.Cliente
go
CREATE TABLE dbo.Cliente (
Cliente_ID int not null CONSTRAINT pk_Cliente PRIMARY KEY,
Nome varchar(100) not null,
Telefone varchar(50) null)
go

INSERT dbo.Cliente (Cliente_ID,Nome,Telefone)
SELECT BusinessEntityID as Cliente_ID,
FirstName + isnull(' ' + MiddleName,'') + isnull(' ' + LastName,'') as Nome,
PhoneNumber as Telefone
FROM AdventureWorks.Sales.vSalesPerson
go
/********************** FIM Prepara Hands On ***************************/


INSERT dbo.Cliente (Cliente_ID,Nome,Telefone)
VALUES (500,'Carla Casa da Silva Que de Oliveira','500')

SELECT * FROM dbo.Cliente
WHERE Nome like '%Casa%Que%'

/*******************************************
 Cria Indice Fulltext com StopList padrão
********************************************/
CREATE FULLTEXT CATALOG HandsOn AS DEFAULT

-- DROP FULLTEXT INDEX ON Cliente
CREATE FULLTEXT INDEX ON Cliente (Nome LANGUAGE 2070)
KEY INDEX pk_Cliente WITH STOPLIST = SYSTEM

-- Consulta com LIKE
SELECT * FROM dbo.Cliente
WHERE Nome like '%Casa%Que%'

-- Consulta com CONTAINS: Retorna zero linhas?!
SELECT * FROM dbo.Cliente
WHERE contains(Nome,'Casa and Que')

-- Encontra "Casa"
SELECT * FROM dbo.Cliente
WHERE contains(Nome,'Casa')

-- Não encontra "Que" por ser Stop Word padrão
SELECT * FROM dbo.Cliente
WHERE contains(Nome,'Que')

-- Consulta lista de Stop Words padrão
SELECT * FROM sys.fulltext_system_stopwords 
WHERE language_id = 2070 and stopword = 'Que'


/***************************************
 Cria lista de Stop Words customizada
****************************************/
CREATE FULLTEXT STOPLIST CustomStoplistBR;

ALTER FULLTEXT STOPLIST CustomStoplistBR ADD 'a' LANGUAGE 2070;
ALTER FULLTEXT STOPLIST CustomStoplistBR ADD 'e' LANGUAGE 2070;
ALTER FULLTEXT STOPLIST CustomStoplistBR ADD 'ou' LANGUAGE 2070;

-- Consulta metadata
SELECT * FROM sys.fulltext_stoplists 
SELECT * FROM sys.fulltext_stopwords

/**********************************************************
 Cria Indice Fulltext com lista de Stop Words customizada
***********************************************************/
-- DROP FULLTEXT INDEX ON Cliente
CREATE FULLTEXT INDEX ON Cliente (Nome LANGUAGE 2070)
KEY INDEX pk_Cliente WITH STOPLIST = CustomStoplistBR

SELECT * FROM dbo.Cliente
WHERE Nome like '%Casa%Que%'

SELECT * FROM dbo.Cliente
WHERE contains(Nome,'Casa and Que')


/***************************************************
 Criando Lista de Stop Words a partir de uma tabela
****************************************************/

CREATE TABLE tb_StopList (stopword NVARCHAR(64))
INSERT tb_StopList VALUES ('da'),('de'),('a'),('ou'),('e')

SELECT stopword FROM sys.fulltext_system_stopwords 
WHERE language_id = 2070 
and stopword not in ('Que')

-- Cria Stop Words List
-- DROP FULLTEXT STOPLIST CustomStoplist
CREATE FULLTEXT STOPLIST Stoplist_Tab

DECLARE @stopword NVARCHAR(64)

DECLARE stopword_cursor CURSOR FOR
SELECT stopword FROM tb_StopList

OPEN stopword_cursor

FETCH NEXT FROM stopword_cursor INTO @stopword

WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC ('ALTER FULLTEXT STOPLIST Stoplist_Tab ADD ''' + @stopword + ''' LANGUAGE 0;')
    FETCH NEXT FROM stopword_cursor INTO @stopword
END

CLOSE stopword_cursor
DEALLOCATE stopword_cursor
go


-- Exemplo de uso
CREATE FULLTEXT INDEX ON Tabela (Coluna)
KEY INDEX indice
WITH STOPLIST = Stoplist_Tab




-- Exclui Banco
use master
go
DROP DATABASE IF exists HandsOn
go