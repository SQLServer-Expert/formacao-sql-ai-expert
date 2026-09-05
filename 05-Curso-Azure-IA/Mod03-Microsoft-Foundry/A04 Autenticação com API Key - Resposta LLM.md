# Tabelas Temporais no SQL Server

Tabelas temporais, ou **system-versioned temporal tables**, permitem manter automaticamente o histórico das alterações de uma tabela.

Elas são úteis para responder perguntas como:

- Qual era o valor de um registro em determinada data?
- Quem tinha determinado endereço antes de uma alteração?
- Quais registros existiam em um período?
- Quando um registro foi alterado ou excluído?

> O recurso está disponível a partir do SQL Server 2016. Ele não deve ser confundido com tabelas temporárias como `#Tabela`, que existem apenas durante uma sessão.

## Como funcionam

Uma tabela temporal possui:

1. Uma tabela principal, com os dados atuais.
2. Uma tabela de histórico, gerenciada pelo SQL Server.
3. Duas colunas que representam o período de validade do registro:
   - início da validade;
   - fim da validade.

Quando um registro é atualizado:

- a versão anterior é movida para a tabela de histórico;
- a nova versão permanece na tabela principal.

Quando um registro é excluído:

- a versão excluída é armazenada no histórico.

## Criando uma tabela temporal

```sql
CREATE TABLE dbo.Cliente
(
    ClienteId int NOT NULL
        CONSTRAINT PK_Cliente PRIMARY KEY,

    Nome varchar(100) NOT NULL,
    Email varchar(200) NULL,

    ValidFrom datetime2(7)
        GENERATED ALWAYS AS ROW START
        CONSTRAINT DF_Cliente_ValidFrom
        DEFAULT SYSUTCDATETIME()
        NOT NULL,

    ValidTo datetime2(7)
        GENERATED ALWAYS AS ROW END
        CONSTRAINT DF_Cliente_ValidTo
        DEFAULT CONVERT(datetime2(7), '9999-12-31 23:59:59.9999999')
        NOT NULL,

    PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo)
)
WITH
(
    SYSTEM_VERSIONING = ON,
    HISTORY_TABLE = dbo.ClienteHistorico
);
```

Nesse exemplo:

- `dbo.Cliente` contém os dados atuais;
- `dbo.ClienteHistorico` contém as versões anteriores;
- `ValidFrom` e `ValidTo` são controladas pelo SQL Server;
- os horários são registrados em UTC.

## Inserindo e alterando dados

A utilização de `INSERT`, `UPDATE` e `DELETE` é semelhante à de uma tabela comum:

```sql
INSERT INTO dbo.Cliente (ClienteId, Nome, Email)
VALUES (1, 'Maria', 'maria@exemplo.com');
```

```sql
UPDATE dbo.Cliente
SET Email = 'maria.novo@exemplo.com'
WHERE ClienteId = 1;
```

Após o `UPDATE`, a versão anterior do cliente será armazenada automaticamente na tabela de histórico.

## Consultando os dados atuais

Sem nenhuma cláusula especial, a consulta retorna somente os dados atuais:

```sql
SELECT *
FROM dbo.Cliente;
```

## Consultando o histórico

### Todas as versões

```sql
SELECT *
FROM dbo.Cliente
FOR SYSTEM_TIME ALL
WHERE ClienteId = 1
ORDER BY ValidFrom;
```

Essa consulta pode retornar:

- a versão atual;
- versões anteriores;
- registros que foram excluídos.

### Estado em uma data específica

```sql
SELECT *
FROM dbo.Cliente
FOR SYSTEM_TIME AS OF '2025-01-15 10:30:00'
WHERE ClienteId = 1;
```

`AS OF` retorna o estado que a tabela tinha naquele instante.

### Registros válidos em um intervalo

```sql
SELECT *
FROM dbo.Cliente
FOR SYSTEM_TIME BETWEEN
    '2025-01-01 00:00:00'
    AND '2025-01-31 23:59:59'
WHERE ClienteId = 1;
```

### Versões que estiveram vigentes em um período

```sql
SELECT *
FROM dbo.Cliente
FOR SYSTEM_TIME FROM
    '2025-01-01 00:00:00'
TO
    '2025-02-01 00:00:00'
WHERE ClienteId = 1;
```

No caso de `FROM ... TO`, o limite inicial é incluído e o limite final não é incluído.

## Criando uma tabela temporal a partir de uma tabela existente

Para converter uma tabela existente, é necessário adicionar as colunas de período:

```sql
ALTER TABLE dbo.Cliente
ADD
    ValidFrom datetime2(7)
        GENERATED ALWAYS AS ROW START
        CONSTRAINT DF_Cliente_ValidFrom
        DEFAULT SYSUTCDATETIME()
        NOT NULL,

    ValidTo datetime2(7)
        GENERATED ALWAYS AS ROW END
        CONSTRAINT DF_Cliente_ValidTo
        DEFAULT CONVERT(datetime2(7), '9999-12-31 23:59:59.9999999')
        NOT NULL;
```

Depois, adicione o período:

```sql
ALTER TABLE dbo.Cliente
ADD PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo);
```

Por fim, habilite o versionamento:

```sql
ALTER TABLE dbo.Cliente
SET
(
    SYSTEM_VERSIONING = ON
    (
        HISTORY_TABLE = dbo.ClienteHistorico
    )
);
```

A tabela deve atender aos requisitos do SQL Server, incluindo valores válidos nas colunas de período e uma chave primária.

## Desabilitando o versionamento

É possível desabilitar temporariamente o versionamento:

```sql
ALTER TABLE dbo.Cliente
SET (SYSTEM_VERSIONING = OFF);
```

Depois, ele pode ser reativado:

```sql
ALTER TABLE dbo.Cliente
SET
(
    SYSTEM_VERSIONING = ON
    (
        HISTORY_TABLE = dbo.ClienteHistorico
    )
);
```

Essa operação deve ser feita com cuidado, pois alterações manuais na tabela de histórico podem comprometer a consistência temporal.

## Considerações importantes

- As colunas de período representam o **tempo do sistema**, não necessariamente uma validade de negócio.
- Os valores são controlados pelo SQL Server enquanto o versionamento está habilitado.
- Os horários normalmente são registrados em UTC.
- A tabela de histórico pode crescer bastante; é importante criar índices adequados e definir uma estratégia de retenção.
- O histórico não substitui uma auditoria completa. Por exemplo, as colunas temporais não identificam automaticamente qual usuário realizou a alteração.
- Consultas temporais devem utilizar `FOR SYSTEM_TIME` imediatamente após o nome da tabela:

```sql
SELECT *
FROM dbo.Cliente
FOR SYSTEM_TIME ALL;
```

## Resumo

Em resumo, tabelas temporais são uma forma nativa do SQL Server de manter versões dos dados e consultar o estado atual ou histórico de uma tabela sem precisar implementar gatilhos manualmente.
