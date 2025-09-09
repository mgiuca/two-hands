@tool
## A single-key and victory flag pair. Automatically shows victory if the level
## is in victory mode.
class_name Flags
extends Node3D

@onready var flag_one_key : Flag = $FlagOneKey
@onready var flag_two_keys : Flag = $FlagTwoKeys

enum State {
  NONE, ONE, TWO
}

@export var state : State = State.NONE:
  set(value):
    state = value
    match value:
      State.NONE:
        flag_one_key.up = false
        flag_two_keys.up = false
      State.ONE:
        flag_one_key.up = true
        flag_two_keys.up = false
      State.TWO:
        flag_one_key.up = false
        flag_two_keys.up = true

## Sets whether the local activator connected to this flag is active. Controls
## the state of the yellow "one key" flag. Always overridden by the level being
## completed.
@export var one_active : bool = false:
  set(value):
    one_active = value
    # In editor only, set the state from this. (In game, _process does it.)
    if Engine.is_editor_hint():
      state = State.ONE if value else State.NONE

func _process(_delta: float) -> void:
  if Engine.is_editor_hint():
    return
  if LevelManager.current_level.victory:
    state = Flags.State.TWO
  else:
    state = Flags.State.ONE if one_active else Flags.State.NONE
