#!/usr/bin/env bash
# Copyright (c) 2026 Cut-it contributors. SPDX-License-Identifier: GPL-3.0-or-later
# Run on Linux with Docker. Builds the exact committed checkout, not upstream Shotcut.
set -euo pipefail
repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
version=0.1.2-linux-beta.1
image=mltframework/shotcut-build:qt6.10.3-ubuntu22.04
output=${CUTIT_LINUX_OUTPUT:-"$repo/../linux-build"}
command -v docker >/dev/null || { echo 'Docker is required to build the Linux bundle.' >&2; exit 1; }
[[ $(uname -m) == x86_64 ]] || { echo 'This build targets x86_64 Linux.' >&2; exit 1; }
git -C "$repo" diff --quiet
git -C "$repo" diff --cached --quiet
revision=$(git -C "$repo" rev-parse HEAD)
mkdir -p "$output"
output=$(cd "$output" && pwd)
# Never overwrite or reuse an unrelated build directory.
[[ ! -e "$output/build-shotcut.conf" ]] || { echo "Use a fresh CUTIT_LINUX_OUTPUT directory: $output" >&2; exit 1; }
cp "$repo/scripts/build-shotcut.sh" "$output/build-shotcut.sh"
cat > "$output/build-shotcut.conf" <<EOF
INSTALL_DIR=/root/shotcut
SOURCE_DIR=/root/shotcut/src
ACTION_CLEANUP=0
SHOTCUT_REPOSITORY=/input/shotcut
SHOTCUT_HEAD=0
SHOTCUT_REVISION=$revision
SHOTCUT_VERSION=26.10.21
SHOTCUT_CMAKE_ARGS="-DSHOTCUT_BUILD_TESTS=ON -DCLANG_FORMAT=OFF -DBUILD_DOCS=OFF"
EOF
docker pull "$image"
docker image inspect "$image" --format '{{json .RepoDigests}}' > "$output/build-image.json"
docker run --rm -v "$repo:/input/shotcut:ro" -v "$output:/root/shotcut" \
    "$image" -c 'git config --global --add safe.directory /input/shotcut; cd /root/shotcut; bash ./build-shotcut.sh' \
    2>&1 | tee "$output/build.log"
test -x "$output/Shotcut/Shotcut.app/bin/shotcut"
docker run --rm -v "$output:/root/shotcut" "$image" -c '
    set -e
    cd /root/shotcut/Shotcut/Shotcut.app
    . ./source-me
    export QT_QPA_PLATFORM=offscreen
    ctest --test-dir /root/shotcut/src/shotcut --output-on-failure
    ./shotcut --version
' 2>&1 | tee "$output/tests.log"
mkdir -p "$repo/dist"
bash "$repo/scripts/package-cutit-linux.sh" "$output/Shotcut/Shotcut.app" "$repo/dist" "$version"
test -s "$output/src.txz"
cp "$output/src.txz" "$repo/dist/Cut-it-$version-sources.tar.xz"
cp "$output/build-image.json" "$output/tests.log" "$repo/dist/"
printf '%s\n' "$revision" > "$repo/dist/SOURCE-COMMIT.txt"
(cd "$repo/dist" && sha256sum Cut-it-* > SHA256SUMS.txt)
