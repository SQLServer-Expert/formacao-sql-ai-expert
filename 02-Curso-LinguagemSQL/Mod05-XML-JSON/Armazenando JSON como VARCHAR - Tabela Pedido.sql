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
Detalhes nvarchar(max)  -- coluna JSON
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

-- Pedido 11 - 1 item, pix, AM, sem observacao
INSERT INTO Pedido VALUES (11, 'Tatiane Oliveira', '2024-03-20 17:10:00', 'Processando', N'{
  "entrega": {
    "logradouro": "Rua Recife",
    "numero": "88",
    "cidade": "Manaus",
    "estado": "AM",
    "cep": "69057-070"
  },
  "pagamento": { "forma": "pix", "parcelas": 1 },
  "itens": [
    { "produto": "Curso SQL Server", "quantidade": 1, "valor": 197.90 }
  ],
  "frete": 35.00
}');

-- Pedido 12 - JSON INVÁLIDO (proposital para demonstrar ISJSON)
INSERT INTO Pedido VALUES (12, 'Bruno Cavalcanti', '2024-03-25 12:00:00', 'Erro', N'isso não é um JSON válido {{ produto: Curso SQL Server }');
go

/******************************* FIM CRIA TABELA **********************************/


-- Mostra Tabela dbo.Pedido com uma linha contendo JSON inválido
SELECT PedidoId, ClienteNome, [Status], Detalhes, ISJSON(Detalhes) AS JsonValido
FROM dbo.Pedido
