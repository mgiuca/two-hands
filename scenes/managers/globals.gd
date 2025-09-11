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

func average_vectors(vectors: PackedVector3Array) -> Vector3:
  var sum := Vector3.ZERO
  if vectors.is_empty():
    return sum
  for v in vectors:
    sum += v
  return sum / float(vectors.size())

## Clamps an angle in some range around 0°. min and max must be in (-PI, PI),
## exclusive.
@warning_ignore("shadowed_global_identifier")
func angle_clamp(angle: float, min: float, max: float) -> float:
  # Normalize angle into the range (-PI, PI].
  angle = fmod(angle, TAU)
  if angle > PI:
    angle -= TAU
  return clampf(angle, min, max)
