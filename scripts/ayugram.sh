#!/usr/bin/env bash
#
# Copyright (C) 2026 anrix <iz@anrix.org>
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
set -e

CHROOT_DIR="voiz-linux"

echo "Fetching latest ROOTFS filename..."
LATEST=$(curl -s https://repo-default.voidlinux.org/live/current/ | grep -o 'void-x86_64-musl-ROOTFS-[0-9]*\.tar\.xz' | head -n 1)

if [ -z "$LATEST" ]; then
    echo "Error: Failed to find the latest rootfs."
    exit 1
fi

echo "Downloading $LATEST..."
wget -q --show-progress "https://repo-default.voidlinux.org/live/current/$LATEST"

echo "Extracting rootfs (requires sudo)..."
mkdir -p "$CHROOT_DIR"
sudo tar xpJf "$LATEST" -C "$CHROOT_DIR"

echo "Configuring network..."
sudo cp /etc/resolv.conf "${CHROOT_DIR}/etc/"

echo "Entering chroot to execute build script..."
sudo chroot "$CHROOT_DIR" /bin/sh -c 'xbps-install -Syu xbps && xbps-install -Syu && xbps-install -Sy curl bash && curl -sf https://raw.githubusercontent.com/voiz-linux/builder/main/scripts/build.sh | bash'
