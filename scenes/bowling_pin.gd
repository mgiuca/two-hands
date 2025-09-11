class_name BowlingPin
extends Activator

@onready var rigid_body : RigidBody3D = $PinBody
@onready var deactivate_timer : Timer = $DeactivateTimer
@onready var reset_timer : Timer = $ResetTimer

## Emitted when the pin is knocked over. Only emitted once, unless [method reset]
## is called.
signal knocked_over

## The position this pin had at ready time.
@onready var original_position : Vector3 = rigid_body.global_position

## Input debug action to knock over the pin.
@export var debug_action : String

## Whether the pin has already been knocked over.
var is_knocked_over : bool

## Reset the pin back to its original position standing up.
##
## Resets the [signal knocked_over] signal so it can be emitted again.
func reset() -> void:
  rigid_body.global_position = original_position
  rigid_body.global_rotation = Vector3.ZERO
  rigid_body.sleeping = true
  is_knocked_over = false

func _unhandled_input(event: InputEvent) -> void:
  if event.is_action_pressed(debug_action):
    # Knock it over, for testing.
    rigid_body.apply_central_impulse(Vector3(20, 0, -20))

func calculate_knocked_over() -> bool:
  var p := rigid_body.global_position
  var r := rigid_body.global_rotation
  # If X/Z euler rotation is large, or it's far away from its start position.
  return absf(r.x) > deg_to_rad(50) or absf(r.z) > deg_to_rad(50) or p.distance_to(original_position) > 0.3

func _process(_delta: float) -> void:
  if not is_knocked_over:
    if calculate_knocked_over():
      is_knocked_over = true
      knocked_over.emit()
      active = true
      # Start both timers. The deactivate timer is quick, resetting the activation
      # state (i.e. the flag). The reset timer is slower, resetting the pin.
      deactivate_timer.start()
      reset_timer.start()

func _on_deactivate_timer_timeout() -> void:
  active = false

func _on_reset_timer_timeout() -> void:
  # Don't reset if the level is completed, so we can bask in the knocked over
  # pins.
  if not LevelManager.current_level.victory:
    reset()
