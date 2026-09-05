# Tabelas temporais no SQL Server

A base de conhecimento fornecida trata de problemas relacionados à **TempDB**, que é diferente de **tabelas temporais**.

- **TempDB**: banco de sistema usado para operações temporárias, ordenações, tabelas temporárias etc.
- **Tabela temporal**: tabela que mantém automaticamente o histórico das alterações feitas nos dados.

No SQL Server, as tabelas temporais são chamadas de **system-versioned temporal tables**.

## Como funcionam

Uma tabela temporal possui:

1. Uma tabela principal, com os dados atuais.
2. Uma tabela de histórico, com as versões anteriores dos registros.
3. Duas colunas que indicam o período de validade de cada versão:
   - início da validade;
   - fim da validade.

Quando um registro é atualizado ou excluído, o SQL Server move automaticamente a versão anterior para a tabela de histórico.

## Criando uma tabela temporal

```sql
CREATE TABLE dbo.Cliente
(
    ClienteId INT NOT NULL
        CONSTRAINT PK_Cliente PRIMARY KEY,

    Nome NVARCHAR(150) NOT NULL,

    DataInicio DATETIME2(7)
        GENERATED ALWAYS AS ROW START
        CONSTRAINT DF_Cliente_DataInicio
        DEFAULT SYSUTCDATETIME()
        NOT NULL,

    DataFim DATETIME2(7)
        GENERATED ALWAYS AS ROW END
        CONSTRAINT DF_Cliente_DataFim
        DEFAULT CONVERT(
            DATETIME2(7),
            '9999-12-31 23:59:59.9999999'
        )
        NOT NULL,

    PERIOD FOR SYSTEM_TIME (DataInicio, DataFim)
)
WITH
(
    SYSTEM_VERSIONING = ON
    (
        HISTORY_TABLE = dbo.ClienteHistorico,
        DATA_CONSISTENCY_CHECK = ON
    )
);
```

Nesse exemplo:

- `dbo.Cliente` contém os dados atuais.
- `dbo.ClienteHistorico` armazena as versões anteriores.
- `DataInicio` e `DataFim` são preenchidas e controladas pelo SQL Server.
- O período é baseado no relógio do sistema do SQL Server.

## Inserindo e alterando dados

A utilização da tabela é semelhante à de uma tabela comum:

```sql
INSERT INTO dbo.Cliente
(
    ClienteId,
    Nome
)
VALUES
(
    1,
    N'Cliente A'
);

UPDATE dbo.Cliente
SET Nome = N'Cliente A - Atualizado'
WHERE ClienteId = 1;

DELETE FROM dbo.Cliente
WHERE ClienteId = 1;
```

Após o `UPDATE`, a versão anterior será armazenada automaticamente na tabela de histórico.

Após o `DELETE`, o registro excluído também permanecerá disponível no histórico.

## Consultando o histórico

### Consultar o estado da tabela em um instante específico

```sql
DECLARE @DataConsulta DATETIME2(7) = '2026-01-15 10:00:00';

SELECT *
FROM dbo.Cliente
FOR SYSTEM_TIME AS OF @DataConsulta;
```

### Consultar todas as versões

```sql
SELECT *
FROM dbo.Cliente
FOR SYSTEM_TIME ALL
WHERE ClienteId = 1
ORDER BY DataInicio;
```

### Consultar versões dentro de um intervalo

```sql
SELECT *
FROM dbo.Cliente
FOR SYSTEM_TIME BETWEEN
    '2026-01-01 00:00:00'
    AND '2026-01-31 23:59:59.9999999'
WHERE ClienteId = 1;
```

Também é possível consultar diretamente a tabela de histórico:

```sql
SELECT *
FROM dbo.ClienteHistorico
WHERE ClienteId = 1
ORDER BY DataInicio;
```

Entretanto, normalmente é preferível utilizar `FOR SYSTEM_TIME`, pois ele considera tanto a tabela atual quanto a tabela histórica.

## Desabilitando o versionamento

Para realizar determinadas alterações estruturais, pode ser necessário desabilitar temporariamente o versionamento:

```sql
ALTER TABLE dbo.Cliente
SET (SYSTEM_VERSIONING = OFF);
```

Depois da alteração, o versionamento pode ser reativado, desde que a tabela principal e a tabela de histórico estejam compatíveis:

```sql
ALTER TABLE dbo.Cliente
SET
(
    SYSTEM_VERSIONING = ON
    (
        HISTORY_TABLE = dbo.ClienteHistorico,
        DATA_CONSISTENCY_CHECK = ON
    )
);
```

Esse procedimento exige cuidado, pois alterações feitas enquanto o versionamento estiver desligado não serão registradas automaticamente no histórico.

## Pontos importantes

- O histórico é gerenciado automaticamente pelo SQL Server.
- A tabela temporal não substitui uma estratégia completa de auditoria.
- Ela registra as versões dos dados, mas não necessariamente informa qual usuário ou aplicação realizou a alteração.
- A tabela de histórico pode crescer bastante e deve ser monitorada.
- É recomendável criar índices adequados, principalmente nas colunas de identificação e nas colunas do período.
- Tabelas temporais não são a mesma coisa que tabelas temporárias, como `#MinhaTabela`, nem estão relacionadas diretamente ao crescimento do log da `tempdb`.

## Resumo

Tabelas temporais são úteis quando é necessário consultar **como os dados estavam em determinado momento** ou acompanhar automaticamente o histórico das alterações.
