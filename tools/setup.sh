#!/bin/bash
#
# Script para instalar las dependencias de EncoreConverter
#
# Requiere:
#   - Go (https://go.dev/dl/)
#   - Python 3 (incluido en macOS o via homebrew)
#

set -e

echo "=== EncoreConverter - Instalacion de dependencias ==="
echo ""

# Check Go
if ! command -v go &> /dev/null; then
    echo "ERROR: Go no esta instalado."
    echo "Descargalo de: https://go.dev/dl/"
    echo "O instalalo con: brew install go"
    exit 1
fi
echo "[OK] Go encontrado: $(go version)"

# Check Python 3
if ! command -v python3 &> /dev/null; then
    echo "ERROR: Python 3 no esta instalado."
    echo "Instalalo con: brew install python3"
    exit 1
fi
echo "[OK] Python 3 encontrado: $(python3 --version)"

# Install go-enc2ly
echo ""
echo "Instalando go-enc2ly..."
go install github.com/hanwen/go-enc2ly@latest
echo "[OK] go-enc2ly instalado en: $(go env GOPATH)/bin/go-enc2ly"

# Install python-ly
echo ""
echo "Instalando python-ly..."
pip3 install python-ly
echo "[OK] python-ly instalado"

# Verify
echo ""
echo "=== Verificacion ==="
if command -v go-enc2ly &> /dev/null; then
    echo "[OK] go-enc2ly disponible en PATH"
else
    echo "[!] go-enc2ly instalado pero no en PATH."
    echo "    Anade $(go env GOPATH)/bin a tu PATH:"
    echo "    export PATH=\$PATH:$(go env GOPATH)/bin"
fi

if command -v ly &> /dev/null; then
    echo "[OK] ly (python-ly) disponible en PATH"
else
    echo "[!] ly instalado pero puede no estar en PATH."
    echo "    Comprueba con: python3 -m ly --help"
fi

echo ""
echo "=== Instalacion completada ==="
