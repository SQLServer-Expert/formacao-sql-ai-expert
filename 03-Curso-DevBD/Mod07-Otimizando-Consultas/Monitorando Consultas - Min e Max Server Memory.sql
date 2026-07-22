/**************************************
 Demonstração
 Autor: Landry Duailibe

 - Max e Min Server Memory
***************************************/
use master
go


/**************************************************
 - Abrir Performance Monitor

 - Abrir SqlQueryStress (Erik Ejlskov Jensen)
   https://github.com/ErikEJ/SqlQueryStress

     - Number of Iterations: Quantidade de vezes que a consulta será executada em cada Thread, isto é usuário virtual.
	 - Number of Threads: Quantidade de processos simultâneos, isto é quantidade de usuários virtuais.


***************************************************/
exec sp_configure 'show advanced options', 1
go
RECONFIGURE

exec sp_configure 'max server memory', 1024
go
RECONFIGURE
go



SELECT [name], [value], [value_in_use]
FROM sys.configurations
WHERE [name] = 'max server memory (MB)' OR [name] = 'min server memory (MB)'



exec sp_configure 'max server memory', 2048
go
RECONFIGURE
go

-- Retorna para 4GB
exec sp_configure 'max server memory', 4096
go
RECONFIGURE
go


