class_name Door
extends Node3D

@onready var animation_player : AnimationPlayer = $Mesh/AnimationPlayer
@onready var snd_open : AudioStreamPlayer3D = $SndOpen
@onready var snd_clunk : AudioStreamPlayer3D = $SndClunk

func _ready() -> void:
  animation_player.animation_finished.connect(_on_animation_finished)

## Opens the door.
func open() -> void:
  animation_player.play(&'open', -1, 0.5)
  snd_open.play()

func _on_animation_finished(anim_name: StringName) -> void:
  if anim_name == &'open':
    snd_clunk.play()
