#!/bin/bash

# === CONFIGURATION ===
DEFAULT_SRC="$HOME/chromium/src"
KEYSTORE="$HOME/Documents/KeyStore/store.jks"
ARCHITECTURE="arm64"  # Options: arm64, x64

# === FUNCTIONS ===

log() {
    echo -e "[INFO] $1"
}

error() {
    echo -e "[ERROR] $1" >&2
}

exit_if_fail() {
    if [[ $1 -ne 0 ]]; then
        error "$2"
        exit 1
    fi
}

# === DETERMINE SOURCE PATH ===

SRC="${1:-$DEFAULT_SRC}"
log "Using Chromium source directory: $SRC"

if [[ ! -d "$SRC" ]]; then
    error "Source directory '$SRC' does not exist."
    echo "Provide a valid path as an argument or update DEFAULT_SRC."
    exit 1
fi

cd "$SRC" || {
    error "Failed to change directory to '$SRC'."
    exit 1
}

# === SELECT BUILD FOLDER BASED ON ARCHITECTURE ===

case "$ARCHITECTURE" in
    arm64)
        BUILD_FOLDER="Release_arm64"
        ;;
    x64)
        BUILD_FOLDER="Release_X64"
        ;;
    *)
        error "Unsupported architecture: $ARCHITECTURE"
        exit 1
        ;;
esac

log "Building for architecture: $ARCHITECTURE"
OUT_DIR="$SRC/out/$BUILD_FOLDER"

# === UPDATE VERSION FILE ===

VERSION_FILE="$SRC/chrome/VERSION"

if [[ -f "$VERSION_FILE" ]]; then
    log "Updating version file: $VERSION_FILE"

    MAJOR=$(awk -F= '/^MAJOR/ {print $2}' "$VERSION_FILE")
    BUILD=$(awk -F= '/^BUILD/ {print $2}' "$VERSION_FILE")

    ((MAJOR++))
    ((BUILD++))

    sed -i "s/^MAJOR=.*/MAJOR=$MAJOR/" "$VERSION_FILE"
    sed -i "s/^BUILD=.*/BUILD=$BUILD/" "$VERSION_FILE"

    cp "$VERSION_FILE" "$HOME/chromium/VERSION"

    log "Version updated: MAJOR=$MAJOR, BUILD=$BUILD"
else
    error "Version file not found at $VERSION_FILE. Skipping version update."
fi

# === BUILD ===

log "Starting build process (this may take a while)..."
autoninja -C "$OUT_DIR" monochrome_public_bundle
exit_if_fail $? "Build failed."

log "Build completed successfully."

# === SIGNING ===

AAB_FILE="$OUT_DIR/apks/MonochromePublic6432.aab"

if [[ -f "$AAB_FILE" ]]; then
    log "Signing AAB file: $AAB_FILE"
    apksigner sign --ks "$KEYSTORE" --min-sdk-version 24 "$AAB_FILE"
    exit_if_fail $? "Signing failed. You can retry manually using:
    apksigner sign --ks \"$KEYSTORE\" --min-sdk-version 24 \"$AAB_FILE\""
    log "Signing completed successfully."
else
    error "AAB file not found: $AAB_FILE"
    exit 1
fi

log "Script execution completed successfully!"
