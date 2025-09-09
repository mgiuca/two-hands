## Generic class that can be "activated" (such as a Keyhole) to win a level.
class_name Activator
extends Node3D

## The flags instance associated with this Activator. Can be a local object
## in the Activator's scene, or some other object. Can be (but shouldn't be)
## null. The Activator automatically keeps the flag state up to date.
@export var flags : Flags

## Whether the object is active (e.g. a key is actively turned in the lock).
## If two activators are active simultaneously, the level is won.
var active : bool:
  set(value):
    if active == value:
      return
    active = value
    if active:
      activate.emit()
    else:
      deactivate.emit()

    if flags != null:
      flags.one_active = active

## Emitted when the object activates (e.g. the key turns).
signal activate

## Emitted when the object deactivates (e.g. the key is unturned).
signal deactivate
