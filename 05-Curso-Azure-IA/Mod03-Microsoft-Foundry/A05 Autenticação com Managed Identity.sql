/*
===============================================================================
Formação SQL AI Expert
Aula : Autenticação com Managed Identity

Objetivo:
Demonstrar, na prática como autenticar no Microsoft Foundry utilizando
Managed Identity, no acesso a modelo de LLM.

Ambiente:
- Azure SQL Database
- Microsoft Foundry

Autor: Landry Duailibe
===============================================================================
*/


/*************************************************
 Managed Identity

1. Habilitar Managed Identity no Azure SQL Server
2. Dar permissão a identidade do Azure SQL Database no Foundry
3. Criar DATABASE SCOPED CREDENTIAL

**************************************************/
--DROP DATABASE SCOPED CREDENTIAL [https://<nome-foundry>.openai.azure.com/]
CREATE DATABASE SCOPED CREDENTIAL [https://<nome-foundry>.openai.azure.com/]
WITH IDENTITY = 'Managed Identity',
SECRET = '{"resourceid":"https://cognitiveservices.azure.com"}'


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
@Prompt_Usuario = N'O que é e como utilizar Tabelas Temporais no SQL Server?'
