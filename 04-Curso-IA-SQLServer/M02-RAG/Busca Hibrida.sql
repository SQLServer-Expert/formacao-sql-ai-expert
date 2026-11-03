/*
===============================================================================
Formação SQL AI Expert
Aula : Busca Híbrida

Objetivo:
Demonstrar como executar Busca Híbrida.

Ambiente:
- SQL Server 2025
- Ollama
- Caddy

Autor: Landry Duailibe | SQL Server Expert
===============================================================================
*/

use Landry_Blogs
go


/*****************************
 Hybrid Search
******************************/
DECLARE @Pergunta varchar(2000) = 'Como diagnosticar crescimento do log do banco de sistema TempDB?'

DECLARE @VetorPergunta vector(768) = AI_GENERATE_EMBEDDINGS(@Pergunta USE MODEL EmbeddingGemma)

DECLARE @Top int = 5
DECLARE @K float = 60.0

/*
Busca Vetorial
*/
;WITH BuscaVetorial as (
SELECT bc.ChunkId, bc.PostId, vs.distance as Distancia,
ROW_NUMBER() OVER (ORDER BY vs.distance) as RankVetorial

FROM VECTOR_SEARCH (
TABLE = dbo.BlogChunks as bc,
COLUMN = Embedding,
SIMILAR_TO = @VetorPergunta,
METRIC = 'cosine',
TOP_N = @Top) as vs
),


/*
Busca Full-Text
*/
BuscaFullText as (
SELECT TOP (@Top) bc.ChunkId, bc.PostId, ft.[RANK] as FullTextScore,
ROW_NUMBER() OVER (ORDER BY ft.[RANK] DESC) as RankFullText

FROM FREETEXTTABLE (dbo.BlogChunks,Chunk_Texto,@Pergunta) ft
JOIN dbo.BlogChunks bc ON bc.ChunkId = ft.[KEY]

ORDER BY ft.[RANK] DESC),


/*
Combina os resultados das duas buscas

FULL OUTER JOIN mantém:
- chunks encontrados nas duas buscas;
- chunks encontrados apenas na busca vetorial;
- chunks encontrados apenas no Full-Text.
*/
ResultadosCombinados as (
SELECT COALESCE(v.ChunkId, f.ChunkId) AS ChunkId,
COALESCE(v.PostId, f.PostId) AS PostId,
v.Distancia, v.RankVetorial, f.FullTextScore, f.RankFullText

FROM BuscaVetorial AS v
FULL OUTER JOIN BuscaFullText AS f ON f.ChunkId = v.ChunkId),


/*
Calcula o RRF

Documento ausente em uma busca recebe contribuição zero
naquela parte da fórmula.

RRF =
    1 / (K + RankVetorial)
    +
    1 / (K + RankFullText)
*/
CalculoRRF as (
SELECT ChunkId, PostId, Distancia, RankVetorial, FullTextScore, RankFullText,
ISNULL (1.0 / (@K + RankVetorial), 0) as ContribuicaoVetorial,
ISNULL (1.0 / (@K + RankFullText), 0) as ContribuicaoFullText,
ISNULL (1.0 / (@K + RankVetorial), 0) + ISNULL (1.0 / (@K + RankFullText),0) as RRFScore

FROM ResultadosCombinados)


/*
Ranking final da busca híbrida
*/
SELECT ROW_NUMBER() OVER (ORDER BY r.RRFScore DESC) as RankingFinal,
r.ChunkId, bp.Titulo, bc.Chunk_TituloSecao,
r.RankVetorial, r.Distancia, r.ContribuicaoVetorial,
r.RankFullText, r.FullTextScore, r.ContribuicaoFullText,
r.RRFScore, bc.Chunk_Texto

FROM CalculoRRF r
JOIN dbo.BlogChunks bc ON bc.ChunkId = r.ChunkId
JOIN dbo.BlogPosts bp ON bp.PostId = r.PostId

ORDER BY r.RRFScore DESC
go
/**************************** FIM ***************************/
