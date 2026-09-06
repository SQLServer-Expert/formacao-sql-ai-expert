# Como e quando utilizar o `DBCC CHECKDB`

O `DBCC CHECKDB` é a principal ferramenta do SQL Server para **verificar a integridade física e lógica de um banco de dados**. Ele ajuda a identificar páginas suspeitas, inconsistências e possíveis corrupções.

## Sintaxe básica

```sql
DBCC CHECKDB (NomeDoBanco);
```

Exemplo:

```sql
DBCC CHECKDB (VendasDB);
```

Para reduzir mensagens informativas e obter o resultado em formato tabular:

```sql
DBCC CHECKDB (VendasDB)
WITH NO_INFOMSGS, TABLERESULTS;
```

- `NO_INFOMSGS`: omite mensagens meramente informativas.
- `TABLERESULTS`: retorna os resultados em formato de tabela.

## Quando executar

O comando deve ser utilizado principalmente:

- Quando ocorrerem erros de I/O ou de consistência, como o **erro 824**.
- Quando consultas apresentarem falhas inesperadas ou derrubarem a conexão.
- Como parte de uma rotina periódica de monitoramento da integridade dos bancos.
- Antes de determinadas operações de manutenção, conforme a política operacional do ambiente.
- Após identificar páginas suspeitas ou outros sinais de corrupção.

Também é recomendável configurar uma rotina de verificação agendada, por exemplo, por meio do SQL Server Agent, e monitorar os resultados.

## Consultando páginas suspeitas

O SQL Server mantém informações sobre páginas suspeitas na tabela `msdb..suspect_pages`:

```sql
SELECT *
FROM msdb..suspect_pages;
```

Essa consulta pode complementar a execução do `DBCC CHECKDB`, especialmente em casos de erros como:

```text
Msg 824, Level 24
SQL Server detected a logical consistency-based I/O error
```

## O que fazer se forem encontradas inconsistências

O `DBCC CHECKDB` deve ser usado inicialmente para **diagnóstico**. Não se deve começar executando uma opção de reparo sem avaliar os backups disponíveis.

Se houver corrupção, a abordagem preferencial deve considerar a recuperação a partir de backups confiáveis. Caso não exista backup utilizável, uma alternativa de último recurso pode ser:

```sql
ALTER DATABASE VendasDB
SET SINGLE_USER
WITH ROLLBACK IMMEDIATE;

DBCC CHECKDB (VendasDB, REPAIR_ALLOW_DATA_LOSS);

ALTER DATABASE VendasDB
SET MULTI_USER;
```

A opção `REPAIR_ALLOW_DATA_LOSS` pode remover ou descartar dados para conseguir reparar a estrutura. Portanto, seu uso deve ser tratado como **último recurso**, pois o banco pode voltar a ficar acessível, mas com perda de dados ou de registros.

## Boas práticas complementares

- Mantenha backups confiáveis e recentes.
- Agende verificações regulares com `DBCC CHECKDB`.
- Monitore a tabela `msdb..suspect_pages`.
- Configure alertas para o erro 824, por exemplo:

```sql
EXEC msdb.dbo.sp_add_alert
    @name = N'Suspect Pages Error',
    @message_id = 824,
    @enabled = 1,
    @include_event_description_in = 5;
```

## Resumo

Em resumo: utilize o `DBCC CHECKDB` regularmente para prevenção e imediatamente diante de erros de consistência. Use opções de reparo somente após avaliar os backups e os riscos de perda de dados.
