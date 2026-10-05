[CmdletBinding()]
param([string]$Model = 'nimble:latest', [ValidateRange(1,10)][int]$Repeat = 1)
. "$PSScriptRoot\Common.ps1"
Assert-OllamaServer
$config = Get-Content -LiteralPath "$PSScriptRoot\..\app\decisions.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$body = @{ model = $Model; state = $config.ticket; questions = $config.questions; keep_alive = '30m' } | ConvertTo-Json -Depth 20
$bytes = [Text.Encoding]::UTF8.GetBytes($body)
for ($i = 1; $i -le $Repeat; $i++) {
    $clock = [Diagnostics.Stopwatch]::StartNew()
    $response = Invoke-RestMethod -Uri 'http://localhost:11434/v1/systemone' -Method Post -ContentType 'application/json; charset=utf-8' -Body $bytes -TimeoutSec 300
    $clock.Stop()
    foreach ($question in $config.questions.PSObject.Properties) {
        $answer = $response.answers.($question.Name)
        if ($null -eq $answer -or $answer.type -ne 'noul' -or $null -eq $answer.noul -or $answer.noul -is [string] -or $answer.noul -is [bool] -or $answer.noul -lt 0 -or $answer.noul -gt 1) { throw "Respuesta invalida: $($question.Name)" }
    }
    Write-Host ("Peticion {0}: {1:N2} segundos" -f $i, $clock.Elapsed.TotalSeconds)
    $response | ConvertTo-Json -Depth 20
}
