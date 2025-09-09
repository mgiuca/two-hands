class_name Keyhole
extends Node3D

@onready var key_lock_marker : Marker3D = $KeyLockMarker
@onready var flags : Flags = $Flags

@onready var snd_insert : AudioStreamPlayer3D = $SndInsert
@onready var snd_remove : AudioStreamPlayer3D = $SndRemove
@onready var snd_click : AudioStreamPlayer3D = $SndClick
@onready var snd_unclick : AudioStreamPlayer3D = $SndUnclick
@onready var snd_small : AudioStreamPlayer3D = $SndSmall

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
      snd_click.play()
    else:
      deactivate.emit()
      snd_unclick.play()

## Emitted when the lock activates (e.g. the key turns).
signal activate

## Emitted when the lock deactivates (e.g. the key is unturned).
signal deactivate

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

func _process(_delta: float) -> void:
  if LevelManager.current_level.victory:
    flags.state = Flags.State.TWO
  else:
    flags.state = Flags.State.ONE if active else Flags.State.NONE
