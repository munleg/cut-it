#!/usr/bin/env bash
# Copyright (c) 2026 Cut-it contributors. SPDX-License-Identifier: GPL-3.0-or-later
# Run as root in a clean Ubuntu 24.04 container against a file or HTTPS repository.
set -euo pipefail
repository=${1:-file:/repo}
[[ $repository == file:/repo || $repository == https://munleg.github.io/cut-it ]] || exit 1
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends ca-certificates curl
if [[ $repository == file:/repo ]]; then
    install -m644 /repo/cut-it-archive-keyring.gpg /usr/share/keyrings/cut-it.gpg
else
    curl --fail --location --retry 5 --retry-all-errors --retry-delay 5 \
        "$repository/cut-it-archive-keyring.gpg" -o /usr/share/keyrings/cut-it.gpg
fi
if [[ -n ${EXPECTED_APT_KEY_SHA256:-} ]]; then
    printf '%s  /usr/share/keyrings/cut-it.gpg\n' "$EXPECTED_APT_KEY_SHA256" | sha256sum -c -
fi
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/cut-it.gpg] $repository beta main" \
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
echo "PASS: signed APT update, install, launch, reinstall, and removal on Ubuntu 24.04 ($repository)."
