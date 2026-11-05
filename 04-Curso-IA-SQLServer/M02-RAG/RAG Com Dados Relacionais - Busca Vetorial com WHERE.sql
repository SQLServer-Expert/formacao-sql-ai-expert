/*
===============================================================================
Formação SQL AI Expert
Aula : RAG Com Dados Relacionais

Objetivo:
Demonstrar como combinar Busca Vetorial e filtro WHERE padrão.

Ambiente:
- SQL Server 2025
- Ollama
- Caddy

Autor: Landry Duailibe | SQL Server Expert
===============================================================================
*/
use AdventureWorks_RAG
go


/*****************************************************
 WHERE (pré-filtro) 

 - VECTOR_DISTANCE é resolvido no plano de execução 
   em "Compute Scalar", pogo após o Merge Join.

 - Filtro WHERE resolvido no Clustered Index Scan
*****************************************************/
DECLARE @Pergunta nvarchar(2000) = N'Qual a melhor bicicleta para pedalar no meio do mato, em caminhos de terra e pedra'
DECLARE @Top int = 5
DECLARE @Preco_INI money = 500.0
DECLARE @Preco_FIM money = 1000.0

DECLARE @VetorPergunta vector(768) = AI_GENERATE_EMBEDDINGS(@Pergunta USE MODEL EmbeddingGemma);

SELECT TOP (@Top) e.Produto_ID, p.Embedding_Texto, p.Descricao, 
VECTOR_DISTANCE('cosine', Embedding, @VetorPergunta) as Distancia
FROM dbo.Produto_Embedding e
JOIN dbo.Produto p on p.Produto_ID = e.Produto_ID

WHERE p.Categoria = 'Bicicletas'
and p.Preco BETWEEN @Preco_INI and @Preco_FIM

ORDER BY Distancia ASC

/*
Produto_ID	Preco	Categoria	Embedding_Texto
992			539,99	Bicicletas	# Produto: Mountain-500 Preto, 48. # Modelo: Mountain-500. # Categoria: Bicicletas. # Subcategoria: Mountain Bikes. # Cor: Preto. # Descrição: Ideal para qualquer tipo de pedalada, no asfalto ou fora dele. Cabe em qualquer orçamento. Trocas de marcha suaves e pedalada confortável.
989			539,99	Bicicletas	# Produto: Mountain-500 Preto, 40. # Modelo: Mountain-500. # Categoria: Bicicletas. # Subcategoria: Mountain Bikes. # Cor: Preto. # Descrição: Ideal para qualquer tipo de pedalada, no asfalto ou fora dele. Cabe em qualquer orçamento. Trocas de marcha suaves e pedalada confortável.
991			539,99	Bicicletas	# Produto: Mountain-500 Preto, 44. # Modelo: Mountain-500. # Categoria: Bicicletas. # Subcategoria: Mountain Bikes. # Cor: Preto. # Descrição: Ideal para qualquer tipo de pedalada, no asfalto ou fora dele. Cabe em qualquer orçamento. Trocas de marcha suaves e pedalada confortável.
993			539,99	Bicicletas	# Produto: Mountain-500 Preto, 52. # Modelo: Mountain-500. # Categoria: Bicicletas. # Subcategoria: Mountain Bikes. # Cor: Preto. # Descrição: Ideal para qualquer tipo de pedalada, no asfalto ou fora dele. Cabe em qualquer orçamento. Trocas de marcha suaves e pedalada confortável.
990			539,99	Bicicletas	# Produto: Mountain-500 Preto, 42. # Modelo: Mountain-500. # Categoria: Bicicletas. # Subcategoria: Mountain Bikes. # Cor: Preto. # Descrição: Ideal para qualquer tipo de pedalada, no asfalto ou fora dele. Cabe em qualquer orçamento. Trocas de marcha suaves e pedalada confortável.
*/


/***********************************************************
 WHERE (pós-filtro) 

 - VECTOR_SEARCH é resolvido primeiro utilizando o
   Vector Index Seek.

 - Filtro WHERE resolvido depois no Clustered Index Seek.
************************************************************/
 DROP INDEX IF EXISTS IX_dbo_Produto_Embedding ON dbo.Produto_Embedding
go
CREATE VECTOR INDEX IX_dbo_Produto_Embedding
ON dbo.Produto_Embedding (Embedding)
WITH (METRIC = 'cosine', TYPE = 'diskann')
go
 
-- Busca Vetorial Aproximada
go
DECLARE @Pergunta varchar(2000) = 'Qual a melhor bicicleta para pedalar no meio do mato, em caminhos de terra e pedra'
DECLARE @Top int = 5
DECLARE @Preco_INI money = 500.0
DECLARE @Preco_FIM money = 1000.0

DECLARE @VetorPergunta vector(768) = AI_GENERATE_EMBEDDINGS(@Pergunta USE MODEL EmbeddingGemma)

SELECT TOP (@Top) e.Produto_ID, p.Preco, p.Categoria, p.Embedding_Texto, p.Descricao ,vs.distance as Distancia
FROM VECTOR_SEARCH(
TABLE = dbo.Produto_Embedding as e,
COLUMN = Embedding,
SIMILAR_TO = @VetorPergunta,
METRIC = 'cosine',
TOP_N  = 50
) as vs

JOIN dbo.Produto p ON p.Produto_ID = e.Produto_ID
WHERE p.Categoria = 'Bicicletas'
and p.Preco BETWEEN @Preco_INI and @Preco_FIM

ORDER BY vs.distance

/*
Produto_ID	Preco	Categoria	Embedding_Texto
992			539,99	Bicicletas	# Produto: Mountain-500 Preto, 48. # Modelo: Mountain-500. # Categoria: Bicicletas. # Subcategoria: Mountain Bikes. # Cor: Preto. # Descrição: Ideal para qualquer tipo de pedalada, no asfalto ou fora dele. Cabe em qualquer orçamento. Trocas de marcha suaves e pedalada confortável.
989			539,99	Bicicletas	# Produto: Mountain-500 Preto, 40. # Modelo: Mountain-500. # Categoria: Bicicletas. # Subcategoria: Mountain Bikes. # Cor: Preto. # Descrição: Ideal para qualquer tipo de pedalada, no asfalto ou fora dele. Cabe em qualquer orçamento. Trocas de marcha suaves e pedalada confortável.
991			539,99	Bicicletas	# Produto: Mountain-500 Preto, 44. # Modelo: Mountain-500. # Categoria: Bicicletas. # Subcategoria: Mountain Bikes. # Cor: Preto. # Descrição: Ideal para qualquer tipo de pedalada, no asfalto ou fora dele. Cabe em qualquer orçamento. Trocas de marcha suaves e pedalada confortável.
993			539,99	Bicicletas	# Produto: Mountain-500 Preto, 52. # Modelo: Mountain-500. # Categoria: Bicicletas. # Subcategoria: Mountain Bikes. # Cor: Preto. # Descrição: Ideal para qualquer tipo de pedalada, no asfalto ou fora dele. Cabe em qualquer orçamento. Trocas de marcha suaves e pedalada confortável.
990			539,99	Bicicletas	# Produto: Mountain-500 Preto, 42. # Modelo: Mountain-500. # Categoria: Bicicletas. # Subcategoria: Mountain Bikes. # Cor: Preto. # Descrição: Ideal para qualquer tipo de pedalada, no asfalto ou fora dele. Cabe em qualquer orçamento. Trocas de marcha suaves e pedalada confortável.
*/


