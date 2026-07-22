use AdventureWorks
go

/*************************************
 Uso de Indices
**************************************/
SELECT * FROM sys.dm_db_index_usage_stats
SELECT * FROM sys.indexes

SELECT OBJECT_NAME(a.[object_id]) as Tabela, b.[name] as Indice, b.[type_desc] as Tipo,
case when b.is_primary_key = 1 then'Sim' else 'Não' end as PK,
a.user_seeks as Seeks, a.user_scans as Scans, a.user_lookups as Lookups,-- a.user_updates as Updates
a.user_seeks + a.user_scans + a.user_lookups as TotalOperacoes

FROM sys.dm_db_index_usage_stats a
JOIN sys.indexes b on a.[object_id] = b.[object_id] and a.index_id = b.index_id
WHERE OBJECTPROPERTY(a.[object_id],'IsUserTable') = 1
and b.[name] is not null
and b.[type_desc] <> 'CLUSTERED' 
ORDER BY TotalOperacoes

/**************************************
 Lista Índices com Chaves e Include
***************************************/
SELECT * FROM sys.index_columns
SELECT * FROM sys.columns

SELECT distinct object_name(i.object_id) as Tabela,i.name as Indice,
(SELECT distinct stuff((select ', ' + c.name
 FROM sys.index_columns ic1 
 JOIN sys.columns c ON ic1.object_id = c.object_id and ic1.column_id = c.column_id
 WHERE ic1.index_id = ic.index_id and ic1.object_id = i.object_id and ic1.index_id = i.index_id
       and ic1.is_included_column = 0
 ORDER BY key_ordinal FOR XML PATH('')),1,2,'')
 FROM sys.index_columns ic 
 WHERE object_id=i.object_id and index_id=i.index_id) as Colunas_Chave,

isnull((SELECT distinct stuff((select ', ' + c.name
 FROM sys.index_columns ic1 
 JOIN sys.columns c ON ic1.object_id = c.object_id and ic1.column_id = c.column_id
 WHERE ic1.index_id = ic.index_id and ic1.object_id = i.object_id and ic1.index_id = i.index_id
       and ic1.is_included_column = 1
 ORDER BY key_ordinal FOR XML PATH('')),1,2,'')
 FROM sys.index_columns ic 
 WHERE object_id=i.object_id and index_id=i.index_id),'') as Colunas_Include

FROM sys.indexes i 
JOIN sys.index_columns ic on i.object_id=ic.object_id and i.index_id=ic.index_id 
WHERE OBJECTPROPERTY(i.[object_id],'IsUserTable') = 1
ORDER BY Tabela, Indice, Colunas_Chave, Colunas_Include 

-- Cria Índices duplicados
CREATE INDEX ix_Landry_Address_StateProvinceID_v1
ON Person.[Address] (StateProvinceID)
INCLUDE (AddressLine1, AddressLine2, City)

CREATE INDEX ix_Landry_Address_StateProvinceID_v2
ON Person.[Address] (StateProvinceID)
INCLUDE (AddressLine1, AddressLine2, City)

/*******************************************************************
 Cria coluna para identificar índices com mesma Chave e Include
********************************************************************/
;WITH CTE_Indices as (
SELECT distinct object_name(i.object_id) as Tabela,i.name as Indice,
(SELECT distinct stuff((select ', ' + c.name
 FROM sys.index_columns ic1 
 JOIN sys.columns c ON ic1.object_id = c.object_id and ic1.column_id = c.column_id
 WHERE ic1.index_id = ic.index_id and ic1.object_id = i.object_id and ic1.index_id = i.index_id
       and ic1.is_included_column = 0
 ORDER BY key_ordinal FOR XML PATH('')),1,2,'')
 FROM sys.index_columns ic 
 WHERE object_id=i.object_id and index_id=i.index_id) as Colunas_Chave,

isnull((SELECT distinct stuff((select ', ' + c.name
 FROM sys.index_columns ic1 
 JOIN sys.columns c ON ic1.object_id = c.object_id and ic1.column_id = c.column_id
 WHERE ic1.index_id = ic.index_id and ic1.object_id = i.object_id and ic1.index_id = i.index_id
       and ic1.is_included_column = 1
 ORDER BY key_ordinal FOR XML PATH('')),1,2,'')
 FROM sys.index_columns ic 
 WHERE object_id=i.object_id and index_id=i.index_id),'') as Colunas_Include

FROM sys.indexes i 
JOIN sys.index_columns ic on i.object_id=ic.object_id and i.index_id=ic.index_id 
WHERE OBJECTPROPERTY(i.[object_id],'IsUserTable') = 1
and i.[type_desc] in ('NONCLUSTERED','CLUSTERED'))

SELECT ROW_NUMBER() OVER (PARTITION BY Tabela, Colunas_Chave, Colunas_Include ORDER BY Indice) as Ordem,
Tabela, Indice, Colunas_Chave, Colunas_Include
FROM CTE_Indices
 
/*******************************************************************
 Retorna Índices Duplicados, com mesma Chave e Include
********************************************************************/
;WITH CTE_Indices as (
SELECT distinct object_name(i.object_id) as Tabela,i.name as Indice,
(SELECT distinct stuff((select ', ' + c.name
 FROM sys.index_columns ic1 
 JOIN sys.columns c ON ic1.object_id = c.object_id and ic1.column_id = c.column_id
 WHERE ic1.index_id = ic.index_id and ic1.object_id = i.object_id and ic1.index_id = i.index_id
       and ic1.is_included_column = 0
 ORDER BY key_ordinal FOR XML PATH('')),1,2,'')
 FROM sys.index_columns ic 
 WHERE object_id=i.object_id and index_id=i.index_id) as Colunas_Chave,

isnull((SELECT distinct stuff((select ', ' + c.name
 FROM sys.index_columns ic1 
 JOIN sys.columns c ON ic1.object_id = c.object_id and ic1.column_id = c.column_id
 WHERE ic1.index_id = ic.index_id and ic1.object_id = i.object_id and ic1.index_id = i.index_id
       and ic1.is_included_column = 1
 ORDER BY key_ordinal FOR XML PATH('')),1,2,'')
 FROM sys.index_columns ic 
 WHERE object_id=i.object_id and index_id=i.index_id),'') as Colunas_Include

FROM sys.indexes i 
JOIN sys.index_columns ic on i.object_id=ic.object_id and i.index_id=ic.index_id 
WHERE OBJECTPROPERTY(i.[object_id],'IsUserTable') = 1
and i.[type_desc] in ('NONCLUSTERED','CLUSTERED')),

CTE_Duplicado as (
SELECT ROW_NUMBER() OVER (PARTITION BY Tabela, Colunas_Chave, Colunas_Include ORDER BY Indice) as Ordem,
Tabela, Indice, Colunas_Chave, Colunas_Include
FROM CTE_Indices)
 
SELECT *
FROM CTE_Duplicado
WHERE Ordem > 1


/**********************
 Exclui Índices
***********************/
DROP INDEX Person.[Address].ix_Landry_Address_StateProvinceID_v1
DROP INDEX Person.[Address].ix_Landry_Address_StateProvinceID_v2
