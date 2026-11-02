/*
===============================================================================
Formação SQL AI Expert
Aula : Chunking de Tamanho Fixo

Objetivo:
Demonstrar a geração de chunks de tamanho fixo utilizando função nativa
do SQL Server 2025 chamda AI_GENERATE_CHUNKS().

Ambiente:
- SQL Server 2025
- Ollama
- Caddy

Autor: Landry Duailibe | SQL Server Expert
===============================================================================
*/

/********************************************
 Habilitando no Banco recursos de IA
*********************************************/
use Landry_Blogs
go

/****************************************
 Tabelas com os Chunks
*****************************************/
DROP TABLE IF exists dbo.BlogChunks_PorTamanho
go
CREATE TABLE dbo.BlogChunks_PorTamanho (
ChunkId int identity(1,1) CONSTRAINT pk_BlogChunks_PorTamanho PRIMARY KEY,
PostId int NOT NULL,
Chunk_Indice int NOT NULL, -- ordem do chunk dentro do post (0, 1, 2...)
Chunk_Texto nvarchar(MAX) NOT NULL, -- texto do chunk
Embedding vector(768) NULL -- 768 dimensões para modelo embeddinggemma
)
go

ALTER TABLE dbo.BlogChunks_PorTamanho ADD CONSTRAINT uq_BlogChunks_PorTamanho_Post_Chunk 
UNIQUE (PostId, Chunk_Indice)

ALTER TABLE dbo.BlogChunks_PorTamanho ADD CONSTRAINT fk_BlogChunks_PorTamanho_BlogPosts 
FOREIGN KEY (PostId) REFERENCES dbo.BlogPosts(PostId)
go

/************************************
 Gerar chunks de todos os posts
 - Modelo embeddinggemma
*************************************/
INSERT INTO dbo.BlogChunks_PorTamanho (PostId, Chunk_Indice, Chunk_Texto)

SELECT bp.PostId, c.chunk_order, c.chunk
FROM dbo.BlogPosts bp
CROSS APPLY AI_GENERATE_CHUNKS(
source     = bp.Conteudo,
chunk_type = FIXED,
chunk_size = 1000,
overlap    = 15
) as c
WHERE NOT EXISTS (SELECT 1 FROM dbo.BlogChunks_PorTamanho bc WHERE bc.PostId = bp.PostId)


SELECT * FROM dbo.BlogChunks_PorTamanho
ORDER BY PostId, Chunk_Indice

-- Validar distribuição de chunks por post
SELECT bp.Titulo,
count(bc.ChunkId) as Total_Chunks,
min(len(bc.Chunk_Texto)) as Menor_Chunk,
max(len(bc.Chunk_Texto)) as Maior_Chunk,
avg(len(bc.Chunk_Texto)) as Media_Chunk
FROM dbo.BlogPosts bp
JOIN dbo.BlogChunks_PorTamanho bc ON bc.PostId = bp.PostId
GROUP BY bp.Titulo
ORDER BY Total_Chunks DESC



