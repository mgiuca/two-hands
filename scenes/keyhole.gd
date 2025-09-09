class_name Keyhole
extends Activator

@onready var key_lock_marker : Marker3D = $KeyLockMarker

@onready var snd_insert : AudioStreamPlayer3D = $SndInsert
@onready var snd_remove : AudioStreamPlayer3D = $SndRemove
@onready var snd_click : AudioStreamPlayer3D = $SndClick
@onready var snd_unclick : AudioStreamPlayer3D = $SndUnclick
@onready var snd_small : AudioStreamPlayer3D = $SndSmall

var key_lock_global_position : Vector3:
  get():
    return key_lock_marker.global_position

var prev_angle_played_sound : float = 0.0

## The angle of the key in the lock, from -TAU/4 to TAU/4.
##
## Setting this changes the activation state of the keyhole.
var key_angle : float:
  set(value):
    key_angle = value

    # Set keyhole activate iff the key is turned far enough.
    active = absf(key_angle) >= TAU/4 - 0.01

    # Play key turning sounds.
    if not active and absf(key_angle - prev_angle_played_sound) > deg_to_rad(15) \
      and not snd_small.playing:
      snd_small.play()
      prev_angle_played_sound = key_angle

func _on_collision_area_body_entered(body: Node3D) -> void:
  if body is Key:
    var key := body as Key
    # TODO: Don't allow a second key if there's already one.
    key.lock_to_keyhole = self
    snd_insert.play()

func _on_collision_area_body_exited(body: Node3D) -> void:
  if body is Key:
    var key := body as Key
    if key.lock_to_keyhole == self:
      key.lock_to_keyhole = null
      active = false
      snd_remove.play()

func _on_activate() -> void:
  snd_click.play()

func _on_deactivate() -> void:
  snd_unclick.play()
