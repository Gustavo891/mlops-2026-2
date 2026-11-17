"""Confere o .env antes de subir a API, sem nunca imprimir os valores.

Uso (na raiz do projeto):
    python scripts/check_env.py            # formato + testes remotos (Mongo e W&B), se as libs existirem
    python scripts/check_env.py --offline  # so o formato do arquivo
"""
import re
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
ENV_PATH = RAIZ / ".env"
OBRIGATORIAS = ["WANDB_API_KEY", "WANDB_PROJECT", "WANDB_MODELS", "MONGO_URL"]
MARCADORES = ["COLE_SUA_CHAVE", "SEU_USUARIO", "USUARIO:SENHA", "xxxxx", "...", "<db_password>"]

erros, avisos = [], []


def ler_env():
    if not ENV_PATH.exists():
        print(f"[ERRO] {ENV_PATH} nao existe. Rode: cp .env.example .env")
        sys.exit(1)
    valores = {}
    for n, linha in enumerate(ENV_PATH.read_text(encoding="utf-8").splitlines(), 1):
        if not linha.strip() or linha.lstrip().startswith("#"):
            continue
        if "=" not in linha:
            erros.append(f"linha {n}: sem '='")
            continue
        chave, valor = linha.split("=", 1)
        if chave != chave.strip() or valor != valor.strip():
            erros.append(f"linha {n} ({chave.strip()}): remova os espacos ao redor do '='")
        valor = valor.strip()
        if len(valor) >= 2 and valor[0] == valor[-1] and valor[0] in "'\"":
            avisos.append(f"{chave.strip()}: valor entre aspas; prefira sem aspas")
            valor = valor[1:-1]
        valores[chave.strip()] = valor
    return valores


def conferir_formato(env):
    for nome in OBRIGATORIAS:
        valor = env.get(nome, "")
        if not valor:
            erros.append(f"{nome}: ausente ou vazia")
        elif any(m in valor for m in MARCADORES):
            erros.append(f"{nome}: ainda tem o valor de exemplo, troque pelo seu")

    chave = env.get("WANDB_API_KEY", "")
    if chave and not chave.startswith("wandb_v1_") and len(chave) != 40:
        avisos.append("WANDB_API_KEY: formato inesperado (chaves novas comecam com wandb_v1_)")

    for url in filter(None, (u.strip() for u in env.get("WANDB_MODELS", "").split(","))):
        if not re.fullmatch(r"[^/\s]+/[^/\s]+/[^/:\s]+:[^/:\s]+", url):
            erros.append("WANDB_MODELS: use o formato entidade/projeto/artefato:versao")

    mongo = env.get("MONGO_URL", "")
    if mongo and not mongo.startswith(("mongodb://", "mongodb+srv://")):
        erros.append("MONGO_URL: deve comecar com mongodb+srv:// (ou mongodb://)")
    if "$" in mongo:
        avisos.append("MONGO_URL: contem '$'; o docker compose tenta interpretar isso como variavel")


def conferir_remoto(env):
    try:
        import pymongo
    except ImportError:
        avisos.append("pymongo nao instalado: teste do Mongo pulado (ative o ambiente conda)")
    else:
        try:
            cliente = pymongo.MongoClient(env["MONGO_URL"], serverSelectionTimeoutMS=8000)
            cliente.admin.command("ping")
            print("[OK]   MongoDB Atlas respondeu ao ping")
        except Exception as e:
            erros.append(f"MongoDB: {type(e).__name__} (veja Network Access e usuario/senha no Atlas)")

    try:
        import wandb
    except ImportError:
        avisos.append("wandb nao instalado: teste do artefato pulado (ative o ambiente conda)")
        return
    try:
        api = wandb.Api(api_key=env["WANDB_API_KEY"])
        for url in filter(None, (u.strip() for u in env["WANDB_MODELS"].split(","))):
            arquivos = {f.name for f in api.artifact(url).files()}
            faltando = {"model.keras", "model_config.yml"} - arquivos
            if faltando:
                erros.append(f"W&B {url}: faltam {sorted(faltando)} no artefato (retreine no Colab)")
            else:
                print(f"[OK]   W&B artefato {url} encontrado com model.keras e model_config.yml")
    except Exception as e:
        erros.append(f"W&B: {type(e).__name__} (confira WANDB_API_KEY e WANDB_MODELS)")


def main():
    env = ler_env()
    conferir_formato(env)
    if not erros and "--offline" not in sys.argv:
        conferir_remoto(env)

    for a in avisos:
        print(f"[AVISO] {a}")
    for e in erros:
        print(f"[ERRO] {e}")
    if erros:
        sys.exit(1)
    print("[OK]   .env pronto")


if __name__ == "__main__":
    main()
