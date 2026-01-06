#!/bin/bash

# Diretório base do script
BASEDIR="$(cd "$(dirname "$0")" && pwd)"

echo "=========================================="
echo "       VSDESKTOP SETUP"
echo "=========================================="
echo ""

# Verificar se container está rodando
if ! podman container exists herodev; then
    echo "Erro: Container herodev não encontrado!"
    echo "Execute start-herodev.sh primeiro."
    read -r -p "Pressione ENTER para continuar..."
    exit 1
fi

if ! podman exec herodev true &>/dev/null; then
    echo "Erro: Container herodev não está rodando!"
    echo "Execute start-herodev.sh primeiro."
    read -r -p "Pressione ENTER para continuar..."
    exit 1
fi

# Verificar se já existe (ambas arquiteturas)
VSDESKTOP_ARM="$BASEDIR/volumes/workspace/vsdesktop/out/vsdesktop-darwin-arm64"
VSDESKTOP_X64="$BASEDIR/volumes/workspace/vsdesktop/out/vsdesktop-darwin-x64"

if [ -d "$VSDESKTOP_ARM" ] || [ -d "$VSDESKTOP_X64" ]; then
    echo "VSDesktop já existe em volumes/workspace/vsdesktop"
    echo ""
    read -r -p "Deseja recompilar? (S/N): " REBUILD
    case "$REBUILD" in
        s|S|y|Y) ;;
        *)
            echo ""
            echo "Operação cancelada."
            read -r -p "Pressione ENTER para continuar..."
            exit 0
            ;;
    esac
fi

# Clonar repositório se não existir
if [ ! -d "$BASEDIR/volumes/workspace/vsdesktop" ]; then
    echo "Clonando repositório vsdesktop..."
    echo ""
    if ! podman exec herodev bash -c "cd /workspace && git clone https://github.com/herodjou/vsdesktop.git"; then
        echo ""
        echo "Erro ao clonar repositório!"
        echo "Verifique:"
        echo "- URL do repositório está correta"
        echo "- Git está instalado no container"
        echo "- Conexão com internet está funcionando"
        echo ""
        read -r -p "Pressione ENTER para continuar..."
        exit 1
    fi
    
    echo ""
    echo "Clone concluído com sucesso!"
    echo ""
fi

echo "Configurando npm para builds grandes..."
echo ""
podman exec herodev bash -c "npm config set fetch-retry-maxtimeout 120000 && npm config set fetch-timeout 120000"

echo ""
echo "Instalando dependências NPM..."
echo "(Isso pode levar alguns minutos...)"
echo ""
if ! podman exec herodev bash -c "cd /workspace/vsdesktop && npm install"; then
    echo ""
    echo "Erro ao instalar dependências!"
    read -r -p "Pressione ENTER para continuar..."
    exit 1
fi

echo ""
echo "Selecione a arquitetura para build:"
echo "  [1] ARM64 (Apple Silicon - M1/M2/M3)"
echo "  [2] x64 (Intel)"
echo ""
while true; do
    read -r -p "Escolha uma opção (1 ou 2): " ARCH_CHOICE
    case "$ARCH_CHOICE" in
        1)
            BUILD_TARGET="package:mac_arm64"
            ARCH_NAME="ARM64 (Apple Silicon)"
            break
            ;;
        2)
            BUILD_TARGET="package:mac_x64"
            ARCH_NAME="x64 (Intel)"
            break
            ;;
        *)
            echo "Opção inválida! Digite 1 ou 2."
            ;;
    esac
done

echo ""
echo "Compilando VSDesktop para macOS ($ARCH_NAME)..."
echo "(Isso pode levar vários minutos...)"
echo ""
if ! podman exec herodev bash -c "cd /workspace/vsdesktop && npm run $BUILD_TARGET"; then
    echo ""
    echo "Erro ao compilar VSDesktop!"
    read -r -p "Pressione ENTER para continuar..."
    exit 1
fi

echo ""
echo "=========================================="
echo "       VSDESKTOP INSTALADO COM SUCESSO!"
echo "=========================================="
echo ""
echo "Executável gerado em:"

# Mostrar o caminho correto baseado na arquitetura
if [ -d "$VSDESKTOP_ARM" ]; then
    echo "$BASEDIR/volumes/workspace/vsdesktop/out/vsdesktop-darwin-arm64/vsdesktop.app"
elif [ -d "$VSDESKTOP_X64" ]; then
    echo "$BASEDIR/volumes/workspace/vsdesktop/out/vsdesktop-darwin-x64/vsdesktop.app"
fi

echo ""
echo "Você pode executar diretamente ou usar start-herodev.sh"
echo "e escolher a opção de GUI."
echo ""

read -r -p "Deseja executar agora? (S/N): " LAUNCH
case "$LAUNCH" in
    s|S|y|Y)
        echo ""
        echo "Iniciando VSDesktop..."
        if [ -d "$VSDESKTOP_ARM/vsdesktop.app" ]; then
            open "$VSDESKTOP_ARM/vsdesktop.app"
        elif [ -d "$VSDESKTOP_X64/vsdesktop.app" ]; then
            open "$VSDESKTOP_X64/vsdesktop.app"
        fi
        sleep 2
        ;;
esac

exit 0
