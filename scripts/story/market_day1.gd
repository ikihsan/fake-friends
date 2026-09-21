class_name FFMarketDay1
extends Node
## Market Day 1 beats: Maxwell greeting, candy, tomorrow's invitation,
## handbook handoff + writing (plan + secret Maria entry) + return.
##
## Owns only Market staging and dialogue order. NPC nodes and presenters come
## from FFDay1Director. All persistent writes go through GameState story APIs
## (idempotent) with stable IDs. Chris never reads the secret entry on Day 1.

signal encounter_finished

const MAXWELL_POS := Vector3(17.50, -2.9, -13.20)
const MARKET_FRONT := Vector3(17.50, -2.9, -12.00)
const HANDBOOK_TEXT_PLAN := "Join Maxwell's home party."
const HANDBOOK_ID_PLAN := "plan.day_2.maxwell_party"
const HANDBOOK_ID_CAFE := "plan.day_2.cafe"
const HANDBOOK_ID_MARIA := "maria.loves_me"
const HANDBOOK_TEXT_MARIA := "Maria loves me."

const Target = preload("res://scripts/gameplay/interaction/interactable.gd")
const Seq = preload("res://scripts/story/story_sequence.gd")

var state: Node
var thoughts: FFThoughtPresenter
var dialogue: FFDialoguePresenter
var player: CharacterBody3D
var neighborhood: Node3D
var maxwell: FFNPCActor
var sofia: FFNPCActor
var bobby: FFNPCActor

var _talk_target: FFInteractable
var _running: bool = false
var _book_prop: Node3D = null
var on_handbook_taken: Callable
var on_handbook_returned: Callable
var on_writing_shown: Callable
var on_writing_hidden: Callable

func configure(p_state: Node, p_thoughts: FFThoughtPresenter, p_dialogue: FFDialoguePresenter, p_player: CharacterBody3D, p_neighborhood: Node3D, p_maxwell: FFNPCActor, p_sofia: FFNPCActor, p_bobby: FFNPCActor) -> void:
	state = p_state
	thoughts = p_thoughts
	dialogue = p_dialogue
	player = p_player
	neighborhood = p_neighborhood
	maxwell = p_maxwell
	sofia = p_sofia
	bobby = p_bobby

func place_maxwell() -> void:
	maxwell.global_position = MAXWELL_POS
	maxwell.rotation.y = deg_to_rad(180.0)
	maxwell.visible = true
	maxwell.look_at_target(MARKET_FRONT)
	_make_talk()

func start_if_ready() -> void:
	if _running:
		return
	if not state.call("flag", "market_group_departed"):
		return
	if state.call("flag", "maxwell_wrote_handbook"):
		_cleanup_talk()
		return
	_running = true
	place_maxwell()
	_run_proximity_greet()

func _make_talk() -> void:
	if is_instance_valid(_talk_target):
		return
	_talk_target = Target.new()
	_talk_target.name = "Interact_maxwell"
	_talk_target.action_id = "talk_maxwell"
	_talk_target.prompt = "Talk to Maxwell"
	neighborhood.add_child(_talk_target)
	_talk_target.position = Vector3(17.50, -2.05, -13.20)
	_talk_target.configure(Vector3(1.6, 1.4, 1.6))
	_talk_target.activated.connect(_on_talk)

func _cleanup_talk() -> void:
	if is_instance_valid(_talk_target):
		_talk_target.queue_free()
	_talk_target = null

func _run_proximity_greet() -> void:
	# Greet when Chris reaches the Market front; talk target covers stragglers.
	await Seq.wait_proximity(player, MARKET_FRONT, 3.5, 0.0)
	if state.call("flag", "maxwell_met"):
		return
	_greet()

func _on_talk(_hit: FFInteractable) -> void:
	if state.call("flag", "maxwell_met"):
		return
	_greet()

func _greet() -> void:
	if state.call("flag", "maxwell_met"):
		return
	state.call("set_flag", "maxwell_met", true)
	if is_instance_valid(_talk_target):
		_talk_target.enabled = false
	maxwell.look_at_target(player.global_position)
	thoughts.say("Maxwell.", 2.0)
	await get_tree().create_timer(2.1).timeout
	dialogue.say("Maxwell", "Sofia. Bobby.", 2.2)
	dialogue.say("Maxwell", "Chris.", 1.8)
	await Seq.wait_dialogue_idle(dialogue, 10.0)
	dialogue.say("Maxwell", "You made it.", 2.0)
	await Seq.wait_dialogue_idle(dialogue, 6.0)
	_run_candy()

func _run_candy() -> void:
	dialogue.say("Maxwell", "Here — candy.", 2.2)
	await Seq.wait_dialogue_idle(dialogue, 6.0)
	state.call("set_flag", "maxwell_candy", true)
	thoughts.say("Thanks.", 1.8)
	await get_tree().create_timer(1.9).timeout
	_run_invitation()

func _run_invitation() -> void:
	dialogue.say("Maxwell", "Come to my house tomorrow. UNO, drinks, hang out.", 3.6)
	await Seq.wait_dialogue_idle(dialogue, 8.0)
	dialogue.say("Maxwell", "Maria should be coming too.", 2.6)
	await Seq.wait_dialogue_idle(dialogue, 7.0)
	state.call("set_flag", "maxwell_invitation_received", true)
	thoughts.say("Tomorrow.", 2.0)
	await get_tree().create_timer(2.1).timeout
	_run_handoff()

func _run_handoff() -> void:
	dialogue.say("Maxwell", "You still... for memory, right? Give me the book. I'll write it down.", 4.2)
	await Seq.wait_dialogue_idle(dialogue, 9.0)
	thoughts.say("Okay.", 1.6)
	await get_tree().create_timer(1.7).timeout
	# --- control transfer: Maxwell visibly has the book ---
	state.call("set_flag", "handbook_with_maxwell", true)
	if on_handbook_taken.is_valid():
		on_handbook_taken.call()
	_spawn_book_prop()
	await get_tree().create_timer(1.2).timeout
	# --- Maxwell writes tomorrow's plan (visible strike + new entry) ---
	if on_writing_shown.is_valid():
		on_writing_shown.call(HANDBOOK_TEXT_PLAN, "", 0)
	dialogue.say("Maxwell", "There. Tomorrow's plan, done.", 2.6)
	await Seq.wait_dialogue_idle(dialogue, 6.0)
	state.call("story_write_entry", HANDBOOK_ID_PLAN, HANDBOOK_TEXT_PLAN)
	state.call("story_strike_entry", HANDBOOK_ID_CAFE, true)
	state.call("set_flag", "day1_cafe_plan_done", true)
	await get_tree().create_timer(1.6).timeout
	# --- secret second entry: player sees the page turn, Chris does not react ---
	if on_writing_shown.is_valid():
		on_writing_shown.call(HANDBOOK_TEXT_PLAN, HANDBOOK_TEXT_MARIA, 1)
	await get_tree().create_timer(2.8).timeout
	state.call("story_write_entry", HANDBOOK_ID_MARIA, HANDBOOK_TEXT_MARIA)
	state.call("set_flag", "maxwell_wrote_handbook", true)
	await get_tree().create_timer(1.4).timeout
	if on_writing_hidden.is_valid():
		on_writing_hidden.call()
	_despawn_book_prop()
	# --- return ---
	state.call("set_flag", "handbook_with_maxwell", false)
	if on_handbook_returned.is_valid():
		on_handbook_returned.call()
	dialogue.say("Chris", "Thanks.", 1.8)
	await Seq.wait_dialogue_idle(dialogue, 6.0)
	_cleanup_talk()
	_wind_down()

func _wind_down() -> void:
	dialogue.say("Bobby", "See you tomorrow then.", 2.4)
	await Seq.wait_dialogue_idle(dialogue, 6.0)
	dialogue.say("Sofia", "Tomorrow.", 2.0)
	await Seq.wait_dialogue_idle(dialogue, 6.0)
	state.call("set_flag", "day1_end_ready", true)
	encounter_finished.emit()

func _spawn_book_prop() -> void:
	if is_instance_valid(_book_prop):
		return
	_book_prop = Node3D.new()
	_book_prop.name = "MaxwellBook"
	neighborhood.add_child(_book_prop)
	# in Maxwell's hands: slightly in front of his chest
	_book_prop.global_position = maxwell.global_position + Vector3(0, 1.15, 0) + -maxwell.global_transform.basis.z * 0.35
	var cover := MeshInstance3D.new()
	cover.name = "Cover"
	var bm := BoxMesh.new()
	bm.size = Vector3(0.24, 0.04, 0.31)
	cover.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.45, 0.22, 0.12)
	m.roughness = 0.85
	cover.material_override = m
	_book_prop.add_child(cover)
	_book_prop.look_at(_book_prop.global_position + -maxwell.global_transform.basis.z, Vector3.UP)

func _despawn_book_prop() -> void:
	if is_instance_valid(_book_prop):
		_book_prop.queue_free()
	_book_prop = null
