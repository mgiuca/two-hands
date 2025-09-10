## Static body that can be pushed by other objects.
##
## Certain other objects call its hit_by method, which sends a signal.
class_name Pushable
extends StaticBody3D

## Emitted when hit by another certain object.
signal hit(body: PhysicsBody3D)

func hit_by(body: PhysicsBody3D) -> void:
  hit.emit(body)
