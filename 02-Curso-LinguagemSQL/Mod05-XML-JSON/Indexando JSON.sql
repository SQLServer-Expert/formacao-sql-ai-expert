/*******************************************************
 Autor: Landry Duailibe


 Hands-on: Índices para JSON
*********************************************************/
use Aula
go


/********************************************************
 Criando tabela com volume para demonstração
 - 400.000 linhas
 - 1 Gb de tamanho

 - ATENÇÃO: leva 4 minutos ou mais!
*********************************************************/
DROP TABLE IF EXISTS dbo.Pedido_JSON_Index
go

CREATE TABLE dbo.Pedido_JSON_Index (
PedidoId INT NOT NULL CONSTRAINT pk_Pedido_JSON_Index PRIMARY KEY,
ClienteNome CHAR(2000),
DataPedido DATETIME,
[Status] VARCHAR(20),
Detalhes JSON NOT NULL)
go

-- Populando com 400.000 linhas
set nocount on

DECLARE @i INT = 1
DECLARE @estados TABLE (estado VARCHAR(2), cidade VARCHAR(50))

INSERT INTO @estados VALUES
('SP','São Paulo'),('RJ','Rio de Janeiro'),('MG','Belo Horizonte'),
('RS','Porto Alegre'),('PR','Curitiba'),('BA','Salvador'),
('CE','Fortaleza'),('PE','Recife'),('GO','Goiânia'),('DF','Brasília')

DECLARE @formas TABLE (forma VARCHAR(30))
INSERT INTO @formas VALUES ('pix'),('cartao_credito'),('cartao_debito'),('boleto')

WHILE @i <= 400000
BEGIN
    DECLARE @estado    VARCHAR(2)  = (SELECT TOP 1 estado FROM @estados ORDER BY NEWID());
    DECLARE @cidade    VARCHAR(50) = (SELECT TOP 1 cidade FROM @estados WHERE estado = @estado);
    DECLARE @forma     VARCHAR(30) = (SELECT TOP 1 forma  FROM @formas  ORDER BY NEWID());
    DECLARE @parcelas  INT         = CASE WHEN @forma = 'cartao_credito' THEN (ABS(CHECKSUM(NEWID())) % 12) + 1 ELSE 1 END;
    DECLARE @frete     DECIMAL(10,2) = ROUND(RAND() * 40, 2);
    DECLARE @valor1    DECIMAL(10,2) = ROUND(100 + RAND() * 300, 2);
    DECLARE @status    VARCHAR(20) = CASE ABS(CHECKSUM(NEWID())) % 4
                                        WHEN 0 THEN 'Entregue'
                                        WHEN 1 THEN 'Em Trânsito'
                                        WHEN 2 THEN 'Processando'
                                        ELSE 'Cancelado' END;

    INSERT INTO dbo.Pedido_JSON_Index (PedidoId, ClienteNome, DataPedido, [Status], Detalhes)
    VALUES (
        @i,
        CONCAT('Cliente ', @i),
        DATEADD(DAY, -(ABS(CHECKSUM(NEWID())) % 365), GETDATE()),
        @status,
        N'{
          "entrega": {
            "logradouro": "Rua Exemplo",
            "numero": "' + CAST(@i AS VARCHAR) + '",
            "cidade": "' + @cidade + '",
            "estado": "' + @estado + '",
            "cep": "01310-100"
          },
          "pagamento": { "forma": "' + @forma + '", "parcelas": ' + CAST(@parcelas AS VARCHAR) + ' },
          "itens": [
            { "produto": "Curso SQL Server", "quantidade": 1, "valor": ' + CAST(@valor1 AS VARCHAR) + ' }
          ],
          "frete": ' + CAST(@frete AS VARCHAR) + '
        }'
    )

    SET @i = @i + 1
END
go

SELECT COUNT(*) AS TotalRegistros FROM dbo.Pedido_JSON_Index
/************************* FIM Prepara Hands On ***********************************/

/***************************************
 Consulta sem índice
****************************************/
set statistics io on

-- JSON_VALUE
SELECT PedidoId, ClienteNome, [Status],
json_value(Detalhes, '$.entrega.estado') as Estado,
JSON_VALUE(Detalhes, '$.entrega.numero') as Numero

FROM dbo.Pedido_JSON_Index
WHERE JSON_VALUE(Detalhes, '$.entrega.numero') = '12345'
-- Table 'Pedido_JSON_Index'. Scan count 5, logical reads 140600
-- Volume de IO: 140600 x 8kb = 1.124.800 kb = 1.098,43 mb = 1,07 gb

/****************************************
 Coluna Computada + Indice Nonclustered
*****************************************/
-- Cria coluna computada com expressão JSON
-- ALTER TABLE dbo.Pedido_JSON_Index DROP COLUMN EntregaNumero
ALTER TABLE dbo.Pedido_JSON_Index ADD EntregaNumero AS JSON_VALUE(Detalhes, '$.entrega.numero')
go

-- Cria índice nonclustered na coluna computada
DROP INDEX IF exists dbo.Pedido_JSON_Index.ix_Pedido_EntregaNumero
go
CREATE INDEX ix_Pedido_EntregaNumero ON dbo.Pedido_JSON_Index (EntregaNumero)
go

/**********************************
 Índice JSON
***********************************/
DROP INDEX IF EXISTS ix_JSON_Pedido_Full ON dbo.Pedido_JSON_Index
go
CREATE JSON INDEX ix_JSON_Pedido_Full
ON dbo.Pedido_JSON_Index (Detalhes)
go

DROP INDEX IF EXISTS ix_JSON_Pedido_Especifico ON dbo.Pedido_JSON_Index
go
CREATE JSON INDEX ix_JSON_Pedido_Especifico
ON dbo.Pedido_JSON_Index (Detalhes)
FOR ('$.entrega.estado', '$.pagamento.forma', '$.entrega.numero')
go

/************************************
 Arquitetura Índice JSON
*************************************/
SELECT * FROM sys.all_objects WHERE object_name(parent_object_id) = 'Pedido_JSON_Index' and [type] = 'IT'
SELECT * FROM sys.dm_db_partition_stats WHERE object_id = 338100245

-- Consulta completa
SELECT s.[name] as [Schema],ao.name AS json_index_object_name, 
ps.index_id,ps.partition_number,
ps.row_count as Linhas,
(ps.used_page_count * 8) / 1024 as Tamanho_MB

FROM sys.all_objects ao
LEFT JOIN sys.dm_db_partition_stats ps ON ao.object_id = ps.object_id
LEFT JOIN sys.schemas s on s.schema_id = ao.schema_id
WHERE OBJECT_NAME(ao.parent_object_id) = 'Pedido_JSON_Index'
and ao.[type] = 'IT'
-- Full -------> 273 + 251 = 524 MB
-- Específico -> 71 + 65 = 136 MB


/**********************************
 Consulta
***********************************/
set statistics io on

-- JSON_VALUE
SELECT PedidoId, ClienteNome, [Status],
json_value(Detalhes, '$.entrega.estado') as Estado,
JSON_VALUE(Detalhes, '$.entrega.numero') as Numero

FROM dbo.Pedido_JSON_Index
WHERE JSON_VALUE(Detalhes, '$.entrega.numero') = '12345'
/*
Cluster Index Scan -----------> Table 'Pedido_JSON_Index'. Scan count 5, logical reads 140600
Index Seek + Bookmark Lookup -> Table 'Pedido_JSON_Index'. Scan count 1, logical reads 6
*/

-- JSON_CONTAINS
SELECT PedidoId, ClienteNome, [Status],
json_value(Detalhes, '$.entrega.estado') as Estado,
JSON_VALUE(Detalhes, '$.entrega.numero') as Numero

FROM dbo.Pedido_JSON_Index
WHERE JSON_CONTAINS(Detalhes, '12345', '$.entrega.numero') = 1
/*
Cluster Index Scan -----------> Table 'Pedido_JSON_Index'. Scan count 5, logical reads 140600
JSON Index + Bookmark Lookup -> Table 'Pedido_JSON_Index'. Scan count 0, logical reads 3
                                Table 'json_index_34099162_1216000'. Scan count 1, logical reads 5
*/




/*************************
 Excluindo tabela
***************************/
DROP TABLE IF EXISTS dbo.Pedido_JSON_Index
