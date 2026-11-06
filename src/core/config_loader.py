import json
import logging
import os
from typing import Any

logger: logging.Logger = logging.getLogger(__name__)

APP_DIR: str = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

if os.getenv("FOGSTRIPPER_DEV_MODE"):
    logger.warning("MODO DE DESENVOLVIMENTO ATIVADO!")
    CONFIG_PATH: str = os.path.join(APP_DIR, "config.dev.json")
else:
    CONFIG_PATH: str = os.path.join(APP_DIR, "config.json")
    if not os.path.exists(CONFIG_PATH):
        # Fallback para o config embarcado ao lado do codigo — e o caso do
        # build Flatpak, que grava /app/src/config.json em vez de usar o HOME.
        _bundled: str = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "config.json"))
        if os.path.exists(_bundled):
            CONFIG_PATH = _bundled

PATHS: dict[str, Any] = {}


def load_paths() -> None:
    global PATHS
    try:
        with open(CONFIG_PATH) as f:
            PATHS = json.load(f)
        logger.info(f"Configuracao ({os.path.basename(CONFIG_PATH)}) carregada.")
    except FileNotFoundError:
        logger.critical(f"CRITICO: Arquivo de configuracao nao encontrado em {CONFIG_PATH}!")
        PATHS = {}
    except Exception as e:
        logger.critical(f"CRITICO: Falha ao ler configuracao: {e}")
        PATHS = {}


load_paths()
