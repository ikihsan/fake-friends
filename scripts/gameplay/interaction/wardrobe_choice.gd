class_name FFWardrobeChoice
extends Node

const Target = preload("res://scripts/gameplay/interaction/interactable.gd")
signal thought_requested(text: String)
var _state: Node
var _targets: Array[Target] = []
const OUTFITS = ["coat", "shirt", "cardigan", "jacket"]
const LABELS = ["Coat", "Shirt", "Cardigan", "Jacket"]

func initialize(rail: Node3D) -> void:
	_state = get_node("/root/GameState")
	var xs: Array[float] = [-0.40, -0.14, 0.13, 0.40]
	for i: int in 4:
		var target: Target = Target.new()
		target.name = "Choose_" + OUTFITS[i]
		target.action_id = "outfit_" + OUTFITS[i]
		rail.add_child(target)
		# Front of the existing broad rail collider, not behind it.
		target.position = Vector3(xs[i], 1.35, 0.33)
		target.configure(Vector3(0.23, 0.70, 0.075))
		target.activated.connect(_choose.bind(i))
		_targets.append(target)
	_refresh()

func _choose(_target: Target, index: int) -> void:
	_state.call("set_outfit", OUTFITS[index])
	_refresh()
	thought_requested.emit("This one.")

func _refresh() -> void:
	var current: String = _state.call("outfit")
	for i: int in _targets.size():
		_targets[i].prompt = ("Wearing — " if current == OUTFITS[i] else "Wear — ") + LABELS[i]
