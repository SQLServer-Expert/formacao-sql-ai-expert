/****************************************************************************************************
 sqlcmd -Slocalhost -i"C:\_HandsOn_Starter\M03A01 SQLCMD.sql" -o"C:\_HandsOn_Starter\Resultado.txt"
****************************************************************************************************/
use AdventureWorks
go
SELECT ProductID, Name, ProductNumber, Color, ListPrice
FROM Production.Product