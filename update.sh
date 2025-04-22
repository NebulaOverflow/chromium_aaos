#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

SRC_DIR="src"
PATCH_FILE="$HOME/chromium/automotive.patch"
PATCH_BASENAME="automotive.patch"

echo ">>> Changing to source directory: $SRC_DIR"
cd "$SRC_DIR" || { echo "Directory $SRC_DIR not found"; exit 1; }

echo ">>> Fetching latest changes"
git fetch

echo ">>> Resetting local changes"
git reset --hard

echo ">>> Switching to main branch"
git checkout main

echo ">>> Pulling latest code"
git pull

echo ">>> Syncing dependencies with gclient"
gclient sync

if [[ -f "$PATCH_FILE" ]]; then
    echo ">>> Copying patch file"
    cp "$PATCH_FILE" .

    echo ">>> Applying patch"
    if git apply "$PATCH_BASENAME"; then
        echo ">>> Patch applied successfully"
        #rm "$PATCH_BASENAME"
    else
        echo "!!! Failed to apply patch"
        rm "$PATCH_BASENAME"
        exit 1
    fi
else
    echo "!!! Patch file not found: $PATCH_FILE"
    exit 1
fi

echo ">>> Running gclient hooks"
gclient runhooks

echo ">>> Done"
