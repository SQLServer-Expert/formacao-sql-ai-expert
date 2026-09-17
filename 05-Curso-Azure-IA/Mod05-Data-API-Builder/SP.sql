CREATE OR ALTER PROC dbo.spu_EmbeddingsPendentes
AS
set nocount on

SELECT COUNT(*) AS Qtd
FROM dbo.BlogChunks
WHERE Embedding IS NULL
go