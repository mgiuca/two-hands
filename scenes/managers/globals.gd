extends Node

## Singleton for the Main scene which is responsible for embedding other scenes.
var main : Main

var inited : bool = false

## Initialize settings. Only works once (so changing levels doesn't
## override your settings).
func init_settings(start_music_volume: float, start_fx_volume: float) -> void:
  if inited:
    return
  AudioManager.music_volume = start_music_volume
  AudioManager.fx_volume = start_fx_volume
  inited = true
