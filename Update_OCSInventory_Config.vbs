' ----------------------------------------------------------------------------------
' CITRA IT - EXCELÊNCIA EM TI
' Script para atualizar o arquivo de configuração do OCS Inventory nas estações
' Faça o deploy deste script como uma tarefa agendada por GPO.
' Autor: luciano@citrait.com.br
' Data: 11/07/2019  Versão: 1.0 release inicial
' Homologado para estações Windows 7, 8, e 10 com ocs inventory x86.
' Importante: Altere o caminho <config_path_network> para a pasta em que está o novo
'   arquivo de configuração do ocs (ocsinventory.ini)
' ----------------------------------------------------------------------------------
On Error Resume Next
'Option Explicit


' --------------------------------------------------------------------------------------
' Copiando o arquivo de configuração do servidor para a estação.
' --------------------------------------------------------------------------------------
config_path_network = "\\SERVER\SHARE$\ocsinventory.ini"
config_path_local = "C:\ProgramData\OCS Inventory NG\Agent\ocsinventory.ini"



' --------------------------------------------------------------------------------------
' Criando os objetos de acesso ao shell e filesystem
' --------------------------------------------------------------------------------------
Set wshShell = CreateObject("WSCript.Shell")
Set Wmi = GetObject("winMgmts:{ImpersonationLevel=Impersonate}!\\.\root\cimv2")
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objNetwork = CreateObject("WScript.Network")



' --------------------------------------------------------------------------------------
' Parando o serviço do OCS inventory para poder sobrescrever o arquivo de configuração.
' --------------------------------------------------------------------------------------
command = "cmd /c net stop " & chr(34) & "OCS Inventory Service" & chr(34)
wshSHell.Run command, 1, 1
WScript.Sleep(2000)

Set services = Wmi.ExecQuery("Select * from WIn32_Service where name='ocs inventory service' and State='Stopped'")
If services.Count <> 1 Then
    WSCript.Echo "[!] Erro ao parar o serviço do OCS Inventory."
    'WScript.Quit
Else
    WSCript.Echo "Serviço parado com sucesso!"
End If





' deleta o arquivo de configuração local da maquina
If objFSO.FileExists(config_path_local) Then
    objFSO.DeleteFile config_path_local, True
    If Not objFSO.FileExists(config_path_local) Then
        WScript.Echo "Arquivo de configuração antigo deletado com sucesso!"
    Else
        WScript.Echo "[!] Erro ao deletar arquivo de configuração antigo."
        'WScript.Quit
    End If
Else
    WScript.Echo "[!] Erro, arquivo de configuração local não encontrado."
    'WScript.Quit
End If


' copiando da rede para a maquina o arq. de configuração.
objFSO.CopyFile config_path_network, config_path_local, True
If objFSO.FileExists(config_path_local) Then
    WScript.Echo "Arquivo de configuração copiado com sucesso!"
Else
    WScript.Echo "[!] Erro ao copiar o arquivo de configuração."
    'WScript.Quit
End If



' --------------------------------------------------------------------------------------
' Iniciando novamente o serviço do OCS.
' --------------------------------------------------------------------------------------
command = "cmd /c net start " & chr(34) & "ocs inventory service" & chr(34)
wshShell.Run command, 1, 1
WScript.Sleep(2000)

Set services = Wmi.ExecQuery("Select * from Win32_Service where name='Ocs Inventory Service' and State='Running'")
If services.Count <> 1 Then
    WSCript.Echo "[!] Erro ao iniciar o serviço do OCS Inventory."
    'WScript.Quit
Else
    WSCript.Echo "Serviço iniciado com sucesso!"
End If

' Debug
'Set oFile = objFSO.CreateTextFile("\\SERVER\SHARE$\" & objNetwork.ComputerName & ".txt")
'oFile.WriteLine "OK"
'oFile.Close


