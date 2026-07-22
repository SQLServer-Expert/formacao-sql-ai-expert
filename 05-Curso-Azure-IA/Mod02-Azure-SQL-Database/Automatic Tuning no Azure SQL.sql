/*******************************************************************
 Autor: Landry Duailibe

 - Automatic Tuning no Azure SQL Database
********************************************************************/

ALTER DATABASE AulasDB 
SET QUERY_STORE = ON 
(
OPERATION_MODE = READ_WRITE, ------------------------- Habilita captura de queries
CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30), -- Mantém histórico de 30 dias
DATA_FLUSH_INTERVAL_SECONDS = 60, -------------------- Flush para disco a cada 1 min
MAX_STORAGE_SIZE_MB = 500, --------------------------- Limite de tamanho em MB
INTERVAL_LENGTH_MINUTES = 1, ------------------------- Agregação dos dados por 1 min
SIZE_BASED_CLEANUP_MODE = AUTO, ---------------------- Limpeza automática se atingir o limite
QUERY_CAPTURE_MODE = ALL, --------------------------- Captura apenas queries relevantes
MAX_PLANS_PER_QUERY = 200 ---------------------------- Limite de planos diferentes por query
)
go


--CREATE SCHEMA HandsOn
DROP TABLE IF exists HandsOn.Venda 
go
CREATE TABLE HandsOn.Venda (
OrderID int identity NOT NULL CONSTRAINT PK_Venda PRIMARY KEY,
CustomerID nchar(5) NULL,
EmployeeID int NULL,
OrderDate datetime NULL,
RequiredDate datetime NULL,
ShippedDate datetime NULL,
ShipVia int NULL,
OrderTotal money NULL,
ShipName nvarchar(40) NULL,
ShipAddress nvarchar(60) NULL,
ShipCity nvarchar(15) NULL,
ShipRegion nvarchar(15) NULL,
ShipPostalCode nvarchar(10) NULL,
ShipCountry nvarchar(15) NULL)
go

-- 2min 32seg
INSERT HandsOn.Venda
(CustomerID, EmployeeID, OrderDate, RequiredDate, ShippedDate, ShipVia, OrderTotal, ShipName, ShipAddress, ShipCity, ShipRegion, ShipPostalCode, ShipCountry)
SELECT CustomerID, EmployeeID, OrderDate, RequiredDate, ShippedDate, ShipVia, Freight as OrderTotal, ShipName, ShipAddress, ShipCity, ShipRegion, ShipPostalCode, ShipCountry
FROM dbo.Orders
go 2400

SELECT count(*) FROM HandsOn.Venda -- 1.992.000 linhas


SELECT  
    actual_state_desc,          -- Estado atual (ON, OFF, READ_ONLY, READ_WRITE)
    desired_state_desc,         -- Estado desejado
    readonly_reason,            -- Motivo de estar somente leitura (se aplicável)
    current_storage_size_mb,    -- Espaço atual utilizado
    flush_interval_seconds,     -- Intervalo de gravação em disco
    interval_length_minutes,    -- Janela de agregação dos dados
    max_storage_size_mb,        -- Tamanho máximo permitido
    query_capture_mode_desc,    -- Modo de captura (ALL, AUTO, NONE)
    size_based_cleanup_mode_desc,
    stale_query_threshold_days, -- Retenção dos dados (dias)
    max_plans_per_query,
    wait_stats_capture_mode_desc
FROM sys.database_query_store_options

-- Limpa Histórico Query Store
ALTER DATABASE current SET QUERY_STORE CLEAR ALL


/********************************
 3 Consultas 3 Missing Indexes
*********************************/
SELECT sum(OrderTotal) as OrderTotal
FROM HandsOn.Venda
WHERE OrderDate >= '19960705' and OrderDate < '19960706'
/*
Missing Index (Impact 95.6948): CREATE NONCLUSTERED INDEX [<Name of Missing Index, sysname,>] ON [HandsOn].[Venda] ([OrderDate]) 
INCLUDE ([OrderTotal])
*/

SELECT sum(OrderTotal) as OrderTotal
FROM HandsOn.Venda
WHERE OrderDate >= '19960701' and OrderDate < '19960731'
and CustomerID = 'HANAR'
/*
Missing Index (Impact 99.7161): CREATE NONCLUSTERED INDEX [<Name of Missing Index, sysname,>] ON [HandsOn].[Venda] ([CustomerID],[OrderDate]) 
INCLUDE ([OrderTotal])
*/

SELECT EmployeeID, count(*) as QtdOrders, sum(OrderTotal) as OrderTotal 
FROM HandsOn.Venda
WHERE OrderDate >= '19960701' and OrderDate < '19960731'
GROUP BY EmployeeID
ORDER BY OrderTotal DESC
/*
Missing Index (Impact 94.416): CREATE NONCLUSTERED INDEX [<Name of Missing Index, sysname,>] ON [HandsOn].[Venda] ([OrderDate]) 
INCLUDE ([EmployeeID],[OrderTotal])
*/


/*******************************
 Executar no SQLQueryStress
 Interactions: 100000
 Threads: 4
********************************/
SET NOCOUNT ON

SELECT sum(OrderTotal) as OrderTotal
FROM HandsOn.Venda
WHERE OrderDate >= '19960705' and OrderDate < '19960706'

SELECT sum(OrderTotal) as OrderTotal
FROM HandsOn.Venda
WHERE OrderDate >= '19960701' and OrderDate < '19960731'
and CustomerID = 'HANAR'

SELECT EmployeeID, count(*) as QtdOrders, sum(OrderTotal) as OrderTotal 
FROM HandsOn.Venda
WHERE OrderDate >= '19960701' and OrderDate < '19960731'
GROUP BY EmployeeID
ORDER BY OrderTotal DESC

/* 
- Recomendação do Auto Tuning
- Levou 12 horas para recomendação aparecer

CREATE NONCLUSTERED INDEX [nci_msft_1_Venda_91A256C773197B8A3BCD2726F76398E2] ON [HandsOn].[Venda] ([OrderDate]) 
INCLUDE ([EmployeeID], [OrderTotal]) WITH (ONLINE = ON)
*/



SELECT * FROM sys.database_automatic_tuning_options 

SELECT * FROM sys.dm_db_tuning_recommendations

-- Indices
SELECT Type as Tipo, Score,
JSON_VALUE([state],'$.currentValue') as [Status],
JSON_VALUE([state],'$.lastChange') as UltimaAtualizacao,
JSON_VALUE(details,'$.createIndexDetails.indexType') as TipoDoIndice,
JSON_VALUE(details,'$.createIndexDetails.estimatedImpact') as TamanhoEstimado,
JSON_VALUE(details,'$.implementationDetails.script') as ScriptSQL,
[State], [Details]

FROM sys.dm_db_tuning_recommendations
ORDER BY score DESC

CREATE NONCLUSTERED INDEX [nci_msft_1_Venda_91A256C773197B8A3BCD2726F76398E2] 
ON [HandsOn].[Venda] ([OrderDate]) 
INCLUDE ([EmployeeID], [OrderTotal]) WITH (ONLINE = ON)
