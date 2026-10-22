#!/usr/bin/env bash
# Copyright (c) 2026 Cut-it contributors. SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail
packages=$(realpath "${1:?Missing package directory}")
output=$(realpath -m "${2:?Missing repository output directory}")
repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
fingerprint=$(tr -d '[:space:]' < "$repo/packaging/linux/apt/FINGERPRINT")
[[ $fingerprint =~ ^[A-F0-9]{40}$ ]]
[[ ! -e "$output" ]] || { echo 'Use a fresh APT output directory.' >&2; exit 1; }
mkdir -p "$output/pool/main/c/cut-it" "$output/dists/beta/main/binary-amd64" "$output/sources"
cp "$packages"/*-linux-x86_64.deb "$output/pool/main/c/cut-it/"
cp "$packages"/*-sources.tar.xz "$output/sources/"
cp "$packages/SOURCE-COMMIT.txt" "$packages/SHA256SUMS.txt" "$output/"
gpg --batch --export "$fingerprint" > "$output/cut-it-archive-keyring.gpg"
test -s "$output/cut-it-archive-keyring.gpg"
cp "$repo/packaging/linux/apt/FINGERPRINT" "$output/"
cd "$output"
apt-ftparchive packages pool > dists/beta/main/binary-amd64/Packages
gzip -n -9 -c dists/beta/main/binary-amd64/Packages > dists/beta/main/binary-amd64/Packages.gz
apt-ftparchive \
    -o APT::FTPArchive::Release::Origin=Cut-it \
    -o APT::FTPArchive::Release::Label=Cut-it \
    -o APT::FTPArchive::Release::Suite=beta \
    -o APT::FTPArchive::Release::Codename=beta \
    -o APT::FTPArchive::Release::Architectures=amd64 \
    -o APT::FTPArchive::Release::Components=main \
    release dists/beta > dists/beta/Release
gpg --batch --yes --local-user "$fingerprint" --digest-algo SHA256 \
    --clearsign --output dists/beta/InRelease dists/beta/Release
gpg --batch --yes --local-user "$fingerprint" --digest-algo SHA256 \
    --armor --detach-sign --output dists/beta/Release.gpg dists/beta/Release
gpgv --keyring "$output/cut-it-archive-keyring.gpg" dists/beta/InRelease
cat > index.html <<EOF
<!doctype html><html lang="en"><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Cut-it Linux beta repository</title>
<style>body{font:17px system-ui;max-width:850px;margin:4rem auto;padding:0 1rem;line-height:1.6}pre{padding:1rem;background:#eee;overflow:auto}</style>
<h1>Cut-it Linux beta</h1>
<p>For x86-64 Ubuntu 24.04 and Linux Mint 22. Add this signed repository once:</p>
<pre>sudo apt install ca-certificates curl
sudo install -d -m 755 /etc/apt/keyrings
curl -fsSL https://munleg.github.io/cut-it/cut-it-archive-keyring.gpg | sudo tee /etc/apt/keyrings/cut-it.gpg &gt;/dev/null
echo 'deb [arch=amd64 signed-by=/etc/apt/keyrings/cut-it.gpg] https://munleg.github.io/cut-it beta main' | sudo tee /etc/apt/sources.list.d/cut-it.list
sudo apt update
sudo apt install cut-it</pre>
<p>Launch <code>cut-it</code> or use the application menu. Update with your normal package manager.
Remove with <code>sudo apt remove cut-it</code>.</p>
<p>Signing-key fingerprint: <code>$fingerprint</code>.</p>
<p>Linux interactive playback, audio and export acceptance are pending. This is a beta.</p>
<p><a href="https://github.com/munleg/cut-it/blob/linux-beta/docs/LINUX.md">Documentation and source information</a></p>
<h2>Matching sources (GPL)</h2><ul>
EOF
for source in sources/*-sources.tar.xz; do
    printf '<li><a href="%s">%s</a></li>\n' "$source" "${source##*/}" >> index.html
done
printf '</ul><p><a href="SOURCE-COMMIT.txt">Build commit</a></p></html>\n' >> index.html
