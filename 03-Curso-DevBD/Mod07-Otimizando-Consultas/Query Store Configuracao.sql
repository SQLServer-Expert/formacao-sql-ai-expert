/*********************************************
 Autor: Landry Duailibe

 Hands On: Query Store
**********************************************/
use master
go

/***********************************
 Cria Banco para Hands On
************************************/
DROP DATABASE IF exists HandsOn
go
CREATE DATABASE HandsOn
go
ALTER DATABASE HandsOn SET RECOVERY simple
go

use HandsOn
go

/******************************
 Habilitando Query Store
*******************************/
-- Habilitando com valor padrão
ALTER DATABASE HandsOn SET QUERY_STORE (OPERATION_MODE = READ_WRITE)

-- Definindo storage de 2GB
ALTER DATABASE HandsOn SET QUERY_STORE (OPERATION_MODE = READ_WRITE, MAX_STORAGE_SIZE_MB = 2000)

-- Permissão para ver dados coletados
GRANT VIEW DATABASE STATE TO [Usuário]

-- Mostrar como acrescentar os Trace Flags 7745 e 7752 no serviço.

-- Mostrar a diferença da quantidade de eventos entre SQL Server 2019 e 2022
SELECT xo.name, xo.description
FROM sys.dm_xe_packages as xp
JOIN sys.dm_xe_objects xo on xp.guid = xo.package_guid
WHERE xp.name = 'qds' and xo.object_type = 'event'



/******************************
 Manutenção Query Store
*******************************/

-- Limpar os dados coletados
ALTER DATABASE HandsOn SET QUERY_STORE CLEAR ALL

-- Se o Query Store estiver em status de erro, basta reiniciar
-- Status normal é readonly_reason = 0

ALTER DATABASE HandsOn SET QUERY_STORE = off
ALTER DATABASE HandsOn SET QUERY_STORE = on

-- Se reiniciar não resolveu, está conrrompido, adotar o procedimento abaixo
ALTER DATABASE HandsOn SET QUERY_STORE = off
EXEC HandsOn.sys.sp_query_store_consistency_check
ALTER DATABASE HandsOn SET QUERY_STORE = on


SELECT * FROM sys.database_query_store_options
/*
Bit map readonly_reason
1 - read-onlu mode
2 - single-user mode
3 - emergency mode
6 - single-user + emergency mode
8 - Secondary replica (Always On)
65536 - reached limit set by the max_storage_size
131072 - number of different statements has reached memory limit
262144 - In-Memory size limit has been hit. Waiting to flush to disk, temporarily in read-only mnode
524288 - Disk size limit reached, cant grow anymore - Azure SQL Database.
*/

-- Mostrar
ALTER DATABASE HandsOn SET single_user
SELECT * FROM sys.database_query_store_options
-- readonly_reason = 2

ALTER DATABASE HandsOn SET emergency
SELECT * FROM sys.database_query_store_options
-- readonly_reason = 6

ALTER DATABASE HandsOn SET online

