class_name Keyhole
extends Node3D

@onready var key_lock_marker : Marker3D = $KeyLockMarker
@onready var flag_one_key : Flag = $FlagOneKey
@onready var flag_two_keys : Flag = $FlagTwoKeys

var key_lock_global_position : Vector3:
  get():
    return key_lock_marker.global_position

## Whether a key is actively turned in the lock (thus, is transmitting an
## activation "signal", two of which win a level).
var active : bool:
  set(value):
    if active == value:
      return
    active = value
    if active:
      activate.emit()
    else:
      deactivate.emit()

## Emitted when the lock activates (e.g. the key turns).
signal activate

## Emitted when the lock deactivates (e.g. the key is unturned).
signal deactivate

enum FlagState {
  NONE, ONE, TWO
}

var flag_state : FlagState:
  set(value):
    flag_state = value
    match value:
      FlagState.NONE:
        flag_one_key.up = false
        flag_two_keys.up = false
      FlagState.ONE:
        flag_one_key.up = true
        flag_two_keys.up = false
      FlagState.TWO:
        flag_one_key.up = false
        flag_two_keys.up = true

func _on_collision_area_body_entered(body: Node3D) -> void:
  if body is Key:
    var key := body as Key
    # TODO: Don't allow a second key if there's already one.
    key.lock_to_keyhole = self

func _on_collision_area_body_exited(body: Node3D) -> void:
  if body is Key:
    var key := body as Key
    if key.lock_to_keyhole == self:
      key.lock_to_keyhole = null
      active = false

func _process(_delta: float) -> void:
  if LevelManager.current_level.victory:
    flag_state = FlagState.TWO
  else:
    flag_state = FlagState.ONE if active else FlagState.NONE
