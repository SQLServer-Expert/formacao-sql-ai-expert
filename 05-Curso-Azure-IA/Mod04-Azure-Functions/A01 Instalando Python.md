### Instalando o Python

Verificar antes a versão mais atual de suporte ao Azure Function, no momento da gravação desta aula a versão mais recente suportada é a 3.14.

Faça download do Python no link abaixo e escolha **"Windows installer (64-bit)"**:

[https://www.python.org/downloads/windows/](https://www.python.org/downloads/windows/)


Durante a instalação marque **"Add python.exe to PATH"**, Se aparecer **"Disable path length limit"**, selecionar essa opção.


### Como verificar se o Python está instalado:

Abrir o **PowerShell** e executar:
```powershell
python --version
```

Onde o Python foi instalado: 
```powershell
where.exe python
```

Para ver todas as versões instaladas: 
```powershell
py -0p
```

Confirmando que o gerenciador de pacotes pip está disponível:
```powershell
python -m pip --version
```

Testando o Python utilizando o interpretador:
```powershell
python
```

Executar:
```python
a = 10
b = 20
print("Resultado:", a + b)
```

Resultado esperado:
```text
Resultado: 30
```

Para sair do enterpretador Python:
```python
exit()
```
