/*******************************************************************
 Autor: Landry Duailibe
 
 - Hands On: Azure SQL Database
********************************************************************/

-- Verifica conexão
SELECT [session_id], client_net_address
FROM sys.dm_exec_connections
WHERE [session_id] = @@SPID 
/* 
IP Público: 20.231.104.186

nslookup srv-aula-sql.database.windows.net

IP Público: 20.124.89.86
IP Privado: 10.1.1.6
*/