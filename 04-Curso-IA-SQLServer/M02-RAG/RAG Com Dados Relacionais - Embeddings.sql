/*
===============================================================================
Formação SQL AI Expert
Aula : RAG Com Dados Relacionais

Objetivo:
Demonstrar acomo preparar dados relacionais para fazer RAG 
e gerar os Embeddings.

Ambiente:
- SQL Server 2025
- Ollama
- Caddy

Autor: Landry Duailibe | SQL Server Expert
===============================================================================
*/
use AdventureWorks_RAG
go

-- Habilitar preview features (necessário no SQL Server 2025)
ALTER DATABASE SCOPED CONFIGURATION SET PREVIEW_FEATURES = ON

/**********************************************
 Analisando dados da tabela Produto
***********************************************/
SELECT top 50 * FROM dbo.Produto


-- Quantidade de produtos por Categoria
SELECT Categoria, count(*) as Qtd_Produtos
FROM dbo.Produto
GROUP BY Categoria
ORDER BY Categoria


SELECT top 50 
CONCAT_WS(N'. # ',
N'# Produto: '      + Produto,
N'Modelo: '       + Modelo,
N'Categoria: '    + Categoria,
N'Subcategoria: ' + SubCategoria,
N'Cor: '          + Cor,
N'Descrição: '    + Descricao) as Embedding_Texto, * 
FROM dbo.Produto
WHERE Categoria = 'Vestuário'

/*********************************************
 Cria coluna com texto para gerar Embeddings
**********************************************/
--ALTER TABLE dbo.Produto DROP COLUMN Embedding_Texto
go
ALTER TABLE dbo.Produto ADD Embedding_Texto AS
CONCAT_WS(N'. # ',
N'# Produto: '      + Produto,
N'Modelo: '       + Modelo,
N'Categoria: '    + Categoria,
N'Subcategoria: ' + SubCategoria,
N'Cor: '          + Cor,
N'Descrição: '    + Descricao)
go

SELECT Embedding_Texto, * FROM dbo.Produto

/*********************************************
 Cria coluna Vector para armazenar Embeddings

**********************************************/
DROP TABLE IF exists dbo.Produto_Embedding
go
CREATE TABLE dbo.Produto_Embedding (
Produto_Embedding_ID int identity NOT NULL CONSTRAINT pk_Produto_Embeddingo PRIMARY KEY,
Produto_ID int NOT NULL,
Data_Atualizacao datetime2(3) NULL,
Embedding vector(768) NULL)
go

ALTER TABLE dbo.Produto_Embedding ADD CONSTRAINT fk_Produto_Embedding_Produto
FOREIGN KEY (Produto_ID) REFERENCES dbo.Produto (Produto_ID)
go

/*******************************
 Modelo de Embedding
********************************/
-- DROP EXTERNAL MODEL EmbeddingGemma
CREATE EXTERNAL MODEL EmbeddingGemma
WITH (
LOCATION = 'https://localhost/api/embed',
API_FORMAT = 'Ollama',
MODEL_TYPE = EMBEDDINGS,
MODEL = 'embeddinggemma'
)

-- Consultando Metadata
SELECT * FROM sys.external_models

/*****************************************
 Gerar embeddings para todos os chunks
******************************************/
-- Modelo embeddinggemma
-- Leva +- 6 minutos

INSERT dbo.Produto_Embedding (Produto_ID, Data_Atualizacao, Embedding)
SELECT  Produto_ID, SYSDATETIME() as Data_Atualizacao, 
AI_GENERATE_EMBEDDINGS(Embedding_Texto USE MODEL EmbeddingGemma) as Embedding
FROM dbo.Produto
go

-- Monitorar progresso em outra aba
DECLARE @QtdLinhas int
SELECT @QtdLinhas = count(*) FROM dbo.Produto

SELECT count(*) as Total_Embeddings,
@QtdLinhas - count(Embedding) as Sem_Embedding,
cast(count(Embedding) * 100.0 / @QtdLinhas as decimal(5,1)) as Percentual
FROM dbo.Produto_Embedding with (nolock)

SELECT * FROM dbo.Produto_Embedding with (nolock)

