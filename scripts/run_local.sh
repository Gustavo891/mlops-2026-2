#!/usr/bin/env bash
# Parte 3 do laboratorio: confere o .env e sobe a API com uvicorn.
# Rode DENTRO do WSL, na raiz do projeto:  bash scripts/run_local.sh [porta]
set -euo pipefail
cd "$(dirname "$0")/.."

PORT="${1:-8000}"

[ -x "$HOME/miniconda3/bin/conda" ] && export PATH="$HOME/miniconda3/bin:$PATH"
eval "$(conda shell.bash hook)"
conda activate mlops-2026-2

python scripts/check_env.py

echo ">> Subindo a API em http://localhost:${PORT}/docs (Ctrl+C para parar)"
exec uvicorn src.app:app --port "$PORT"
