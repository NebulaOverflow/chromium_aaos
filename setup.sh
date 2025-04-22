#!/bin/bash

set -e

# Colors
GREEN='\033[0;32m'
NC='\033[0m' # No Color

function step() {
    echo -e "${GREEN}[STEP] $1${NC}"
}

# Variables
CHROMIUM_DIR="$HOME/chromium"
ANDROID_DIR="$HOME/Android/Sdk"
KEYSTORE_DIR="$HOME/Documents/KeyStore"
DEPOT_TOOLS_REPO="https://chromium.googlesource.com/chromium/tools/depot_tools.git"
CHROMIUM_AAOS_REPO="https://github.com/NebulaOverflow/chromium_aaos"
CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip"
CMDLINE_ZIP="commandlinetools.zip"
KEYSTORE_PASSWORD=$(tr -dc A-Za-z0-9 </dev/urandom | head -c16)
PASSWORD_FILE="$HOME/pass.txt"

step "Checking for at least 200GB of available disk space..."
FREE_SPACE=$(df --output=avail "$HOME" | tail -1)
if [ "$FREE_SPACE" -lt $((200 * 1024 * 1024)) ]; then
    echo "Error: Not enough disk space. At least 200GB is required."
    exit 1
fi

step "1/12: Updating system and installing required packages..."
sudo apt update && sudo apt upgrade -y
sudo apt install git wget unzip openjdk-17-jdk -y

step "2/12: Cloning depot_tools..."
mkdir -p "$CHROMIUM_DIR"
git clone "$DEPOT_TOOLS_REPO" "$CHROMIUM_DIR/depot_tools"

step "3/12: Configuring depot_tools PATH in ~/.bashrc..."
if ! grep -q 'depot_tools' ~/.bashrc; then
    echo 'export PATH="$HOME/chromium/depot_tools:$PATH"' >> ~/.bashrc
    export PATH="$HOME/chromium/depot_tools:$PATH"
fi

step "4/12: Fetching Chromium source code..."
cd "$CHROMIUM_DIR"
fetch --nohooks android
cd src
build/install-build-deps.sh
gclient runhooks

step "5/12: Downloading and setting up Android command line tools..."
mkdir -p "$ANDROID_DIR/cmdline-tools/latest"
cd "$ANDROID_DIR/cmdline-tools/latest"
wget "$CMDLINE_TOOLS_URL" -O "$CMDLINE_ZIP"
unzip -o "$CMDLINE_ZIP"
mv cmdline-tools/* .
rmdir cmdline-tools
rm "$CMDLINE_ZIP"

step "6/12: Adding Android SDK environment variables to ~/.bashrc..."
if ! grep -q 'ANDROID_SDK_ROOT' ~/.bashrc; then
    {
        echo "export ANDROID_SDK_ROOT=$ANDROID_DIR"
        echo 'export PATH=$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/emulator:$PATH'
        echo 'export PATH=$PATH:$ANDROID_SDK_ROOT/build-tools/35.0.0'
    } >> ~/.bashrc
    export ANDROID_SDK_ROOT=$ANDROID_DIR
    export PATH=$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/emulator:$PATH
    export PATH=$PATH:$ANDROID_SDK_ROOT/build-tools/35.0.0
fi

source ~/.bashrc

step "7/12: Installing Android SDK packages..."
yes | sdkmanager --licenses
sdkmanager "platform-tools" "build-tools;35.0.0"

step "8/12: Creating and configuring KeyStore..."
mkdir -p "$KEYSTORE_DIR"
echo "$KEYSTORE_PASSWORD" > "$PASSWORD_FILE"
cd "$KEYSTORE_DIR"
keytool -genkeypair -v -keystore store.jks -storepass "$KEYSTORE_PASSWORD" -alias chromium-key -keyalg RSA -keysize 2048 -validity 3650 -dname "CN=chromium, OU=dev, O=AAOS, L=internet, S=nowhere, C=US"

step "9/12: Cloning helper scripts from chromium_aaos repository..."
cd "$CHROMIUM_DIR"
git clone "$CHROMIUM_AAOS_REPO" chromium_aaos
find "$CHROMIUM_DIR/chromium_aaos" -type f \( -name "*.sh" -o -name "*.patch" \) ! -name "install.sh" -exec cp {} "$CHROMIUM_DIR" \;

step "10/12: Creating GN args templates..."
cd "$CHROMIUM_DIR/src"
mkdir -p out/Release_arm64 out/Release_x64

RANDOM_ID=$(tr -dc 'a-z' </dev/urandom | head -c 14)
cat <<EOF > out/Release_arm64/args.gn
target_os = "android"
target_cpu = "arm64"
chrome_public_manifest_package = "com.${RANDOM_ID}.chromium"
is_debug = false
is_java_debug = false
is_component_build = false
is_chrome_branded = false
is_official_build = true
media_use_ffmpeg = true
media_use_libvpx = true
proprietary_codecs = true
ffmpeg_branding = "Chrome"
chrome_pgo_phase = 0
EOF

RANDOM_ID_X64=$(tr -dc 'a-z' </dev/urandom | head -c 14)
cat <<EOF > out/Release_x64/args.gn
target_os = "android"
target_cpu = "x64"
chrome_public_manifest_package = "com.${RANDOM_ID_X64}.browser"
is_debug = false
is_java_debug = false
is_component_build = false
is_chrome_branded = false
is_official_build = true
media_use_ffmpeg = true
media_use_libvpx = true
proprietary_codecs = true
ffmpeg_branding = "Chrome"
EOF

step "11/12: GN args configured automatically."

source ~/.bashrc

step "12/12: Ready to build! Running update and build scripts..."
cd "$CHROMIUM_DIR"
chmod +x ./update.sh ./build.sh
./update.sh

cd "$CHROMIUM_DIR/src"
gn gen out/Release_arm64

cd "$CHROMIUM_DIR"
./build.sh

echo -e "${GREEN}Build complete! Your APK(s) can be found here:${NC}"
echo -e "${GREEN}$HOME/chromium/src/out/Release_arm64/apks${NC}"
echo -e "${GREEN}KeyStore password saved in:${NC}"
echo -e "${GREEN}$PASSWORD_FILE${NC}"
