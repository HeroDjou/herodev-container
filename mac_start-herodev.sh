#!/bin/bash

# Diretório base do script
BASEDIR="$(cd "$(dirname "$0")" && pwd)"

# --------- ESTRUTURA ---------
mkdir -p "$BASEDIR/volumes/workspace/www"
mkdir -p "$BASEDIR/volumes/db"
mkdir -p "$BASEDIR/volumes/vscode/config"
mkdir -p "$BASEDIR/volumes/vscode/data"

# --------- PODMAN ---------
podman machine start &>/dev/null
sleep 5

if podman container exists herodev; then
    podman start herodev
else
    podman run -d \
      --name herodev \
      --privileged \
      --systemd=always \
      -p 8080:80 \
      -p 12777:12777 \
      -p 8081:8081 \
      -p 6379:6379 \
      -p 27017:27017 \
      -p 8082:8082 \
      -p 8083:8083 \
      -p 9090:9090 \
      -p 3000:3000 \
      -v "$BASEDIR/volumes/workspace:/workspace" \
      -v "$BASEDIR/volumes/db:/var/lib/mysql" \
      -v "$BASEDIR/volumes/vscode/config:/home/dev/.config/code-server" \
      -v "$BASEDIR/volumes/vscode/data:/home/dev/.local/share/code-server" \
      herodev-all
fi

podman exec herodev systemctl daemon-reload

# Habilitar e iniciar serviços core
podman exec herodev systemctl enable apache2 mariadb code-server
podman exec herodev systemctl start apache2 mariadb code-server

# Detectar e iniciar serviços opcionais se instalados
podman exec herodev bash -c "[ -f /usr/local/bin/filebrowser ] && systemctl enable filebrowser && systemctl start filebrowser || true"
podman exec herodev bash -c "[ -f /usr/bin/redis-server ] && systemctl enable redis-server && systemctl start redis-server || true"
podman exec herodev bash -c "[ -f /usr/bin/mongod ] && systemctl enable mongod && systemctl start mongod || true"
podman exec herodev bash -c "[ -f /usr/bin/mongo-express ] && systemctl enable mongo-express && systemctl start mongo-express || true"
podman exec herodev bash -c "[ -f /usr/sbin/nginx ] && systemctl enable nginx php8.1-fpm && systemctl start nginx php8.1-fpm || true"
podman exec herodev bash -c "[ -f /usr/local/bin/prometheus ] && systemctl enable prometheus && systemctl start prometheus || true"
podman exec herodev bash -c "[ -f /usr/sbin/grafana-server ] && systemctl enable grafana-server && systemctl start grafana-server || true"

echo ""
echo "=========================================="
echo "HERODEV ONLINE"
echo "=========================================="
echo ""
echo "SERVIÇOS CORE:"
echo "  Web:        http://localhost:8080"
echo "  phpMyAdmin: http://localhost:8080/phpmyadmin"
echo "  VS Code:    http://localhost:12777"

# Detectar e listar serviços opcionais
podman exec herodev bash -c "[ -f /usr/local/bin/filebrowser ] && echo '  File Browser: http://localhost:8081' || true"
podman exec herodev bash -c "[ -f /usr/bin/mongo-express ] && echo '  Mongo Express: http://localhost:8082' || true"
podman exec herodev bash -c "[ -f /usr/sbin/nginx ] && echo '  Nginx: http://localhost:8083' || true"
podman exec herodev bash -c "[ -f /usr/local/bin/prometheus ] && echo '  Prometheus: http://localhost:9090' || true"
podman exec herodev bash -c "[ -f /usr/sbin/grafana-server ] && echo '  Grafana: http://localhost:3000' || true"

echo "=========================================="
echo ""

# --------- GUI VSDESKTOP e outras ---------
gui_prompt() {
    while true; do
        echo "=========================================="
        echo "INTERFACE GRÁFICA"
        echo "=========================================="
        read -r -p "Deseja executar a GUI? (S/N): " RUN_GUI
        
        case "$RUN_GUI" in
            s|S|y|Y) check_gui; return ;;
            n|N) terminal_only; return ;;
            *) 
                echo ""
                echo "Opção inválida! Digite S ou N."
                sleep 2
                ;;
        esac
    done
}

terminal_only() {
    echo ""
    echo "Iniciando terminal do container..."
    sleep 2
    podman exec -it herodev bash
}

check_gui() {
    echo "Verificando VSDesktop..."
    
    # Detectar arquitetura do Mac
    MAC_ARCH=$(uname -m)
    if [ "$MAC_ARCH" = "arm64" ]; then
        IS_ARM=true
        echo "Arquitetura detectada: Apple Silicon (ARM64)"
    else
        IS_ARM=false
        echo "Arquitetura detectada: Intel (x64)"
    fi
    
    # Verificar quais builds existem
    GUI_ARM="$BASEDIR/volumes/workspace/vsdesktop/out/vsdesktop-darwin-arm64/vsdesktop.app"
    GUI_X64="$BASEDIR/volumes/workspace/vsdesktop/out/vsdesktop-darwin-x64/vsdesktop.app"
    
    HAS_ARM=false
    HAS_X64=false
    [ -d "$GUI_ARM" ] && HAS_ARM=true
    [ -d "$GUI_X64" ] && HAS_X64=true
    
    echo ""
    
    # ===== MAC ARM64 =====
    if [ "$IS_ARM" = true ]; then
        if [ "$HAS_ARM" = true ]; then
            # Tem ARM64, roda direto
            echo "Iniciando VSDesktop (ARM64)..."
            sleep 2
            open "$GUI_ARM"
            return
        elif [ "$HAS_X64" = true ]; then
            # Não tem ARM64, mas tem x64
            echo "[AVISO] Seu Mac é Apple Silicon (ARM64), mas só encontramos a build x64."
            echo "A versão x64 vai funcionar via Rosetta, mas uma build nativa seria mais rápida."
            echo ""
            echo "O que deseja fazer?"
            echo "  [1] Buildar versão ARM64 (recomendado)"
            echo "  [2] Rodar versão x64 mesmo assim"
            echo ""
            while true; do
                read -r -p "Escolha (1 ou 2): " CHOICE
                case "$CHOICE" in
                    1)
                        build_vsdesktop "arm64"
                        return
                        ;;
                    2)
                        echo ""
                        echo "Iniciando VSDesktop (x64 via Rosetta)..."
                        sleep 2
                        open "$GUI_X64"
                        return
                        ;;
                    *)
                        echo "Opção inválida!"
                        ;;
                esac
            done
        else
            # Não tem nenhuma build
            echo "VSDesktop não encontrado!"
            offer_build "arm64"
            return
        fi
    fi
    
    # ===== MAC X64 (Intel) =====
    if [ "$IS_ARM" = false ]; then
        if [ "$HAS_X64" = true ]; then
            # Tem x64, roda direto
            echo "Iniciando VSDesktop (x64)..."
            sleep 2
            open "$GUI_X64"
            return
        elif [ "$HAS_ARM" = true ]; then
            # Tem ARM64 mas não tem x64 - ARM não roda em Intel
            echo "[AVISO] Seu Mac é Intel (x64), mas só encontramos a build ARM64."
            echo "Builds ARM64 NÃO são compatíveis com Macs Intel."
            echo ""
            echo "O que deseja fazer?"
            echo "  [1] Buildar versão x64"
            echo "  [2] Sair"
            echo ""
            while true; do
                read -r -p "Escolha (1 ou 2): " CHOICE
                case "$CHOICE" in
                    1)
                        build_vsdesktop "x64"
                        return
                        ;;
                    2)
                        echo "Operação cancelada."
                        return
                        ;;
                    *)
                        echo "Opção inválida!"
                        ;;
                esac
            done
        else
            # Não tem nenhuma build
            echo "VSDesktop não encontrado!"
            offer_build "x64"
            return
        fi
    fi
}

offer_build() {
    local SUGGESTED_ARCH="$1"
    echo ""
    echo "Será necessário compilar na primeira execução."
    echo "Isso pode levar alguns minutos..."
    echo ""
    read -r -p "Pressione ENTER para continuar..."
    
    # Verificar se a pasta vsdesktop existe
    if [ ! -d "$BASEDIR/volumes/workspace/vsdesktop" ]; then
        echo ""
        echo "Pasta vsdesktop não encontrada em:"
        echo "$BASEDIR/volumes/workspace/vsdesktop"
        echo ""
        while true; do
            read -r -p "Deseja executar o setup do VSDesktop agora? (S/N): " RUN_SETUP
            case "$RUN_SETUP" in
                s|S|y|Y)
                    echo ""
                    echo "Executando setup do VSDesktop..."
                    "$BASEDIR/mac_setup-vsdesktop.sh"
                    return
                    ;;
                n|N)
                    echo ""
                    echo "Operação cancelada."
                    return
                    ;;
                *)
                    echo ""
                    echo "Opção inválida! Digite S ou N."
                    sleep 2
                    ;;
            esac
        done
    fi
    
    build_vsdesktop "$SUGGESTED_ARCH"
}

build_vsdesktop() {
    local TARGET_ARCH="$1"
    
    if [ "$TARGET_ARCH" = "arm64" ]; then
        BUILD_TARGET="package:mac_arm64"
        ARCH_NAME="ARM64 (Apple Silicon)"
        EXPECTED_PATH="$BASEDIR/volumes/workspace/vsdesktop/out/vsdesktop-darwin-arm64/vsdesktop.app"
    else
        BUILD_TARGET="package:mac_x64"
        ARCH_NAME="x64 (Intel)"
        EXPECTED_PATH="$BASEDIR/volumes/workspace/vsdesktop/out/vsdesktop-darwin-x64/vsdesktop.app"
    fi
    
    echo ""
    echo "Iniciando compilação do VSDesktop ($ARCH_NAME)..."
    echo "Abrindo terminal do container para build..."
    echo ""
    echo "Comandos a executar:"
    echo "  cd /workspace/vsdesktop"
    echo "  npm install"
    echo "  npm run $BUILD_TARGET"
    echo ""
    sleep 3
    
    # Executar npm install e build em novo terminal
    osascript -e "tell app \"Terminal\" to do script \"podman exec -it herodev bash -c 'cd /workspace/vsdesktop && npm install && npm run $BUILD_TARGET'\"" &>/dev/null || \
    open -a Terminal -n --args -c "podman exec -it herodev bash -c 'cd /workspace/vsdesktop && npm install && npm run $BUILD_TARGET'" &>/dev/null || \
    podman exec -it herodev bash -c "cd /workspace/vsdesktop && npm install && npm run $BUILD_TARGET"
    
    echo ""
    echo "Build em progresso! Acompanhe no terminal do container."
    echo ""
    echo "Aguardando conclusão da compilação..."
    echo ""
    
    # Loop de verificação do executável
    while true; do
        sleep 5
        
        if [ -d "$EXPECTED_PATH" ]; then
            echo "Build concluído!"
            echo "Iniciando VSDesktop..."
            sleep 2
            open "$EXPECTED_PATH"
            break
        else
            echo "Verificando..."
        fi
    done
}

gui_prompt

echo ""
