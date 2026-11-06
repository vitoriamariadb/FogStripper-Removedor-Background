#!/bin/bash
set -e

APP_WM_CLASS="fogstripper"

echo "============================================================"
echo "  FOGSTRIPPER - INSTALACAO SIMPLIFICADA"
echo "  AVISO: Este processo pode levar alguns minutos."
echo "============================================================"
echo ""

# Definir diretorios
# O app roda da própria pasta do projeto: venv, modelos, config e log moram aqui.
APP_DIR=$(cd "$(dirname "$0")" && pwd)
PROJECT_ROOT="$APP_DIR"
cd "$APP_DIR"
VENV_DIR="$APP_DIR/venv"
PYTHON_EXEC="$VENV_DIR/bin/python3"

# Configurar TMPDIR local para evitar falta de espaco em /tmp
# Isso resolve o problema de travamento no basicsr/realesrgan
export TMPDIR="$HOME/.pip_tmp_fogstripper"
mkdir -p "$TMPDIR"
echo ">> Configurando diretorio temporario: $TMPDIR"

echo ">> Gerando icones..."
[ -x "$PYTHON_EXEC" ] || python3 -m venv "$VENV_DIR"
"$PYTHON_EXEC" -m pip install --upgrade pip setuptools wheel > /dev/null
"$PYTHON_EXEC" -m pip install Pillow > /dev/null
"$PYTHON_EXEC" "$PROJECT_ROOT/src/utils/icon_resizer.py" "$PROJECT_ROOT"
echo ">> Icones gerados."

echo ""
echo "[1/3] Configurando ambiente virtual unificado..."
# Instalando PyTorch primeiro para garantir binarios
# torch 2.5.1 / torchvision 0.20.1: primeira serie com wheels para Python 3.10-3.12
# (os antigos 2.0.1/0.15.2 nao possuem wheels para o Python 3.12 de distros atuais).
# O worker_upscale.py ja possui shim para torchvision.transforms.functional_tensor,
# mantendo o basicsr/realesrgan funcionais com torchvision >= 0.17.
echo ">> Instalando Core e PyTorch (isso ajuda a evitar compilacao desnecessaria)..."
if command -v nvidia-smi > /dev/null 2>&1 && nvidia-smi > /dev/null 2>&1; then
    echo ">> GPU NVIDIA detectada. Instalando PyTorch com CUDA."
    TORCH_INDEX="https://download.pytorch.org/whl/cu124"
else
    echo ">> Nenhuma GPU NVIDIA detectada. Instalando PyTorch CPU."
    TORCH_INDEX="https://download.pytorch.org/whl/cpu"
fi
"$PYTHON_EXEC" -m pip install --no-cache-dir "torch==2.5.1" "torchvision==0.20.1" --index-url "$TORCH_INDEX" || \
"$PYTHON_EXEC" -m pip install --no-cache-dir "torch==2.5.1" "torchvision==0.20.1" --index-url https://download.pytorch.org/whl/cpu

echo ""
echo "[2/3] Instalando demais dependencias (pode demorar um pouco)..."
# Instalando o resto do requirements.txt
"$PYTHON_EXEC" -m pip install --no-cache-dir -r ./requirements.txt

echo ""
echo "[3/3] Configurando sistema..."

echo ">> Criando arquivo de configuracao..."
cat > "$APP_DIR/config.json" << EOL
{
    "PYTHON_REMBG": "$PYTHON_EXEC",
    "PYTHON_UPSCALE": "$PYTHON_EXEC",
    "REMBG_SCRIPT": "$APP_DIR/src/workers/worker_rembg.py",
    "UPSCALE_SCRIPT": "$APP_DIR/src/workers/worker_upscale.py",
    "EFFECTS_SCRIPT": "$APP_DIR/src/workers/worker_effects.py",
    "BACKGROUND_SCRIPT": "$APP_DIR/src/workers/worker_background.py",
    "U2NET_HOME": "$APP_DIR/models/u2net"
}
EOL

echo ">> Criando diretorio de modelos..."
mkdir -p "$APP_DIR/models/u2net"

echo ">> Instalando atalhos..."
for size in 16 32 64 128; do
    ICON_DIR="$HOME/.local/share/icons/hicolor/${size}x${size}/apps"
    mkdir -p "$ICON_DIR"
    cp "$PROJECT_ROOT/assets/generated_icons/icon_${size}x${size}.png" "$ICON_DIR/fogstripper.png"
done

DESKTOP_INSTALL_DIR="$HOME/.local/share/applications"
mkdir -p "$DESKTOP_INSTALL_DIR"
cat > "$DESKTOP_INSTALL_DIR/fogstripper.desktop" << EOL
[Desktop Entry]
Name=FogStripper
Comment=Removedor de fundo de imagens
Exec=env PYTHONPATH=$APP_DIR $PYTHON_EXEC $APP_DIR/src/main.py
Icon=fogstripper
Type=Application
Categories=Graphics;
Terminal=false
StartupWMClass=$APP_WM_CLASS
EOL

# Atualiza caches de atalhos/icones quando as ferramentas existem (com set -e,
# a ausencia delas em desktops como o COSMIC abortaria a instalacao ja concluida)
command -v update-desktop-database > /dev/null && update-desktop-database -q "$DESKTOP_INSTALL_DIR" || true
command -v gtk-update-icon-cache > /dev/null && gtk-update-icon-cache -q -f -t "$HOME/.local/share/icons/hicolor" || true

# Limpeza
rm -rf "$TMPDIR"
echo ">> Limpeza concluida."

echo ""
echo "######################################################################"
echo "INSTALACAO CONCLUIDA COM SUCESSO!"
echo "Pode iniciar pelo menu de aplicativos."
echo "######################################################################"
