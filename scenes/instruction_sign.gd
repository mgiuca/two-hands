@tool
## Signpost that provides an instruction, on a supplied texture. Also acts as
## a static body on the Walls layer for rigid bodies to collide with.
class_name InstructionSign
extends StaticBody3D

@onready var instruction : Sprite3D = $Pole/Backplate/Instruction

## The texture to show on the signpost.
@export var texture : Texture2D:
  set(value):
    texture = value
    if instruction:
      instruction.texture = texture

func _ready() -> void:
  instruction.texture = texture
