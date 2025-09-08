extends Node3D

func _on_collision_area_body_entered(body: Node3D) -> void:
  print('%s entered keyhole' % body)

func _on_collision_area_body_exited(body: Node3D) -> void:
  print('%s exited keyhole' % body)
