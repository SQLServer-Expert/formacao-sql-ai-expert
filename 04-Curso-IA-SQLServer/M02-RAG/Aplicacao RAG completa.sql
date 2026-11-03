/*
===============================================================================
Formação SQL AI Expert
Aula : Aplicação RAG completa

Objetivo:
Demonstrar a solução completa de RAG com prompt ideal.

Ambiente:
- SQL Server 2025
- Ollama
- Caddy

Autor: Landry Duailibe | SQL Server Expert
===============================================================================
*/

use Landry_Blogs
go



/*****************************************
 Cria SP para Chamada Chat com LLM Local

EXEC dbo.spAI_Chat_Ollama
@pSystem = 'Você é um assistente especializado em bancos de dados Microsoft SQL Server que explica conceitos de forma clara e objetiva',
@pUser = 'Explique o que é o Banco de Dados de Sistema TempDB'

*****************************************/
go
--DROP PROC dbo.spAI_Chat_Ollama
CREATE or ALTER PROC dbo.spAI_Chat_Ollama
@pSystem nvarchar(max),
@pUser nvarchar(max),
@Modelo nvarchar(200) = N'llama3.2:1b',
@Temp nvarchar(4) = N'0.3',
@Timeout int = 230
as
set nocount on

DECLARE @payload nvarchar(MAX) = N'{
    "model": "' + STRING_ESCAPE(@Modelo, 'json') + N'",
    "options": {"temperature":' + @Temp + N'},
    "messages": [
        {"role": "system", "content": "' + STRING_ESCAPE(@pSystem, 'json') + N'"},
        {"role": "user",   "content": "' + STRING_ESCAPE(@pUser, 'json') + N'"}
    ],
    "stream": false
}'

DECLARE @response nvarchar(MAX)

EXEC sp_invoke_external_rest_endpoint
@url      = 'https://localhost/api/chat',
@method   = 'POST',
@headers  = '{"Content-Type":"application/json"}',
@payload  = @payload,
@timeout  = @Timeout,
@response = @response OUTPUT

SELECT JSON_VALUE(@response, '$.result.message.content') AS Resposta
go
/********************** FIM SP *********************/




/**********************************************************************************************************
  RAG com PROMPT IDEAL

 PERGUNTA DO USUÁRIO
 <pergunta>
 
 ========================================
 BASE DE CONHECIMENTO RECUPERADA
 ========================================
 Documento 1
 Título: ...
 Trecho:
 ...
 
 ----------------------------------------
 Documento 2
 Título: ...
 Trecho:
 ...

 ========================================
 TAREFA
 ========================================
 Utilize prioritariamente a base de conhecimento recuperada para responder à pergunta.
 Combine informações de diferentes documentos quando apropriado.
 Não invente informações que não estejam presentes na base de conhecimento.
 Se a base de conhecimento não contiver informações suficientes para responder, informe isso claramente.
 Responda em Markdown.

****************************************************************************************************************/

set nocount on


/*==============================================================================
  1. CONFIGURAÇÕES
==============================================================================*/

DECLARE @Pergunta nvarchar(2000) = N'Como diagnosticar crescimento do log do banco de sistema TempDB?'
-- Quantidade de candidatos recuperados por cada mecanismo de busca
DECLARE @TopCandidatos  int = 20

-- Quantidade de documentos após o Ranking, apresentados a LLM
DECLARE @TopDocumentos int = 5

-- Constante utilizada no cálculo do Reciprocal Rank Fusion (RRF)
DECLARE @ConstanteRRF   decimal(10,2) = 60.0

/*==============================================================================
 GERAÇÃO DO EMBEDDING DA PERGUNTA
==============================================================================*/
DECLARE @VetorPergunta vector(768)
SET @VetorPergunta = AI_GENERATE_EMBEDDINGS (@Pergunta USE MODEL EmbeddingGemma)

/*==============================================================================
 BUSCA HÍBRIDA COM RECIPROCAL RANK FUSION
==============================================================================*/
DROP TABLE IF EXISTS #ResultadoHibrido

;WITH BuscaVetorial AS
(
    SELECT
        bc.ChunkId,
        vs.distance AS Distancia,
        ROW_NUMBER() OVER
        (
            ORDER BY vs.distance, bc.ChunkId
        ) AS RankingVetorial

    FROM VECTOR_SEARCH
    (
        TABLE       = dbo.BlogChunks AS bc,
        COLUMN      = Embedding,
        SIMILAR_TO  = @VetorPergunta,
        METRIC      = 'cosine',
        TOP_N       = @TopCandidatos
    ) AS vs
),

BuscaTextual AS
(
    SELECT
        bc.ChunkId,
        ft.[RANK] AS RelevanciaTextual,
        ROW_NUMBER() OVER
        (
            ORDER BY ft.[RANK] DESC, bc.ChunkId
        ) AS RankingTextual

    FROM FREETEXTTABLE
    (
        dbo.BlogChunks,
        Chunk_Texto,
        @Pergunta,
        LANGUAGE 1046,
        @TopCandidatos
    ) AS ft

    JOIN dbo.BlogChunks AS bc
        ON bc.ChunkId = ft.[KEY]
),
FusaoRankings AS
(
    SELECT
        COALESCE(v.ChunkId, t.ChunkId) AS ChunkId,
        v.Distancia,
        t.RelevanciaTextual,
        v.RankingVetorial,
        t.RankingTextual,

        COALESCE
        (
            1.0 / (@ConstanteRRF + v.RankingVetorial),
            0
        )
        +
        COALESCE
        (
            1.0 / (@ConstanteRRF + t.RankingTextual),
            0
        ) AS PontuacaoRRF

    FROM BuscaVetorial AS v

    FULL OUTER JOIN BuscaTextual AS t
        ON t.ChunkId = v.ChunkId
)
SELECT TOP (@TopDocumentos)
    f.ChunkId,
    bc.PostId,
    bp.Titulo,
    bc.Chunk_Indice,
    bc.Chunk_Texto,
    f.Distancia,
    f.RelevanciaTextual,
    f.RankingVetorial,
    f.RankingTextual,
    CAST(f.PontuacaoRRF AS decimal(19,8)) AS PontuacaoRRF

INTO #ResultadoHibrido

FROM FusaoRankings AS f

JOIN dbo.BlogChunks AS bc
    ON bc.ChunkId = f.ChunkId

JOIN dbo.BlogPosts AS bp
    ON bp.PostId = bc.PostId

ORDER BY
    f.PontuacaoRRF DESC,
    f.Distancia,
    f.ChunkId;


/* Documentos selecionados para o contexto */

SELECT
    ChunkId,
    Titulo,
    LEFT(Chunk_Texto, 300) AS Trecho,
    RankingVetorial,
    RankingTextual,
    PontuacaoRRF
FROM #ResultadoHibrido
ORDER BY
    PontuacaoRRF DESC,
    Distancia;


/* Montagem do contexto */

DECLARE @Contexto nvarchar(MAX);

;WITH DocumentosOrdenados AS
(
    SELECT
        ROW_NUMBER() OVER
        (
            ORDER BY PontuacaoRRF DESC, Distancia, ChunkId
        ) AS NumeroDocumento,
        Titulo,
        Chunk_Texto
    FROM #ResultadoHibrido
)
SELECT
    @Contexto =
        STRING_AGG
        (
            CONVERT
            (
                nvarchar(MAX),

                N'Documento '
                + CONVERT(nvarchar(10), NumeroDocumento)
                + CHAR(13) + CHAR(10)
                + CHAR(13) + CHAR(10)

                + N'Título: '
                + COALESCE(Titulo, N'Sem título')
                + CHAR(13) + CHAR(10)
                + CHAR(13) + CHAR(10)

                + Chunk_Texto
            ),

            CHAR(13) + CHAR(10)
            + CHAR(13) + CHAR(10)
            + N'----------------------------------------'
            + CHAR(13) + CHAR(10)
            + CHAR(13) + CHAR(10)
        )
        WITHIN GROUP
        (
            ORDER BY NumeroDocumento
        )
FROM DocumentosOrdenados;


/*==============================================================================
  5. PROMPTS - CENÁRIO 2: ESTRUTURA IDEAL PARA RAG
==============================================================================*/

DECLARE @System nvarchar(MAX) = N'
Você é um assistente especializado em Microsoft SQL Server.

Responda dúvidas técnicas sobre SQL Server de forma clara, correta e objetiva.

Regras obrigatórias:
- Utilize o contexto fornecido como principal fonte da resposta.
- Não invente comandos, funcionalidades ou informações.
- Se o contexto não for suficiente, informe isso claramente.
- Responda em português do Brasil.
- Utilize Markdown.
';

DECLARE @User nvarchar(MAX) =
      N'PERGUNTA DO USUÁRIO'
    + CHAR(13) + CHAR(10)
    + CHAR(13) + CHAR(10)

    + @Pergunta

    + CHAR(13) + CHAR(10)
    + CHAR(13) + CHAR(10)

    + N'========================================'
    + CHAR(13) + CHAR(10)
    + N'BASE DE CONHECIMENTO RECUPERADA'
    + CHAR(13) + CHAR(10)
    + N'========================================'
    + CHAR(13) + CHAR(10)
    + CHAR(13) + CHAR(10)

    + COALESCE
      (
          @Contexto,
          N'Nenhum documento relevante foi localizado.'
      )

    + CHAR(13) + CHAR(10)
    + CHAR(13) + CHAR(10)

    + N'========================================'
    + CHAR(13) + CHAR(10)
    + N'REGRAS PARA A RESPOSTA'
    + CHAR(13) + CHAR(10)
    + N'========================================'
    + CHAR(13) + CHAR(10)
    + CHAR(13) + CHAR(10)

    + N'1. Responda exclusivamente com informações presentes no contexto.'
    + CHAR(13) + CHAR(10)
    + CHAR(13) + CHAR(10)

    + N'2. Não utilize conhecimento próprio.'
    + CHAR(13) + CHAR(10)
    + CHAR(13) + CHAR(10)

    + N'3. Não crie comandos, parâmetros, opções ou exemplos que não estejam no contexto.'
    + CHAR(13) + CHAR(10)
    + CHAR(13) + CHAR(10)

    + N'4. Se o contexto não responder à pergunta, responda exatamente: Não encontrei informações suficientes na base de conhecimento.'
    + CHAR(13) + CHAR(10)
    + CHAR(13) + CHAR(10)

    + N'Responda em Markdown.';


/* Conferência antes do envio */

SELECT
    @System AS Prompt_Sistema,
    @User   AS Prompt_Usuario;


/* Chamada ao Ollama */

EXEC dbo.spAI_Chat_Ollama
     @pSystem = @System,
     @pUser   = @User,
     @Modelo  = N'llama3.2:1b',
     @Temp    = N'0.2';
GO
/******************** FIM RAG **************************/




