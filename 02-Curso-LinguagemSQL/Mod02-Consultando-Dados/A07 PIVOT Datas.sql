/*************************************************
 Curso T-SQL
 Autor: Landry

 Demonstração:
 - Comparando NULL
 - ISNULL()
 - NULLIF()
 - COALESCE()
*************************************************/
use Aula
go

if OBJECT_ID('Vendas_Ano') is not null
   DROP TABLE Vendas_Ano
go
CREATE TABLE Vendas_Ano (
Vendas_AnoID int not null identity primary key,
Cliente varchar(50) not null, 
Ano char(4) not null, 
Mes char(3) not null, 
Valor decimal(12,2))
go
INSERT Vendas_Ano (Cliente, Ano, Mes, Valor) VALUES('Ana','2010','Jan',90000.00)
INSERT Vendas_Ano (Cliente, Ano, Mes, Valor) VALUES('Ana','2010','Jan',12000.00)
INSERT Vendas_Ano (Cliente, Ano, Mes, Valor) VALUES('Ana','2010','Fev',30000.00)
INSERT Vendas_Ano (Cliente, Ano, Mes, Valor) VALUES('Ana','2010','Fev',54000.00)
INSERT Vendas_Ano (Cliente, Ano, Mes, Valor) VALUES('Ana','2010','Mar',10000.00)
INSERT Vendas_Ano (Cliente, Ano, Mes, Valor) VALUES('Ana','2010','Mar',12000.00)
INSERT Vendas_Ano (Cliente, Ano, Mes, Valor) VALUES('Ana','2010','Abr',10000.00)
INSERT Vendas_Ano (Cliente, Ano, Mes, Valor) VALUES('Ana','2010','Abr',12000.00)
INSERT Vendas_Ano (Cliente, Ano, Mes, Valor) VALUES('Ana','2010','Abr',20000.00)
INSERT Vendas_Ano (Cliente, Ano, Mes, Valor) VALUES('Ana','2010','Mai',12000.00)
INSERT Vendas_Ano (Cliente, Ano, Mes, Valor) VALUES('Ana','2010','Mai',16000.00)
INSERT Vendas_Ano (Cliente, Ano, Mes, Valor) VALUES('Ana','2010','Jun',12000.00)
INSERT Vendas_Ano (Cliente, Ano, Mes, Valor) VALUES('Ana','2010','Jun',10000.00)
INSERT Vendas_Ano (Cliente, Ano, Mes, Valor) VALUES('Ana','2010','Jun',12000.00)

INSERT Vendas_Ano (Cliente, Ano, Mes, Valor) VALUES('Fred','2010','Jan',40000.00)
INSERT Vendas_Ano (Cliente, Ano, Mes, Valor) VALUES('Fred','2010','Jan',12000.00)
INSERT Vendas_Ano (Cliente, Ano, Mes, Valor) VALUES('Fred','2010','Fev',30000.00)
INSERT Vendas_Ano (Cliente, Ano, Mes, Valor) VALUES('Fred','2010','Fev',14000.00)
INSERT Vendas_Ano (Cliente, Ano, Mes, Valor) VALUES('Fred','2010','Mar',80000.00)
INSERT Vendas_Ano (Cliente, Ano, Mes, Valor) VALUES('Fred','2010','Mar',12000.00)
INSERT Vendas_Ano (Cliente, Ano, Mes, Valor) VALUES('Fred','2010','Abr',16000.00)
INSERT Vendas_Ano (Cliente, Ano, Mes, Valor) VALUES('Fred','2010','Abr',12000.00)
INSERT Vendas_Ano (Cliente, Ano, Mes, Valor) VALUES('Fred','2010','Abr',10000.00)
INSERT Vendas_Ano (Cliente, Ano, Mes, Valor) VALUES('Fred','2010','Mai',52000.00)
INSERT Vendas_Ano (Cliente, Ano, Mes, Valor) VALUES('Fred','2010','Mai',10000.00)
INSERT Vendas_Ano (Cliente, Ano, Mes, Valor) VALUES('Fred','2010','Jun',42000.00)
INSERT Vendas_Ano (Cliente, Ano, Mes, Valor) VALUES('Fred','2010','Jun',80000.00)
INSERT Vendas_Ano (Cliente, Ano, Mes, Valor) VALUES('Fred','2010','Jun',22000.00)
go

SELECT * FROM Vendas_Ano ORDER BY Cliente,Ano,Mes

go
DECLARE @Ano char(4) = '2010'

SELECT p.Cliente, Jan, Fev, Mar, Abr, Mai, Jun
FROM (SELECT Cliente, Mes, Valor FROM Vendas_Ano WHERE Ano = @Ano) v
PIVOT (SUM(Valor) FOR Mes IN (Jan, Fev, Mar, Abr, Mai, Jun)) p
ORDER BY Cliente
go

-- Exclui tabelas
DROP TABLE Vendas_Ano
