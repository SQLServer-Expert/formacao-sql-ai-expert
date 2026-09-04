/**************************************
 Autor: Landry Duailibe

 HandsOn: Cópia de Banco de Dados
***************************************/


/****************************************
 Fazer uma cópia para o mesmo servidor
 - Executar no banco MASTER
 - Permissão mínima dbmanager
*****************************************/

CREATE DATABASE AulaDB_Teste AS COPY OF AulaDB

/*****************************************
 Copiar para um servidor diferente
 - Conectar no servidor destino
******************************************/
CREATE DATABASE AulaDB_Teste AS COPY OF [srv-aula-sql].AulaDB

-- Master
SELECT * FROM sys.databases
SELECT * FROM sys.dm_database_copies

SELECT operation as Operacao, major_resource_id as Banco,
state_desc [Status], percent_complete as [% Completo],
start_time as DataHora_Inicio, 
last_modify_time as DataHora_Alteracao,
start_time AT TIME ZONE 'UTC' AT TIME ZONE 'Bahia Standard Time' as DataHora_Inicio_Local, 
last_modify_time AT TIME ZONE 'UTC' AT TIME ZONE 'Bahia Standard Time' as DataHora_Alteracao_Local
FROM sys.dm_operation_status 
ORDER BY last_modify_time desc

/*******************************
 ALTER DATABASE

 MODIFY (EDITION = ['Basic' | 'Standard' | 'Premium' |'GeneralPurpose' | 'BusinessCritical' | 'Hyperscale'])
 MODIFY (SERVICE_OBJECTIVE = <service-objective>)
 MODIFY (BACKUP_STORAGE_REDUNDANCY = ['LOCAL' | 'ZONE' | 'GEO'])
 MODIFY (MAXSIZE = [100 MB | 500 MB | 1 | 1024...4096] GB)
********************************/
SELECT DATABASEPROPERTYEX('AulaDB_Teste', 'EDITION') as Edition,
DATABASEPROPERTYEX('AulaDB_Teste', 'ServiceObjective') as ServiceObjective,
(((cast(DATABASEPROPERTYEX('AulaDB_Teste', 'MaxSizeInBytes') as float) / 1024) / 1024) / 1024) as MaxSize_GB


ALTER DATABASE AulaDB_Teste MODIFY (SERVICE_OBJECTIVE = 'S1')

ALTER DATABASE AulaDB_Teste MODIFY (SERVICE_OBJECTIVE = 'S0')
ALTER DATABASE AulaDB_Teste MODIFY (MAXSIZE = 10 GB) -- Verificar em Compute + Storage

DROP DATABASE AulaDB_Teste