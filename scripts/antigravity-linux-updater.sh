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

# Official Release URLs
URL_STANDALONE="https://storage.googleapis.com/antigravity-public/antigravity-hub/2.8.1-6512087774658560/linux-x64/Antigravity.tar.gz"
URL_IDE="https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/2.5.5-4923483625488384/linux-x64/Antigravity%20IDE.tar.gz"

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
    mkdir -p "$BIN_DIR"
}

# Update Antigravity IDE
update_ide() {
    echo ""
    echo "📦 [1/2] Updating Antigravity IDE..."
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

    # Symlink to bin
    ln -sf "$INSTALL_DIR_IDE/antigravity-ide" "$BIN_DIR/antigravity-ide"
    if [ -d "/usr/local/bin" ] && [ -w "/usr/local/bin" ]; then
        ln -sf "$INSTALL_DIR_IDE/antigravity-ide" "/usr/local/bin/antigravity-ide"
    fi

    rm -rf "$TMP_DIR"
    echo "   ✅ Antigravity IDE updated successfully!"
}

# Update Antigravity Standalone App
update_standalone() {
    echo ""
    echo "📦 [2/2] Updating Antigravity Standalone App..."
    TMP_DIR=$(mktemp -d)
    TAR_PATH="$TMP_DIR/Antigravity_Standalone.tar.gz"

    LOCAL_ARCHIVE=$(ls -t "$DOWNLOAD_DIR"/Antigravity*x64*.tar.gz "$DOWNLOAD_DIR"/Antigravity*Standalone*.tar.gz 2>/dev/null | head -n 1 || true)

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
        sudo chown -R "$USER:$USER" "$INSTALL_DIR_STANDALONE"
    fi

    # Symlink to bin
    ln -sf "$INSTALL_DIR_STANDALONE/antigravity" "$BIN_DIR/antigravity"
    if [ -d "/usr/local/bin" ] && [ -w "/usr/local/bin" ]; then
        ln -sf "$INSTALL_DIR_STANDALONE/antigravity" "/usr/local/bin/antigravity"
    fi

    rm -rf "$TMP_DIR"
    echo "   ✅ Antigravity Standalone updated successfully!"
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
    echo "🎉 Update finished! All Antigravity packages are up to date."
}

main "$@"
