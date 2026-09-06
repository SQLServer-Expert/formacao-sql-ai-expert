/*
===============================================================================
Formação SQL AI Expert
Aula : Autenticação com Managed Identity

Objetivo:
Stored Procedure para demonstrar a solução completa de RAG.

Ambiente:
- Azure SQL Database
- Microsoft Foundry

Autor: Landry Duailibe
===============================================================================
*/

go
CREATE or ALTER PROC dbo.ia_RAG_Foundry
/*==============================================================================
  Parâmetros:
  @Pergunta nvarchar(2000) - prompt do usuário final

  @TopDocumentos int - Quantidade de documentos após o Ranking, 
                       apresentados a LLM

  Chamada:
  EXEC dbo.ia_RAG_Foundry 
  @Pergunta = N'O que é e como utilizar Tabelas Temporais no SQL Server',
  @TopDocumentos = 5,
  @vModelo = N'gpt-5.6-luna',
  @vTemp = N'1'
==============================================================================*/
@Pergunta nvarchar(2000) = N'Como usar DBCC CHECKDB no SQL Server?',
@TopDocumentos int = 8,
@vModelo nvarchar(200) = N'gpt-5.6-luna',
@vTemp nvarchar(4) = N'1'
as

set nocount on

/*******************************************
  GERAÇÃO DO EMBEDDING DA PERGUNTA
********************************************/
DECLARE @VetorPergunta vector(1536)
SET @VetorPergunta = AI_GENERATE_EMBEDDINGS (@Pergunta USE MODEL Embedding_3small)


/*******************************************
  BUSCA VETORIAL
********************************************/
DROP TABLE IF EXISTS #Documentos

SELECT TOP (@TopDocumentos) bc.ChunkId, bp.Titulo, bc.Chunk_Texto, vs.distance as Distancia

INTO #Documentos

FROM VECTOR_SEARCH (
TABLE      = dbo.BlogChunks as bc,
COLUMN     = Embedding,
SIMILAR_TO = @VetorPergunta,
METRIC     = 'cosine'
-- TOP_N      = @TopDocumentos -> não suportado no Azure SQL Database usar TOP no SELECT
) as vs

JOIN dbo.BlogPosts bp ON bp.PostId = bc.PostId
ORDER BY vs.distance

/* Documentos selecionados para o contexto */

SELECT ChunkId, Titulo, LEFT(Chunk_Texto, 300) as Chunk_Texto, Distancia
FROM #Documentos
ORDER BY Distancia


/* Montagem do contexto */
DECLARE @Contexto nvarchar(MAX)

;WITH DocumentosOrdenados as (
SELECT ROW_NUMBER() OVER (ORDER BY Distancia) as NumeroDocumento, Titulo, Chunk_Texto
FROM #Documentos)

SELECT @Contexto =
STRING_AGG (CONVERT (nvarchar(MAX), N'# Documento '
+ CONVERT(nvarchar(10), NumeroDocumento)
+ CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)

+ N'Título: ' + COALESCE(Titulo, N'Sem título')
+ CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)

+ Chunk_Texto),

+ CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10))

WITHIN GROUP (ORDER BY NumeroDocumento)
FROM DocumentosOrdenados


/*************************************
  PROMPTS
**************************************/

DECLARE @System nvarchar(MAX) = N'
Você é um assistente especializado em Microsoft SQL Server.

Responda dúvidas técnicas sobre SQL Server de forma clara, correta e objetiva.

Regras obrigatórias:
- Utilize o contexto fornecido como principal fonte da resposta.
- Não invente comandos, funcionalidades ou informações.
- Se o contexto não for suficiente, informe isso claramente.
- Responda em português do Brasil.
- Utilize Markdown.'

DECLARE @User nvarchar(MAX) = N'>> PERGUNTA DO USUÁRIO:'
+ CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)

+ @Pergunta
+ CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)

+ N'>> BASE DE CONHECIMENTO RECUPERADA:'
+ CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)

+ COALESCE (@Contexto,N'Nenhum documento relevante foi localizado.')
+ CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)

+ N'>> REGRAS PARA A RESPOSTA:'
+ CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)

+ N'1. Responda exclusivamente com informações presentes no contexto.'
+ CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)

+ N'2. Não utilize conhecimento próprio.'
+ CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)

+ N'3. Não crie comandos, parâmetros, opções ou exemplos que não estejam no contexto.'
+ CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)

+ N'4. Se o contexto não responder à pergunta, responda exatamente: Não encontrei informações suficientes na base de conhecimento.'
+ CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)

+ N'Responda em Markdown.'


/* Conferência antes do envio */

SELECT @System AS Prompt_Sistema,
       @User   AS Prompt_Usuario


/* Chamada ao Ollama */

EXEC dbo.ia_Chat_Foundry
@Prompt_Sistema = @System,
@Prompt_Usuario = @User,
@Modelo = @vModelo,
@Temperatura = @vTemp
go
/******************** FIM SP **************************/




