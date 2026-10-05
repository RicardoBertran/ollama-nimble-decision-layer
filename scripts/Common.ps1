$ErrorActionPreference = 'Stop'
function Assert-OllamaVersion {
    if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) { throw 'Ollama no esta instalado o no esta en PATH. Consulta el paso 2 del README.' }
    $versionText = (& ollama --version 2>&1 | Out-String)
    if ($versionText -notmatch '(\d+\.\d+\.\d+)') { throw "No se pudo comprobar la version: $versionText" }
    if ([version]$Matches[1] -lt [version]'0.35.1') { throw 'Actualiza Ollama a 0.35.1 o posterior y abre una nueva terminal.' }
}
function Assert-OllamaServer {
    $server = Invoke-RestMethod 'http://localhost:11434/api/version' -TimeoutSec 10
    if ([version]($server.version -replace '-.*$', '') -lt [version]'0.35.1') { throw 'El servidor activo es anterior a 0.35.1. Cierra Ollama y vuelve a arrancarlo tras actualizar.' }
}
