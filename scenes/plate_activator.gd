class_name PlateActivator
extends Activator

## Duration after which the activator automatically deactivates.
@export_range(0, 5, 0.1, 'or_greater') var activation_timeout : float = 1.0

@onready var deactivate_timer : Timer = $DeactivateTimer

func _on_button_hit(_body: PhysicsBody3D) -> void:
  active = true
  deactivate_timer.wait_time = activation_timeout
  deactivate_timer.start()

func _on_deactivate_timer_timeout() -> void:
  active = false
