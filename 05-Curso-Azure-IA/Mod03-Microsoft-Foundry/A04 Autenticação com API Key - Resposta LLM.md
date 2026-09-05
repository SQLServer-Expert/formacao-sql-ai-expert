# Como usar `DBCC CHECKDB` no SQL Server  
O `DBCC CHECKDB` verifica a integridade lógica e física de um banco de dados, incluindo:  
- Páginas e estruturas internas; 
- Índices; 
- Integridade de alocação; 
- Consistência entre tabelas e objetos; 
- Problemas de corrupção de dados.  

## Verificar o banco atual  
```sql 
DBCC CHECKDB; 
```  

## Verificar um banco específico  
```sql 
DBCC CHECKDB (N'MeuBanco'); 
```  
Uma opção comum para reduzir a quantidade de mensagens informativas é:  
```sql 
DBCC CHECKDB (N'MeuBanco') WITH NO_INFOMSGS; 
```  
Para exibir todas as mensagens de erro:  
```sql 
DBCC CHECKDB (N'MeuBanco') WITH ALL_ERRORMSGS; 
```  

## Verificação física mais rápida  
A opção `PHYSICAL_ONLY` concentra a verificação em estruturas físicas, como páginas, cabeçalhos e checksums:  
```sql 
DBCC CHECKDB (N'MeuBanco') WITH PHYSICAL_ONLY, NO_INFOMSGS; 
```  
Ela costuma ser usada para verificações frequentes, pois geralmente exige menos recursos. Porém, não substitui uma execução completa do `CHECKDB`.  

## Estimar o espaço necessário  
Para estimar o espaço necessário no `tempdb`:  
```sql 
DBCC CHECKDB (N'MeuBanco') WITH ESTIMATEONLY; 
```  

## Verificar uma tabela específica  
```sql 
DBCC CHECKTABLE (N'MinhaTabela') WITH NO_INFOMSGS; 
```  

## Interpretar o resultado  
Se o banco estiver íntegro, normalmente será exibida uma mensagem semelhante a:  
```text 
CHECKDB found 0 allocation errors and 0 consistency errors in database ... 
```  
Se forem encontrados erros, o SQL Server exibirá mensagens indicando:  
- O objeto afetado; 
- A página ou índice envolvido; 
- O tipo de corrupção; 
- Uma sugestão de reparo, quando aplicável.  

Também é possível consultar o log de erros do SQL Server:  
```sql 
EXEC sys.xp_readerrorlog; 
```  

## Opções de reparo  
O `DBCC CHECKDB` possui opções de reparo, mas elas devem ser usadas com muita cautela:  
```sql 
DBCC CHECKDB (N'MeuBanco', REPAIR_REBUILD) WITH NO_INFOMSGS; 
```  
Ou:  
```sql 
DBCC CHECKDB (N'MeuBanco', REPAIR_ALLOW_DATA_LOSS) WITH NO_INFOMSGS; 
```  

### `REPAIR_REBUILD`  
Pode corrigir alguns problemas sem perda de dados, principalmente relacionados a índices. Mesmo assim, deve ser usado somente após análise do problema.  

### `REPAIR_ALLOW_DATA_LOSS`  
Pode remover páginas, linhas ou objetos corrompidos. Apesar do nome, essa opção pode causar perda de dados e não deve ser a primeira alternativa.  Antes de usá-la:  
1. Faça um backup do banco; 
2. Tente restaurar um backup íntegro mais recente; 
3. Execute o `CHECKDB` em uma cópia restaurada; 
4. Avalie os erros e o impacto da perda de dados; 
5. Coloque o banco em modo de usuário único, se solicitado pelo SQL Server.  

Exemplo de modo de usuário único:  
```sql 
ALTER DATABASE [MeuBanco] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; 
```  

Após o reparo:  
```sql 
ALTER DATABASE [MeuBanco] SET MULTI_USER; 
```  

## Recomendações práticas  
- Execute o `CHECKDB` regularmente; 
- Prefira executá-lo em horários de menor utilização; 
- Monitore o uso de CPU, I/O e `tempdb`; 
- Não use `REPAIR_ALLOW_DATA_LOSS` como procedimento padrão; 
- A melhor forma de corrigir corrupção normalmente é restaurar um backup íntegro; 
- Valide periodicamente se os backups podem ser restaurados.  

Uma execução comum em ambiente de produção seria:  
```sql 
DBCC CHECKDB (N'MeuBanco') WITH NO_INFOMSGS, ALL_ERRORMSGS; 
```  
Para uma verificação física frequente:  
```sql 
DBCC CHECKDB (N'MeuBanco') WITH PHYSICAL_ONLY, NO_INFOMSGS; 
```  
A execução exige, em geral, permissões de `sysadmin` ou `db_owner`.