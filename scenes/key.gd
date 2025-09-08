class_name Key
extends AnimatableBody3D

## Controller this key is bound to. Can't be null.
var xr_controller : XRController3D

## Keyhole this is currently inside of (position and semi-rotation-locked),
## or null in the usual state of floating.
var lock_to_keyhole : Keyhole

@onready var visual : Node3D = $Visual

func _physics_process(_delta: float) -> void:
  # Follow the controller around. (This has to be done manually, not via
  # the parenting system, or collision detection won't work properly.)
  # NOTE: This happens even when the key is apparently locked in the keyhole,
  # the physical key still moves (that way, we can detect when it leaves the
  # keyhole!). Only the model gets locked. We transform the model separately,
  # as it has top_level = true.
  global_transform = xr_controller.global_transform

  if lock_to_keyhole:
    # Snap the key's position to the keyhole. Only take a single axis of
    # rotation from the controller.
    visual.global_position = lock_to_keyhole.key_lock_global_position
    var aligned_rotation := Vector3.ZERO
    # Only take Z axis rotation from the controllers.
    # TODO: Allow the keyhole to determine the allowed rotation axis and the
    # fixed rotation in the other two axes.
    aligned_rotation.z = Globals.angle_clamp(xr_controller.global_rotation.z, -PI, PI)
    visual.global_rotation = aligned_rotation

    # Set keyhole active if the key is turned far enough.
    if absf(aligned_rotation.z) >= PI - 0.01:
      lock_to_keyhole.active = true
  else:
    visual.global_transform = global_transform
