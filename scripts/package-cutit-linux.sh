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

# Keep prereleases below the stable version in Debian's version ordering.
debversion=${version/-linux-beta./~beta.}
debdir="$staging/deb"
mkdir -p "$debdir/DEBIAN" "$debdir/opt" "$debdir/usr/bin" \
    "$debdir/usr/share/applications" "$debdir/usr/share/metainfo" \
    "$debdir/usr/share/icons/hicolor/64x64/apps" "$debdir/usr/share/doc/cut-it"
cp -a "$appdir/opt/cut-it" "$debdir/opt/"
ln -s /opt/cut-it/cut-it "$debdir/usr/bin/cut-it"
cp "$repo/packaging/linux/io.github.munleg.CutIt.desktop" "$debdir/usr/share/applications/"
cp "$repo/packaging/linux/io.github.munleg.CutIt.metainfo.xml" "$debdir/usr/share/metainfo/"
cp "$repo/icons/shotcut-logo-64.png" "$debdir/usr/share/icons/hicolor/64x64/apps/io.github.munleg.CutIt.png"
cp "$repo/COPYING" "$debdir/usr/share/doc/cut-it/copyright"
cp "$repo/docs/LINUX.md" "$debdir/usr/share/doc/cut-it/README.md"
installed_size=$(du -sk "$debdir/opt" | cut -f1)
cat > "$debdir/DEBIAN/control" <<EOF
Package: cut-it
Version: $debversion
Section: video
Priority: optional
Architecture: amd64
Maintainer: Cut-it contributors <munleg@users.noreply.github.com>
Homepage: https://github.com/munleg/cut-it
Installed-Size: $installed_size
Depends: libc6 (>= 2.35), libstdc++6 (>= 12), libgcc-s1, libx11-6, libx11-xcb1, libgl1, libglx0, libopengl0, libegl1, libxcb1, libxcb-cursor0, libxkbcommon-x11-0, libfontconfig1, libfreetype6, libglib2.0-0t64 | libglib2.0-0, zlib1g, libexpat1, libuuid1, libcom-err2, libgpg-error0, libdbus-1-3, libasound2t64 | libasound2, libpulse0
Recommends: libgl1-mesa-dri, libpipewire-0.3-0t64 | libpipewire-0.3-0
Description: Cut-it video editor, based on Shotcut
 Multitrack video editing with text, effects, and preview pose keyframes.
 This Linux beta bundles its Qt and media runtime under /opt/cut-it.
EOF
dpkg-deb --build --root-owner-group -Zxz -z3 "$debdir" "$output/Cut-it-$version-linux-x86_64.deb"
