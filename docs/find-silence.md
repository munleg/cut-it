# Silence Removal (development build)

Select one normal-speed audio/video clip, then choose **Silence Removal** on the timeline (default **Ctrl+Alt+V**). Set the threshold, minimum pause length, and **Keep gap**; click **Find silence** in the dialog. Ctrl+Alt+S remains Backup and Save. An old Silence Removal binding to Ctrl+Alt+S is migrated to Ctrl+Alt+V; other custom bindings are preserved.

Detected ranges are listed in timeline seconds. Click a range to seek; use **Play / pause preview** to listen. Select the ranges to remove, then choose **Delete selected** or press **Ctrl+Enter**. One Undo restores the whole operation. Change shortcuts using the existing shortcut editor under the Timeline group.

Scanning uses FFmpeg in a background process. Close the dialog to cancel. It reads the selected source audio stream, including the clip's trim, but does not apply timeline audio filters. The default threshold is -35 dB, minimum pause 0.5 seconds, and total retained gap 0.2 seconds. Keep gap offers 0.1-second steps and typed values; half is preserved at each edge. Cuts round inward to video frames, so the retained gap may be slightly longer (for example 0.1 seconds becomes four frames at 30 fps). Changing the gap reuses the scan without decoding audio again. Quiet speech can be detected as silence: review before deleting.

This first version edits one selected clip and ripples only its own track. Other tracks and global markers do not move; separately recorded audio or overlays need manual alignment afterward. Video and embedded audio in the selected clip are cut together. Speed changes, generators, transitions, and clips adjacent to transitions are not supported. Whole-timeline scanning and colored timeline overlays are not implemented yet.

The UI scaffold was delegated to OpenCode using DeepSeek V4.1 Flash Free, then reviewed and integrated. Detection, frame-boundary conversion, timeline command integration, and tests were implemented locally.

Validation: seven native regression tests passed, including silence parsing, inward rounding, total retained gaps of 0.1/0.2 seconds, trailing silence, invalid logs, and fractional frame rates. A generated five-second audio fixture with two silent sections was scanned from a trimmed starting point using the packaged FFmpeg; both expected ranges were detected. Interactive deletion/Undo on a real project remains a manual validation step.
