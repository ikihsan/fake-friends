class_name FFCafeDay1
extends Node
## Cafe Caffeine Day 1 beats: recognition, seating, coffee, Bobby's fight story,
## the coffee contradiction, invitation to Market.
##
## Owns only cafe staging and dialogue order. NPC nodes, player, GameState and
## presenters are owned by FFDay1Director and passed in. Idempotent via flags.

signal meeting_completed
signal group_departed

const SEAT_POS := Vector3(9.95, -2.9, -13.30)
const SEAT_YAW := -90.0  # faces west toward Table1 (matches T1ChairE yaw 270)
const TABLE_POS := Vector3(9.30, -2.9, -13.30)
const CAFE_INSIDE := Vector3(10.30, -2.9, -12.50)

const Target = preload("res://scripts/gameplay/interaction/interactable.gd")
const Seq = preload("res://scripts/story/story_sequence.gd")

var state: Node
var thoughts: FFThoughtPresenter
var dialogue: FFDialoguePresenter
var player: CharacterBody3D
var neighborhood: Node3D
var sofia: FFNPCActor
var bobby: FFNPCActor

var _seat_target: FFInteractable
var _sat: bool = false
var _saved_pos: Vector3
var _saved_yaw: float = 0.0
var _saved_cam_y: float = 1.65
var _saved_cam_pitch: float = 0.0
var _running: bool = false

func configure(p_state: Node, p_thoughts: FFThoughtPresenter, p_dialogue: FFDialoguePresenter, p_player: CharacterBody3D, p_neighborhood: Node3D, p_sofia: FFNPCActor, p_bobby: FFNPCActor) -> void:
	state = p_state
	thoughts = p_thoughts
	dialogue = p_dialogue
	player = p_player
	neighborhood = p_neighborhood
	sofia = p_sofia
	bobby = p_bobby

func start() -> void:
	if _running:
		return
	_running = true
	if state.call("flag", "cafe_meeting_completed"):
		_cleanup_seat()
		return
	_place_pair()
	_make_seat()
	_run_recognition()

func _place_pair() -> void:
	# Sofia north of Table1, Bobby west — both already seated, calm and ordinary.
	sofia.global_position = Vector3(9.30, -2.9, -14.00)
	sofia.rotation.y = deg_to_rad(0.0)
	sofia.set_seated(true)
	sofia.look_at_target(TABLE_POS)
	bobby.global_position = Vector3(8.65, -2.9, -13.30)
	bobby.rotation.y = deg_to_rad(90.0)
	bobby.set_seated(true)
	bobby.look_at_target(TABLE_POS)
	sofia.visible = true
	bobby.visible = true

func _make_seat() -> void:
	if is_instance_valid(_seat_target):
		return
	_seat_target = Target.new()
	_seat_target.name = "Interact_cafe_seat"
	_seat_target.action_id = "cafe_sit"
	_seat_target.prompt = "Sit with Sofia and Bobby"
	neighborhood.add_child(_seat_target)
	_seat_target.position = Vector3(9.55, -2.05, -13.30)
	_seat_target.configure(Vector3(1.2, 1.0, 1.2))
	_seat_target.activated.connect(_on_sit)

func _cleanup_seat() -> void:
	if is_instance_valid(_seat_target):
		_seat_target.queue_free()
	_seat_target = null

func _run_recognition() -> void:
	# First recognition when Chris gets close to the table OR enters the cafe room.
	# Fire once; resume path skips it if already started.
	if state.call("flag", "cafe_meeting_started"):
		return
	await Seq.wait_proximity(player, TABLE_POS, 4.2, 0.0)
	if state.call("flag", "cafe_meeting_completed"):
		return
	state.call("set_flag", "cafe_meeting_started", true)
	thoughts.say("Sofia.", 2.0)
	await get_tree().create_timer(2.1).timeout
	thoughts.say("Bobby.", 2.0)

func _on_sit(_hit: FFInteractable) -> void:
	if _sat or state.call("flag", "cafe_meeting_completed"):
		return
	if is_instance_valid(player) and player.global_position.distance_to(TABLE_POS) > 4.5:
		return
	_sat = true
	_seat_target.enabled = false
	_sit_player()
	_run_scene()

func _sit_player() -> void:
	_saved_pos = player.global_position
	_saved_yaw = player.rotation.y
	if is_instance_valid(player.camera):
		_saved_cam_y = player.camera.position.y
		_saved_cam_pitch = player.camera.rotation.x
	player.global_position = SEAT_POS
	player.rotation.y = deg_to_rad(SEAT_YAW)
	if is_instance_valid(player.camera):
		player.camera.position = Vector3(0, 1.20, 0)
		# face the table (west): keep current pitch, yaw handled by body
	player.velocity = Vector3.ZERO
	if "movement_enabled" in player:
		player.movement_enabled = false

func _stand_player() -> void:
	if "movement_enabled" in player:
		player.movement_enabled = true
	if is_instance_valid(player.camera):
		player.camera.position = Vector3(0, 1.65, 0)
	# step slightly south of the chair so Chris is not inside the table collider
	player.global_position = Vector3(10.15, -2.9, -12.55)
	player.velocity = Vector3.ZERO
	# face the door/NPCs so the departure reads immediately
	var d: Vector3 = CAFE_INSIDE - player.global_position
	d.y = 0.0
	if d.length_squared() > 0.0001:
		player.rotation.y = atan2(-d.x, -d.z)
	_sat = false

func _run_scene() -> void:
	# Deterministic beat order; each step waits for the previous line to finish
	# so reloads can't interleave two runs (guarded by cafe_meeting_completed).
	if state.call("flag", "cafe_meeting_completed"):
		return
	# greet
	dialogue.say("Sofia", "Chris. You made it.", 2.6)
	dialogue.say("Bobby", "Look who remembered the place.", 2.6)
	await Seq.wait_dialogue_idle(dialogue, 12.0)
	# order — Chris answers automatically, no menu (canon: coffee)
	dialogue.say("Sofia", "What do you want?", 2.4)
	await Seq.wait_dialogue_idle(dialogue, 8.0)
	dialogue.say("Chris", "Coffee.", 1.8)
	await Seq.wait_dialogue_idle(dialogue, 6.0)
	state.call("set_flag", "cafe_coffee_ordered", true)
	dialogue.say("Bobby", "Three coffees.", 2.0)
	await Seq.wait_dialogue_idle(dialogue, 6.0)
	_spawn_coffees()
	await get_tree().create_timer(2.2).timeout
	# Bobby's Market fight story — exaggerated, unclear how much happened.
	dialogue.say("Bobby", "So around the Market, this guy starts trouble.", 3.2)
	dialogue.say("Bobby", "I mean, I destroyed him.", 2.6)
	dialogue.say("Bobby", "Nearly beat him to death, honestly.", 3.0)
	await Seq.wait_dialogue_idle(dialogue, 14.0)
	dialogue.say("Sofia", "Mm.", 1.6)
	await Seq.wait_dialogue_idle(dialogue, 5.0)
	# The coffee contradiction — the psychological beat. Ambiguity preserved.
	dialogue.say("Bobby", "Coffee?", 1.8)
	await Seq.wait_dialogue_idle(dialogue, 5.0)
	dialogue.say("Bobby", "Since when do you order coffee?", 2.8)
	await Seq.wait_dialogue_idle(dialogue, 6.0)
	thoughts.say("I drink coffee.", 2.4)
	await get_tree().create_timer(2.5).timeout
	thoughts.say("Don't I?", 2.2)
	await get_tree().create_timer(2.3).timeout
	dialogue.say("Sofia", "It's just coffee, Bobby.", 2.4)
	await Seq.wait_dialogue_idle(dialogue, 6.0)
	state.call("set_flag", "cafe_story_done", true)
	# Invitation to Market — canon path, no branching.
	dialogue.say("Sofia", "We're heading to the Market. Maxwell's around there.", 3.4)
	await Seq.wait_dialogue_idle(dialogue, 7.0)
	dialogue.say("Bobby", "You coming?", 2.0)
	await Seq.wait_dialogue_idle(dialogue, 6.0)
	dialogue.say("Chris", "Sure.", 1.8)
	await Seq.wait_dialogue_idle(dialogue, 6.0)
	state.call("set_flag", "cafe_meeting_completed", true)
	_cleanup_seat()
	_stand_player()
	# unseat the pair so the walk reads as standing up together
	sofia.set_seated(false)
	bobby.set_seated(false)
	dialogue.say("Bobby", "Come on then.", 2.0)
	await Seq.wait_dialogue_idle(dialogue, 5.0)
	meeting_completed.emit()
	_depart_pair()

func _depart_pair() -> void:
	if state.call("flag", "market_group_departed"):
		return
	state.call("set_flag", "market_group_departed", true)
	# Stand, face the door, then walk the authored route. Director listens for
	# group_departed to hand the pair to the Market beat.
	sofia.look_at_target(CAFE_INSIDE)
	bobby.look_at_target(CAFE_INSIDE)
	await get_tree().create_timer(0.6).timeout
	group_departed.emit()

func _spawn_coffees() -> void:
	# Three small cups on Table1 — implied service, no barista AI.
	var cafe: Node3D = neighborhood.get_node_or_null("CafeCaffeine") as Node3D
	if cafe == null:
		return
	if cafe.get_node_or_null("StoryCups") != null:
		return
	var cups := Node3D.new()
	cups.name = "StoryCups"
	cafe.add_child(cups)
	var spots: Array[Vector3] = [
		Vector3(9.15, -2.9 + 0.78, -13.15),
		Vector3(9.45, -2.9 + 0.78, -13.45),
		Vector3(9.30, -2.9 + 0.78, -13.30),
	]
	for i: int in spots.size():
		var cup := MeshInstance3D.new()
		cup.name = "Cup%d" % i
		var cm := CylinderMesh.new()
		cm.top_radius = 0.045
		cm.bottom_radius = 0.035
		cm.height = 0.10
		cup.mesh = cm
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.92, 0.89, 0.82)
		m.roughness = 0.6
		cup.material_override = m
		cup.position = spots[i]
		cups.add_child(cup)
