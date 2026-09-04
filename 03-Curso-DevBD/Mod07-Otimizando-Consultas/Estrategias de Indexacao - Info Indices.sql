/**********************************************************************
 Autor: Landry

 - Informações sobre indices
***********************************************************************/
use AdventureWorks
go

SELECT * FROM sys.indexes 
/*
https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-indexes-transact-sql?view=sql-server-ver16

index_id
0   = Heap
1   = Clustered index
> 1 = Nonclustered index

type
0 = Heap
1 = Clustered rowstore (B-tree)
2 = Nonclustered rowstore (B-tree)
3 = XML
4 = Spatial
5 = Clustered columnstore index. Applies to: SQL Server 2014 (12.x) and later.
6 = Nonclustered columnstore index. Applies to: SQL Server 2012 (11.x) and later.
7 = Nonclustered hash index. Applies to: SQL Server 2014 (12.x) and later.
*/

/*****************************
 Tabelas e seus índices
******************************/
SELECT object_name(t.object_id) as Tabela, i.name as Indice,
case i.[type] 
when 0 then 'Heap'
when 1 then 'Clustered B-tree'
when 2 then 'Nonclustered B-tree'
when 3 then 'XML'
when 4 then 'Spatial'
when 5 then 'Clustered columnstore'
when 6 then 'Nonclustered columnstore'
when 7 then 'Nonclustered hash columnstore'
end as Tipo
FROM sys.indexes i
JOIN sys.tables t on t.object_id = i.object_id
WHERE OBJECTPROPERTY(t.[object_id],'IsUserTable') = 1
and i.[type] = 2 -- Nonclustered B-tree

/*************************
 Uso dos índices
**************************/
SELECT OBJECT_NAME(a.[object_id]) as Tabela, b.[name] as Indice, b.[type_desc] as Tipo,
case when b.is_primary_key = 1 then'Sim' else 'Não' end as PK,
a.user_seeks as Seeks, a.user_scans as Scans, a.user_lookups as Lookups, a.user_updates as Updates,
a.user_seeks + a.user_scans + a.user_lookups as TotalOperacoes

FROM sys.dm_db_index_usage_stats a
JOIN sys.indexes b on a.[object_id] = b.[object_id] and a.index_id = b.index_id
WHERE OBJECTPROPERTY(a.[object_id],'IsUserTable') = 1
and b.[name] is not null
--and b.[type_desc] = 'NONCLUSTERED'
ORDER BY TotalOperacoes


/*************************************
 Indices com mesma chave
**************************************/
use Aula
go

DROP TABLE If exists Cliente
go
CREATE TABLE Cliente (
Cliente_ID int not null primary key,
Nome varchar(50) not null,
CPF varchar(14) not null,
Credito char(2) not null,
FaixaRendaAnual varchar(100) null,
Telefone varchar(100) null,
Endereco varchar(200) null)
go

CREATE INDEX ix_Cliente_Credito ON Cliente (Credito,FaixaRendaAnual)
INCLUDE (Nome,CPF)
go
CREATE INDEX ix_Cliente_FaixaRendaAnual1 ON Cliente (FaixaRendaAnual,Credito)
INCLUDE (Nome,CPF)
go
CREATE INDEX ix_Cliente_FaixaRendaAnual2 ON Cliente (FaixaRendaAnual,Credito)
go

/**************************************************
 Identificar índices com mesma chave
***************************************************/

-- Lista índices ordenando por chave
SELECT distinct object_name(i.object_id) as Tabela,i.name as Indice,
(SELECT distinct stuff((select ', ' + c.name
 FROM sys.index_columns ic1 
 JOIN sys.columns c ON ic1.object_id = c.object_id and ic1.column_id = c.column_id
 WHERE ic1.index_id = ic.index_id and ic1.object_id = i.object_id and ic1.index_id = i.index_id
       and ic1.is_included_column = 0
 ORDER BY key_ordinal FOR XML PATH('')),1,2,'')
 FROM sys.index_columns ic 
 WHERE object_id=i.object_id and index_id=i.index_id) as Colunas_Chave

FROM sys.indexes i 
JOIN sys.index_columns ic on i.object_id=ic.object_id and i.index_id=ic.index_id 
WHERE OBJECTPROPERTY(i.[object_id],'IsUserTable') = 1



-- Retorna índices duplicados
;WITH CTE_Indices as (
SELECT distinct object_name(i.object_id) as Tabela,i.name as Indice,
(SELECT distinct stuff((select ', ' + c.name
 FROM sys.index_columns ic1 
 JOIN sys.columns c ON ic1.object_id = c.object_id and ic1.column_id = c.column_id
 WHERE ic1.index_id = ic.index_id and ic1.object_id = i.object_id and ic1.index_id = i.index_id
       and ic1.is_included_column = 0
 ORDER BY key_ordinal FOR XML PATH('')),1,2,'')
 FROM sys.index_columns ic 
 WHERE object_id=i.object_id and index_id=i.index_id) as Colunas_Chave

FROM sys.indexes i 
JOIN sys.index_columns ic on i.object_id=ic.object_id and i.index_id=ic.index_id 
WHERE OBJECTPROPERTY(i.[object_id],'IsUserTable') = 1),

CTE_Duplicados as (
SELECT Tabela, Colunas_Chave, count(*) as Linhas
FROM CTE_Indices
GROUP BY Tabela, Colunas_Chave
HAVING count(*) > 1)


SELECT a.Tabela, a.Indice, a.Colunas_Chave
FROM CTE_Indices a
JOIN CTE_Duplicados b on b.Tabela = a.Tabela and b.Colunas_Chave = a.Colunas_Chave