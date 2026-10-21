#!/usr/bin/env bash
# Copyright (c) 2026 Cut-it contributors. SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail
bundle=$(realpath "${1:?Usage: package-cutit-linux.sh BUNDLE OUTPUT VERSION}")
output=$(realpath -m "${2:?Missing output directory}")
version=${3:?Missing version}
[[ $version =~ ^[A-Za-z0-9.-]+$ ]] || exit 1
repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test -x "$bundle/bin/shotcut"
test -x "$bundle/shotcut"
test -d "$bundle/share/shotcut/qml"
test -d "$bundle/share/shotcut/fonts"
mkdir -p "$output"
staging=$(mktemp -d)
trap 'rm -rf -- "$staging"' EXIT
mkdir -p "$staging/Cut-it"
cp -a "$bundle/." "$staging/Cut-it/"
install -m755 "$repo/packaging/linux/cut-it" "$staging/Cut-it/cut-it"
cp "$repo/docs/LINUX.md" "$staging/Cut-it/README-LINUX.md"
tar -cJf "$output/Cut-it-$version-linux-x86_64.tar.xz" -C "$staging" Cut-it
appdir="$staging/Cut-it.AppDir"
mkdir -p "$appdir/opt" "$appdir/usr/share/metainfo"
mv "$staging/Cut-it" "$appdir/opt/cut-it"
cp "$repo/packaging/linux/io.github.munleg.CutIt.desktop" "$appdir/"
cp "$repo/icons/shotcut-logo-64.png" "$appdir/io.github.munleg.CutIt.png"
cp "$repo/packaging/linux/io.github.munleg.CutIt.metainfo.xml" "$appdir/usr/share/metainfo/"
cat > "$appdir/AppRun" <<'EOF'
#!/bin/sh
set -eu
appdir=$(dirname "$(readlink -f "$0")")
exec "$appdir/opt/cut-it/cut-it" "$@"
EOF
chmod +x "$appdir/AppRun"
desktop-file-validate "$appdir/io.github.munleg.CutIt.desktop"
tool=${APPIMAGETOOL:?Set APPIMAGETOOL to an appimagetool executable}
ARCH=x86_64 APPIMAGE_EXTRACT_AND_RUN=1 "$tool" "$appdir" "$output/Cut-it-$version-linux-x86_64.AppImage"
