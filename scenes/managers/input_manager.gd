# Singleton manager concerned with detecting which input device is active and
# notifying of input device changes.

extends Node

enum InputMode { KEYBOARD, JOYSTICK }

signal input_mode_changed(new_mode: InputMode)

# Which device we last received input from.
# Used for various things like whether to show the cursor, tutorial prompts.
var input_mode : InputMode:
  set(value):
    if input_mode != value:
      input_mode = value
      input_mode_changed.emit(value)

## Sets whether the mouse cursor should be visible when in keyboard mode.
## Note: The mouse will always be hidden in joystick mode regardless of this
## setting.
var mouse_visible : bool = true:
  set(value):
    mouse_visible = value
    set_mouse_mode()

func _ready() -> void:
  input_mode = InputMode.KEYBOARD if Input.get_connected_joypads().is_empty() \
               else InputMode.JOYSTICK
  process_mode = Node.PROCESS_MODE_ALWAYS  # So _input works when paused.
  set_mouse_mode()

func _input(event : InputEvent) -> void:
  # Just used to detect input mode changes (not actually handle input).
  if event is InputEventKey:
    input_mode = InputMode.KEYBOARD
  elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
    input_mode = InputMode.JOYSTICK
  elif event is InputEventMouse and mouse_visible:
    # Logic is a bit tricky: if mouse_visible it means it would be hidden in
    # joystick mode, so moving the mouse should switch to keyboard mode so you
    # can see the mouse. If not mouse_visible, the mouse isn't relevant so this
    # should not change things.
    input_mode = InputMode.KEYBOARD
  set_mouse_mode()

func set_mouse_mode() -> void:
  # TODO: Assumes the game will use a mouse only for menus. If the game will
  # always have a mouse cursor, remove the mouse_visible concept and delete the
  # else branches here.
  if mouse_visible and input_mode == InputMode.KEYBOARD:
    DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE)
  else:
    DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_HIDDEN)
