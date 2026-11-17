#!/usr/bin/env bash
# Roda um comando dentro do ambiente conda mlops-2026-2, na raiz do projeto.
# Uso (WSL): bash scripts/conda_run.sh python scripts/check_env.py
set -euo pipefail
cd "$(dirname "$0")/.."

[ -x "$HOME/miniconda3/bin/conda" ] && export PATH="$HOME/miniconda3/bin:$PATH"
eval "$(conda shell.bash hook)"
conda activate mlops-2026-2

exec "$@"
