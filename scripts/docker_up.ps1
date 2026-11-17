# Parte 4 do laboratorio: sobe a API no container Docker e espera ela ficar pronta.
# Uso (PowerShell, na raiz do projeto):
#   .\scripts\docker_up.ps1          # build + up em segundo plano
#   .\scripts\docker_up.ps1 -Logs    # idem, e ja abre o docker logs -f no fim
param([switch]$Logs, [int]$TimeoutSec = 900)

Set-Location (Split-Path $PSScriptRoot -Parent)

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host '[ERRO] docker nao encontrado. Instale o Docker Desktop (com WSL2) e reinicie.'
    exit 1
}
cmd /c "docker info >nul 2>&1"
if ($LASTEXITCODE -ne 0) {
    Write-Host '[ERRO] O motor do Docker nao esta rodando. Abra o Docker Desktop e espere "Engine running".'
    exit 1
}
if (-not (Test-Path .env)) {
    Write-Host '[ERRO] .env nao encontrado na raiz do projeto.'
    exit 1
}
if (Get-Command py -ErrorAction SilentlyContinue) {
    py -3 scripts\check_env.py --offline
    if ($LASTEXITCODE -ne 0) { exit 1 }
}

# Mongo local: dentro do container "localhost" e o proprio container, nao o Windows.
# A variavel do shell tem prioridade sobre o .env na interpolacao do compose.
$mongoLinha = Get-Content .env | Where-Object { $_ -match '^\s*MONGO_URL\s*=' } | Select-Object -First 1
if ($mongoLinha -match '(localhost|127\.0\.0\.1)') {
    $env:MONGO_URL = ($mongoLinha -replace '^\s*MONGO_URL\s*=\s*', '') -replace '(localhost|127\.0\.0\.1)', 'host.docker.internal'
    Write-Host '>> MONGO_URL aponta para o Mongo local: usando host.docker.internal no container'
}

Write-Host '>> docker compose up --build -d (a primeira vez demora varios minutos)'
docker compose up --build -d
if ($LASTEXITCODE -ne 0) { exit 1 }

Write-Host '>> Esperando a API (download do modelo do W&B)...'
$t = 0
while ($true) {
    try {
        $r = Invoke-WebRequest -Uri 'http://localhost:8000/' -UseBasicParsing -TimeoutSec 5
        if ($r.StatusCode -eq 200) { break }
    } catch { }

    $estado = (docker inspect -f '{{.State.Status}}' mlops-container) 2>$null
    if ($estado -ne 'running') {
        Write-Host "[ERRO] mlops-container nao esta rodando (estado: $estado). Ultimos logs:"
        docker compose logs --tail 60 mlops-container
        exit 1
    }
    if ($t -ge $TimeoutSec) {
        Write-Host "[ERRO] A API nao respondeu em $TimeoutSec s. Ultimos logs:"
        docker compose logs --tail 60 mlops-container
        exit 1
    }
    Start-Sleep -Seconds 10
    $t += 10
    Write-Host "   ... $t s"
}

docker compose ps
Write-Host ''
Write-Host "[OK] API pronta no container: http://localhost:8000/docs"
Write-Host 'Para o print dos logs: deixe rodando  docker logs -f mlops-container --tail 30'
Write-Host 'e faca o POST /predictions no Swagger (ou .\scripts\predict.ps1 -Nome "Seu Nome").'

if ($Logs) { docker logs -f mlops-container --tail 30 }
