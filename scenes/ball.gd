class_name Ball
extends Node3D

## The controller velocity is multiplied by this amount when the ball is
## released.
@export_range(0.0, 5.0, 0.1, 'or_greater') var throw_velocity_multiplier : float = 2.0

@onready var reattach_timer : Timer = $ReattachTimer

## Controller this ball is bound to. Can't be null (even when detached).
var xr_controller : XRController3D:
  set(value):
    if xr_controller != null:
      xr_controller.button_pressed.disconnect(_on_controller_button_pressed)
      xr_controller.button_released.disconnect(_on_controller_button_released)

    xr_controller = value

    xr_controller.button_pressed.connect(_on_controller_button_pressed)
    xr_controller.button_released.connect(_on_controller_button_released)

## When throwing the ball, the velocity of the ball is set to the velocity of
## the controller, averaged out over the most recent N records. This provides
## the number of records to average over.
## Bigger numbers make the ball feel more sluggish, smaller numbers might make
## a small movement or tracking error throw the ball way off. Heavier balls
## should probably have a bigger window size.
@export_range(1, 10, 1.0, 'or_greater') var velocity_stabilizer_window_size : int = 3
## Records the last [member velocity_stabilizer_window_size] linear velocities
## from the controller.
var last_n_linear_velocities : PackedVector3Array
## Records the last [member velocity_stabilizer_window_size] angular velocities
## from the controller.
var last_n_angular_velocities : PackedVector3Array

## The average of the last [member velocity_stabilizer_window_size] linear
## velocities from the controller.
var controller_average_linear_velocity : Vector3:
  get():
    return Globals.average_vectors(last_n_linear_velocities)

## The average of the last [member velocity_stabilizer_window_size] angular
## velocities from the controller.
var controller_average_angular_velocity : Vector3:
  get():
    return Globals.average_vectors(last_n_angular_velocities)

var trigger_pressed : bool = false
var grip_pressed : bool = false

@onready var snd_hit_ground : AudioStreamPlayer3D = $SndHitGround
@onready var snd_hit_metal : AudioStreamPlayer3D = get_node_or_null('SndHitMetal')
@onready var snd_hit_moon : AudioStreamPlayer3D = get_node_or_null('SndHitMoon')
@onready var snd_hit_pin : AudioStreamPlayer3D = get_node_or_null('SndHitPin')

## Whether the ball is freely moving as a rigid body (as opposed to attached
## to the [member xr_controller]).
var detached : bool:
  set(value):
    if detached == value:
      return
    detached = value
    if detached:
      # Rigid body is frozen, which means we just set detached to true and we
      # need to transfer the position and velocity from the controller to the
      # body, then let it go by unfreezing.
      visual.reparent(rigid_body, false)
      rigid_body.teleport(xr_controller.global_transform)
      # Transfer linear and angular velocity from the controller to the rigid body.
      # Give the ball a bit of a boost.
      var lin_vel := controller_average_linear_velocity * throw_velocity_multiplier
      rigid_body.force_new_linear_velocity(lin_vel)
      rigid_body.force_new_angular_velocity(controller_average_angular_velocity)
      rigid_body.freeze = false
    else:
      visual.reparent(animatable_body, false)
      rigid_body.freeze = true
      # Hit ground can be a long rolling sound, so stop it.
      snd_hit_ground.stop()

## Z rotation to apply to the visual mesh.
@export_range(-180, 180, 1, 'radians_as_degrees') var z_rotate : float = 0.0:
  set(value):
    z_rotate = value
    if visual != null:
      visual.rotation.z = z_rotate

@onready var animatable_body : AnimatableBody3D = $AnimatableBody
@onready var rigid_body : TeleportableBody = $RigidBody
@onready var visual : Node3D = %Visual

enum SoundType {
  BOWLING,
  BASEBALL,
}

@export var sound_type : SoundType

# This has both an AnimatableBody and a RigidBody. Switches between the two
# depending on the state of Detached. The %Visual node is literally reparented
# depending on which object is needed.

func _ready() -> void:
  visual.rotation.z = z_rotate

func _physics_process(_delta: float) -> void:
  if not xr_controller:
    return

  if not detached:
    animatable_body.global_transform = xr_controller.global_transform

  var pose := xr_controller.get_pose()
  # Only include the high-confidence poses.
  if pose and pose.tracking_confidence == XRPose.TrackingConfidence.XR_TRACKING_CONFIDENCE_HIGH:
    last_n_linear_velocities.append(pose.linear_velocity)
    if last_n_linear_velocities.size() > velocity_stabilizer_window_size:
      last_n_linear_velocities.remove_at(0)
    last_n_angular_velocities.append(pose.angular_velocity)
    if last_n_angular_velocities.size() > velocity_stabilizer_window_size:
      last_n_angular_velocities.remove_at(0)

func _on_controller_button_pressed(button_name: String) -> void:
  if button_name == 'trigger_click':
    trigger_pressed = true
  elif button_name == 'grip_click':
    grip_pressed = true

func _on_controller_button_released(button_name: String) -> void:
  var trigger_or_grip_was_pressed := trigger_pressed or grip_pressed
  if button_name == 'trigger_click':
    trigger_pressed = false
  elif button_name == 'grip_click':
    grip_pressed = false

  if trigger_or_grip_was_pressed and not trigger_pressed and not grip_pressed:
    # Was gripping, now released.
    detached = true
    reattach_timer.start()

func _on_reattach_timer_timeout() -> void:
  detached = false

func _on_rigid_body_body_entered(body: Node) -> void:
  if body is Pushable:
    match (body as Pushable).sound_type:
      Pushable.SoundType.METAL:
        if snd_hit_metal:
          snd_hit_metal.play()
      Pushable.SoundType.MOON:
        if snd_hit_moon:
          snd_hit_moon.play()
    (body as Pushable).hit_by(rigid_body)
  elif body.name == 'PinBody':
    if snd_hit_pin:
      snd_hit_pin.play()
  else:
    if snd_hit_ground:
      snd_hit_ground.play()

func _on_rigid_body_sleeping_state_changed() -> void:
  if rigid_body.sleeping:
    # Hit ground can be a long rolling sound, so stop it.
    snd_hit_ground.stop()
