class_name Level
extends Node

@onready var hud : HUD = $UI/HUD

@export_group('Debug')

## If true, UI shows lots of extra debugging info.
@export var debug_info : bool

## Bypass the menu and immediately exit.
@export var esc_immediately_quits : bool = false

## Introduces an artificial random lag each (actual) frame to simulate a
## low-performance device.
@export var artificial_lag : bool

@onready var keyhole_left : Keyhole = $PedestalLeft/Keyhole
@onready var keyhole_right : Keyhole = $PedestalRight/Keyhole

@onready var key_left : Key = $KeyLeft
@onready var key_right : Key = $KeyRight

## Both locks have been activated at the same time. Once true, never set to
## false (even if locks become inactive).
var victory : bool

func _ready() -> void:
  if Main.ensure_main_and_load_file(self):
    return

  LevelManager.current_level = self

  hud.debug_visible = debug_info

  key_left.xr_controller = Globals.main.left_hand
  key_right.xr_controller = Globals.main.right_hand

func _unhandled_input(event: InputEvent) -> void:
  # Meta/UI inputs.
  if event.is_action_pressed('menu'):
    if esc_immediately_quits:
      get_tree().quit()
    else:
      (%Menu as Menu).show_menu()
  elif event.is_action_pressed('debug_prev_level'):
    LevelManager.switch_to_prev_level()
  elif event.is_action_pressed('debug_next_level'):
    LevelManager.switch_to_next_level()

func _process(delta: float) -> void:
  # Delta in real-world seconds.
  # TODO: Only relevant if this game changes Engine.time_scale.
  # If not, just use delta.
  var delta_real_s := delta / Engine.time_scale
  hud.set_framerate(1.0 / delta_real_s)

  if artificial_lag:
    # Artificial delay for testing.
    var x : float
    for i in randi_range(1000000, 4000000):
      x = sin(x)

func complete_level() -> void:
  victory = true

func _on_keyhole_activate(_keyhole_id: int) -> void:
  if keyhole_left.active and keyhole_right.active:
    complete_level()

func _on_keyhole_deactivate(_keyhole_id: int) -> void:
  # Actually nothing to do here.
  pass
