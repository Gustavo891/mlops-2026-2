#!/usr/bin/env bash
# Envia o POST /predictions do laboratorio (equivalente ao Swagger).
# Uso: bash scripts/predict.sh "Seu Nome Completo" [porta]
set -euo pipefail

NOME="${1:?Informe seu nome: bash scripts/predict.sh \"Seu Nome Completo\"}"
PORT="${2:-8000}"

curl -sS -w '\nHTTP %{http_code}\n' -X POST "http://localhost:${PORT}/predictions" \
  -H "Content-Type: application/json" \
  -d "{\"id\": \"lab-001\", \"nome\": \"${NOME}\", \"text\": \"eu não estou entendendo nada\"}"
