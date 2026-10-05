[CmdletBinding()]
param([ValidateNotNullOrEmpty()][string]$Model = 'nimble:latest')
. "$PSScriptRoot\Common.ps1"
Assert-OllamaVersion
Assert-OllamaServer
$previousHost = [Environment]::GetEnvironmentVariable('OLLAMA_HOST', 'Process')
try {
    $env:OLLAMA_HOST = '127.0.0.1:11434'
    & ollama pull $Model
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo descargar el modelo. Revisa la conexion y el espacio libre.' }
    & ollama list
} finally { [Environment]::SetEnvironmentVariable('OLLAMA_HOST', $previousHost, 'Process') }
