# Tabelas Temporais no SQL Server

Uma **Tabela Temporal** é uma tabela que mantém automaticamente o histórico das alterações realizadas em seus registros.

Quando um registro é atualizado ou excluído:

- A versão anterior é armazenada em uma tabela de histórico;
- A tabela principal mantém os dados atuais;
- O SQL Server controla automaticamente o período de validade de cada versão;
- Não é necessário criar triggers ou código adicional para registrar as alterações.

Esse recurso é chamado de **system-versioned temporal table**.

## Requisitos

Para utilizar tabelas temporais:

- SQL Server **2016 ou superior**;
- Banco de dados com **compatibility level 130 ou superior**;
- Uma chave primária na tabela;
- Duas colunas `datetime2` para controlar o período da linha;
- As colunas devem ser definidas com `GENERATED ALWAYS`;
- Deve ser declarado um período com `PERIOD FOR SYSTEM_TIME`.

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

    PERIOD FOR SYSTEM_TIME (SysStartTime, SysEndTime)
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

- `Cliente` é a tabela principal;
- `Cliente_Hist` é a tabela de histórico;
- `SysStartTime` indica o início da validade da versão;
- `SysEndTime` indica o fim da validade da versão;
- `HIDDEN` faz com que as colunas de controle não apareçam em um `SELECT *`.

Também é possível deixar o SQL Server criar a tabela de histórico com um nome padrão, omitindo:

```sql
HISTORY_TABLE = dbo.Cliente_Hist
```

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
    (2, 'Ana',   20000.00),
    (3, 'Katia', 30000.00);
```

A inserção cria a versão atual do registro na tabela principal.

```sql
SELECT *
FROM dbo.Cliente;
```

Como as colunas temporais foram definidas como `HIDDEN`, elas não aparecem no `SELECT *`.

Para visualizá-las, informe as colunas explicitamente:

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

## Atualizações e exclusões

Ao executar uma atualização:

```sql
UPDATE dbo.Cliente
SET RendaMensal = 12000.00
WHERE Cliente_ID = 1;
```

O SQL Server:

1. Atualiza o registro na tabela `Cliente`;
2. Armazena automaticamente a versão anterior em `Cliente_Hist`.

O mesmo ocorre com exclusões:

```sql
DELETE FROM dbo.Cliente
WHERE Cliente_ID = 2;
```

Antes de remover o registro da tabela principal, o SQL Server mantém sua versão no histórico.

## Consultando o histórico

A tabela de histórico pode ser consultada diretamente:

```sql
SELECT *
FROM dbo.Cliente_Hist;
```

Também é possível consultar versões temporais usando `FOR SYSTEM_TIME`. Por exemplo, para consultar como a tabela estava em determinado instante:

```sql
SELECT
    Cliente_ID,
    Nome,
    RendaMensal,
    SysStartTime,
    SysEndTime
FROM dbo.Cliente
FOR SYSTEM_TIME AS OF '2025-01-01 12:00:00';
```

Esse tipo de consulta é útil para auditoria e para descobrir qual era o estado dos dados em uma data específica.

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

Adicione as colunas de controle e o período:

```sql
ALTER TABLE dbo.Produto
ADD
    SysStartTime datetime2
        GENERATED ALWAYS AS ROW START HIDDEN
        CONSTRAINT DF_SysStart
        DEFAULT SYSUTCDATETIME(),

    SysEndTime datetime2
        GENERATED ALWAYS AS ROW END HIDDEN
        CONSTRAINT DF_SysEnd
        DEFAULT CONVERT(datetime2, '9999-12-31 23:59:59'),

    PERIOD FOR SYSTEM_TIME (SysStartTime, SysEndTime);
```

Em seguida, habilite o versionamento:

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

A partir desse momento, alterações e exclusões feitas em `dbo.Produto` serão registradas automaticamente em `dbo.Produto_Hist`.

## Quando utilizar

Tabelas temporais são adequadas quando é necessário:

- Manter rastreabilidade e auditoria;
- Consultar o estado dos dados em determinado momento;
- Registrar automaticamente versões anteriores;
- Evitar a criação de triggers ou lógica adicional para controle histórico.

Em resumo, a tabela principal representa o estado atual dos dados, enquanto a tabela de histórico conserva as versões anteriores gerenciadas automaticamente pelo SQL Server.
