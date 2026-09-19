class_name FFDoorOpen
extends Node
## One-way opening foundation. Closing is deliberately unavailable until safe swept-door handling exists.
const Target = preload("res://scripts/gameplay/interaction/interactable.gd")
var _pivot: Node3D
var _target: Target
var _open_yaw: float
var _body: StaticBody3D

func initialize(pivot: Node3D, open_yaw: float) -> void:
	_pivot = pivot
	_open_yaw = open_yaw
	_body = pivot.get_node("Body") as StaticBody3D
	_target = Target.new()
	_target.name = "OpenDoor"
	_target.action_id = "open_door"
	_target.prompt = "Open"
	pivot.add_child(_target)
	_target.configure(Vector3(0.88, 1.95, 0.14), Vector3(-0.44, 1.03, 0))
	_target.activated.connect(_open)

func _open(_hit: Target) -> void:
	_target.enabled = false
	_body.collision_layer = 0
	# Retain an open-only, nonblocking leaf to avoid pushing/trapping Chris.
	var tween: Tween = create_tween()
	tween.tween_property(_pivot, "rotation_degrees:y", _open_yaw, 0.55).set_trans(Tween.TRANS_SINE)
