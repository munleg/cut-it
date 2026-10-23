# Autosave recovery

Cut-it saves a separate recovery copy every minute when the project has unsaved
changes. In Settings > Autosave Recovery, choose 30 seconds, 1 minute, 2 minutes,
or 5 minutes. The choice persists across restarts. A status message confirms each
successful recovery save or reports a failure.

Use Save (Ctrl+S) to save the actual project. Recovery saves do not clear the
unsaved-changes indicator or replace the project file. After a crash, reopen the
project and accept the recovery prompt. Normal project closure removes the
temporary recovery copy; choosing to discard changes still discards them.

Recovery copies reference source media and do not contain the video files.

Manual acceptance: change an existing project, select 30 seconds, wait for the
confirmation, and confirm the original project file is unchanged. Restart and
check that the selected interval persists. With a disposable project only,
simulate an abnormal exit after the confirmation, reopen the project, and verify
the recovered edit. Also verify normal Save and discard-on-close behavior.
