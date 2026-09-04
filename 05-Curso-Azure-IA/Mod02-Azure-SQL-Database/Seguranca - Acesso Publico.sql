/*******************************************************************
 Autor: Landry Duailibe
 
 - Hands On: Regras de Firewall
********************************************************************/


/************************************************

Qual o IP público do Azure SQL Database?
nslookup srv-aula-sql.database.windows.net

Obter IP Público do cliente:
https://whatismyipaddress.com/
************************************************/

SELECT [session_id], client_net_address
FROM sys.dm_exec_connections
WHERE [session_id] = @@SPID 

/********************************************
 Regra de Firewall nível do Servidor Lógico
*********************************************/
EXECUTE sp_set_firewall_rule N'Regra VM Azure','20.124.89.86','20.124.89.86'

EXECUTE sp_delete_firewall_rule @name = N'Regra VM Azure'

SELECT * FROM sys.firewall_rules


/********************************************
 Regra de Firewall nível do Banco de Dados
*********************************************/
EXECUTE sp_set_database_firewall_rule N'Regra VM Azure','20.124.89.86','20.124.89.86'

EXECUTE sp_delete_database_firewall_rule @name = N'Regra VM Azure'

SELECT * FROM sys.database_firewall_rules




