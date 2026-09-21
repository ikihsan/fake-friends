class_name FFDay2Director
extends Node
## Day 2 morning owner. The apartment systems (wake, ritual, handbook, wardrobe)
## are reused untouched; day-specific behavior comes from GameState data.
## This layer adds only the Day 2 apartment-exit endpoint. Discovery beats and
## the permanent-write UI live in later passes of this same file/layer.

const Target = preload("res://scripts/gameplay/interaction/interactable.gd")
const EXIT_POS := Vector3(3.80, 1.16, 0.30)

var state: Node
var morning = null  # FFApartmentMorning, untyped to avoid cyclic class load
var thoughts: FFThoughtPresenter
var player: CharacterBody3D
var _exit_target: FFInteractable

func initialize(p_morning) -> void:
	morning = p_morning
	state = morning.state
	thoughts = morning.thoughts
	player = morning.player
	_make_exit()
	print("Day2Director ready — exit endpoint placed.")

func _make_exit() -> void:
	if is_instance_valid(_exit_target):
		return
	if morning == null or morning.apartment == null:
		return
	_exit_target = Target.new()
	_exit_target.name = "Interact_leave_day2"
	_exit_target.action_id = "leave_day2"
	_exit_target.prompt = "Leave for Maxwell's"
	morning.apartment.add_child(_exit_target)
	_exit_target.position = EXIT_POS
	_exit_target.configure(Vector3(1.0, 1.8, 1.0))
	_exit_target.activated.connect(_on_exit)

func _on_exit(_hit: FFInteractable) -> void:
	if morning.wake.transitioning or morning.handbook.is_open:
		return
	state.call("set_flag", "day2_ready_for_party", true)
	morning.endpoint.set_message(
		"DAY 2 — READY FOR MAXWELL'S HOUSE",
		"Handbook, outfit, one write. Maxwell's house is next.",
		"Stay in apartment")
	morning.endpoint.open()
