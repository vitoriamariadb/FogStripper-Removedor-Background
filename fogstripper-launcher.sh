#!/bin/bash
# /app precisa estar no PYTHONPATH (e nao /app/src): os imports do projeto
# sao absolutos a partir do pacote "src" (ex.: from src.core import ...).
export PYTHONPATH=$PYTHONPATH:/app
exec /app/venv/bin/python3 /app/src/main.py
