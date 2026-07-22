/***************************************************************************************************************************
 Curso T-SQL
 Autor: Landry

 Tipo de Dado XML
 https://learn.microsoft.com/en-us/sql/relational-databases/xml/xml-data-type-and-columns-sql-server?view=sql-server-ver16

 Métodos:
 https://learn.microsoft.com/en-us/sql/t-sql/xml/xml-data-type-methods?view=sql-server-ver16
 - VALUE()
 - QUERY()
 - EXIST()
 - MODIFY()
 - NODES()

 Indices XML
 https://learn.microsoft.com/en-us/sql/relational-databases/xml/xml-indexes-sql-server?view=sql-server-ver16
***************************************************************************************************************************/
use Aula
go

/***********************************************************************
 Cria tabela para importar conteúdo dos arquivos .XML para colunas do 
 XML data type
************************************************************************/
IF object_id('dbo.LivrosXML') is not null
   DROP TABLE dbo.LivrosXML

CREATE TABLE dbo.LivrosXML (
LivroID int not null,
Doc xml not null)
go

-- Importação dos livros
INSERT INTO dbo.LivrosXML (LivroID, doc)
SELECT 1, * 
FROM OPENROWSET(BULK 'C:\Aula\Livro - The Gurus Guide to Transact SQL.xml',SINGLE_BLOB) as t

INSERT INTO dbo.LivrosXML (LivroID, doc)
SELECT 2, * 
FROM OPENROWSET(BULK 'C:\Aula\Livro - Admin 911 SQL Server 2000.xml',SINGLE_BLOB) as t

INSERT INTO dbo.LivrosXML (LivroID, doc)
SELECT 3, * 
FROM OPENROWSET(BULK 'C:\Aula\Livro - Inside SQL Server 2000.xml',SINGLE_BLOB) as t

INSERT INTO dbo.LivrosXML (LivroID, doc)
SELECT 4, * 
FROM OPENROWSET(BULK 'C:\Aula\Livro - SQL Server 2000 DTS.xml',SINGLE_BLOB) as t

INSERT INTO dbo.LivrosXML (LivroID, doc)
SELECT 5, * 
FROM OPENROWSET(BULK 'C:\Aula\Livro - Performance Tuning Guide SQL Server 2000.xml',SINGLE_BLOB) as t


SELECT * FROM LivrosXML

/****************************************************************************
 - O método VALUE retorna um valor escalar.  
 - O uso do [1] é obrigaório, porque um XML sem schema pode ter elementos
   com o mesmo nome no mesmo nível.
*****************************************************************************/
SELECT LivroID, Doc.value('(/Livro/Titulo)[1]','VARCHAR(50)') as Titulo
FROM LivrosXML

-- o livro de ID 5 tem dois elementos <Paginas> com valores 200 e 100.
-- Para retornar o primeiro valor [1].
SELECT LivroID, Doc.value('(/Livro/Paginas)[1]','VARCHAR(50)') as Titulo
FROM LivrosXML

-- WHERE utilizando .value para filtrar.
SELECT LivroID,Doc.value('(/Livro/Titulo)[1]','VARCHAR(50)') as Titulo,doc 
FROM LivrosXML
where Doc.value('(/Livro/Titulo)[1]','VARCHAR(50)') like 'Performance%'

/****************************************************************************
 - O método QUERY retorna um fragmento XML.  
 - Pode-se fazer uso das contruções FLOWR acrônimo de:
   For - Let - Order by - Where - Return.
*****************************************************************************/
-- Retona subelementos em um documento XML
SELECT LivroID, Doc.query('(/Livro/Autores)') as FragmentoXML
FROM LivrosXML

-- Uso do método QUERY com RETURN para formatar o fragmento XML retornado.
SELECT LivroID, 
Doc.query('<Root> 
               { 
                 for $v in /Livro/Autores
                   return element PrincipalAutor
                   {
                     element Nome {$v/Autor[1]/text()[1]}
                   }
               } 
           </Root>') as FragmentoXML
FROM LivrosXML

/****************************************************************************
 - O método EXIST retorna um boleano.  
*****************************************************************************/
-- Localiza valores em um documento XML e retorna 1 (achou) ou  0 (não achou).
SELECT LivroID, doc
FROM LivrosXML
where Doc.exist('/Livro/isbn[(text()[1])=12592]') = 1

/****************************************************************************
 - O método MODIFY  
*****************************************************************************/
SELECT LivroID, doc
FROM LivrosXML
WHERE LivroID = 1

-- insert
UPDATE LivrosXML
SET Doc.modify('
insert <Autor>Landry</Autor> as first
into (/Livro/Autores)[1]')
WHERE LivroID = 1

-- replace value
UPDATE LivrosXML
SET Doc.modify('
replace value of (/Livro/Autores/Autor[1]/text())[1]
with "Landry Duailibe"')
WHERE LivroID = 1

-- delete
UPDATE LivrosXML
SET Doc.modify('
delete /Livro/Autores/Autor[1]')
WHERE LivroID = 1

/****************************************************************************
 - O método NODES
*****************************************************************************/

SELECT LivroID,
a.value('isbn[1]','varchar(20)') as ISBN, 
a.value('Titulo[1]','varchar(100)') as Titulo

FROM LivrosXML
CROSS APPLY Doc.nodes('/Livro') as Livro(a)

/*******************************************************************************
 Indices XML

 - Primary: deve ser criado primeiro; só em tabelas com índice Cluster na PK.
 - Secondary:
   - Path: queries para localizar expressões PATH completas, 
           principalmente .EXIST
   - Value: queries que localizam valores, onde o PATH não é completo (wildcard).
   - Property: queries que retornam um ou mais valores .VALUE
********************************************************************************/
-- Cria PK cluster para criar os indices XML
ALTER TABLE LivrosXML ADD CONSTRAINT PK_LivrosXML PRIMARY KEY (LivroID)

-- Cria indices XML Primário
CREATE PRIMARY XML INDEX LivrosXML_xml_Doc ON LivrosXML(Doc)

-- Cria indice XML PATH
CREATE XML INDEX LivrosXML_xmlpath_doc ON LivrosXML(Doc)
USING XML INDEX LivrosXML_xml_Doc FOR PATH


-- Habilitar Plano de Execução Gráfico
SELECT LivroID, Doc
FROM LivrosXML
where Doc.exist('/Livro/isbn[(text()[1])=12592]') = 1

-- Exclui Tabela
DROP TABLE LivrosXML
