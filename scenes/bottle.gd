class_name Bottle
extends AnimatableBody3D

## Controller this bottle is bound to. Can't be null.
var xr_controller : XRController3D

## Baby this is currently inside of (position and semi-rotation-locked),
## or null in the usual state of floating.
var lock_to_baby : Baby

@onready var visual : Node3D = $Visual

func _physics_process(_delta: float) -> void:
  # Follow the controller around. (This has to be done manually, not via
  # the parenting system, or collision detection won't work properly.)
  # NOTE: This happens even when the bottle is apparently locked in the baby,
  # the physical bottle still moves (that way, we can detect when it leaves the
  # baby!). Only the model gets locked. We transform the model separately,
  # as it has top_level = true.
  global_transform = xr_controller.global_transform

  if lock_to_baby:
    # Snap the bottle's position to the baby.
    visual.global_transform = lock_to_baby.bottle_lock_global_transform
  else:
    visual.global_transform = global_transform
