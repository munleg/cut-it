# Cut-it Linux beta

Target: x86-64 Linux Mint 22 / Ubuntu 24.04. Linux GUI acceptance is pending.
The AppImage and portable archive contain Cut-it plus its media dependencies.
This is a test build of Cut-it 0.1.2, not a stable Linux release.

## Run in Linux Mint 22

Download and extract the `Cut-it-linux-x86_64-beta` artifact from the successful
**Cut-it Linux runtime beta** (or **Cut-it Linux beta**) GitHub Actions run. Check `SHA256SUMS.txt` with
`sha256sum --ignore-missing -c SHA256SUMS.txt` in the extracted directory.
Corresponding sources are in the separate `Cut-it-linux-corresponding-sources`
artifact; they are not required to run the editor.

For the AppImage, open a terminal in that directory:

```sh
chmod +x Cut-it-*-linux-x86_64.AppImage
./Cut-it-*-linux-x86_64.AppImage
```

If Linux reports a FUSE error, use extraction mode (no system changes required):

```sh
./Cut-it-*-linux-x86_64.AppImage --appimage-extract-and-run
```

Or extract the portable `.tar.xz` archive with Archive Manager, then run `cut-it`
inside its `Cut-it` folder. Keep the whole folder together. No administrator
permissions are needed to run either package.

## VirtualBox

Start with 4 GB RAM and 2 virtual CPUs if your host has sufficient resources.
If the preview is black or graphics initialization fails, launch with:

```sh
CUTIT_SOFTWARE_RENDERING=1 ./Cut-it-*-linux-x86_64.AppImage --appimage-extract-and-run
```

For the portable archive: `CUTIT_SOFTWARE_RENDERING=1 ./Cut-it/cut-it`.
Software rendering will be slower. VM performance does not establish native
Linux performance; hardware decoding and encoding may be unavailable in a VM.

## Acceptance checklist

- Open an MP4, play it, seek, and confirm audio is audible and synchronized.
- Add two clips to the timeline; split, delete, undo, and redo.
- Add a text layer using a bundled font and apply an effect.
- Set position/scale/rotation keyframes and verify interpolation.
- Save a project, close Cut-it, reopen, and verify media and edits.
- Export a short H.264/AAC MP4 and play it outside Cut-it.
- Check Help > About and the update checker; Linux must not offer a Windows-only release.
- Repeat a launch from a folder containing spaces.

Report the failing step, Mint version, VirtualBox version, graphics settings,
and terminal output. Do not include private media.

## Build

On x86-64 Linux with Docker, commit source changes and run:

```sh
bash scripts/build-cutit-linux-runtime.sh
```

Set `APPIMAGETOOL` to the absolute path of an official appimagetool executable
and install `desktop-file-utils` first. The workflow does this automatically.
The standard beta build uses Shotcut's pinned Qt 6.10.3 Ubuntu 22.04 container
and a checksum-verified published media runtime. It compiles the exact Cut-it
commit exported from the local repository, avoiding container Git ownership issues.
It never substitutes an upstream Shotcut binary for Cut-it. Output is in `dist/`.
For a fresh rebuild, set `CUTIT_LINUX_OUTPUT` to a new empty directory.

`SOURCE-COMMIT.txt`, `build-image.json`, dependency `versions` in the portable
folder, corresponding source archives, test logs and SHA256 sums accompany
the build. The workflow only uploads build artifacts; it does not publish a release.
GPL and upstream Shotcut attribution remain in the bundle and source tree.

The build verifies the published Shotcut 26.9.27 runtime and corresponding source
archive against pinned SHA256 hashes, builds an MLT 7.41 SDK from those sources,
then compiles and tests Cut-it with Qt 6.10.3. The media libraries stay unchanged;
the editor binary and its resources are built from the current Cut-it commit.
Both Cut-it and upstream dependency source archives accompany this variant.

Both beta workflows use this build path. After the seven C++ tests, the finished
portable archive and AppImage are launched headlessly from a directory containing
spaces. The portable launcher is also checked with software rendering enabled.
Results accompany the download in `package-tests.log`. These startup checks do
not replace the interactive playback, editing, audio, and export checklist above.

The original full dependency build remains available for development through
`bash scripts/build-cutit-linux.sh`; it is not the standard beta packaging path.
