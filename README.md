# Cut-it 0.1 Beta

A free, open-source desktop video editor built on [Shotcut](https://github.com/mltframework/shotcut), with a simpler editing workspace. Windows is the current development focus.

## Make the edit, without the clutter

- A monochrome workspace with the preview and timeline kept visible.
- One-click text layers, font selection, quick styles, and optional Google Fonts downloads.
- A searchable effects gallery with thumbnail cards.
- Guided color adjustments for brightness, contrast, saturation, and white balance.
- Ctrl+B to split. Backspace/Delete to delete and close the gap. Shift+Backspace to keep the gap.
- Customizable keyboard shortcuts and existing Shotcut editing, export, and Undo support.

## Beta status

This is an early beta, not a stability guarantee. The Windows build and five native regression tests pass. Desktop checks cover text creation and style changes, the color entry panel, and effects-gallery loading. Broad hardware testing, full workflow regression coverage, and a unified color-grading panel remain in progress.

## Build on Windows

See [Build-CutIt.ps1](Build-CutIt.ps1), [upstream build documentation](README-SHOTCUT.md), and [the development notes](CUT-IT.md). The current local build uses MSYS2 MinGW64, Qt 6, MLT, FFmpeg, CMake and Ninja. The script stages a development build; it does not produce a complete standalone installer by itself.

Keep build outputs and personal media outside this repository. The NSIS packaging definition is [packaging/Cut-it.nsi](packaging/Cut-it.nsi).

## Downloads

Public Windows binaries are not published yet. Before distributing the bundled installer, the release must include corresponding source and build information for its GPL/LGPL dependencies as well as Cut-it itself. Do not substitute an upstream source link for the modified release source.

## Contributing

Report the steps to reproduce, Windows version, media format, and expected behavior. Avoid attaching private footage or credentials. Small, focused improvements and reproducible performance measurements are welcome.

## License and attribution

Cut-it is an independent modification of Shotcut and is not affiliated with or endorsed by Meltytech. Shotcut was created by Dan Dennedy, with Brian Matherly and other contributors. Video processing remains powered by MLT and FFmpeg; the interface uses Qt.

Source code is licensed under the GNU General Public License, version 3 or later, except where individual files specify otherwise. See [COPYING](COPYING), original file notices, [upstream documentation](README-SHOTCUT.md), and the bundled font licenses. Original copyright and attribution notices are retained.
