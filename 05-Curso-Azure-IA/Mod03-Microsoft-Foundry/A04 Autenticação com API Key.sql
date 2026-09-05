/*
===============================================================================
Formação SQL AI Expert
Aula : Autenticação com API Key

Objetivo:
Demonstrar, na prática como autenticar no Microsoft Foundry utilizando
API Key, no acesso a modelo de LLM.

Ambiente:
- Azure SQL Database
- Microsoft Foundry

Autor: Landry Duailibe
===============================================================================
*/

-- Requisito criar uma Database Master Key
-- DROP MASTER KEY
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'SenhaForte@123!'



/****************************************************************************
 Criando uma Scoped Credential
 - Nome do Microsoft Foundry [https://<nome-foundry>.openai.azure.com/]
 - Secret pegar no projeto API Key
*****************************************************************************/

--DROP DATABASE SCOPED CREDENTIAL [https://<nome-foundry>.openai.azure.com/]
CREATE DATABASE SCOPED CREDENTIAL [https://<nome-foundry>.openai.azure.com/]
WITH IDENTITY = 'HTTPEndpointHeaders',
SECRET = '{"api-key":"<APIKey-do-Projeto>"}'


/********************************************
 Stored Procedure ia_Chat_Foundry
*********************************************/
EXEC dbo.ia_Chat_Foundry 
@Modelo = N'gpt-5.6-luna',
@Temperatura = N'1', -- Para este modelo tem que ser valor 1
@Prompt_Sistema = N'
Você é um assistente especializado em Microsoft SQL Server.

Responda dúvidas técnicas sobre SQL Server de forma clara, correta e objetiva.

Regras obrigatórias:
- Utilize o contexto fornecido como principal fonte da resposta.
- Não invente comandos, funcionalidades ou informações.
- Se o contexto não for suficiente, informe isso claramente.
- Responda em português do Brasil.
- Utilize Markdown.',
@Prompt_Usuario = N'Como usar DBCC CHECKDB no SQL Server?'

go
CREATE or ALTER PROC dbo.ia_Chat_Foundry
@Modelo nvarchar(200) = 'gpt-5.6-luna',
@Temperatura nvarchar(10) = '1',
@Prompt_Sistema nvarchar(4000),
@Prompt_Usuario nvarchar(4000)
as
-- Create a simple prompt payload:
DECLARE @payload nvarchar(MAX)

SET @payload = N'{
    "messages": [
        {
            "role": "system",
            "content": "' + STRING_ESCAPE(@Prompt_Sistema, 'json') + '"
        },
        {
            "role": "user",
            "content": "' + STRING_ESCAPE(@Prompt_Usuario, 'json') + '"
        }
    ],
    "model": "' + STRING_ESCAPE(@Modelo, 'json') + '",
    "temperature": ' + @Temperatura + '}'

-- Call the LLM API using the sp_invoke_external_rest_endpoint stored procedure:
DECLARE @response NVARCHAR(MAX)
DECLARE @returnValue INT

EXEC @returnValue = sp_invoke_external_rest_endpoint
@url = N'https://<nome-foundry>.openai.azure.com/openai/v1/chat/completions', -- ALTERAR
@method = 'POST',
@payload = @payload,
@credential = [https://<nome-foundry>.openai.azure.com/], -- ALTERAR
@response = @response OUTPUT

-- See Raw Response
--SELECT @response AS RawResponse

-- Parse Response (Extract Generated Text)
--SELECT JSON_VALUE(@response, '$.result.choices[0].message.content') AS Answer

-- Tratamento de Erro
IF @returnValue = 0
BEGIN
    SELECT 
        JSON_VALUE(@response, '$.result.choices[0].message.content') 
        AS Answer;
END
ELSE
BEGIN
    SELECT 
        @returnValue AS HttpStatus,
        JSON_VALUE(@response, '$.response.status.http.description') 
        AS Error;
END
go
/************************** FIM SP *****************************/



