# Chromium AAOS Automated Setup 🧩🚗

This project provides a fully automated script to set up and build **Chromium for Android Automotive OS (AAOS)** on Ubuntu. It installs all required tools, configures the Android SDK, fetches the Chromium source, and prepares the build environment—all with minimal manual input.

> ⚠️ **Minimum Requirements**  
> - At least **200 GB** of free disk space  
> - **Ubuntu 22.04.5 LTS** (recommended)  
> - Reliable internet connection  
> - Basic familiarity with the terminal

## ⚡ Quick Install

Get started instantly with a single command:

```bash
bash <(curl -s https://raw.githubusercontent.com/NebulaOverflow/chromium_aaos/refs/heads/main/setup.sh)
```

> 💡 Always review scripts before downloading them from the internet.

This will:
- Clone the repository into your home directory
- Run the entire setup process
- Prompt for your `sudo` password when necessary

## 📦 Features

- End-to-end Chromium + Android SDK setup for AAOS builds
- Automatically installs dependencies and configures environment variables
- Generates a secure Android KeyStore with a random password
- Preconfigured `gn args` for both `arm64` and `x64` target builds
- Pulls helper scripts and patches from the [chromium_aaos](https://github.com/NebulaOverflow/chromium_aaos) community repo

## 🚀 Getting Started

1. **Download the setup script**

   ```bash
   curl -O https://raw.githubusercontent.com/NebulaOverflow/chromium_aaos/refs/heads/main/setup.sh
   ```

2. **Make the script executable and run it**

   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

This will:
- Install all required dependencies and tools
- Set up `depot_tools` and fetch the Chromium source
- Configure the Android SDK and accept licenses
- Generate a KeyStore and store the password in `~/pass.txt`
- Create GN configuration files for both `arm64` and `x64`
- Start the build process automatically

> ✅ Tip: You can also use the [Quick Install](#-quick-install) one-liner above to do all this in one step.

## 📁 Output Overview

| Path                            | Description                         |
|---------------------------------|-------------------------------------|
| `~/chromium/src`                | Chromium source code                |
| `~/Android/Sdk`                 | Installed Android SDK               |
| `~/Documents/KeyStore/store.jks`| Android signing KeyStore            |
| `~/pass.txt`                    | Auto-generated KeyStore password    |
| `out/Release_arm64` / `x64`     | Build output directories            |

## 📌 Notes

- Intended for **development and testing** use cases.
- For production apps, consider customizing the KeyStore, manifest, and branding.
- Supports integration with additional patches via `chromium_aaos`.

## 🧠 Credits

- [Chromium Project](https://chromium.org)
- [zunichky](https://github.com/zunichky/chromium_aaos) for the original `automotive.patch` and scripts
