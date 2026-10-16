# Cut-it update checks

Cut-it checks `https://api.github.com/repos/munleg/cut-it/releases?per_page=100` five seconds after startup. Checks use HTTPS without GitHub sign-in, have a 15-second transfer timeout, and run asynchronously. Startup network errors are quiet. No project or media files are sent.

Help contains **Check for updates…** and a **Check for updates on startup** toggle. The command-line `--noupgrade` option still suppresses startup checks; the Windows launcher no longer adds that option automatically.

The checker includes Beta releases, ignores drafts, and offers only a newer recognized version with an uploaded Cut-it Windows installer. Version order is numerical: beta.10 is newer than beta.2, and a stable version is newer than its prereleases. Tags use `vMAJOR.MINOR.PATCH` or `vMAJOR.MINOR.PATCH-beta.NUMBER` (alpha and rc also supported). It checks the first 100 release records.

Accepting an update offer opens the matching release page in the browser. Save projects and close Cut-it before running the installer. The app does not silently download, execute, or replace binaries. Existing published Beta 1 installations need a manual update to obtain this checker.

`src/cutitupdate.h` defines the installed Cut-it version separately from Shotcut's engine/application version. This development build is `0.1.0-beta.2`; advance it for each future published build and use the matching GitHub release tag. The About dialog displays this version. Publishing source commits alone does not trigger update offers: publish a release with its Windows installer.

Validation covers version comparison, Beta selection, drafts, missing installers, and foreign download URLs. The live GitHub endpoint was also checked against the published Beta 1 asset metadata. Downloading and installing an update remains a user-driven browser/installer flow.
