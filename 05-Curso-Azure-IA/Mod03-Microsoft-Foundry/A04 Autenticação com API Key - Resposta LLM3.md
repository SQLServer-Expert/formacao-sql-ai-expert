## O que é o `DBCC CHECKDB`?

`DBCC CHECKDB` verifica a **consistência física e lógica** de um banco de dados SQL Server. Ele pode identificar problemas em:

- Páginas e estruturas de alocação;
- Índices e tabelas;
- Integridade estrutural do banco;
- Relacionamentos internos entre páginas e objetos;
- Catálogos do sistema.

Exemplo básico:

```sql
DBCC CHECKDB (N'MeuBanco');
```

Para ocultar mensagens informativas e exibir apenas problemas relevantes:

```sql
DBCC CHECKDB (N'MeuBanco')
WITH NO_INFOMSGS;
```

## Quando executar?

O ideal é executar de forma **preventiva e periódica**, e não apenas quando ocorrer um erro.

Uma política comum é:

- Bancos críticos: execução semanal ou conforme a janela de manutenção;
- Bancos menores: execução diária ou semanal;
- Bancos muito grandes: combinar verificações rápidas frequentes com verificações completas em uma janela maior.

Também é recomendável executar o comando após:

- Falhas de armazenamento ou problemas de I/O;
- Desligamento inesperado do servidor;
- Mensagens de corrupção no log do SQL Server;
- Erros como `823`, `824` ou `825`;
- Restauração ou migração importante, como validação adicional.

A frequência deve considerar o tamanho do banco, o SLA e a janela disponível, pois o comando pode consumir CPU, memória, I/O e espaço em disco.

## Opção `PHYSICAL_ONLY`

Para uma verificação mais rápida, principalmente em bancos grandes:

```sql
DBCC CHECKDB (N'MeuBanco')
WITH PHYSICAL_ONLY, NO_INFOMSGS;
```

`PHYSICAL_ONLY` verifica principalmente a integridade física das páginas, cabeçalhos e estruturas de alocação. Ele pode reduzir o tempo de execução, mas **não substitui completamente** uma verificação normal com `CHECKDB`, pois não realiza todas as verificações lógicas.

Uma estratégia possível é:

```sql
-- Verificação física frequente
DBCC CHECKDB (N'MeuBanco')
WITH PHYSICAL_ONLY, NO_INFOMSGS;

-- Verificação completa em uma janela semanal
DBCC CHECKDB (N'MeuBanco')
WITH NO_INFOMSGS;
```

## O comando bloqueia o banco?

O `CHECKDB` normalmente utiliza um **database snapshot interno** para realizar a verificação, reduzindo o bloqueio das operações normais. Porém, ainda pode gerar:

- Alto consumo de I/O;
- Crescimento do arquivo de snapshot;
- Pressão sobre CPU e memória;
- Impacto no desempenho durante a execução.

Por isso, é recomendado agendá-lo fora dos horários de pico e garantir espaço livre suficiente.

## O que fazer se forem encontrados erros?

O resultado pode conter mensagens semelhantes a:

```text
CHECKDB found 0 allocation errors and 0 consistency errors
```

Esse é o resultado esperado.

Se forem encontrados erros:

1. Salve e analise toda a saída do comando;
2. Verifique o log do SQL Server e os logs do sistema operacional;
3. Investigue problemas de disco, armazenamento, memória ou controladora;
4. Prefira restaurar o banco a partir de um backup íntegro;
5. Não execute opções de reparo sem avaliar o impacto.

Os comandos de reparo incluem:

```sql
DBCC CHECKDB (N'MeuBanco', REPAIR_REBUILD);
```

e:

```sql
DBCC CHECKDB (N'MeuBanco', REPAIR_ALLOW_DATA_LOSS);
```

`REPAIR_ALLOW_DATA_LOSS` pode remover páginas, linhas ou objetos danificados. O nome é literal: **pode haver perda de dados**. Deve ser utilizado somente como último recurso, após realizar backup/cópia do estado atual e, preferencialmente, sob orientação especializada.

Em geral, a ordem de preferência é:

1. Restaurar um backup íntegro;
2. Corrigir a causa da corrupção;
3. Usar opções de reparo apenas se não houver alternativa.

## Boas práticas

- Não confunda `DBCC CHECKDB` com backup: um backup não valida completamente a consistência lógica do banco.
- Execute o `CHECKDB` também sobre bancos restaurados em um ambiente de validação.
- Monitore os tempos de execução e o espaço disponível.
- Não interrompa o comando sem necessidade.
- Não use `REPAIR_ALLOW_DATA_LOSS` como procedimento rotineiro.
- Em bancos muito grandes, avalie também comandos específicos como `DBCC CHECKTABLE` e `DBCC CHECKALLOC`, sem deixar de realizar verificações completas periodicamente.

Uma execução preventiva típica seria:

```sql
USE master;
GO

DBCC CHECKDB (N'MeuBanco')
WITH NO_INFOMSGS;
GO
```

O resultado mais importante é confirmar que não existem erros de consistência e, caso existam, investigar a causa antes de tentar qualquer reparo.
