class_name Key
extends AnimatableBody3D

## Controller this key is bound to. Can't be null.
var xr_controller : XRController3D

func _physics_process(_delta: float) -> void:
  # Follow the controller around. (This has to be done manually, not via
  # the parenting system, or collision detection won't work properly.)
  global_transform = xr_controller.global_transform
