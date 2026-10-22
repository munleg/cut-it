#!/usr/bin/env bash
# Copyright (c) 2026 Cut-it contributors. SPDX-License-Identifier: GPL-3.0-or-later
# Run as root in a clean Ubuntu 24.04 container with the signed repository at /repo.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends ca-certificates
install -m644 /repo/cut-it-archive-keyring.gpg /usr/share/keyrings/cut-it.gpg
echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/cut-it.gpg] file:/repo beta main' \
    > /etc/apt/sources.list.d/cut-it.list
apt-get update
apt-cache policy cut-it
apt-get install -y cut-it
test "$(dpkg-query -W -f='${Status}' cut-it)" = 'install ok installed'
test -s /usr/share/applications/io.github.munleg.CutIt.desktop
QT_QPA_PLATFORM=offscreen cut-it --version
QT_QPA_PLATFORM=offscreen CUTIT_SOFTWARE_RENDERING=1 cut-it --version
apt-get install -y --reinstall cut-it
QT_QPA_PLATFORM=offscreen cut-it --version
apt-get remove -y cut-it
test ! -e /opt/cut-it
test ! -L /usr/bin/cut-it
test ! -e /usr/share/applications/io.github.munleg.CutIt.desktop
echo 'PASS: signed APT update, install, launch, reinstall, and removal on Ubuntu 24.04.'
