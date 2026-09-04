use Landry_Blogs
go
-- Habilitando o uso do recurso de endpoint externo no SQL Server
EXECUTE sp_configure 'external rest endpoint enabled', 1;
RECONFIGURE;

-- Requisito criar uma Database Master Key
DROP MASTER KEY
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'SenhaForte@123!'

-- Requisito criar uma Database Scoped Credential para autenticação com o endpoint externo
-- DROP DATABASE SCOPED CREDENTIAL [https://fd-dp800.openai.azure.com/]

CREATE DATABASE SCOPED CREDENTIAL [https://fd-dp800.openai.azure.com/]
WITH IDENTITY = 'HTTPEndpointHeaders',
SECRET = '{"api-key":"9EwrmAiV3l9IlRpIFLmERLvaHo3sGn7q8ihLkC03LcHL9UHWQBMbJQQJ99CEACYeBjFXJ3w3AAAAACOG7ZdO"}'


SELECT * FROM sys.database_scoped_credentials


/*************************************************
 Opção 1: Usando Managed Identity (Recomendado)

1. Habilitar Managed Identity no Azure SQL Server
2. Conceder Cognitive Services OpenAI User no Foundry
3. Criar DATABASE SCOPED CREDENTIAL

**************************************************/
-- Modelo
CREATE DATABASE SCOPED CREDENTIAL [https://<resource-name>.openai.azure.com/]
WITH IDENTITY = 'Managed Identity',
SECRET = '{"resourceid":"https://cognitiveservices.azure.com"}'

-- Projeto fd-dp800
CREATE DATABASE SCOPED CREDENTIAL [https://fd-dp800.openai.azure.com/]
WITH IDENTITY = 'Managed Identity',
SECRET = '{"resourceid":"https://cognitiveservices.azure.com"}'


/*************************************************
 Opção 2: Usando API Key (Menos Seguro)
**************************************************/
-- Modelo
CREATE DATABASE SCOPED CREDENTIAL [https://<resource-name>.openai.azure.com/]
WITH IDENTITY = 'HTTPEndpointHeaders',
SECRET = '{"api-key":"<your-api-key>"}'

-- Projeto fd-dp800
--DROP DATABASE SCOPED CREDENTIAL [https://fd-dp800.openai.azure.com/]
CREATE DATABASE SCOPED CREDENTIAL [https://fd-dp800.openai.azure.com/]
WITH IDENTITY = 'HTTPEndpointHeaders',
SECRET = '{"api-key":"9EwrmAiV3l9IlRpIFLmERLvaHo3sGn7q8ihLkC03LcHL9UHWQBMbJQQJ99CEACYeBjFXJ3w3AAAAACOG7ZdO"}'


/********************************************
 Stored Procedure ia_Chat_Foundry
*********************************************/
go
CREATE or ALTER PROC dbo.ia_Chat_Foundry
@Modelo varchar(200) = 'gpt-4.1-dp800',
@Temperatura varchar(10) = '0.7',
@Prompt_Sistema varchar(4000),
@Prompt_Usuario varchar(4000)
as
-- Create a simple prompt payload:
DECLARE @payload NVARCHAR(MAX)

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
    "max_completion_tokens": 2000,
    "temperature": ' + @Temperatura + '}'

-- Call the LLM API using the sp_invoke_external_rest_endpoint stored procedure:
DECLARE @response NVARCHAR(MAX)
DECLARE @returnValue INT

EXEC @returnValue = sp_invoke_external_rest_endpoint
@url = N'https://fd-dp800.openai.azure.com/openai/v1/chat/completions',
@method = 'POST',
@payload = @payload,
@credential = [https://fd-dp800.openai.azure.com/],
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



