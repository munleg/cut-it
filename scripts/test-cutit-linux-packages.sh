#!/usr/bin/env bash
# Copyright (c) 2026 Cut-it contributors. SPDX-License-Identifier: GPL-3.0-or-later
# Run inside the Linux build container, against the actual distributable files.
set -euo pipefail
packages=$(realpath "${1:?Missing package directory}")
version=${2:?Missing version}
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
export QT_QPA_PLATFORM=offscreen
export LC_ALL=C.UTF-8
mkdir -p "$work/Folder With Spaces"
tar -xJf "$packages/Cut-it-$version-linux-x86_64.tar.xz" -C "$work/Folder With Spaces"
bundle="$work/Folder With Spaces/Cut-it"
test -s "$bundle/README-LINUX.md"
test -d "$bundle/share/shotcut/qml"
test -d "$bundle/share/shotcut/fonts"
"$bundle/cut-it" --version
CUTIT_SOFTWARE_RENDERING=1 "$bundle/cut-it" --version
# Exercise the AppImage entry point without requiring FUSE or a display server.
cp "$packages/Cut-it-$version-linux-x86_64.AppImage" "$work/Folder With Spaces/Cut-it.AppImage"
chmod +x "$work/Folder With Spaces/Cut-it.AppImage"
APPIMAGE_EXTRACT_AND_RUN=1 "$work/Folder With Spaces/Cut-it.AppImage" --version
echo 'PASS: portable and AppImage packages launch from a path containing spaces.'
deb="$packages/Cut-it-$version-linux-x86_64.deb"
test "$(dpkg-deb -f "$deb" Package)" = cut-it
test "$(dpkg-deb -f "$deb" Architecture)" = amd64
dpkg --compare-versions "$(dpkg-deb -f "$deb" Version)" lt "${version%%-linux-beta.*}"
dpkg-deb -x "$deb" "$work/deb"
test "$(readlink "$work/deb/usr/bin/cut-it")" = /opt/cut-it/cut-it
test -s "$work/deb/usr/share/applications/io.github.munleg.CutIt.desktop"
"$work/deb/opt/cut-it/cut-it" --version
echo 'PASS: Debian package metadata, desktop entry, version ordering, and bundled launcher.'
