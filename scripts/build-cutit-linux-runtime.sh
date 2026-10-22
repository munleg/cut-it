#!/usr/bin/env bash
# Copyright (c) 2026 Cut-it contributors. SPDX-License-Identifier: GPL-3.0-or-later
# Reuse the published media runtime; compile Cut-it and its matching MLT SDK.
set -euo pipefail
repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
version=0.1.2-linux-beta.1
image=mltframework/shotcut-build:qt6.10.3-ubuntu22.04@sha256:5c0a901bba3c923d6c03336df2e463e0695ee4c7b107271f2f8c3a5499bd29c1
output=${CUTIT_LINUX_OUTPUT:-"$repo/../linux-runtime-build"}
command -v docker >/dev/null || { echo 'Docker is required to build the Linux bundle.' >&2; exit 1; }
[[ $(uname -m) == x86_64 ]] || { echo 'This build targets x86_64 Linux.' >&2; exit 1; }
git -C "$repo" diff --exit-code
git -C "$repo" diff --cached --exit-code
revision=$(git -C "$repo" rev-parse HEAD)
mkdir -p "$output"
output=$(realpath "$output")
[[ ! -e "$output/Shotcut.app" ]] || { echo 'Use a fresh output directory.' >&2; exit 1; }
base=https://github.com/mltframework/shotcut/releases/download/v26.9.27
curl -fL --retry 3 "$base/shotcut-linux-x86_64-26.9.27.txz" -o "$output/runtime.txz"
curl -fL --retry 3 "$base/shotcut-src-26.9.27.txz" -o "$output/upstream-sources.txz"
(cd "$output" && sha256sum -c <<'EOF'
849da6bbd24737f9edd07ba185b46982f2fb330981c05e1752809e85bcbb7e7b  runtime.txz
c20cef9e5e23acbbd2ba20a46e53919b923839a7f577584c0f9ec18aefa06576  upstream-sources.txz
EOF
)
tar -xJf "$output/runtime.txz" -C "$output"
tar -xJf "$output/upstream-sources.txz" -C "$output" src/mlt
mkdir "$output/cutit-source"
git -C "$repo" archive HEAD | tar -x -C "$output/cutit-source"
docker pull "$image"
docker image inspect "$image" --format '{{json .RepoDigests}}' > "$output/build-image.json"
docker run --rm -v "$output:/work" "$image" /work/cutit-source/scripts/compile-cutit-linux-runtime.sh \
    2>&1 | tee "$output/build.log"
mkdir -p "$repo/dist"
bash "$repo/scripts/package-cutit-linux.sh" "$output/Shotcut.app" "$repo/dist" "$version"
docker run --rm -v "$repo/dist:/packages:ro" -v "$output:/work" "$image" \
    /work/cutit-source/scripts/test-cutit-linux-packages.sh /packages "$version" \
    2>&1 | tee "$output/package-tests.log"
cp "$output/upstream-sources.txz" "$repo/dist/Shotcut-runtime-26.9.27-sources.tar.xz"
git -C "$repo" archive --prefix=cut-it/ HEAD | xz > "$repo/dist/Cut-it-$version-sources.tar.xz"
cp "$output/build-image.json" "$output/tests.log" "$output/package-tests.log" "$repo/dist/"
printf '%s\n' "$revision" > "$repo/dist/SOURCE-COMMIT.txt"
printf '%s\n' "$base/shotcut-linux-x86_64-26.9.27.txz" > "$repo/dist/RUNTIME-SOURCE.txt"
(cd "$repo/dist" && sha256sum Cut-it-* Shotcut-*-sources.tar.xz > SHA256SUMS.txt)
