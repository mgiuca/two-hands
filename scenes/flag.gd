@tool
class_name Flag
extends Node3D

const ANIM_TIME : float = 0.3

@onready var pivot : Node3D = $Pivot
@onready var sprite : Sprite3D = %Sprite

@export var texture : Texture2D:
  set(value):
    texture = value
    if sprite != null:
      sprite.texture = texture

var tween : Tween

@export var up : bool:
  set(value):
    if up == value:
      return

    up = value
    # TODO: Tween it quickly.
    if tween:
      tween.kill()
    tween = get_tree().create_tween()
    tween.set_ease(Tween.EASE_OUT)
    # Spring up, bounce down.
    tween.set_trans(Tween.TRANS_SPRING if up else Tween.TRANS_BOUNCE)
    tween.tween_property(pivot, 'rotation',
      Vector3(TAU/4 if up else 0.0, 0.0, 0.0), ANIM_TIME)

func _ready() -> void:
  sprite.texture = texture
