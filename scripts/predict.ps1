# Envia o POST /predictions do laboratorio (equivalente ao Swagger).
# Uso: .\scripts\predict.ps1 -Nome "Seu Nome Completo" [-Port 8000]
param([Parameter(Mandatory = $true)][string]$Nome, [int]$Port = 8000)

$texto = "eu n$([char]0x00E3)o estou entendendo nada"
$body = @{ id = 'lab-001'; nome = $Nome; text = $texto } | ConvertTo-Json
$bytes = [System.Text.Encoding]::UTF8.GetBytes($body)

$r = Invoke-RestMethod -Uri "http://localhost:$Port/predictions" -Method Post `
    -Body $bytes -ContentType 'application/json; charset=utf-8'
$r | ConvertTo-Json -Depth 6
