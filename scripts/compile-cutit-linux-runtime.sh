#!/usr/bin/env bash
# Copyright (c) 2026 Cut-it contributors. SPDX-License-Identifier: GPL-3.0-or-later
# Internal entry point for the pinned Linux build container.
set -eo pipefail
qt=$(find /root/Qt -path '*/bin/qmake' -print -quit)
test -n "$qt"
test "$("$qt" -query QT_VERSION)" = 6.10.3
qt=$(dirname "$(dirname "$qt")")
export PATH="$qt/bin:$PATH"
export CC=gcc-12 CXX=g++-12
# Build only the SDK from the exact sources corresponding to the runtime.
# Keep the published runtime libraries and all media plugins unchanged.
grep -q 'VERSION 7.41.0' /work/src/mlt/CMakeLists.txt
mapfile -t modules < <(sed -n 's/^option(\(MOD_[A-Z0-9_]*\).*/-D\1=OFF/p' /work/src/mlt/CMakeLists.txt)
cmake -S /work/src/mlt -B /work/mlt-sdk-build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/work/sdk \
    -DCMAKE_INSTALL_LIBDIR=lib -DBUILD_TESTING=OFF "${modules[@]}"
cmake --build /work/mlt-sdk-build --parallel 4
cmake --install /work/mlt-sdk-build
export PKG_CONFIG_PATH=/work/sdk/lib/pkgconfig
cmake -S /work/cutit-source -B /work/cutit-build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="$qt" \
    -DCMAKE_INSTALL_PREFIX=/work/Shotcut.app -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_INSTALL_RPATH='$ORIGIN/../lib' -DSHOTCUT_VERSION=26.10.21 \
    -DSHOTCUT_BUILD_TESTS=ON -DCLANG_FORMAT=OFF -DBUILD_DOCS=OFF
cmake --build /work/cutit-build --parallel 4
cmake --install /work/cutit-build
cd /work/Shotcut.app
. ./source-me
export QT_QPA_PLATFORM=offscreen
# Tests must resolve the published runtime rather than the temporary SDK.
ldd bin/shotcut | tee /work/linked-libraries.log
! grep -q 'not found' /work/linked-libraries.log
ctest --test-dir /work/cutit-build --output-on-failure 2>&1 | tee /work/tests.log
./shotcut --version 2>&1 | tee -a /work/tests.log
