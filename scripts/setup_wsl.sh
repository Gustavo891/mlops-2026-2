#!/usr/bin/env bash
# Parte 1 do laboratorio: instala o Miniconda (se faltar), cria o ambiente
# mlops-2026-2 com Python 3.11 e instala o requirements.txt.
# Rode DENTRO do WSL (Ubuntu), na raiz do projeto:  bash scripts/setup_wsl.sh
set -euo pipefail
cd "$(dirname "$0")/.."

ENV_NAME=mlops-2026-2

if ! command -v conda >/dev/null 2>&1; then
  if [ ! -x "$HOME/miniconda3/bin/conda" ]; then
    echo ">> Instalando Miniconda em ~/miniconda3 ..."
    curl -fsSL https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o /tmp/miniconda.sh
    bash /tmp/miniconda.sh -b -p "$HOME/miniconda3"
    rm -f /tmp/miniconda.sh
    "$HOME/miniconda3/bin/conda" init bash >/dev/null
  fi
  export PATH="$HOME/miniconda3/bin:$PATH"
fi
eval "$(conda shell.bash hook)"

if ! conda env list | grep -qE "^${ENV_NAME}[[:space:]]"; then
  echo ">> Criando o ambiente ${ENV_NAME} (Python 3.11) ..."
  # conda-forge evita o aceite de termos dos canais 'defaults' do Anaconda
  conda create -n "$ENV_NAME" -c conda-forge --override-channels python=3.11 -y
fi
conda activate "$ENV_NAME"

echo ">> Instalando dependencias (demora alguns minutos) ..."
python -m pip install --upgrade pip
pip install -r requirements.txt

echo ">> Versoes (esperado: 2.19.1 3.13.2):"
python -c "import tensorflow as tf, keras; print(tf.__version__, keras.__version__)"

echo
echo "Pronto. Proximos passos:"
echo "  1. Preencha o .env (W&B e MongoDB Atlas)"
echo "  2. bash scripts/run_local.sh"
