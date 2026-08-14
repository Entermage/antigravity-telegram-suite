#!/bin/bash
# ==============================================================================
# Antigravity Linux Auto-Updater
# Open-Source Linux Installer & Updater for Antigravity Standalone & IDE
# ==============================================================================

set -euo pipefail

# Configuration
INSTALL_DIR_IDE="${INSTALL_DIR_IDE:-/opt/antigravity-ide}"
INSTALL_DIR_STANDALONE="${INSTALL_DIR_STANDALONE:-/opt/antigravity-standalone}"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
DOWNLOAD_DIR="${DOWNLOAD_DIR:-$HOME/Downloads}"
APPLICATIONS_DIR="$HOME/.local/share/applications"
ICONS_DIR="$HOME/.local/share/icons"

# Official Release URLs (Can be overridden via env vars)
URL_STANDALONE="${URL_STANDALONE:-https://storage.googleapis.com/antigravity-public/antigravity-hub/2.8.1-6512087774658560/linux-x64/Antigravity.tar.gz}"
URL_IDE="${URL_IDE:-https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/2.5.5-4923483625488384/linux-x64/Antigravity%20IDE.tar.gz}"

echo "✨ ==========================================="
echo "🚀 Antigravity Linux Auto-Updater"
echo "✨ ==========================================="

# Check system dependencies
check_deps() {
    for cmd in curl tar rsync find; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "❌ Error: Required dependency '$cmd' is missing."
            exit 1
        fi
    done
    mkdir -p "$BIN_DIR" "$APPLICATIONS_DIR" "$ICONS_DIR"
}

# Update Antigravity IDE
update_ide() {
    echo ""
    echo "📦 [1/2] Updating Antigravity IDE..."

    LATEST_VERSION=$(echo "$URL_IDE" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+-[0-9]+' || true)
    if [ -f "$INSTALL_DIR_IDE/.version" ] && [ -n "$LATEST_VERSION" ]; then
        CURRENT_VERSION=$(cat "$INSTALL_DIR_IDE/.version")
        if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
            echo "   ✅ Antigravity IDE is already up to date ($CURRENT_VERSION). Refreshing shortcuts..."
            install_ide_shortcuts
            return 0
        fi
    fi

    TMP_DIR=$(mktemp -d)
    TAR_PATH="$TMP_DIR/Antigravity_IDE.tar.gz"

    LOCAL_ARCHIVE=$(ls -t "$DOWNLOAD_DIR"/Antigravity*IDE*.tar.gz "$DOWNLOAD_DIR"/Antigravity*IDE*.zip 2>/dev/null | head -n 1 || true)

    # Determine curl progress mode based on TTY availability
    CURL_FLAGS="-fsSL"
    if [ -t 1 ]; then
        CURL_FLAGS="-fsSL --progress-bar"
    fi

    if [ -n "$LOCAL_ARCHIVE" ]; then
        echo "   -> Local archive found in Downloads: $(basename "$LOCAL_ARCHIVE")"
        TAR_PATH="$LOCAL_ARCHIVE"
    else
        echo "   -> Downloading latest release from Google storage..."
        curl $CURL_FLAGS "$URL_IDE" -o "$TAR_PATH"
    fi

    echo "   -> Unpacking archive..."
    EXTRACT_DIR="$TMP_DIR/extracted"
    mkdir -p "$EXTRACT_DIR"
    tar -xzf "$TAR_PATH" -C "$EXTRACT_DIR"

    TARGET_SRC=$(find "$EXTRACT_DIR" -maxdepth 2 -type f -name "antigravity-ide" -exec dirname {} \; | head -n 1)

    if [ -z "$TARGET_SRC" ]; then
        echo "   ❌ Failed to locate 'antigravity-ide' binary in archive."
        rm -rf "$TMP_DIR"
        return 1
    fi

    echo "   -> Syncing files into $INSTALL_DIR_IDE..."
    if [ -w "$(dirname "$INSTALL_DIR_IDE")" ] || [ -w "$INSTALL_DIR_IDE" ]; then
        mkdir -p "$INSTALL_DIR_IDE"
        rsync -a --delete "$TARGET_SRC/" "$INSTALL_DIR_IDE/"
    else
        sudo mkdir -p "$INSTALL_DIR_IDE"
        sudo rsync -a --delete "$TARGET_SRC/" "$INSTALL_DIR_IDE/"
        sudo chown -R "$USER:$USER" "$INSTALL_DIR_IDE"
    fi

    [ -n "$LATEST_VERSION" ] && echo "$LATEST_VERSION" > "$INSTALL_DIR_IDE/.version"
    rm -rf "$TMP_DIR"

    install_ide_shortcuts
    echo "   ✅ Antigravity IDE updated successfully!"
}

install_ide_shortcuts() {
    # Symlink to bin
    ln -sf "$INSTALL_DIR_IDE/antigravity-ide" "$BIN_DIR/antigravity-ide"
    if [ -d "/usr/local/bin" ] && [ -w "/usr/local/bin" ]; then
        ln -sf "$INSTALL_DIR_IDE/antigravity-ide" "/usr/local/bin/antigravity-ide" 2>/dev/null || true
    fi

    # Launcher wrapper with CDP port 9334
    cat > "$BIN_DIR/antigravity-ide-launcher.sh" << 'EOF'
#!/bin/bash
PORT=9334
APP_PATH="/opt/antigravity-ide/antigravity-ide"
LISTENING_PIDS=$(lsof -t -i :"$PORT" -s TCP:LISTEN 2>/dev/null || true)
if [ -n "$LISTENING_PIDS" ]; then
    exec "$APP_PATH" "$@"
fi
rm -f "$HOME/.config/Antigravity IDE/code.lock" "$HOME/.config/Antigravity-IDE/code.lock"
exec "$APP_PATH" --remote-debugging-port="$PORT" "$@"
EOF
    chmod +x "$BIN_DIR/antigravity-ide-launcher.sh"

    # Create Desktop entry
    cat > "$APPLICATIONS_DIR/antigravity-ide.desktop" << EOF
[Desktop Entry]
Name=Antigravity IDE
Comment=Antigravity IDE - AI-powered Code Editor
GenericName=Text Editor
Exec=$BIN_DIR/antigravity-ide-launcher.sh %F
Icon=/usr/share/icons/hicolor/512x512/apps/antigravity-ide.png
Type=Application
StartupNotify=false
StartupWMClass=antigravity-ide
Categories=Development;IDE;TextEditor;
MimeType=application/x-antigravity-workspace;
EOF
    chmod +x "$APPLICATIONS_DIR/antigravity-ide.desktop"
}

# Update Antigravity Standalone App
update_standalone() {
    echo ""
    echo "📦 [2/2] Updating Antigravity Standalone App..."

    LATEST_VERSION=$(echo "$URL_STANDALONE" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+-[0-9]+' || true)
    if [ -f "$INSTALL_DIR_STANDALONE/.version" ] && [ -n "$LATEST_VERSION" ]; then
        CURRENT_VERSION=$(cat "$INSTALL_DIR_STANDALONE/.version")
        if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
            echo "   ✅ Antigravity Standalone is already up to date ($CURRENT_VERSION). Refreshing shortcuts..."
            install_standalone_shortcuts
            return 0
        fi
    fi

    TMP_DIR=$(mktemp -d)
    TAR_PATH="$TMP_DIR/Antigravity_Standalone.tar.gz"

    LOCAL_ARCHIVE=$(ls -t "$DOWNLOAD_DIR"/Antigravity*.tar.gz "$DOWNLOAD_DIR"/Antigravity*.zip 2>/dev/null | grep -i -v "IDE" | head -n 1 || true)

    # Determine curl progress mode based on TTY availability
    CURL_FLAGS="-fsSL"
    if [ -t 1 ]; then
        CURL_FLAGS="-fsSL --progress-bar"
    fi

    if [ -n "$LOCAL_ARCHIVE" ]; then
        echo "   -> Local archive found in Downloads: $(basename "$LOCAL_ARCHIVE")"
        TAR_PATH="$LOCAL_ARCHIVE"
    else
        echo "   -> Downloading latest release from Google storage..."
        curl $CURL_FLAGS "$URL_STANDALONE" -o "$TAR_PATH"
    fi

    echo "   -> Unpacking archive..."
    EXTRACT_DIR="$TMP_DIR/extracted"
    mkdir -p "$EXTRACT_DIR"
    tar -xzf "$TAR_PATH" -C "$EXTRACT_DIR"

    TARGET_SRC=$(find "$EXTRACT_DIR" -maxdepth 2 -type f -name "antigravity" -exec dirname {} \; | head -n 1)

    if [ -z "$TARGET_SRC" ]; then
        echo "   ❌ Failed to locate 'antigravity' binary in archive."
        rm -rf "$TMP_DIR"
        return 1
    fi

    echo "   -> Syncing files into $INSTALL_DIR_STANDALONE..."
    if [ -w "$(dirname "$INSTALL_DIR_STANDALONE")" ] || [ -w "$INSTALL_DIR_STANDALONE" ]; then
        mkdir -p "$INSTALL_DIR_STANDALONE"
        rsync -a --delete "$TARGET_SRC/" "$INSTALL_DIR_STANDALONE/"
    else
        sudo mkdir -p "$INSTALL_DIR_STANDALONE"
        sudo rsync -a --delete "$TARGET_SRC/" "$INSTALL_DIR_STANDALONE/"
        sudo chown -R "$USER:$USER" "$INSTALL_DIR_STANDALONE" 2>/dev/null || true
    fi

    # Ensure /opt/antigravity links to /opt/antigravity-standalone
    if [ "$INSTALL_DIR_STANDALONE" != "/opt/antigravity" ]; then
        if [ -w "/opt" ]; then
            ln -sfn "$INSTALL_DIR_STANDALONE" "/opt/antigravity" 2>/dev/null || true
        fi
    fi

    [ -n "$LATEST_VERSION" ] && echo "$LATEST_VERSION" > "$INSTALL_DIR_STANDALONE/.version"
    rm -rf "$TMP_DIR"

    install_standalone_shortcuts
    echo "   ✅ Antigravity Standalone updated successfully!"
}

install_standalone_shortcuts() {
    # Symlinks to bin
    ln -sf "$INSTALL_DIR_STANDALONE/antigravity" "$BIN_DIR/antigravity"
    ln -sf "$INSTALL_DIR_STANDALONE/antigravity" "$BIN_DIR/antigravity-standalone"
    if [ -d "/usr/local/bin" ] && [ -w "/usr/local/bin" ]; then
        ln -sf "$INSTALL_DIR_STANDALONE/antigravity" "/usr/local/bin/antigravity" 2>/dev/null || true
        ln -sf "$INSTALL_DIR_STANDALONE/antigravity" "/usr/local/bin/antigravity-standalone" 2>/dev/null || true
    fi

    # Launcher wrapper with CDP port 9333
    cat > "$BIN_DIR/antigravity-launcher.sh" << 'EOF'
#!/bin/bash
PORT=9333
APP_PATH="/opt/antigravity-standalone/antigravity"
LISTENING_PIDS=$(lsof -t -i :"$PORT" -s TCP:LISTEN 2>/dev/null || true)
if [ -n "$LISTENING_PIDS" ]; then
    exec "$APP_PATH" "$@"
fi
rm -f "$HOME/.config/Antigravity/code.lock" "$HOME/.config/Antigravity/SingletonLock"
exec "$APP_PATH" --remote-debugging-port="$PORT" "$@"
EOF
    chmod +x "$BIN_DIR/antigravity-launcher.sh"
    ln -sf "$BIN_DIR/antigravity-launcher.sh" "$BIN_DIR/antigravity-standalone-launcher.sh"

    # User Desktop Entry (overrides broken /usr/share/applications/antigravity.desktop)
    cat > "$APPLICATIONS_DIR/antigravity.desktop" << EOF
[Desktop Entry]
Name=Antigravity
Comment=Antigravity Standalone AI Agent
GenericName=AI Coding Assistant
Exec=$BIN_DIR/antigravity-launcher.sh %F
Icon=antigravity
Type=Application
StartupNotify=false
StartupWMClass=Antigravity
Categories=Development;IDE;TextEditor;
Actions=new-empty-window;
MimeType=x-scheme-handler/antigravity;application/x-antigravity-workspace;

[Desktop Action new-empty-window]
Name=New Empty Window
Exec=$BIN_DIR/antigravity-launcher.sh --new-window %F
Icon=antigravity
EOF
    chmod +x "$APPLICATIONS_DIR/antigravity.desktop"

    cat > "$APPLICATIONS_DIR/antigravity-standalone.desktop" << EOF
[Desktop Entry]
Name=Antigravity Standalone
Comment=Antigravity Standalone AI Agent
GenericName=AI Coding Assistant
Exec=$BIN_DIR/antigravity-launcher.sh %F
Icon=antigravity
Type=Application
StartupNotify=false
StartupWMClass=Antigravity
Categories=Development;IDE;
EOF
    chmod +x "$APPLICATIONS_DIR/antigravity-standalone.desktop"

    # Update desktop database
    update-desktop-database "$APPLICATIONS_DIR" 2>/dev/null || true
}

main() {
    check_deps
    
    MODE="${1:-all}"
    case "$MODE" in
        --ide-only)
            update_ide
            ;;
        --standalone-only)
            update_standalone
            ;;
        *)
            update_ide
            update_standalone
            ;;
    esac

    echo ""
    echo "🎉 Update finished! All Antigravity packages and launchers are up to date."
}

main "$@"
