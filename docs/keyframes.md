# Preview pose keyframes

Select a video, image or text clip and place the playhead inside it.

1. Click the small diamond below the preview to save its first pose. Cut-it opens or reuses its transform internally.
2. Move the playhead to a later time.
3. Drag the clip in the preview, resize using the handles, or rotate it. You can also use the existing transform controls.
4. Click the diamond to save that pose. Playback interpolates between the poses.

The diamond saves position, size and rotation together (GPU Size & Position supports position and size). Repeated clicks on a saved pose do not delete it. Once animation is enabled, changing the transform at another time also updates that time's keyframe using Shotcut's existing editing behavior.

A filled diamond marks a saved position/size keyframe. The adjacent arrows jump between these keyframes. Right-click the diamond > Keyframes, or use Ctrl+7, for the full editor and deletion/interpolation controls. Existing simple in/out animation is left intact and must be edited in the full editor first.

Undo/Redo uses the existing filter command stack. The preview controls use selection and playhead signals, without timers or background media scans. Available in Cut-it 0.1.2.
