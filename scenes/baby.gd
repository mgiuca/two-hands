class_name Baby
extends Activator

@onready var bottle_lock_marker : Marker3D = $BottleLockMarker

@onready var snd_insert : AudioStreamPlayer3D = $SndInsert
@onready var snd_remove : AudioStreamPlayer3D = $SndRemove

@export var crying_sound : AudioStream:
  set(value):
    crying_sound = value
    if snd_crying:
      snd_crying.stream = value

@onready var snd_crying : AudioStreamPlayer3D = $SndCrying

var bottle_lock_global_transform : Transform3D:
  get():
    return bottle_lock_marker.global_transform

## The bottle currently in the mouth, or null.
var inserted_bottle : Bottle = null

## The angle of the bottle in the lock, from -TAU/4 to TAU/4.
##
## Setting this changes the activation state of the bottlehole.
var bottle_angle : float:
  set(value):
    bottle_angle = value

    # Set bottlehole activate iff the bottle is turned far enough.
    active = absf(bottle_angle) >= TAU/4 - 0.01

func _ready() -> void:
  snd_crying.stream = crying_sound
  snd_crying.play()

func _on_collision_area_body_entered(body: Node3D) -> void:
  if body is Bottle and inserted_bottle == null:
    inserted_bottle = body as Bottle
    inserted_bottle.lock_to_baby = self
    active = true
    snd_insert.play()

func _on_collision_area_body_exited(body: Node3D) -> void:
  if body is Bottle and inserted_bottle == body:
    (body as Bottle).lock_to_baby = null
    inserted_bottle = null
    active = false
    snd_remove.play()

func _on_snd_crying_finished() -> void:
  # Just keep crying.
  snd_crying.play()

func _on_activate() -> void:
  snd_crying.stop()

func _on_deactivate() -> void:
  snd_crying.play()
