## A RigidBody3D that can have its transform and velocity set abruptly.
class_name TeleportableBody
extends RigidBody3D

var tele_trans : Transform3D
var tele_lin_vel : Vector3
var tele_ang_vel : Vector3
var schedule_trans : bool = false
var schedule_lin_vel : bool = false
var schedule_ang_vel : bool = false

func teleport(trans: Transform3D) -> void:
  tele_trans = trans
  schedule_trans = true

func force_new_linear_velocity(lin_vel: Vector3) -> void:
  tele_lin_vel = lin_vel
  schedule_lin_vel = true

func force_new_angular_velocity(ang_vel: Vector3) -> void:
  tele_ang_vel = ang_vel
  schedule_ang_vel = true

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
  if schedule_trans:
    state.transform = tele_trans
    schedule_trans = false
  if schedule_lin_vel:
    state.linear_velocity = tele_lin_vel
    schedule_lin_vel = false
  if schedule_ang_vel:
    state.angular_velocity = tele_ang_vel
    schedule_ang_vel = false
