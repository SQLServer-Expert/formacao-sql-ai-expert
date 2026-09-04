/*******************************************************************
 Autor: Landry Duailibe
 
 - Hands On: Lista Backups
********************************************************************/
SELECT logical_database_name as Banco, backup_finish_date as DataHora_UTC,
backup_finish_date AT TIME ZONE 'UTC' AT TIME ZONE 'Bahia Standard Time' as DataHora_Local,
CASE backup_type
WHEN 'D' THEN 'Full'
WHEN 'I' THEN 'Differential'
WHEN 'L' THEN 'Transaction Log'
END as Tipo_Backup,
CASE in_retention WHEN 1 THEN 'Dentro do Período' ELSE 'Fora do Período' END as Retencao

FROM sys.dm_database_backups
WHERE 1=1
and backup_type <> 'L'
--and backup_finish_date >= '20241001'
ORDER BY backup_start_date DESC