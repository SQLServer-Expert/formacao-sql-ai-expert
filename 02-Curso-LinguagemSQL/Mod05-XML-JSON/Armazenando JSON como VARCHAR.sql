/*******************************************************
 Autor: Landry Duailibe


 Hands-on: Manipulando JSON com T-SQL 
*********************************************************/
use Aula
go

/*************************************************************
 ISJSON() - Validando se o conteúdo é um JSON válido
 https://learn.microsoft.com/en-us/sql/t-sql/functions/isjson-transact-sql?view=sql-server-ver17
**************************************************************/
-- Mostra Tabela dbo.Pedido com uma linha contendo JSON inválido
SELECT PedidoId, ClienteNome, [Status], Detalhes, ISJSON(Detalhes) AS JsonValido
FROM dbo.Pedido

-- Filtrando apenas registros com JSON inválidos
SELECT PedidoId, ClienteNome, [Status], Detalhes
FROM dbo.Pedido
WHERE ISJSON(Detalhes) = 1


/*************************************************************
 JSON_VALUE() - Extraindo valores escalares
 https://learn.microsoft.com/en-us/sql/t-sql/functions/json-value-transact-sql?view=sql-server-ver17
**************************************************************/

-- Extraindo cidade e estado de entrega
SELECT PedidoId, ClienteNome, Detalhes,

JSON_VALUE(Detalhes, '$.entrega.cidade') as Cidade,
JSON_VALUE(Detalhes, '$.entrega.estado') as Estado

FROM dbo.Pedido
WHERE ISJSON(Detalhes) = 1

-- Extraindo forma de pagamento e parcelas
SELECT PedidoId, ClienteNome, Detalhes,

JSON_VALUE(Detalhes, '$.pagamento.forma') as FormaPagamento,
CAST(JSON_VALUE(Detalhes, '$.pagamento.parcelas') as INT) as Parcelas

FROM dbo.Pedido
WHERE ISJSON(Detalhes) = 1

-- Extraindo frete (convertendo para DECIMAL)
SELECT PedidoId, ClienteNome, Detalhes,

CAST(JSON_VALUE(Detalhes, '$.frete') as DECIMAL(10,2)) as Frete

FROM dbo.Pedido
WHERE ISJSON(Detalhes) = 1

-- Observação: campos ausentes retornam NULL
-- Pedidos sem o campo "observacao" aparecem com NULL
SELECT PedidoId, ClienteNome, Detalhes,

JSON_VALUE(Detalhes, '$.observacao') as Observacao

FROM dbo.Pedido
WHERE ISJSON(Detalhes) = 1

-- Filtrando pedidos de um estado específico usando JSON_VALUE no WHERE
SELECT PedidoId, ClienteNome, Detalhes,

JSON_VALUE(Detalhes, '$.entrega.cidade') as Cidade

FROM dbo.Pedido
WHERE ISJSON(Detalhes) = 1
and JSON_VALUE(Detalhes, '$.entrega.estado') = 'SP'


/*************************************************************
 JSON_QUERY() - Extraindo objetos e arrays
 https://learn.microsoft.com/en-us/sql/t-sql/functions/json-query-transact-sql?view=sql-server-ver17
**************************************************************/

-- Extraindo o objeto completo de entrega
SELECT PedidoId, ClienteNome, Detalhes,

JSON_QUERY(Detalhes, '$.entrega') as DadosEntrega

FROM dbo.Pedido
WHERE ISJSON(Detalhes) = 1

-- Extraindo o array de itens completo
SELECT PedidoId, ClienteNome, Detalhes,

JSON_QUERY(Detalhes, '$.itens') as Itens

FROM dbo.Pedido
WHERE ISJSON(Detalhes) = 1

-- Dica: JSON_VALUE x JSON_QUERY na prática
-- JSON_VALUE retorna valor escalar, JSON_QUERY retorna objeto/array
SELECT PedidoId, ClienteNome, Detalhes,

JSON_VALUE(Detalhes, '$.entrega.cidade') as Cidade_VALUE,   -- retorna "São Paulo"
JSON_QUERY(Detalhes, '$.entrega') as Entrega_QUERY   -- retorna o objeto inteiro

FROM dbo.Pedido
WHERE ISJSON(Detalhes) = 1


/*************************************************************
 JSON_MODIFY() - Alterando valores no JSON
 https://learn.microsoft.com/en-us/sql/t-sql/functions/json-modify-transact-sql?view=sql-server-ver17
**************************************************************/

-- Alterando a cidade de entrega (apenas visualizando o resultado)
SELECT PedidoId, ClienteNome, Detalhes,

JSON_MODIFY(Detalhes, '$.entrega.cidade', 'Campinas') as DetalhesAlterado
FROM dbo.Pedido
WHERE PedidoId = 1


-- Adicionando um novo campo ao JSON
SELECT PedidoId, ClienteNome, Detalhes,

JSON_MODIFY(Detalhes, '$.prioridade', 'alta') AS DetalhesAlterado

FROM dbo.Pedido
WHERE PedidoId = 1

-- Removendo um campo do JSON (definindo como NULL)
SELECT PedidoId, ClienteNome, Detalhes,

json_modify(Detalhes, '$.observacao', NULL) AS DetalhesAlterado

FROM dbo.Pedido
WHERE PedidoId = 1

-- Persistindo a alteração com UPDATE
UPDATE dbo.Pedido
SET Detalhes = json_modify(Detalhes, '$.pagamento.parcelas', 13)
WHERE PedidoId =  1

-- Confirmando a alteração
SELECT PedidoId, ClienteNome, Detalhes,

json_value(Detalhes, '$.pagamento.parcelas') as Parcelas

FROM dbo.Pedido
WHERE PedidoId = 1


/*************************************************************
 OPENJSON() - Convertendo JSON em linhas e colunas
 https://learn.microsoft.com/en-us/sql/t-sql/functions/openjson-transact-sql?view=sql-server-ver17
**************************************************************/

-- Expandindo os itens de um único pedido
SELECT p.PedidoId, p.ClienteNome, i.produto, i.quantidade, i.valor

FROM dbo.Pedido p

CROSS APPLY OPENJSON(p.Detalhes, '$.itens')
WITH (
    produto     nvarchar(100)   '$.produto',
    quantidade  int             '$.quantidade',
    valor       decimal(10,2)   '$.valor'
) as i

WHERE isjson(p.Detalhes) = 1

-- Calculando o total de cada pedido expandindo os itens
SELECT p.PedidoId, p.ClienteNome, 

sum(i.quantidade * i.valor) as Total_Itens,
sum(cast(json_value(p.Detalhes, '$.frete') as decimal(10,2))) as Frete,
sum(i.quantidade * i.valor) + 
sum(cast(json_value(p.Detalhes, '$.frete') as decimal(10,2))) as TotalPedido

FROM dbo.Pedido p

CROSS APPLY OPENJSON(p.Detalhes, '$.itens')
WITH (
    produto     nvarchar(100)   '$.produto',
    quantidade  int             '$.quantidade',
    valor       decimal(10,2)   '$.valor'
) as i

WHERE isjson(p.Detalhes) = 1
GROUP BY p.PedidoId, p.ClienteNome
ORDER BY TotalPedido desc

-- Contando quantos pedidos cada produto aparece
SELECT i.produto, count(*) as Qtd_Pedidos, sum(i.quantidade) as Total_Unidades

FROM dbo.Pedido p

CROSS APPLY OPENJSON(p.Detalhes, '$.itens')
WITH (
    produto     nvarchar(100)  '$.produto',
    quantidade  int            '$.quantidade',
    valor       decimal(10,2)  '$.valor'
) as i

WHERE isjson(p.Detalhes) = 1
GROUP BY i.produto
ORDER BY Qtd_Pedidos desc


/*************************************************************
 FOR JSON - Gerando JSON a partir de consultas SQL
 https://learn.microsoft.com/en-us/sql/relational-databases/json/format-query-results-as-json-with-for-json-sql-server?view=sql-server-ver17&tabs=json-path
**************************************************************/

-- FOR JSON AUTO - SQL Server decide a estrutura
SELECT PedidoId, ClienteNome, DataPedido, [Status]
FROM dbo.Pedido
WHERE ISJSON(Detalhes) = 1
FOR JSON AUTO

-- FOR JSON PATH - você controla a estrutura e os nomes das chaves
SELECT PedidoId as 'pedido.id',
ClienteNome as 'pedido.cliente',
format(DataPedido, 'yyyy-MM-dd') as 'pedido.data',
[Status] as 'pedido.status',
json_value(Detalhes, '$.entrega.cidade') as 'pedido.entrega.cidade',
json_value(Detalhes, '$.entrega.estado') as 'pedido.entrega.estado',
json_value(Detalhes, '$.pagamento.forma') as 'pedido.pagamento.forma',
cast(json_value(Detalhes, '$.frete') as decimal(10,2)) as 'pedido.frete'

FROM dbo.Pedido
WHERE isjson(Detalhes) = 1
FOR JSON PATH

-- FOR JSON PATH com ROOT - envolve o resultado em uma chave raiz
SELECT PedidoId as 'id', ClienteNome as 'cliente', [Status] as 'status'
FROM dbo.Pedido
WHERE ISJSON(Detalhes) = 1
FOR JSON PATH, ROOT('pedidos')


