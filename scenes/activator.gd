## Generic class that can be "activated" (such as a Keyhole) to win a level.
class_name Activator
extends Node3D

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

## Emitted when the object activates (e.g. the key turns).
signal activate

## Emitted when the object deactivates (e.g. the key is unturned).
signal deactivate
