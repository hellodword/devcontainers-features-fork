#!/bin/bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/devcontainers/features/tree/main/src/dotnet
# Maintainer: The VS Code and Codespaces Teams

DOTNET_VERSION="${VERSION:-'latest'}"
DOTNET_ADDITIONAL_VERSIONS="${ADDITIONALVERSIONS:-''}"
DOTNET_RUNTIME_ONLY="${RUNTIMEONLY:-'false'}"

DOTNET_INSTALL_SCRIPT_URL='https://dot.net/v1/dotnet-install.sh'
DOTNET_INSTALL_SCRIPT='/tmp/dotnet-install.sh'
DOTNET_INSTALL_DIR='/usr/local/dotnet/current'

set -e

apt_get_update() {
    if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update -y
    fi
}

# Checks if packages are installed and installs them if not
check_packages() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        apt_get_update
        apt-get -y install --no-install-recommends "$@"
    fi
}

install_version() {
    local version="$1"
    local channel="LTS"
    local runtimeArg=""

    # If version is just a major value, assume it is a channel
    if [[ "$version" =~ ^[0-9]+$ ]]; then
        channel="$version.0"
        version='latest'
    fi

    if ! [[ "$version" = 'latest' || "$version" =~ ^[0-9]+.[0-9]+.[0-9]+$ ]]; then
        echo "version must be 'latest' or use the form 'N.M.O'"
        return 1
    fi

    if [ "$DOTNET_RUNTIME_ONLY" = 'true' ]; then
        runtimeArg = '--runtime dotnet'
    fi

    "$DOTNET_INSTALL_SCRIPT" \
        --install-dir "$DOTNET_INSTALL_DIR" \
        --version "$version" \
        --channel "$channel" \
        $runtimeArg
}

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# icu-devtools includes dependencies for .NET
check_packages wget ca-certificates icu-devtools

wget -O "$DOTNET_INSTALL_SCRIPT" "$DOTNET_INSTALL_SCRIPT_URL"
chmod +x "$DOTNET_INSTALL_SCRIPT"

# Install primary version
install_version "$DOTNET_VERSION"

# TODO: Install additional versions

rm "$DOTNET_INSTALL_SCRIPT"

echo "Done!"
