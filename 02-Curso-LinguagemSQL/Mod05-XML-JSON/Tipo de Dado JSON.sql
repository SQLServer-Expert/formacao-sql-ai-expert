/****************************************************************
 Autor: Landry Duailibe

 Hands-on: Manipulando JSON com T-SQL 
 - Cria tabela dbo.Pedido (coluna Detalhes como NVARCHAR(MAX))
****************************************************************/
use Aula
go


/********************************************************
 Cria tabela dbo.Padidos para Hands On
*********************************************************/
DROP TABLE IF exists dbo.Pedido
go
CREATE TABLE dbo.Pedido (
PedidoId int not null CONSTRAINT pk_Pedido PRIMARY KEY,
ClienteNome varchar(100),
DataPedido datetime,
[Status] varchar(20),
Detalhes JSON  -- coluna JSON
)
go

-- =====================================================
-- INSERTs
-- =====================================================

-- Pedido 1 - 2 itens, cartao credito, SP
INSERT INTO Pedido VALUES (1, 'Fabiana Souza', '2024-01-05 10:23:00', 'Entregue', N'{
  "entrega": {
    "logradouro": "Rua das Flores",
    "numero": "142",
    "cidade": "São Paulo",
    "estado": "SP",
    "cep": "01310-100"
  },
  "pagamento": { "forma": "cartao_credito", "parcelas": 3 },
  "itens": [
    { "produto": "Curso SQL Server", "quantidade": 1, "valor": 197.90 },
    { "produto": "Curso Azure",      "quantidade": 1, "valor": 147.90 }
  ],
  "frete": 19.90,
  "observacao": "Entregar após 18h"
}');

-- Pedido 2 - 1 item, pix, RJ
INSERT INTO Pedido VALUES (2, 'Ricardo Almeida', '2024-01-08 14:45:00', 'Entregue', N'{
  "entrega": {
    "logradouro": "Av. Atlântica",
    "numero": "800",
    "cidade": "Rio de Janeiro",
    "estado": "RJ",
    "cep": "22010-000"
  },
  "pagamento": { "forma": "pix", "parcelas": 1 },
  "itens": [
    { "produto": "Curso SQL Server", "quantidade": 1, "valor": 197.90 }
  ],
  "frete": 0.00
}');

-- Pedido 3 - 3 itens, cartao credito, MG
INSERT INTO Pedido VALUES (3, 'Mariana Costa', '2024-01-12 09:10:00', 'Entregue', N'{
  "entrega": {
    "logradouro": "Rua Sapucaí",
    "numero": "310",
    "cidade": "Belo Horizonte",
    "estado": "MG",
    "cep": "30150-050"
  },
  "pagamento": { "forma": "cartao_credito", "parcelas": 6 },
  "itens": [
    { "produto": "Curso SQL Server",    "quantidade": 1, "valor": 197.90 },
    { "produto": "Curso Azure",         "quantidade": 1, "valor": 147.90 },
    { "produto": "Curso Power BI",      "quantidade": 1, "valor": 127.90 }
  ],
  "frete": 24.90,
  "observacao": "Presente, capricha na embalagem!"
}');

-- Pedido 4 - 1 item, boleto, RS
INSERT INTO Pedido VALUES (4, 'Carlos Pereira', '2024-01-15 16:30:00', 'Cancelado', N'{
  "entrega": {
    "logradouro": "Av. Borges de Medeiros",
    "numero": "2000",
    "cidade": "Porto Alegre",
    "estado": "RS",
    "cep": "90020-021"
  },
  "pagamento": { "forma": "boleto", "parcelas": 1 },
  "itens": [
    { "produto": "Curso Azure", "quantidade": 1, "valor": 147.90 }
  ],
  "frete": 15.90
}');

-- Pedido 5 - 2 itens, pix, BA
INSERT INTO Pedido VALUES (5, 'Juliana Ferreira', '2024-02-02 11:05:00', 'Entregue', N'{
  "entrega": {
    "logradouro": "Rua Chile",
    "numero": "45",
    "cidade": "Salvador",
    "estado": "BA",
    "cep": "40020-050"
  },
  "pagamento": { "forma": "pix", "parcelas": 1 },
  "itens": [
    { "produto": "Curso Power BI",   "quantidade": 1, "valor": 127.90 },
    { "produto": "Curso SQL Server", "quantidade": 1, "valor": 197.90 }
  ],
  "frete": 22.50,
  "observacao": "Ligar antes de entregar"
}');

-- Pedido 6 - 2 itens, cartao debito, PR
INSERT INTO Pedido VALUES (6, 'Anderson Lima', '2024-02-10 08:55:00', 'Em Trânsito', N'{
  "entrega": {
    "logradouro": "Rua XV de Novembro",
    "numero": "700",
    "cidade": "Curitiba",
    "estado": "PR",
    "cep": "80020-310"
  },
  "pagamento": { "forma": "cartao_debito", "parcelas": 1 },
  "itens": [
    { "produto": "Curso Azure",    "quantidade": 2, "valor": 147.90 },
    { "produto": "Curso Power BI", "quantidade": 1, "valor": 127.90 }
  ],
  "frete": 18.00
}');

-- Pedido 7 - 1 item, pix, CE, sem observacao
INSERT INTO Pedido VALUES (7, 'Patrícia Rocha', '2024-02-18 13:40:00', 'Entregue', N'{
  "entrega": {
    "logradouro": "Av. Beira Mar",
    "numero": "1200",
    "cidade": "Fortaleza",
    "estado": "CE",
    "cep": "60165-121"
  },
  "pagamento": { "forma": "pix", "parcelas": 1 },
  "itens": [
    { "produto": "Curso SQL Server", "quantidade": 1, "valor": 197.90 }
  ],
  "frete": 29.90
}');

-- Pedido 8 - 3 itens, cartao credito, DF
INSERT INTO Pedido VALUES (8, 'Fernando Gomes', '2024-03-01 10:00:00', 'Processando', N'{
  "entrega": {
    "logradouro": "SQN 310",
    "numero": "Bloco B",
    "cidade": "Brasília",
    "estado": "DF",
    "cep": "70755-020"
  },
  "pagamento": { "forma": "cartao_credito", "parcelas": 12 },
  "itens": [
    { "produto": "Curso SQL Server",    "quantidade": 1, "valor": 197.90 },
    { "produto": "Curso Azure",         "quantidade": 1, "valor": 147.90 },
    { "produto": "Curso Power BI",      "quantidade": 2, "valor": 127.90 }
  ],
  "frete": 0.00,
  "observacao": "Nota fiscal obrigatória"
}');

-- Pedido 9 - 1 item, boleto, PE
INSERT INTO Pedido VALUES (9, 'Camila Nascimento', '2024-03-05 15:20:00', 'Entregue', N'{
  "entrega": {
    "logradouro": "Av. Boa Viagem",
    "numero": "3500",
    "cidade": "Recife",
    "estado": "PE",
    "cep": "51020-001"
  },
  "pagamento": { "forma": "boleto", "parcelas": 1 },
  "itens": [
    { "produto": "Curso Power BI", "quantidade": 1, "valor": 127.90 }
  ],
  "frete": 21.00
}');

-- Pedido 10 - 2 itens, cartao credito, GO
INSERT INTO Pedido VALUES (10, 'Rodrigo Martins', '2024-03-12 09:30:00', 'Em Trânsito', N'{
  "entrega": {
    "logradouro": "Av. Goiás",
    "numero": "500",
    "cidade": "Goiânia",
    "estado": "GO",
    "cep": "74015-010"
  },
  "pagamento": { "forma": "cartao_credito", "parcelas": 2 },
  "itens": [
    { "produto": "Curso Azure",      "quantidade": 1, "valor": 147.90 },
    { "produto": "Curso SQL Server", "quantidade": 1, "valor": 197.90 }
  ],
  "frete": 17.50,
  "observacao": "Portaria 24h"
}');

/******************************* FIM CRIA TABELA **********************************/


-- Mostra Tabela dbo.Pedido com uma linha contendo JSON inválido
SELECT PedidoId, ClienteNome, [Status], Detalhes, ISJSON(Detalhes) AS JsonValido
FROM dbo.Pedido


/*******************************************
 Funções JSON também funcionam no tipo JSON
********************************************/

-- Extraindo valores escalares com JSON_VALUE
SELECT PedidoId, ClienteNome,
json_value(Detalhes, '$.entrega.cidade') as Cidade,
json_value(Detalhes, '$.entrega.estado') as Estado,
json_value(Detalhes, '$.pagamento.forma') as FormaPagamento,
cast(json_value(Detalhes, '$.frete') as decimal(10,2)) as Frete,
json_value(Detalhes, '$.observacao') as Observacao -- NULL quando ausente
FROM dbo.Pedido

-- Extraindo objetos e arrays com JSON_QUERY
SELECT PedidoId, ClienteNome,
json_query(Detalhes, '$.entrega') as DadosEntrega, -- objeto
json_query(Detalhes, '$.itens') as Itens -- array
FROM dbo.Pedido

-- Expandindo os itens com OPENJSON
SELECT p.PedidoId, p.ClienteNome, i.produto, i.quantidade,
i.valor, i.quantidade * i.valor as Subtotal

FROM dbo.Pedido p
CROSS APPLY OPENJSON(Detalhes, '$.itens')
WITH (
    produto     nvarchar(100)  '$.produto',
    quantidade  int            '$.quantidade',
    valor       decimal(10,2)  '$.valor'
) as i

/*******************************************
 JSON_MODIFY também funciona no tipo JSON
********************************************/

-- Visualizando o resultado da modificação SEM alterar a tabela
SELECT
PedidoId,
json_value(Detalhes, '$.entrega.cidade') as CidadeOriginal,
json_value(json_modify(Detalhes, '$.entrega.cidade', 'Campinas'), '$.entrega.cidade') as CidadeModificada
FROM dbo.Pedido
WHERE PedidoId = 1

-- Persistindo a alteração com UPDATE + JSON_MODIFY
UPDATE dbo.Pedido
SET Detalhes = json_modify(Detalhes, '$.entrega.cidade', 'Campinas')
WHERE PedidoId = 1

-- Confirmando
SELECT PedidoId, json_value(Detalhes, '$.entrega.cidade') as Cidade
FROM dbo.Pedido
WHERE PedidoId = 1

/*******************************************
 Novo método MODIFY() do tipo JSON
 - Modificação in-place: mais eficiente que JSON_MODIFY + UPDATE

 Sintaxe: UPDATE tabela SET coluna.modify('$.caminho', novoValor)

 https://learn.microsoft.com/en-us/sql/t-sql/data-types/json-data-type?view=sql-server-ver17#modify-method
********************************************/

SELECT PedidoId, 
json_value(Detalhes, '$.entrega.cidade') as Cidade,
json_value(Detalhes, '$.frete') as Frete
FROM dbo.Pedido
WHERE PedidoId = 2
-- Rio de Janeiro

-- Alterando um valor escalar (string)
UPDATE dbo.Pedido
SET Detalhes.modify('$.entrega.cidade', 'Santos')
WHERE PedidoId = 2


-- Alterando um valor numérico
UPDATE dbo.Pedido
SET Detalhes.modify('$.frete', 30.00)
WHERE PedidoId = 2;

-- Adicionando nova Chave / Valor com .modify()
UPDATE dbo.Pedido
SET Detalhes.modify('$.prioridade', 'Alta')
WHERE PedidoId = 2

SELECT PedidoId, 
json_value(Detalhes, '$.entrega.cidade') as Cidade,
json_value(Detalhes, '$.frete') as Frete,
json_value(Detalhes, '$.prioridade') as Prioridade
FROM dbo.Pedido
WHERE PedidoId = 2

-- Remoer apenas com 
UPDATE dbo.Pedido
SET Detalhes = json_modify(Detalhes, '$.prioridade', NULL)
WHERE PedidoId = 2

