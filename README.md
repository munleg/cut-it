# Cut-it 0.1.1

A free, open-source desktop video editor built on [Shotcut](https://github.com/mltframework/shotcut), with a simpler editing workspace. Windows is the current development focus.

## Make the edit, without the clutter

- A monochrome workspace with the preview and timeline kept visible.
- One-click text layers, font selection, quick styles, and optional Google Fonts downloads.
- A searchable effects gallery with thumbnail cards.
- Guided color adjustments for brightness, contrast, saturation, and white balance.
- Ctrl+B to split. Backspace/Delete to delete and close the gap. Shift+Backspace to keep the gap.
- Customizable keyboard shortcuts and existing Shotcut editing, export, and Undo support.

## Development status

This is an early development release, not a stability guarantee. The Windows build and seven native regression tests pass. Earlier desktop checks cover text creation and style changes, the color entry panel, and effects-gallery loading. Broad hardware testing, live silence-deletion/Undo validation, full workflow regression coverage, and a unified color-grading panel remain in progress.

## Support Cut-it

[Support Cut-it on Patreon](https://www.patreon.com/Cut_it) to help fund continued development, improvements, and bug fixes.

Cut-it remains free and open source. Supporting the project is optional; editing features do not require a membership. Visit Patreon for the current supporter tiers and benefits.

You can also find the support link on the app's welcome screen and under **Help → Support Cut-it on Patreon**.

## Build on Windows

See [Build-CutIt.ps1](Build-CutIt.ps1), [upstream build documentation](README-SHOTCUT.md), and [the development notes](CUT-IT.md). The current local build uses MSYS2 MinGW64, Qt 6, MLT, FFmpeg, CMake and Ninja. The script stages a development build; it does not produce a complete standalone installer by itself.

Keep build outputs and personal media outside this repository. The NSIS packaging definition is [packaging/Cut-it.nsi](packaging/Cut-it.nsi).

## Downloads

Get the Windows installer from [Cut-it 0.1.1 releases](https://github.com/munleg/cut-it/releases/tag/v0.1.1). The installer is unsigned. Save your work and close Cut-it before updating.

[Application and dependency source downloads](docs/releases/0.1.1-sources.md) accompany the binary release. These include exact MSYS2 package versions and source-archive links; you do not need to download them to run the editor.

## Contributing

Report the steps to reproduce, Windows version, media format, and expected behavior. Avoid attaching private footage or credentials. Small, focused improvements and reproducible performance measurements are welcome.

## License and attribution

Cut-it is an independent modification of Shotcut and is not affiliated with or endorsed by Meltytech. Shotcut was created by Dan Dennedy, with Brian Matherly and other contributors. Video processing remains powered by MLT and FFmpeg; the interface uses Qt.

Source code is licensed under the GNU General Public License, version 3 or later, except where individual files specify otherwise. See [COPYING](COPYING), original file notices, [upstream documentation](README-SHOTCUT.md), and the bundled font licenses. Original copyright and attribution notices are retained.

