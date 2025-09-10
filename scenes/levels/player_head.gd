## This class simply tracks the player's head (XRCamera) from the Main scene.
##
## The node it is attached to should have top_level = true.
class_name PlayerHead
extends Node3D

func _physics_process(_delta: float) -> void:
  if Globals.main == null:
    return

  global_transform = Globals.main.xr_camera.global_transform
