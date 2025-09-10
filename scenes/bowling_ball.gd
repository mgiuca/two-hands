extends Node3D

## Controller this ball is bound to. Can't be null (even when detached).
var xr_controller : XRController3D

## Whether the ball is freely moving as a rigid body (as opposed to attached
## to the [member xr_controller]).
var detached : bool

## Z rotation to apply to the visual mesh.
@export_range(-180, 180, 1, 'radians_as_degrees') var z_rotate : float = 0.0:
  set(value):
    z_rotate = value
    if visual != null:
      visual.rotation.z = z_rotate

@onready var animatable_body : AnimatableBody3D = $AnimatableBody
@onready var visual : Node3D = %Visual

# This has both an AnimatableBody and a RigidBody. Switches between the two
# depending on the state of Detached. The %Visual node is literally reparented
# depending on which object is needed.

func _ready() -> void:
  visual.rotation.z = z_rotate

func _physics_process(_delta: float) -> void:
  if detached:
    pass
  else:
    animatable_body.global_transform = xr_controller.global_transform
