class_name FFDay1Director
extends Node
## Day 1 story owner. Spans cafe -> walk -> market -> home.
## Preserves: GameState authority, landmark discovery, handbook architecture,
## interaction framework, first-person controller. Extends only.

const NPCScript = preload("res://scripts/story/npc_actor.gd")
const DialogueScript = preload("res://scripts/story/dialogue_presenter.gd")
const CafeScript = preload("res://scripts/story/cafe_day1.gd")
const MarketScript = preload("res://scripts/story/market_day1.gd")
const Target = preload("res://scripts/gameplay/interaction/interactable.gd")

const WALK_ROUTE: Array[Vector3] = [
	Vector3(10.30, -2.9, -12.50),
	Vector3(10.30, -2.9, -11.10),
	Vector3(10.30, -2.9, -9.90),
	Vector3(14.00, -2.9, -9.90),
	Vector3(17.50, -2.9, -9.90),
	Vector3(17.50, -2.9, -12.00),
]
const SOFIA_OFFSET := Vector3(-0.55, 0.0, 0.25)
const BOBBY_OFFSET := Vector3(0.55, 0.0, -0.25)
const BED_POS := Vector3(6.50, 0.35, 1.15)

var state: Node
var morning = null  # FFApartmentMorning, untyped to avoid cyclic class load
var thoughts: FFThoughtPresenter
var dialogue: FFDialoguePresenter
var player: CharacterBody3D
var neighborhood: Node3D

var sofia: FFNPCActor
var bobby: FFNPCActor
var maxwell: FFNPCActor
var cafe: FFCafeDay1
var market: FFMarketDay1

var _bed_target: FFInteractable
var _writing: CanvasLayer
var _writing_plan: Label
var _writing_maria: Label
var _writing_title: Label
var _fade: ColorRect

func initialize(p_morning) -> void:
	morning = p_morning
	state = morning.state
	thoughts = morning.thoughts
	player = morning.player
	neighborhood = get_parent().get_node_or_null("Neighborhood") as Node3D
	if neighborhood == null:
		push_warning("FFDay1Director: no Neighborhood found.")
		return
	dialogue = DialogueScript.new()
	dialogue.name = "Dialogue"
	morning.add_child(dialogue)
	_spawn_cast()
	_build_writing_overlay()
	_build_fade()
	cafe = CafeScript.new()
	cafe.name = "CafeDay1"
	add_child(cafe)
	cafe.configure(state, thoughts, dialogue, player, neighborhood, sofia, bobby)
	cafe.meeting_completed.connect(_on_cafe_completed)
	cafe.group_departed.connect(_on_group_departed)
	market = MarketScript.new()
	market.name = "MarketDay1"
	add_child(market)
	market.configure(state, thoughts, dialogue, player, neighborhood, maxwell, sofia, bobby)
	market.on_handbook_taken = _on_handbook_taken
	market.on_handbook_returned = _on_handbook_returned
	market.on_writing_shown = _show_writing
	market.on_writing_hidden = _hide_writing
	market.encounter_finished.connect(_on_market_done)
	_make_bed()
	_resume_or_start()

func _spawn_cast() -> void:
	sofia = NPCScript.new()
	sofia.name = "Sofia"
	neighborhood.add_child(sofia)
	sofia.setup("sofia", "Sofia", Color(0.30, 0.52, 0.52), Color(0.18, 0.20, 0.26), Color(0.87, 0.72, 0.58), Color(0.35, 0.22, 0.12), 0.95)
	bobby = NPCScript.new()
	bobby.name = "Bobby"
	neighborhood.add_child(bobby)
	bobby.setup("bobby", "Bobby", Color(0.68, 0.32, 0.20), Color(0.55, 0.50, 0.38), Color(0.82, 0.66, 0.52), Color(0.15, 0.10, 0.08), 1.04)
	maxwell = NPCScript.new()
	maxwell.name = "Maxwell"
	neighborhood.add_child(maxwell)
	maxwell.setup("maxwell", "Maxwell", Color(0.85, 0.75, 0.45), Color(0.25, 0.25, 0.30), Color(0.87, 0.72, 0.58), Color(0.10, 0.10, 0.10), 1.0)
	maxwell.visible = false
	sofia.visible = false
	bobby.visible = false

func _resume_or_start() -> void:
	if state.call("flag", "maxwell_wrote_handbook"):
		# Post-market: pair waits at the market, Maxwell stays, bed is ready.
		sofia.global_position = Vector3(16.80, -2.9, -12.30)
		bobby.global_position = Vector3(18.20, -2.9, -12.30)
		sofia.visible = true
		bobby.visible = true
		sofia.look_at_target(maxwell.global_position if maxwell.visible else Vector3(17.5, -2.9, -13.2))
		bobby.look_at_target(player.global_position)
		market.place_maxwell()
		_refresh_bed()
		return
	if state.call("flag", "market_group_departed"):
		# Reload mid-walk or at market: put the pair at the market front.
		sofia.global_position = Vector3(16.90, -2.9, -11.60)
		bobby.global_position = Vector3(18.10, -2.9, -11.60)
		sofia.visible = true
		bobby.visible = true
		market.start_if_ready()
		_refresh_bed()
		return
	if state.call("flag", "cafe_meeting_completed"):
		# Completed but not yet departed (brief window): stand them in the cafe.
		sofia.global_position = Vector3(9.60, -2.9, -12.70)
		bobby.global_position = Vector3(10.00, -2.9, -12.70)
		sofia.visible = true
		bobby.visible = true
		sofia.set_seated(false)
		bobby.set_seated(false)
		_on_group_departed()
		return
	# Fresh: cafe owns the pair.
	sofia.visible = true
	bobby.visible = true
	cafe.start()
	_refresh_bed()

func _on_cafe_completed() -> void:
	pass  # departure follows immediately in cafe beat

func _on_group_departed() -> void:
	# Walk the real world: cafe -> street -> market. No teleport.
	var sofia_route: Array[Vector3] = []
	var bobby_route: Array[Vector3] = []
	for p: Vector3 in WALK_ROUTE:
		sofia_route.append(p + SOFIA_OFFSET)
		bobby_route.append(p + BOBBY_OFFSET)
	sofia.set_seated(false)
	bobby.set_seated(false)
	sofia.walk_path(sofia_route, 1.15, player, 8.5)
	bobby.walk_path(bobby_route, 1.15, player, 8.5)
	_walk_chatter()
	# Wait for BOTH (either may arrive first; sequential awaits would hang).
	while sofia.walking or bobby.walking:
		await get_tree().create_timer(0.3).timeout
		if not is_instance_valid(sofia) or not is_instance_valid(bobby):
			return
	if not state.call("flag", "maxwell_wrote_handbook"):
		market.start_if_ready()

func _walk_chatter() -> void:
	# Sparse by design: Chris mostly follows and observes.
	await get_tree().create_timer(4.0).timeout
	if not is_instance_valid(dialogue) or state.call("flag", "maxwell_met"):
		return
	# Only chatter while the pair is actually walking.
	if sofia.walking or bobby.walking:
		dialogue.say("Bobby", "Maxwell's got the stall today.", 2.6)
		await get_tree().create_timer(3.0).timeout
		if sofia.walking or bobby.walking:
			dialogue.say("Sofia", "He said to come by.", 2.4)

func _on_market_done() -> void:
	_refresh_bed()
	thoughts.say("Home.", 2.2)

# ------------------------------------------------------- handbook transfer ----

func _on_handbook_taken() -> void:
	# Deterministic control transfer: H cannot open, interact prompt clears.
	if morning != null and morning.handbook != null and morning.handbook.is_open:
		morning.handbook.close_book()
	if morning != null and is_instance_valid(morning.interactor):
		morning.interactor.enabled = false
	# player keeps look but cannot wander off mid-writing
	if is_instance_valid(player) and "movement_enabled" in player:
		player.movement_enabled = false

func _on_handbook_returned() -> void:
	if morning != null and is_instance_valid(morning.interactor):
		morning.interactor.enabled = true
	if is_instance_valid(player) and "movement_enabled" in player:
		player.movement_enabled = true

func is_handbook_held_by_maxwell() -> bool:
	return state != null and state.call("flag", "handbook_with_maxwell")

# ------------------------------------------------------- writing overlay ----

func _build_writing_overlay() -> void:
	_writing = CanvasLayer.new()
	_writing.name = "MaxwellWriting"
	_writing.layer = 42
	morning.add_child(_writing)
	var panel := PanelContainer.new()
	panel.name = "Paper"
	_writing.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -260
	panel.offset_right = 260
	panel.offset_top = -90
	panel.offset_bottom = 90
	var margin := MarginContainer.new()
	panel.add_child(margin)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	var col := VBoxContainer.new()
	margin.add_child(col)
	col.add_theme_constant_override("separation", 10)
	_writing_title = Label.new()
	_writing_title.text = "MAXWELL WRITES"
	_writing_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_writing_title.add_theme_font_size_override("font_size", 13)
	col.add_child(_writing_title)
	_writing_plan = Label.new()
	_writing_plan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_writing_plan.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_writing_plan.add_theme_font_size_override("font_size", 22)
	col.add_child(_writing_plan)
	_writing_maria = Label.new()
	_writing_maria.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_writing_maria.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_writing_maria.add_theme_font_size_override("font_size", 22)
	col.add_child(_writing_maria)
	_writing.hide()

func _show_writing(plan_text: String, maria_text: String, page: int) -> void:
	# page 0: tomorrow's plan. page 1: Maria's page (player sees the turn,
	# Chris never comments on it — that asymmetry is the point of Day 2).
	if page == 0:
		_writing_title.text = "TOMORROW'S PLAN"
		_writing_plan.text = plan_text
		_writing_maria.text = ""
	else:
		_writing_title.text = "MARIA"
		_writing_maria.text = maria_text
	_writing.show()
	await get_tree().create_timer(0.2).timeout

func _hide_writing() -> void:
	_writing.hide()

# ------------------------------------------------------- return home / sleep ----

func _make_bed() -> void:
	if is_instance_valid(_bed_target):
		return
	_bed_target = Target.new()
	_bed_target.name = "Interact_bed_sleep"
	_bed_target.action_id = "sleep_day1"
	_bed_target.prompt = "Sleep"
	if morning == null or morning.apartment == null:
		return
	morning.apartment.add_child(_bed_target)
	_bed_target.position = BED_POS
	_bed_target.configure(Vector3(1.5, 1.0, 2.1))
	_bed_target.activated.connect(_on_sleep)
	_refresh_bed()

func _refresh_bed() -> void:
	if not is_instance_valid(_bed_target):
		return
	# Only after the Market winds down does the bed end the day.
	_bed_target.enabled = state.call("flag", "day1_end_ready") and not state.call("flag", "day1_completed")

func _build_fade() -> void:
	var layer := CanvasLayer.new()
	layer.name = "Day1FadeLayer"
	layer.layer = 48
	morning.add_child(layer)
	_fade = ColorRect.new()
	_fade.name = "Day1Fade"
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)
	layer.hide()
	_fade.hide()

func _show_fade() -> void:
	if is_instance_valid(_fade):
		_fade.get_parent().show()
		_fade.show()

func _on_sleep(_hit: FFInteractable) -> void:
	if not state.call("flag", "day1_end_ready") or state.call("flag", "day1_completed"):
		return
	if is_instance_valid(player):
		player.enabled = false
	thoughts.say("Tomorrow.", 2.0)
	await get_tree().create_timer(2.1).timeout
	_show_fade()
	var tw: Tween = create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 1.4)
	await tw.finished
	state.call("set_flag", "day1_completed", true)
	_bed_target.enabled = false
	if morning != null and morning.endpoint != null:
		morning.endpoint.set_message(
			"DAY 1 COMPLETE",
			"Chris is home. Tomorrow: Maxwell's house — UNO, drinks, Maria.",
			"Rest")
		morning.endpoint.open()
		# Closing this overlay confirms the day: advance the persistent clock so
		# Day 2 loads through the normal day architecture. One-shot, Day 1 only.
		morning.endpoint.closed.connect(_on_complete_closed, CONNECT_ONE_SHOT)

## Day 1 -> Day 2 transition. Runs once, after sleep is persisted. Completed Day 1
## flags remain as history; Day 1 beats never replay because the bootstrap picks
## the Day 2 layer from here on.
func _on_complete_closed() -> void:
	if not state.call("flag", "day1_completed"):
		return
	if int((state.get("data") as Dictionary).get("current_day", 1)) != 1:
		return
	state.call("advance_day", 2)
	get_tree().call_deferred("reload_current_scene")
