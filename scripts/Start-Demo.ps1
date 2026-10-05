[CmdletBinding()]
param([ValidateRange(1024,65535)][int]$Port = 8080, [switch]$NoBrowser)
$ErrorActionPreference = 'Stop'
$appDir = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\app'))
$routes = @{ '/'='index.html'; '/index.html'='index.html'; '/styles.css'='styles.css'; '/app.js'='app.js'; '/decisions.json'='decisions.json' }
$mime = @{ '.html'='text/html'; '.css'='text/css'; '.js'='text/javascript'; '.json'='application/json' }
$listener = New-Object Net.Sockets.TcpListener([Net.IPAddress]::Loopback, $Port)
try {
    $listener.Start()
    $url = "http://localhost:$Port"
    Write-Host "Demo: $url. Deja esta ventana abierta. Ctrl+C para detener."
    if (-not $NoBrowser) { Start-Process $url }
    while ($true) {
        if (-not $listener.Pending()) { Start-Sleep -Milliseconds 100; continue }
        $client = $listener.AcceptTcpClient()
        try {
            $client.ReceiveTimeout = 3000; $client.SendTimeout = 3000
            $stream = $client.GetStream()
            $reader = New-Object IO.StreamReader($stream, [Text.Encoding]::ASCII, $false, 1024, $true)
            $line = $reader.ReadLine()
            $parts = $line -split ' '
            $count = 0
            do { $header = $reader.ReadLine(); $count++; if ($count -gt 100) { throw 'Demasiadas cabeceras.' } } while ($header)
            $code = '404 Not Found'; $type = 'text/plain'; $body = [Text.Encoding]::UTF8.GetBytes('Archivo no encontrado.')
            if ($parts.Count -ge 2 -and $parts[0] -eq 'GET') {
                $route = ($parts[1] -split '\?',2)[0]
                if ($routes.ContainsKey($route)) {
                    $file = Join-Path $appDir $routes[$route]
                    $body = [IO.File]::ReadAllBytes($file); $type = $mime[[IO.Path]::GetExtension($file)]; $code = '200 OK'
                }
            } else { $code = '405 Method Not Allowed' }
            $head = [Text.Encoding]::ASCII.GetBytes("HTTP/1.1 $code`r`nContent-Type: $type; charset=utf-8`r`nContent-Length: $($body.Length)`r`nCache-Control: no-store`r`nX-Content-Type-Options: nosniff`r`nConnection: close`r`n`r`n")
            $stream.Write($head,0,$head.Length); $stream.Write($body,0,$body.Length); $stream.Flush()
        } catch { Write-Warning $_.Exception.Message } finally { $client.Close() }
    }
} finally { $listener.Stop() }
