#!/bin/bash

# Diretório base do script
BASEDIR="$(cd "$(dirname "$0")" && pwd)"

echo "=========================================="
echo "       HERODEV IMAGE BUILD"
echo "=========================================="
echo ""
echo "Serviços OPCIONAIS disponíveis:"
echo ""

# Função para perguntar sim/não
ask_yes_no() {
    local prompt="$1"
    local result
    while true; do
        read -r -p "$prompt (S/N): " result
        case "$result" in
            s|S|y|Y) return 0 ;;
            n|N) return 1 ;;
            *) echo "Opção inválida! Digite S ou N." ;;
        esac
    done
}

BUILD_ARGS=""

# Perguntar sobre File Browser
if ask_yes_no "Instalar File Browser (gerenciador de arquivos web)?"; then
    BUILD_ARGS="$BUILD_ARGS --build-arg INSTALL_FILEBROWSER=true"
    echo "  [x] File Browser"
else
    echo "  [ ] File Browser"
fi

# Perguntar sobre Redis
if ask_yes_no "Instalar Redis (cache e filas)?"; then
    BUILD_ARGS="$BUILD_ARGS --build-arg INSTALL_REDIS=true"
    echo "  [x] Redis"
else
    echo "  [ ] Redis"
fi

# Perguntar sobre MongoDB
if ask_yes_no "Instalar MongoDB + Mongo Express?"; then
    BUILD_ARGS="$BUILD_ARGS --build-arg INSTALL_MONGODB=true"
    echo "  [x] MongoDB + Mongo Express"
else
    echo "  [ ] MongoDB"
fi

# Perguntar sobre Nginx
if ask_yes_no "Instalar Nginx (servidor web alternativo)?"; then
    BUILD_ARGS="$BUILD_ARGS --build-arg INSTALL_NGINX=true"
    echo "  [x] Nginx"
else
    echo "  [ ] Nginx"
fi

# Perguntar sobre Monitoramento
if ask_yes_no "Instalar Prometheus + Grafana (monitoramento)?"; then
    BUILD_ARGS="$BUILD_ARGS --build-arg INSTALL_PROMETHEUS=true --build-arg INSTALL_GRAFANA=true"
    echo "  [x] Prometheus + Grafana"
else
    echo "  [ ] Monitoring"
fi

echo ""
echo "Serviços selecionados confirmados!"
echo ""

# --------- PODMAN MACHINE ---------
if ! podman machine inspect &>/dev/null; then
    echo "Inicializando Podman Machine..."
    podman machine init
fi

podman machine start &>/dev/null
sleep 5

echo "Construindo a imagem 'herodev-all' a partir do Containerfile..."
echo "(Isso pode levar vários minutos dependendo dos serviços selecionados)"
echo ""

# shellcheck disable=SC2086
if podman build $BUILD_ARGS -t herodev-all "$BASEDIR"; then
    echo ""
    echo "Imagem criada com sucesso!"
    echo ""
    bash "$BASEDIR/mac_start-herodev.sh"
else
    echo ""
    echo "Erro ao criar a imagem."
    exit 1
fi

echo "=========================================="
echo "       HERODEV IMAGE BUILD FINALIZADO"
echo "=========================================="
