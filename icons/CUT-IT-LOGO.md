# Temporary Cut-it logo

`cut-it.png` is the first logo image supplied by the project owner on 2026-10-16 (`Cut-it (1).png`). It is retained unchanged. `packaging/windows/cut-it.ico` contains resized Windows icon representations of that image. Replace these two assets when the final logo is ready.

The application icon is embedded through `icons/resources.qrc` and the Windows executable resource. The launcher uses `packaging/launcher.rc`; compile this resource with windres and link it with launcher.cpp. NSIS uses the same icon for setup and uninstall.
