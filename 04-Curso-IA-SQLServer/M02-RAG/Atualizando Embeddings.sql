/*
===============================================================================
Formação SQL AI Expert
Aula : Atualizando Embeddings com Change Tracking

Objetivo:
 Demonstrar como atualizar os Embeddings utilizando o rastreamento
 das linhas alteradas, utilizando Change Tracking.

Ambiente:
- SQL Server 2025
- Ollama
- Caddy

Autor: Landry Duailibe | SQL Server Expert
===============================================================================
*/

use master
go


/**************************************************************
 Indicação da Microsoft para Change Tracking
 - Ativar no Banco ALLOW_SNAPSHOT_ISOLATION
 - Dados e versao sao lidos na mesma transacao SNAPSHOT.
 - O destino e local apenas para simplificar a demonstracao.
***************************************************************/
ALTER DATABASE AdventureWorks_RAG
SET CHANGE_TRACKING = ON
(CHANGE_RETENTION = 7 DAYS, AUTO_CLEANUP = ON)
go

ALTER DATABASE AdventureWorks_RAG SET ALLOW_SNAPSHOT_ISOLATION ON
go


/***************************************************
 Habilitando Change Tracking na tabela Produto
****************************************************/
use AdventureWorks_RAG
go

ALTER TABLE dbo.Produto ENABLE CHANGE_TRACKING
WITH (TRACK_COLUMNS_UPDATED = ON)
go


/*************************************************
 Alterando FK para DELETE CASCADE
**************************************************/
ALTER TABLE dbo.Produto_Embedding DROP CONSTRAINT fk_Produto_Embedding_Produto
go

ALTER TABLE dbo.Produto_Embedding ADD CONSTRAINT fk_Produto_Embedding_Produto
FOREIGN KEY (Produto_ID) REFERENCES dbo.Produto (Produto_ID) ON DELETE CASCADE
go

-- Na versão do índice disponível no SQL Server 2025, a tabela fica somente leitura.
DROP INDEX IF EXISTS IX_dbo_Produto_Embedding ON dbo.Produto_Embedding
go



/*************************************************
 Cria tabela de Controle para Change Tracking
**************************************************/
CREATE TABLE dbo.CT_Controle (
Consumidor varchar(50) NOT NULL CONSTRAINT pk_CT_Controle PRIMARY KEY,
UltimaVersao bigint NOT NULL,
DataSincronizacao datetime2(0) NOT NULL)
go

INSERT dbo.CT_Controle (Consumidor,UltimaVersao,DataSincronizacao)
VALUES ('Embeddings', CHANGE_TRACKING_CURRENT_VERSION(), SYSDATETIME())
go

/**************************************
 Metadata Change Tracking
***************************************/
-- Configuração do Banco
SELECT b.[name] as Banco,
is_auto_cleanup_on as [Auto_Cleanup],
[retention_period] as Periodo_Retencao,
[retention_period_units_desc] as Unidade_Retencao

FROM sys.change_tracking_databases a
JOIN sys.databases b on b.database_id = a.database_id

-- Configuração por Tabela
SELECT S.[name] + '.' + t.[name] as Tabela,
CT.[is_track_columns_updated_on] as Track_Colunas

FROM sys.change_tracking_tables CT
JOIN sys.tables T ON CT.[object_id] = T.[object_id]
JOIN sys.schemas S ON s.[schema_id] = T.[schema_id]


/****************************************
 Rastreando Alterações
*****************************************/
-- Retorna o contador de versão do Banco, não importa a tabela
SELECT CHANGE_TRACKING_CURRENT_VERSION()

-- Versão 1
INSERT INTO dbo.Produto
(Produto_ID, Produto_Codigo, Produto, Modelo, Descricao, SubCategoria, Categoria, Cor, Preco)
VALUES
(1001, N'LJ-ICE-VI-P', N'Camisa Manga Longa Ice Cooling, P', N'Camisa Manga Longa',
       N'Camisa de ciclismo unissex de manga longa, na cor violeta, com tecido de resfriamento por contato que proporciona sensação '
       + N'gelada na pele. Possui proteção solar UV UPF 50+, secagem rápida e painéis ventilados nas axilas. '
       + N'Indicada para pedalar em dias quentes com os braços protegidos do sol.',
       N'Camisas de Ciclismo', N'Vestuário', N'Violeta', 129.90)
go

-- Versão 2 
SELECT * FROM dbo.Produto WHERE Modelo like 'Camisa Manga Longa com Logo%'

UPDATE dbo.Produto SET Modelo = replace(Modelo,'Camisa Manga Longa com Logo', 'Camisa Manga Longa')
WHERE Modelo like 'Camisa Manga Longa com Logo%'
go

-- Versão 3 
SELECT * FROM dbo.Produto WHERE Produto_ID = 680

UPDATE dbo.Produto SET Preco = 1500.0 -- 1431,50
WHERE Produto_ID = 680
go



/***********************************
 Identitica alterações
************************************/
-- Consulta PKs alteradas
go
DECLARE @UltimaVersao bigint
SELECT @UltimaVersao = UltimaVersao FROM dbo.CT_Controle WHERE Consumidor = 'Embeddings'

PRINT @UltimaVersao

SELECT p.Produto_ID,
p.SYS_CHANGE_OPERATION as Operacao,
p.SYS_CHANGE_VERSION as Versao,
p.SYS_CHANGE_CREATION_VERSION as VersaoCriacao,
p.SYS_CHANGE_COLUMNS as ColunasAlteradas
FROM CHANGETABLE(CHANGES dbo.Produto, @UltimaVersao) p
ORDER BY p.Produto_ID
go


/**************************************************
 Identica colunas alterada
***************************************************/
go
DECLARE @UltimaVersao bigint
SELECT @UltimaVersao = UltimaVersao FROM dbo.CT_Controle WHERE Consumidor = 'Embeddings'

SELECT CT.Produto_ID, CT.SYS_CHANGE_OPERATION as Operacao,
p.Produto_Codigo, p.Produto, p.Modelo, p.Descricao, p.SubCategoria, p.Categoria, p.Cor, p.Preco,

CASE WHEN CT.SYS_CHANGE_OPERATION = 'U' 
THEN CHANGE_TRACKING_IS_COLUMN_IN_MASK(COLUMNPROPERTY(OBJECT_ID(N'dbo.Produto'), N'Produto_Codigo', 'ColumnId'), CT.SYS_CHANGE_COLUMNS) 
END as Produto_Codigo_Atualizado,

CASE WHEN CT.SYS_CHANGE_OPERATION = 'U' 
THEN CHANGE_TRACKING_IS_COLUMN_IN_MASK(COLUMNPROPERTY(OBJECT_ID(N'dbo.Produto'), N'Produto', 'ColumnId'), CT.SYS_CHANGE_COLUMNS) 
END as Produto_Atualizado,

CASE WHEN CT.SYS_CHANGE_OPERATION = 'U' 
THEN CHANGE_TRACKING_IS_COLUMN_IN_MASK(COLUMNPROPERTY(OBJECT_ID(N'dbo.Produto'), N'Modelo', 'ColumnId'), CT.SYS_CHANGE_COLUMNS) 
END as Modelo_Atualizado,

CASE WHEN CT.SYS_CHANGE_OPERATION = 'U' 
THEN CHANGE_TRACKING_IS_COLUMN_IN_MASK(COLUMNPROPERTY(OBJECT_ID(N'dbo.Produto'), N'Preco', 'ColumnId'), CT.SYS_CHANGE_COLUMNS) 
END as Preco_Atualizado

FROM CHANGETABLE(CHANGES dbo.Produto, @UltimaVersao) CT
LEFT JOIN dbo.Produto P ON P.Produto_ID = CT.Produto_ID
ORDER BY CT.Produto_ID
go
-- LEFT JOIN preserva exclusoes, devido ao FK DELETE CASCADE não seria necessário


