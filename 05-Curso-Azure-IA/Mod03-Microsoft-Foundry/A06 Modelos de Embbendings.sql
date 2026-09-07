/*
===============================================================================
Formação SQL AI Expert
Aula : Autenticação com Managed Identity

Objetivo:
Chunking e Embeddings

Ambiente:
- Azure SQL Database
- Microsoft Foundry

Autor: Landry Duailibe
===============================================================================
*/

-- Gera Chunks
EXEC dbo.spAI_GerarBlogChunks


SELECT * FROM dbo.BlogChunks

-- Validar distribuição de chunks por post
SELECT bp.Titulo,
count(bc.ChunkId) as Total_Chunks,
min(len(bc.Chunk_Texto)) as Menor_Chunk,
max(len(bc.Chunk_Texto)) as Maior_Chunk,
avg(len(bc.Chunk_Texto)) as Media_Chunk
FROM dbo.BlogPosts bp
JOIN dbo.BlogChunks bc ON bc.PostId = bp.PostId
GROUP BY bp.Titulo
ORDER BY Total_Chunks DESC

/*****************************************
 EXTERNAL MODEL
******************************************/
--DROP EXTERNAL MODEL Embedding_3small
CREATE EXTERNAL MODEL Embedding_3small
WITH (
LOCATION = 'https://<nome-foundry>.openai.azure.com/openai/deployments/text-embedding-3-small/embeddings?api-version=2024-02-01',
API_FORMAT = 'Azure OpenAI',
MODEL_TYPE = EMBEDDINGS,
MODEL = 'text-embedding-3-small',
CREDENTIAL = [https://<nome-foundry>.openai.azure.com/])
go


/*****************************************
 Gerar embeddings para todos os chunks
******************************************/

-- Leva +- 2 minutos
UPDATE dbo.BlogChunks
SET Embedding = ai_generate_embeddings(Chunk_Texto USE MODEL Embedding_3small)
WHERE Embedding is null

-- Monitorar progresso em outra aba
SELECT count(*) as Total_Chunks,
count(Embedding) as Com_Embedding,
count(*) - count(Embedding) as Sem_Embedding,
cast(count(Embedding) * 100.0 / count(*) as decimal(5,1)) as Percentual
FROM dbo.BlogChunks with (nolock)

SELECT * FROM dbo.BlogChunks with (nolock)

/***************************************/
go
DECLARE @Pergunta nvarchar(4000) = N'O que é e como utilizar Tabelas Temporais no SQL Server'
DECLARE @VetorPergunta vector(1536)
SET @VetorPergunta = AI_GENERATE_EMBEDDINGS (@Pergunta USE MODEL Embedding_3small)

SELECT TOP (8) bc.ChunkId, bp.Titulo, bc.Chunk_Texto, vs.distance as Distancia

FROM VECTOR_SEARCH (
TABLE      = dbo.BlogChunks as bc,
COLUMN     = Embedding,
SIMILAR_TO = @VetorPergunta,
METRIC     = 'cosine') as vs

JOIN dbo.BlogPosts bp ON bp.PostId = bc.PostId
ORDER BY vs.distance

SELECT * FROM dbo.BlogChunks ORDER BY PostId,Chunk_Indice
