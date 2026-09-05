# Como usar `DBCC CHECKDB` no SQL Server  
O `DBCC CHECKDB` verifica a integridade lógica e física de um banco de dados, identificando possíveis problemas em páginas, estruturas internas, tabelas, índices e alocações.  

## Sintaxe básica  
```sql 
DBCC CHECKDB ('NomeDoBanco'); 
```  
Exemplo:  
```sql 
DBCC CHECKDB ('MinhaBase'); 
```  
Também é possível usar o banco atual:  
```sql 
USE MinhaBase; 
GO  
DBCC CHECKDB; 
```  

## Opções comuns  

### Ocultar mensagens informativas  
```sql 
DBCC CHECKDB ('MinhaBase') WITH NO_INFOMSGS; 
```  

### Verificar apenas a integridade física  
Útil para uma checagem mais rápida:  
```sql 
DBCC CHECKDB ('MinhaBase') WITH PHYSICAL_ONLY; 
```  
Essa opção verifica principalmente a consistência física das páginas e dos cabeçalhos, mas não substitui uma execução completa do `CHECKDB`.  

### Exibir todas as mensagens por objeto  
```sql 
DBCC CHECKDB ('MinhaBase') WITH ALL_ERRORMSGS; 
```  

## Exemplo recomendado para uma verificação completa  
```sql 
DBCC CHECKDB ('MinhaBase') WITH NO_INFOMSGS, ALL_ERRORMSGS; 
```  

## Se forem encontrados erros  
Primeiro, analise a saída do comando e verifique os backups disponíveis. Não execute imediatamente opções de reparo em produção.  O `DBCC CHECKDB` pode sugerir comandos como:  
```sql 
DBCC CHECKDB ('MinhaBase', REPAIR_REBUILD); 
```  
ou:  
```sql 
DBCC CHECKDB ('MinhaBase', REPAIR_ALLOW_DATA_LOSS); 
```  
`REPAIR_ALLOW_DATA_LOSS` pode causar perda de dados e deve ser considerado apenas como último recurso, preferencialmente após restaurar um backup ou trabalhar em uma cópia do banco.  
> O contexto fornecido trata de diagnóstico de crescimento do log da `tempdb`, usando `DBCC OPENTRAN`, DMVs e `KILL`, mas não detalha o `DBCC CHECKDB`. Portanto, os comandos acima são orientações gerais para verificação de integridade, não relacionadas diretamente ao diagnóstico apresentado.