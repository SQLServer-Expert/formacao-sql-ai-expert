# O que são Tabelas Temporais?

As **Tabelas Temporais** (*Temporal Tables*) do SQL Server mantêm automaticamente o histórico das alterações realizadas nos dados.

Elas são compostas por:

- **Tabela principal**: contém os dados atuais.
- **Tabela de histórico**: armazena as versões anteriores das linhas.
- **Colunas de período**: indicam quando cada versão foi válida.

Quando ocorre um `UPDATE` ou `DELETE`, o SQL Server copia automaticamente a versão anterior para a tabela de histórico. Isso ocorre sem a necessidade de triggers ou código adicional.

> Tabelas temporais não devem ser confundidas com tabelas temporárias (`#Tabela`).

## Requisitos

De acordo com o SQL Server:

- Versão mínima: **SQL Server 2016**.
- Compatibility level **130 ou superior**.
- A tabela deve possuir uma chave primária.
- Devem ser definidas duas colunas `datetime2` com `GENERATED ALWAYS`:
  - início da validade da linha;
  - fim da validade da linha.

## Criando uma tabela temporal

```sql
CREATE TABLE dbo.Cliente
(
    Cliente_ID int NOT NULL PRIMARY KEY,
    Nome varchar(50) NOT NULL,
    RendaMensal decimal(10,2) NULL,

    RendaAnual AS RendaMensal * 12,

    SysStartTime datetime2
        GENERATED ALWAYS AS ROW START HIDDEN,

    SysEndTime datetime2
        GENERATED ALWAYS AS ROW END HIDDEN,

    PERIOD FOR SYSTEM_TIME
        (SysStartTime, SysEndTime)
)
WITH
(
    SYSTEM_VERSIONING = ON
    (
        HISTORY_TABLE = dbo.Cliente_Hist
    )
);
```

Nesse exemplo:

- `Cliente` é a tabela principal.
- `Cliente_Hist` é a tabela de histórico.
- `SysStartTime` e `SysEndTime` controlam o período de validade de cada versão.
- `HIDDEN` faz com que essas colunas não apareçam em um `SELECT *`.

Se `HISTORY_TABLE` for omitido, o SQL Server poderá criar uma tabela de histórico com um nome padrão.

## Inserindo dados

```sql
INSERT INTO dbo.Cliente
(
    Cliente_ID,
    Nome,
    RendaMensal
)
VALUES
    (1, 'Paulo', 10000.00),
    (2, 'Ana', 20000.00),
    (3, 'Katia', 30000.00);
```

A versão inserida ficará inicialmente na tabela principal.

## Atualizando dados

```sql
UPDATE dbo.Cliente
SET RendaMensal = 12000.00
WHERE Cliente_ID = 1;
```

Após o `UPDATE`:

- A nova versão ficará em `dbo.Cliente`.
- A versão anterior, com `RendaMensal = 10000.00`, será armazenada automaticamente em `dbo.Cliente_Hist`.

## Excluindo dados

```sql
DELETE FROM dbo.Cliente
WHERE Cliente_ID = 2;
```

Nesse caso, a versão existente do cliente será preservada na tabela de histórico, mesmo que não exista mais na tabela principal.

## Consultando os dados atuais

```sql
SELECT
    Cliente_ID,
    Nome,
    RendaMensal,
    RendaAnual
FROM dbo.Cliente;
```

Para exibir também as colunas de controle:

```sql
SELECT
    Cliente_ID,
    Nome,
    RendaMensal,
    RendaAnual,
    SysStartTime,
    SysEndTime
FROM dbo.Cliente;
```

## Consultando o histórico

A cláusula `FOR SYSTEM_TIME` permite consultar as versões temporais dos dados.

### Todas as versões

```sql
SELECT
    Cliente_ID,
    Nome,
    RendaMensal,
    SysStartTime,
    SysEndTime
FROM dbo.Cliente
FOR SYSTEM_TIME ALL
WHERE Cliente_ID = 1;
```

Essa consulta retorna tanto a versão atual quanto as versões anteriores encontradas na tabela de histórico.

### Estado dos dados em determinado momento

Para saber como os dados estavam em uma data e hora específicas:

```sql
SELECT
    Cliente_ID,
    Nome,
    RendaMensal
FROM dbo.Cliente
FOR SYSTEM_TIME AS OF '2024-01-15 10:00:00'
WHERE Cliente_ID = 1;
```

Esse tipo de consulta é útil para auditoria e para descobrir como os dados estavam em um determinado instante.

## Habilitando temporalidade em uma tabela existente

Considere uma tabela já criada:

```sql
CREATE TABLE dbo.Produto
(
    Produto_ID int NOT NULL PRIMARY KEY,
    Descricao varchar(50) NOT NULL,
    ValorUnitario decimal(10,2) NULL
);
```

Primeiro, adicione as colunas de período:

```sql
ALTER TABLE dbo.Produto
ADD
    SysStartTime datetime2
        GENERATED ALWAYS AS ROW START HIDDEN
        CONSTRAINT DF_Produto_SysStart
        DEFAULT SYSUTCDATETIME(),

    SysEndTime datetime2
        GENERATED ALWAYS AS ROW END HIDDEN
        CONSTRAINT DF_Produto_SysEnd
        DEFAULT CONVERT(datetime2, '9999-12-31 23:59:59'),

    PERIOD FOR SYSTEM_TIME
        (SysStartTime, SysEndTime);
```

Depois, habilite o versionamento:

```sql
ALTER TABLE dbo.Produto
SET
(
    SYSTEM_VERSIONING = ON
    (
        HISTORY_TABLE = dbo.Produto_Hist
    )
);
```

## Quando utilizar

Tabelas temporais são especialmente úteis quando é necessário:

- Manter rastreabilidade e auditoria nativas.
- Consultar o estado dos dados em momentos anteriores.
- Preservar automaticamente versões antigas.
- Evitar a implementação de triggers ou lógica adicional para histórico.

Em resumo, basta realizar os `INSERT`, `UPDATE` e `DELETE` normalmente. O SQL Server gerencia automaticamente a tabela de histórico e o período de validade de cada versão.
