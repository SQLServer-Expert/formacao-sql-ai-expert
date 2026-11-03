/*
===============================================================================
Formação SQL AI Expert
Aula : Busca Vetorial

Objetivo:
Demonstrar busca vetorial em embeddings gerados por uma LLM.

Ambiente:
- SQL Server 2025
- Ollama
- Caddy

Autor: Landry Duailibe | SQL Server Expert
===============================================================================
*/

use Landry_Blogs
go

/**************************************
 Criar o índice vetorial
***************************************/
-- Chunks tamanho fixo
DROP INDEX IF EXISTS IX_BlogChunks_PorTamanho ON dbo.BlogChunks_PorTamanho
go
CREATE VECTOR INDEX IX_BlogChunks_PorTamanho
ON dbo.BlogChunks_PorTamanho (Embedding)
WITH (METRIC = 'cosine', TYPE = 'diskann')
go

-- Chunks tamanho variável
DROP INDEX IF EXISTS IX_BlogChunks ON dbo.BlogChunks
go
CREATE VECTOR INDEX IX_BlogChunks
ON dbo.BlogChunks (Embedding)
WITH (METRIC = 'cosine', TYPE = 'diskann')
go


-- Verificar a criação dos índices vetoriais
SELECT i.[name] as Nome_Indice,
i.[type_desc] as Tipo,
vi.distance_metric as Metrica,
vi.vector_index_type as Algoritmo,
vi.build_parameters as Parametros
FROM sys.indexes i
JOIN sys.vector_indexes vi ON vi.object_id = i.object_id AND vi.index_id  = i.index_id
WHERE  object_name(i.object_id) like 'BlogChunks%'

/**************************************
 Busca Vetorial Aproximada
 - VECTOR_SEARCH
***************************************/
go
DECLARE @Pergunta varchar(2000) = 'Como diagnosticar crescimento do log do banco de sistema TempDB?'
DECLARE @VetorPergunta vector(768) = AI_GENERATE_EMBEDDINGS(@Pergunta USE MODEL EmbeddingGemma)
DECLARE @Top int = 5

-- Chunk Tamanho Fixo
SELECT bp.Titulo, bc.Chunk_Texto as ChunkFixo, vs.distance as Distancia
FROM VECTOR_SEARCH(
TABLE = dbo.BlogChunks_PorTamanho AS bc,
COLUMN = Embedding,
SIMILAR_TO = @VetorPergunta,
METRIC = 'cosine',
TOP_N  = @Top
) as vs

JOIN dbo.BlogPosts bp ON bp.PostId = bc.PostId
ORDER BY vs.distance

-- Chunk Tamanho Variável
SELECT bp.Titulo, bc.Chunk_TituloSecao,bc.Chunk_Texto as ChunkVariavel, vs.distance as Distancia
FROM VECTOR_SEARCH(
TABLE = dbo.BlogChunks AS bc,
COLUMN = Embedding,
SIMILAR_TO = @VetorPergunta,
METRIC = 'cosine',
TOP_N  = @Top
) as vs

JOIN dbo.BlogPosts bp ON bp.PostId = bc.PostId
ORDER BY vs.distance
go

/*******************************************************
 Busca Vetorial Exata
 - VECTOR_DISTANCE
*********************************************************/
go
DECLARE @Pergunta varchar(2000) = 'Como diagnosticar crescimento do log do banco de sistema TempDB?'
DECLARE @VetorPergunta vector(768) = AI_GENERATE_EMBEDDINGS(@Pergunta USE MODEL EmbeddingGemma)

-- Chunk Tamanho Fixo
SELECT TOP (5) bp.Titulo, bc.Chunk_Texto as ChunkFixo,
VECTOR_DISTANCE('cosine', bc.Embedding, @VetorPergunta) as Distancia
FROM dbo.BlogChunks_PorTamanho bc
INNER JOIN dbo.BlogPosts bp ON bp.PostId = bc.PostId
ORDER BY Distancia ASC

-- Chunk Tamanho Variável
SELECT TOP (5) bp.Titulo, bc.Chunk_TituloSecao, bc.Chunk_Texto as ChunkVariavel,
VECTOR_DISTANCE('cosine', bc.Embedding, @VetorPergunta) as Distancia
FROM dbo.BlogChunks bc
INNER JOIN dbo.BlogPosts bp ON bp.PostId = bc.PostId
ORDER BY Distancia ASC
go
