[CmdletBinding()]
param(
    [string]$Gpu,
    [switch]$Cpu,
    [ValidatePattern('^\d+(s|m|h)$')][string]$KeepAlive = '30m',
    [ValidateRange(1024,65535)][int]$DemoPort = 8080
)
. "$PSScriptRoot\Common.ps1"
Assert-OllamaVersion
if ($Cpu -and $Gpu) { throw 'Usa -Cpu o -Gpu, no ambos.' }
if (Get-NetTCPConnection -LocalPort 11434 -State Listen -ErrorAction SilentlyContinue) {
    throw 'El puerto 11434 ya esta ocupado. Sal de Ollama desde su icono junto al reloj o cierra la consola que ejecuta ollama serve. Despues repite este comando.'
}
$gpuId = $null
if ($Gpu) {
    if (-not (Get-Command nvidia-smi -ErrorAction SilentlyContinue)) { throw 'No se encuentra nvidia-smi. -Gpu requiere una GPU NVIDIA y su controlador.' }
    $rows = @(& nvidia-smi --query-gpu=index,uuid,name --format=csv,noheader)
    if ($LASTEXITCODE -ne 0) { throw 'nvidia-smi no pudo consultar las GPUs.' }
    foreach ($row in $rows) {
        $parts = $row -split ',',3
        if ($parts.Count -eq 3 -and ($Gpu -eq $parts[0].Trim() -or $Gpu -eq $parts[1].Trim())) {
            $gpuId = $parts[1].Trim()
            Write-Host ("GPU seleccionada: {0} ({1})" -f $parts[2].Trim(), $gpuId)
            break
        }
    }
    if (-not $gpuId) { throw 'GPU no encontrada. Ejecuta nvidia-smi -L y copia su indice o UUID completo.' }
}
$names = @('CUDA_VISIBLE_DEVICES','ROCR_VISIBLE_DEVICES','HIP_VISIBLE_DEVICES','GPU_DEVICE_ORDINAL','OLLAMA_VULKAN','GGML_VK_VISIBLE_DEVICES','OLLAMA_KEEP_ALIVE','OLLAMA_HOST','OLLAMA_ORIGINS','OLLAMA_NO_CLOUD')
$previous = @{}
foreach ($name in $names) { $previous[$name] = [Environment]::GetEnvironmentVariable($name, 'Process') }
try {
    $env:OLLAMA_HOST = '127.0.0.1:11434'
    $env:OLLAMA_ORIGINS = "http://localhost:$DemoPort,http://127.0.0.1:$DemoPort"
    $env:OLLAMA_KEEP_ALIVE = $KeepAlive
    $env:OLLAMA_NO_CLOUD = '1'
    if ($gpuId) {
        $env:CUDA_VISIBLE_DEVICES = $gpuId
        $env:ROCR_VISIBLE_DEVICES = '-1'
        $env:HIP_VISIBLE_DEVICES = '-1'
        $env:GPU_DEVICE_ORDINAL = '-1'
        $env:OLLAMA_VULKAN = '0'
        $env:GGML_VK_VISIBLE_DEVICES = '-1'
    } elseif ($Cpu) {
        $env:CUDA_VISIBLE_DEVICES = '-1'
        $env:ROCR_VISIBLE_DEVICES = '-1'
        $env:HIP_VISIBLE_DEVICES = '-1'
        $env:GPU_DEVICE_ORDINAL = '-1'
        $env:OLLAMA_VULKAN = '0'
        $env:GGML_VK_VISIBLE_DEVICES = '-1'
    }
    Write-Host 'Ollama: http://localhost:11434. Deja esta ventana abierta. Ctrl+C para detener.'
    Write-Host "Permanencia por defecto: $KeepAlive. Origen de la demo: http://localhost:$DemoPort"
    & ollama serve
    if ($LASTEXITCODE -ne 0) { throw "Ollama termino con codigo $LASTEXITCODE." }
} finally {
    foreach ($name in $names) { [Environment]::SetEnvironmentVariable($name, $previous[$name], 'Process') }
}
