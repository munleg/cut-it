# Cut-it 0.1 Beta — development checkpoint

**Status (2026-10-14): Windows Release build compiled and staged. Native tests and startup smoke checks passed. Interactive editing acceptance and performance measurements remain pending. This is a local development build, not a release installer.**

Cloned https://github.com/mltframework/shotcut.git at commit
`f360166260fa5dbe93003c5756567cb4b132dbdb` on 2026-10-13.
This is a local clone with changes, not a published GitHub fork.

## Architecture

Shotcut is a native C++/Qt application. MainWindow owns dock panels and the player.
The timeline and filter interfaces use QML. TimelineDock routes editing to undo
commands and MultitrackModel; Mlt::Controller owns processing and playback.
MLT and FFmpeg provide media decoding, compositing and export. Cut-it adds controls
to these existing paths, with no second media engine, browser shell, or AI service.

## Implemented in source

- Media label and adjacent Tools menu: Editing, Color Grading, Effects, Text, Audio.
- Editing raises Media; other tools raise the existing filter panel and select its
  category/search. Color uses Shotcut's `#color` category. Select a clip before
  adding filters. These are shortcuts into existing tools, not five new editors.
- Switching tools shows the existing timeline and player without restoring or
  replacing the dock layout or constructing new processing components.
- A hover-revealed `+` at the timeline's upper right offers four layer types.
  It also reveals on keyboard focus. The passive hover handler leaves ruler
  scrubbing available outside the button.
- Video and image layers create named MLT video tracks; audio creates an audio
  track. Drag imported media onto them. Images use standard Shotcut image clips.
- Text opens Shotcut's text generator; accepting creates a video track and text
  clip in one undo group. Cancel creates no track. Existing filter controls edit
  the resulting text. This requires the normal Shotcut text plugins at runtime.
- Windows window title and About identify Cut-it 0.1 Beta; upstream credits stay.
  Settings use a separate organization to avoid overwriting Shotcut preferences.
- GPL COPYING, source notices, upstream README and dependencies are preserved.

## Validation on this machine

| Check | Result |
|---|---|
| Clone and inspect exact upstream | Completed |
| `git diff --check` | Passed |
| EDL export Node smoke check | Passed with a two-second test project |
| Chapter export Node smoke check | Passed with expected chapter marker |
| Windows Release configure/build | Passed using MSYS2 GCC 16.2, Qt 6.11.2, MLT 7.40.0 |
| Native tests | 2/2 passed: GPU information and mix transition order |
| QML syntax / startup | Modified QML parsed; startup log showed filter panel Ready, test clip opened, D3D11 decoder and audio initialized |
| Engine render | Passed: two-second H.264/AAC output at 640x360, verified with ffprobe |
| Import, playback/audio, undo, save/reopen, export | Not tested |
| Memory and performance benchmarks | Not measured |

At the initial checkpoint, no CMake, Ninja, C++ compiler or Qt build tools were found on PATH; common Qt and
MSYS2 installation directories were also absent. This is not proof that no SDK
exists elsewhere. Upstream AGENTS.md directs work to stop when dependency checks
fail, so dependency installation and a partial native setup were not attempted.

## Build prerequisites and next steps

Use one consistent Windows toolchain, following upstream
`.github/workflows/build-windows.yml` and `scripts/`. Install CMake (minimum 3.12),
Ninja, a C++ compiler, pkg-config, Qt >=6.4 (upstream preset expects 6.10.3),
MLT++ >=7.36.0, and FFTW development packages. Supply MLT's FFmpeg, frei0r, SDL2
and Qt text runtime plugins. Do not mix MSVC and MinGW libraries.

The upstream Windows workflow contains the detailed MSYS2 package list and
dependency build procedure. It is upstream-account gated and is not a ready
Cut-it release workflow. Do not use its signing or upload stages for this fork.

After installing compatible dependencies in MSYS2 or your configured developer
shell, configure with the correct Qt and pkg-config paths:

```sh
cmake -S . -B build/cut-it -G Ninja -DCMAKE_BUILD_TYPE=Release -DCLANG_FORMAT=OFF
cmake --build build/cut-it --parallel 2
cmake --install build/cut-it --prefix "$PWD/build/cut-it-portable"
```

Install is necessary to place runtime QML resources. This does not automatically
produce a self-contained Windows bundle: stage compatible Qt/MLT libraries and
plugins using upstream packaging. Internal target/executable name remains
`shotcut`; renaming packaging has not been completed. Set `QSG_RHI_BACKEND=d3d11`
when debugging on Windows as directed by AGENTS.md.

For the existing JavaScript tests, run `npm install --ignore-scripts` separately
in `src/qml/export-edl` and `src/qml/export-chapters`, then run each `test-node.js`.
Those tests do not validate the new UI.

## Runtime acceptance gate

### Performance direction

Use Shotcut/MLT as the foundation and optimize measured bottlenecks. A new
Playback button next to Tools exposes the existing preview-resolution, proxy,
and hardware-decoder actions. These are shared QAction instances, preserving
upstream availability checks, checked state, settings persistence and command
handling. Nothing is enabled automatically. This is easier access to existing
capabilities, not a new engine optimization or a measured speedup.

Lower preview resolution reduces the size of preview frames; it does not promise
lower total process memory or cheaper source decoding. Proxies require generation
time and disk space. Hardware decoding depends on codec, GPU and driver support.
Preview resolution is separate from project/export resolution.

Once the native build works, compare upstream and Cut-it Release builds with the
same preview, proxy and decoder settings. Record startup time, idle and peak
working set, private bytes, seek latency, dropped frames and export time using
the same footage and project. Test repeated open/close and tool switching for
memory growth. Start with one 1080p clip, then 4K footage and a layered project.
Investigate retained decoder frames, thumbnail/waveform work and hidden-panel
updates only after profiling identifies their contribution. Keep output quality
and audio synchronization as acceptance requirements.

The Playback menu compiles; interactive menu verification remains pending. Verify each
entry against its Settings counterpart, including disabled/hidden states; confirm
save/reopen and export retain the intended project resolution.

### End-to-end checks

1. Launch the installed Windows build; check logs for QML errors.
2. Import a real H.264 phone clip with audio, a PNG, and a WAV; play and scrub.
3. Add all four layer types with the hover control; verify Tab/Enter access.
4. Cancel text creation: track count and undo history must remain unchanged.
5. Accept text creation: verify transparency, editable text and correct placement.
6. Undo and redo each layer operation, including text clip and track together.
7. Switch all five tools repeatedly with a selected clip and with no selection.
   Verify category/search, player and timeline visibility, and ongoing playback.
8. Save, close, reopen; verify track names, images, audio, text and filters.
9. Export a short composition and inspect the rendered picture and sound.
10. Measure idle and playback memory, dropped frames and tool-switch responsiveness
    against the same upstream build and footage on this machine.

Still needed: interactive runtime acceptance, visual refinement, complete
Cut-it icons/installer branding, Windows bundle, and performance measurements.
Existing Shotcut docks and icons remain; this is an incremental interface change.

## Attribution and distribution

Cut-it is an independent modification of Shotcut, not endorsed by Meltytech.
Shotcut copyright and GPL license notices remain intact. See COPYING and the
upstream README. Modified source changes are identified above. A local development executable is now staged beside this source tree; it requires the installed MSYS2 libraries. Any future binary distribution must include the
corresponding modified source and required license/third-party notices; the
upstream source URL alone is not the corresponding source for Cut-it.

## Current local build and launch

Open `../cut-it-windows/Launch-Cut-it.cmd`. Keep `C:/msys64` installed: the
launcher uses its Qt and media DLLs. The staged executable is
`../cut-it-windows/runtime/shotcut.exe`; use the launcher to set its environment.
The internal executable name remains Shotcut; the window identifies Cut-it.

Rebuild from PowerShell with `./Build-CutIt.ps1`. This configures a Release build,
uses two parallel jobs by default, runs the native tests, and stages the app.
The fixed internal version avoids a full rebuild merely because the date changed.
The script assumes this source tree remains under this task's outputs folder.

Additional MLT runtime packages installed: libebur128, rnnoise and rtaudio.
libebur128 is required for this package's plus module, including dynamictext.
MLT plugins and data must be staged relative to the executable's parent folder;
environment-only plugin paths did not suffice with this Windows MLT package.
The initial transition test crashed before that layout was corrected; both tests
passed afterward. These were deployment issues, not test assertions removed.

The startup smoke check used synthetic media and a separate settings directory.
Its logs showed no QML errors, but this is not a visual or interactive UI test.
The test process was stopped after log inspection. Full playback/audio perception,
layer creation/undo, tool switching, save/reopen and UI export remain to test.
The optional DeckLink-driver warning does not indicate failure of normal playback.
No performance improvement or memory-use reduction has been established.

## Clean Test 4 (2026-10-14)

Launch `../cut-it-test-four/Launch-Cut-it.cmd`. The title must include
`Clean Test 4`; an older open process keeps its old interface until you save
and switch builds. This is a local test build, still dependent on MSYS2.

- Main toolbar: Import, Save, Undo/Redo, Media, Tools and Export.
- Timeline: labeled Delete (keeps the gap), Split and Snap; zoom and advanced menu.
  Clipboard actions and ripple operations remain available through menus/shortcuts.
- Media: Import media and a menu; display modes are inside Media display.
- Preview: thin seek bar, previous/play/next, volume and View menu.
- Ctrl+B splits at the playhead; Ctrl+Shift+B splits all unlocked tracks.
  S/Shift+S remain legacy aliases. Existing user-customized shortcuts are preserved.
  Space, Ctrl+Z, Ctrl+Shift+Z, Ctrl+C/V and Delete retain their existing actions.
- Split reuses complete source waveform data with Qt implicit sharing, avoiding
  redundant waveform cache loading for both halves. Incomplete data still uses
  the existing background worker. Audio/video editing behavior is unchanged.
- Split command processing time is recorded in the application log. This excludes
  later painting/decoding and is not a total responsiveness benchmark.
- Earlier click/drag threshold and split StartRole fixes are included.

The waveform regression test checks missing/partial caches, full reuse and
independent ownership after replacing the original cache. Native build/test
results and interactive checks are recorded in the task's work directory.
No measured speedup on the user's long recording is claimed.

Clean Test 4 retains Ctrl+Y and also supports Ctrl+Shift+Z for redo on Windows.
Visual inspection confirmed the sparse top bar and thin player seek bar in
Test 3. Fixed widths then replaced truncating label styles for Test 4.
User interaction took over the disposable test window, so automated Ctrl+B/undo
verification was not completed. Recorded split command times on the synthetic
color clip included 7-10 ms; these do not represent real-media seek latency.

## Mono Test 5 (2026-10-14)

Latest build: `../cut-it-mono-five/Launch-Cut-it.cmd`.

- Neutral black/gray/white palette, gray clips and track selection, white playhead.
- Default timeline panel reduced to one fifth of window height; tracks default to
  56 pixels. Both remain resizable. Layout migration is applied once per settings directory.
- Import now adds media through the existing undoable Media library pipeline.
  Opening a single .mlt still opens a project. Media toolbar and empty-state link
  open the import picker; dragging files to Media still uses the existing importer.
- Tools > Customize shortcuts opens the existing editable, persistent shortcut
  dialog. Ctrl+Z remains Undo; Ctrl+Shift+Z/Ctrl+Y remain Redo.
- No splash or Shotcut app/window icon; custom logo is pending. GPL and attribution
  remain intact in source and About.
- Selecting a timeline clip no longer constructs a clip-properties undo snapshot
  or rebuilds the Properties widget while Properties is hidden. Opening Properties
  refreshes selection and captures the before-state before controls can edit it.
  Filter selection still updates normally. This removes unnecessary synchronous
  work; real-media responsiveness still needs validation on the user's recording.

Mono Test 5 validation: Release build and all three native tests passed. The
staged executable matches the tested build. Startup reached a targetable window.
Interactive import/undo and Properties edit/undo checks remain unverified:
computer control repeatedly reported intervening user input. The user's existing
open projects were left untouched. The long-recording selection delay has not
been benchmarked after this change.

## Text Test 6

- Add text button (Ctrl+Alt+T) and timeline + > Text create a transparent text
  layer immediately. Click a Cut-it text layer to reopen its text controls.
- Simple editor: multiline text, installed font picker with editable family name,
  pixel size, bold/italic, color, four styles and top/center/bottom placement.
  Existing preview positioning and advanced text/animation controls are retained.
- Lato, Noto Sans and Bebas Neue are bundled with their individual OFL licenses
  in fonts/. Font binaries came from Google's CSS API; licenses came from the
  official google/fonts repository. Montserrat was replaced with Lato because the
  served file exposed a different legacy family name to Windows/Qt.
- Google Fonts picker initially offers eight families. Downloads use the keyless
  CSS API, not the key-requiring full catalog API. Files and licenses are cached
  under the app settings fonts directory; offline use needs no requests.
- On Windows, cached fonts are registered for the current login session so the
  separate MLT exporter can resolve them too. No registry or system font folder
  changes. Other-platform export parity is not yet validated.
- Fonts stay on this computer, not embedded in project XML. A project opened on
  another computer needs the same fonts installed/cached there.

## Hybrid timeline (October 14)

- Compact monochrome tracks and viewport-limited asynchronous filmstrip thumbnails.
- Details button switches 60/104-pixel tracks and adjusts dock space; preview stays visible.
- Brighter waveform display. Background decoding publishes its first partial result after
  approximately 250 ms of worker time instead of waiting 3 seconds, then updates once per second.
  This is not a guarantee that every part of a long recording is ready in 250 ms. Source
  decoding remains sequential; viewport-priority audio decoding is not implemented.
- Existing waveform disk caching and split cache reuse remain active.
- Native build and all four tests passed for the corrected timeline build. Live Windows
  checks on a 20-second H.264/AAC sample verified filmstrip loading, Details both ways,
  Ctrl+B split at 9.92 seconds, Ctrl+Z undo, Ctrl+Shift+Z redo, and preserved waveforms.
- Split edit logged 15 ms on that sample; this excludes frame decode, thumbnail loading,
  and display latency, and is not a benchmark for long user recordings.
- This is still a local development build requiring the installed C:/msys64 dependencies.

## Details resize repair

The filmstrip now uses a fixed sampling grid, so changing track height does not
request different frames. Loaded images remain visible during asynchronous updates.
The Details command derives its next state from the actual track height, and its
checked state synchronizes after project creation/reset. Expanded docks reserve
enough height before resizing; clip reparenting preserves the height binding.
Validation uses a 25-minute generated H.264/AAC clip, with repeated expand/collapse
checks at a zoom level showing roughly 40 seconds. This checks layout and thumbnail
continuity, not performance of the user's original recording.

## Windows exit repair

Shutdown now cancels waveform tasks before QThreadPool::clear deletes queued
runnables, uses an atomic cancellation flag, and stops new thumbnail requests.
A live close test reached the final exit call after 191 ms of cleanup but left
its window/process alive. The exact blocking DLL was not identified. This is
consistent with the Windows DLL-detach deadlock documented by Microsoft:
https://learn.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-exitprocess

For normal Windows exit only, after the existing save/export confirmations,
settings sync, job cleanup, playback stop and shutdown signal, the process now
terminates itself without DLL-detach callbacks. The existing _Exit path already
skipped C++ destruction. Cancel still returns without starting shutdown. Restart
and reset use their existing paths. In-progress disposable thumbnail cache work
may be abandoned and regenerated next launch.

Final Windows validation: the stress project (eight 25-minute clips) exited with
code 0 after 133 ms of measured cleanup. The previous build remained alive after
its final exit call. A second live check verified the save-changes prompt, Cancel
preserving the open unsaved project, saving, and successful exit afterward.
All four native tests passed. No original user project was closed or modified.

## Playback priority update

Thumbnail decoding now reuses one source decoder per provider rather than opening
one per filmstrip image. Cache misses and waveform frame analysis wait while the
preview is playing, and resume when paused. Shutdown wakes waiting workers before
clearing them. Existing thumbnails/cache hits remain available; one decode already
in progress may finish after playback starts. Preview/export resolution is unchanged.

Validation: native build and five tests pass with normal Windows access, including
background pause/resume and shutdown wakeup checks. The font-registration test is
blocked by the restricted sandbox and passes outside it. A temporary 24-second
1920x1080 30fps sample from the user's recording was divided into twelve independent
clips. The application loaded it without QML errors and logged one thumbnail decoder
open. MLT rendered the twelve-cut fixture successfully. The desktop helper failed
with 'failed to write kernel assets: The system cannot find the path specified'
after retry/reset, so live playback frame-timing and subjective smoothness remain
unverified. Original media/project files were not modified. No claim of a measured
frame-rate improvement is made.

Set CUTIT_PLAYBACK_DIAGNOSTICS=1 when launching a test instance to log displayed
frame count, elapsed time, and maximum display gap at pause/end. This diagnostic is
off in the normal launcher. Decoder startup at individual cut boundaries remains
an independent possible source of stutter on compressed/high-resolution media.
