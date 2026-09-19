class_name FFInteractor
extends Node

const TargetScript = preload("res://scripts/gameplay/interaction/interactable.gd")
const PlayerScript = preload("res://scripts/gameplay/player/first_person.gd")

signal focused(target: TargetScript)
## Empty string means clear the prompt; otherwise includes the E prefix.
signal prompt_changed(text: String)
signal interacted(target: TargetScript)

var camera: Camera3D
var player: CharacterBody3D
var enabled: bool = true
var reach: float = 2.0
var hud_enabled: bool = true
var current_target: TargetScript
var _hud: CanvasLayer
var _prompt_label: Label
var _last_prompt: String = ""

func initialize(cam: Camera3D, body: CharacterBody3D) -> void:
	camera = cam
	player = body
	_ensure_input()
	set_physics_process(true)
	if is_inside_tree():
		_build_hud()

func _ready() -> void:
	_ensure_input()
	_build_hud()

func _ensure_input() -> void:
	if not InputMap.has_action("interact"):
		InputMap.add_action("interact")
		var event: InputEventKey = InputEventKey.new()
		event.physical_keycode = KEY_E
		InputMap.action_add_event("interact", event)

func _physics_process(_delta: float) -> void:
	var active: bool = enabled and is_instance_valid(camera) and is_instance_valid(player)
	if player is PlayerScript:
		active = active and player.enabled
	active = active and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if is_instance_valid(_hud):
		_hud.visible = active and hud_enabled
	if not active:
		_set_target(null)
		return
	var origin: Vector3 = camera.global_position
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin, origin - camera.global_basis.z.normalized() * maxf(reach, 0.0), 3, [player.get_rid()])
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.hit_from_inside = true
	var hit: Dictionary = camera.get_world_3d().direct_space_state.intersect_ray(query)
	var target: TargetScript = null
	if not hit.is_empty():
		target = hit.get("collider") as TargetScript
	if is_instance_valid(target) and (not target.enabled or target.busy or target.is_queued_for_deletion()):
		target = null
	_set_target(target)

## Activation is event-driven, never polled. A key press is consumed the moment
## it arrives, and a GUI control that swallows the event (the open handbook)
## swallows the interaction with it.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return
	if not enabled or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if not is_instance_valid(current_target) or current_target.busy or not current_target.enabled:
		return
	var activated_target: TargetScript = current_target
	activated_target.interact()
	if is_instance_valid(activated_target):
		interacted.emit(activated_target)
	_refresh_prompt()

func _set_target(target: TargetScript) -> void:
	if not is_instance_valid(current_target):
		current_target = null
	if current_target != target:
		current_target = target
		focused.emit(target)
		if is_instance_valid(target):
			target.focus()
	_refresh_prompt()

func _refresh_prompt() -> void:
	var text: String = ""
	if is_instance_valid(current_target) and current_target.enabled and not current_target.busy and not current_target.is_queued_for_deletion():
		text = "E — " + current_target.prompt
	if text != _last_prompt:
		_last_prompt = text
		prompt_changed.emit(text)
	if is_instance_valid(_prompt_label):
		_prompt_label.text = text

func _build_hud() -> void:
	if is_instance_valid(_hud):
		return
	_hud = CanvasLayer.new()
	_hud.name = "InteractionHUD"
	add_child(_hud)
	var crosshair: Label = Label.new()
	crosshair.name = "Crosshair"
	crosshair.text = "·"
	_hud.add_child(crosshair)
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.offset_left = -10.0
	crosshair.offset_right = 10.0
	crosshair.offset_top = -12.0
	crosshair.offset_bottom = 12.0
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt_label = Label.new()
	_prompt_label.name = "Prompt"
	_hud.add_child(_prompt_label)
	_prompt_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_prompt_label.offset_left = -280.0
	_prompt_label.offset_right = 280.0
	_prompt_label.offset_top = 30.0
	_prompt_label.offset_bottom = 60.0
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.visible = false
