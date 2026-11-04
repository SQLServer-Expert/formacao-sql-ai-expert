/*
===============================================================================
Formação SQL AI Expert
Aula : Atualizando Embeddings com Change Tracking

Objetivo:
Stored Procedure que atualiza os Embeddings utilizando o rastreamento
 das linhas alteradas, utilizando Change Tracking.

Ambiente:
- SQL Server 2025
- Ollama
- Caddy

Autor: Landry Duailibe | SQL Server Expert
===============================================================================
*/
use AdventureWorks_RAG
go

/**********************************************
 Sincroniza as últimas alterações
***********************************************/
go
DECLARE @UltimaVersao bigint
SELECT @UltimaVersao = UltimaVersao FROM dbo.CT_Controle WHERE Consumidor = 'Embeddings'

SELECT CT.Produto_ID, CT.SYS_CHANGE_OPERATION as Operacao, p.Embedding_Texto

FROM CHANGETABLE(CHANGES dbo.Produto, @UltimaVersao) CT
LEFT JOIN dbo.Produto P ON P.Produto_ID = CT.Produto_ID

WHERE CT.SYS_CHANGE_OPERATION = 'I'
OR (CT.SYS_CHANGE_OPERATION = 'U' AND (CT.SYS_CHANGE_COLUMNS IS NULL 
OR CHANGE_TRACKING_IS_COLUMN_IN_MASK(COLUMNPROPERTY(OBJECT_ID(N'dbo.Produto'), N'Produto', 'ColumnId'), CT.SYS_CHANGE_COLUMNS) = 1
OR CHANGE_TRACKING_IS_COLUMN_IN_MASK(COLUMNPROPERTY(OBJECT_ID(N'dbo.Produto'), N'Modelo', 'ColumnId'), CT.SYS_CHANGE_COLUMNS) = 1
OR CHANGE_TRACKING_IS_COLUMN_IN_MASK(COLUMNPROPERTY(OBJECT_ID(N'dbo.Produto'), N'Descricao', 'ColumnId'), CT.SYS_CHANGE_COLUMNS) = 1
OR CHANGE_TRACKING_IS_COLUMN_IN_MASK(COLUMNPROPERTY(OBJECT_ID(N'dbo.Produto'), N'SubCategoria', 'ColumnId'), CT.SYS_CHANGE_COLUMNS) = 1
OR CHANGE_TRACKING_IS_COLUMN_IN_MASK(COLUMNPROPERTY(OBJECT_ID(N'dbo.Produto'), N'Categoria', 'ColumnId'), CT.SYS_CHANGE_COLUMNS) = 1
OR CHANGE_TRACKING_IS_COLUMN_IN_MASK(COLUMNPROPERTY(OBJECT_ID(N'dbo.Produto'), N'Cor', 'ColumnId'), CT.SYS_CHANGE_COLUMNS) = 1
) )

ORDER BY CT.Produto_ID
go

SELECT Produto_ID, Data_Atualizacao
FROM dbo.Produto_Embedding
WHERE Produto_ID in (713,714,715,716,1001)
/*
Produto_ID	Data_Atualizacao
713	        2026-10-31 21:20:12.343
714	        2026-10-31 21:20:12.343
715	        2026-10-31 21:20:12.343
716	        2026-10-31 21:20:12.343
*/

-- Dispara carga
SELECT * FROM dbo.CT_Controle

EXEC dbo.spu_CT_SincronizarProduto

-- Excluida em Produto_Embedding via DELETE CASCADE da FK
DELETE dbo.Produto WHERE Produto_ID = 1001

/*****************************************
 Stored Procedure de carga
******************************************/
go
CREATE OR ALTER PROCEDURE dbo.spu_CT_SincronizarProduto
as
set nocount on
set xact_abort on

-- Uma execucao por consumidor; nao executar em transacao externa.
IF @@TRANCOUNT > 0
    THROW 50000, N'Execute a procedure sem transacao externa.', 1

DECLARE @UltimaVersao bigint, @VersaoMinima bigint, @NovaVersao bigint

BEGIN TRY
    SET TRANSACTION ISOLATION LEVEL SNAPSHOT
    BEGIN TRANSACTION

    SELECT @UltimaVersao = UltimaVersao
    FROM dbo.CT_Controle
    WHERE Consumidor = 'Embeddings'

    SET @VersaoMinima = CHANGE_TRACKING_MIN_VALID_VERSION(OBJECT_ID(N'dbo.Produto'))
    SET @NovaVersao = CHANGE_TRACKING_CURRENT_VERSION()

    IF @UltimaVersao IS NULL OR @VersaoMinima IS NULL OR @NovaVersao IS NULL
        THROW 50001, N'Controle ausente ou Change Tracking indisponivel.', 1

    IF @UltimaVersao < @VersaoMinima OR @UltimaVersao > @NovaVersao
        THROW 50002, N'Versao invalida. Reexecute a carga inicial completa.', 1

    -- Materializar a lista e os valores no mesmo snapshot.
    SELECT CT.Produto_ID, CT.SYS_CHANGE_OPERATION as Operacao, p.Embedding_Texto
    INTO #Mudancas

    FROM CHANGETABLE(CHANGES dbo.Produto, @UltimaVersao) CT
    LEFT JOIN dbo.Produto P ON P.Produto_ID = CT.Produto_ID
    
    WHERE CT.SYS_CHANGE_OPERATION = 'I'
    OR (CT.SYS_CHANGE_OPERATION = 'U' AND (CT.SYS_CHANGE_COLUMNS IS NULL 
    OR CHANGE_TRACKING_IS_COLUMN_IN_MASK(COLUMNPROPERTY(OBJECT_ID(N'dbo.Produto'), N'Produto', 'ColumnId'), CT.SYS_CHANGE_COLUMNS) = 1
    OR CHANGE_TRACKING_IS_COLUMN_IN_MASK(COLUMNPROPERTY(OBJECT_ID(N'dbo.Produto'), N'Modelo', 'ColumnId'), CT.SYS_CHANGE_COLUMNS) = 1
    OR CHANGE_TRACKING_IS_COLUMN_IN_MASK(COLUMNPROPERTY(OBJECT_ID(N'dbo.Produto'), N'Descricao', 'ColumnId'), CT.SYS_CHANGE_COLUMNS) = 1
    OR CHANGE_TRACKING_IS_COLUMN_IN_MASK(COLUMNPROPERTY(OBJECT_ID(N'dbo.Produto'), N'SubCategoria', 'ColumnId'), CT.SYS_CHANGE_COLUMNS) = 1
    OR CHANGE_TRACKING_IS_COLUMN_IN_MASK(COLUMNPROPERTY(OBJECT_ID(N'dbo.Produto'), N'Categoria', 'ColumnId'), CT.SYS_CHANGE_COLUMNS) = 1
    OR CHANGE_TRACKING_IS_COLUMN_IN_MASK(COLUMNPROPERTY(OBJECT_ID(N'dbo.Produto'), N'Cor', 'ColumnId'), CT.SYS_CHANGE_COLUMNS) = 1
    ) )

    IF exists (SELECT 1 FROM #Mudancas) BEGIN

        -- Inclui Embeddings novos
        INSERT dbo.Produto_Embedding (Produto_ID, Data_Atualizacao, Embedding)

        SELECT m.Produto_ID, SYSDATETIME() as Data_Atualizacao,
        AI_GENERATE_EMBEDDINGS(m.Embedding_Texto USE MODEL EmbeddingGemma) as Embedding
        FROM #Mudancas m
        WHERE NOT EXISTS (SELECT 1 FROM dbo.Produto_Embedding d WHERE d.Produto_ID = m.Produto_ID)

        -- Atualiza Embeddings
        UPDATE d SET 
        d.Embedding = AI_GENERATE_EMBEDDINGS(m.Embedding_Texto USE MODEL EmbeddingGemma),
        d.Data_Atualizacao = SYSDATETIME()
        FROM dbo.Produto_Embedding d
        JOIN #Mudancas m ON m.Produto_ID = d.Produto_ID
    
    END

    -- Atualiza tabela de controle somente com atualização bem-sucedida dos Embeddings
    UPDATE dbo.CT_Controle
    SET UltimaVersao = @NovaVersao, DataSincronizacao = SYSDATETIME()
    WHERE Consumidor = 'Embeddings'

    COMMIT TRANSACTION
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED

    SELECT @UltimaVersao AS VersaoAnterior, @NovaVersao AS VersaoAtual,
    COUNT(*) AS QuantidadeChavesAlteradas
    FROM #Mudancas

    SELECT * FROM #Mudancas ORDER BY Produto_ID
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    THROW;
END CATCH
go
/***************************** FIM SP ***************************/

