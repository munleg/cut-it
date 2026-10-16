# Find silence (development build)

Select one normal-speed audio/video clip, then choose **Find silence** on the timeline (default **Ctrl+Alt+S**). Set the threshold, minimum pause length, and padding; click **Find silence** in the dialog.

Detected ranges are listed in timeline seconds. Click a range to seek; use **Play / pause preview** to listen. Select the ranges to remove, then choose **Delete selected** or press **Ctrl+Enter**. One Undo restores the whole operation. Change shortcuts using the existing shortcut editor under the Timeline group.

Scanning uses FFmpeg in a background process. Close the dialog to cancel. It reads the selected source audio stream, including the clip's trim, but does not apply timeline audio filters. The default threshold is -35 dB, minimum pause 0.5 seconds, and padding 0.08 seconds on each end. Quiet speech can be detected as silence: review before deleting.

This first version edits one selected clip and ripples only its own track. Other tracks and global markers do not move; separately recorded audio or overlays need manual alignment afterward. Video and embedded audio in the selected clip are cut together. Speed changes, generators, transitions, and clips adjacent to transitions are not supported. Whole-timeline scanning and colored timeline overlays are not implemented yet.

The UI scaffold was delegated to OpenCode using DeepSeek V4.1 Flash Free, then reviewed and integrated. Detection, frame-boundary conversion, timeline command integration, and tests were implemented locally.

Validation: six native regression tests passed, including silence parsing, inward rounding, padding, trailing silence, invalid logs, and fractional frame rates. A generated five-second audio fixture with two silent sections was scanned from a trimmed starting point using the packaged FFmpeg; both expected ranges were detected. Interactive deletion/Undo on a real project remains a manual validation step.
