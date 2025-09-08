class_name Keyhole
extends Node3D

@onready var key_lock_marker : Marker3D = $KeyLockMarker

var key_lock_global_position : Vector3:
  get():
    return key_lock_marker.global_position

func _on_collision_area_body_entered(body: Node3D) -> void:
  if body is Key:
    var key := body as Key
    key.lock_to_keyhole = self

func _on_collision_area_body_exited(body: Node3D) -> void:
  if body is Key:
    var key := body as Key
    if key.lock_to_keyhole == self:
      key.lock_to_keyhole = null
