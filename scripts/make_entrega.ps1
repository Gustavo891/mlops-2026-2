# Monta lab_api_SEU_NOME.zip com os 3 itens da entrega.
# Antes, salve os prints em ..\entrega\ (pasta atividade2\entrega):
#   print_swagger.png  e  print_logs.png
# Uso: .\scripts\make_entrega.ps1 -Nome "Seu Nome Completo"
param([Parameter(Mandatory = $true)][string]$Nome)

$raiz = Split-Path $PSScriptRoot -Parent
$entrega = Join-Path (Split-Path $raiz -Parent) 'entrega'
New-Item -ItemType Directory -Force $entrega | Out-Null

$faltando = @('print_swagger.png', 'print_logs.png') | Where-Object { -not (Test-Path (Join-Path $entrega $_)) }
if ($faltando) {
    Write-Host "[ERRO] Faltam em ${entrega}: $($faltando -join ', ')"
    exit 1
}

Copy-Item (Join-Path $raiz 'src\modules\intent_classifier\controller.py') $entrega -Force

# nome do arquivo sem acentos e sem espacos
$semAcento = -join ($Nome.Normalize([Text.NormalizationForm]::FormD).ToCharArray() |
    Where-Object { [Globalization.CharUnicodeInfo]::GetUnicodeCategory($_) -ne 'NonSpacingMark' })
$zip = Join-Path (Split-Path $raiz -Parent) ("lab_api_" + ($semAcento.Trim() -replace '\s+', '_') + ".zip")

$arquivos = 'print_swagger.png', 'print_logs.png', 'controller.py' | ForEach-Object { Join-Path $entrega $_ }
Compress-Archive -Path $arquivos -DestinationPath $zip -Force

Write-Host "[OK] Entrega criada: $zip"
Write-Host '     Conteudo: print_swagger.png, print_logs.png, controller.py (sem .env)'
Write-Host '     Confira nos prints que nenhuma chave do W&B ou connection string do Mongo aparece.'
