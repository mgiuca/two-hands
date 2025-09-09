@tool
class_name Flags
extends Node3D

@onready var flag_one_key : Flag = $FlagOneKey
@onready var flag_two_keys : Flag = $FlagTwoKeys

enum State {
  NONE, ONE, TWO
}

@export var state : State:
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
