/*
===============================================================================
Formação SQL AI Expert
Aula : Gerando Embeddings

Objetivo:
Gerar os Embeddings em ambas as tabelas de Chunks, 
tamanho fixo e variável.

Ambiente:
- SQL Server 2025
- Ollama
- Caddy

Autor: Landry Duailibe | SQL Server Expert
===============================================================================
*/
use Landry_Blogs
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



/***************************************************
 Gerar Embeddings  para Chunks de tamanho fixo
****************************************************/
UPDATE dbo.BlogChunks_PorTamanho
SET Embedding = AI_GENERATE_EMBEDDINGS(Chunk_Texto USE MODEL EmbeddingGemma)
WHERE Embedding is null

-- Monitorar progresso em outra aba
SELECT count(*) as Total_Chunks,
count(Embedding) as Com_Embedding,
count(*) - count(Embedding) as Sem_Embedding,
cast(count(Embedding) * 100.0 / count(*) as decimal(5,1)) as Percentual
FROM dbo.BlogChunks_PorTamanho with (nolock)

SELECT * FROM dbo.BlogChunks_PorTamanho with (nolock)

/***************************************************
 Gerar Embeddings  para Chunks de tamanho variável
****************************************************/
UPDATE dbo.BlogChunks
SET Embedding = AI_GENERATE_EMBEDDINGS(Chunk_Texto USE MODEL EmbeddingGemma)
WHERE Embedding is null

-- Monitorar progresso em outra aba
SELECT count(*) as Total_Chunks,
count(Embedding) as Com_Embedding,
count(*) - count(Embedding) as Sem_Embedding,
cast(count(Embedding) * 100.0 / count(*) as decimal(5,1)) as Percentual
FROM dbo.BlogChunks with (nolock)

SELECT * FROM dbo.BlogChunks with (nolock)


