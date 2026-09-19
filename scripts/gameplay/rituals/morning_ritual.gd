class_name FFMorningRitual
extends Node
## Runtime-only props; interaction areas and E bindings belong to the caller.
## Morning state: coffee_state, smoke_state, lighter_in_pocket, coffee_drunk, cigarette_smoked.

signal thought_requested(text: String)
signal sound_requested(cue: String)

const WINDOW := Vector3(8.1, 1.3, 1.6)
const STATION := Vector3(8.0, 0.77, 0.25)
var busy: bool = false
var _camera: Camera3D
var _state: Node
var _coffee: String = "empty"
var _smoke: String = "pocket"
var _phase: String = ""
var _remaining: float = 0.0
var _station: Node3D
var _coffee_surface: MeshInstance3D
var _cup: Node3D
var _smoking: Node3D
var _lighter: Node3D
var _ember: MeshInstance3D
var _desk_mugs: Array[MeshInstance3D] = []
var _original_visibility: Array[bool] = []
var _initialized: bool = false

func initialize(apartment: Node3D, camera: Camera3D) -> void:
	if _initialized:
		return
	if not is_instance_valid(apartment) or not is_instance_valid(camera) or not is_inside_tree():
		push_warning("Morning ritual needs live apartment, camera and tree membership.")
		return
	_camera = camera
	_state = get_node_or_null("/root/GameState")
	_coffee = str(_read_state("coffee_state", "empty"))
	# A interrupted brew can restart; a interrupted sip keeps its full cup.
	if _coffee == "drinking":
		_coffee = "carried"
	if not _coffee in ["empty", "ready", "carried", "empty_carried"]:
		_coffee = "empty"
	_smoke = "pocket"
	_build_station(apartment)
	_build_carried_cup()
	_build_smoking()
	_initialized = true
	_save()
	_sync_visuals()

func coffee_interaction() -> void:
	if not _initialized or busy:
		return
	match _coffee:
		"empty":
			_coffee = "preparing"
			_start("brewing", 3.0)
			sound_requested.emit("coffee_brew")
			thought_requested.emit("Coffee.")
		"ready":
			_coffee = "carried"
			sound_requested.emit("cup_take")
		"empty_carried":
			_coffee = "empty"
			sound_requested.emit("cup_return")
	_save()
	_sync_visuals()

func drink_interaction() -> void:
	if not _initialized or busy:
		return
	if _coffee != "carried":
		return
	if not _near_window():
		thought_requested.emit("By the window.")
		return
	_coffee = "drinking"
	_start("drinking", 2.0)
	_save()
	_sync_visuals()
	sound_requested.emit("coffee_sip")

func smoke_interaction() -> void:
	if not _initialized or busy:
		return
	if not _near_window():
		thought_requested.emit("By the window.")
		return
	_smoke = "lighting"
	_start("lighting", 1.0)
	_save()
	_sync_visuals()
	sound_requested.emit("lighter_flick")

func coffee_prompt() -> String:
	if busy:
		return "Ritual in progress · X cancel"
	match _coffee:
		"ready": return "Take coffee"
		"carried": return "Coffee carried · drink by window"
		"empty_carried": return "Put down cup"
	return "Brew coffee"

func smoke_prompt() -> String:
	if busy:
		return "Ritual in progress · X cancel"
	return "Smoke by the window"

func cancel() -> void:
	if not _initialized:
		return
	_settle_active()
	_save()
	_sync_visuals()

func _settle_active() -> void:
	if _coffee == "preparing":
		_coffee = "empty"
	elif _coffee == "drinking":
		_coffee = "carried"
	_smoke = "pocket"
	_phase = ""
	_remaining = 0.0
	busy = false

func _unhandled_input(event: InputEvent) -> void:
	if busy and InputMap.has_action("ritual_cancel") and event.is_action_pressed("ritual_cancel"):
		cancel()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not busy:
		return
	if not is_instance_valid(_camera):
		cancel()
		return
	if _phase in ["drinking", "lighting", "lit"] and not _near_window():
		cancel()
		return
	_remaining -= delta
	if _remaining > 0.0:
		return
	match _phase:
		"brewing":
			_coffee = "ready"
			busy = false
			_phase = ""
			sound_requested.emit("coffee_ready")
			thought_requested.emit("Ready.")
		"drinking":
			_coffee = "empty_carried"
			_complete("coffee_drunk")
			busy = false
			_phase = ""
		"lighting":
			_smoke = "lit"
			_start("lit", 8.0)
			sound_requested.emit("cigarette_lit")
		"lit":
			_smoke = "spent"
			_complete("cigarette_smoked")
			busy = false
			_phase = ""
			sound_requested.emit("cigarette_out")
	_save()
	_sync_visuals()

func _start(phase: String, seconds: float) -> void:
	_phase = phase
	_remaining = seconds
	busy = true

func _near_window() -> bool:
	if not is_instance_valid(_camera):
		return false
	var p: Vector3 = _camera.global_position
	return Vector2(p.x - WINDOW.x, p.z - WINDOW.z).length() <= 0.95 and absf(p.y - WINDOW.y) < 1.2

func _read_state(key: String, fallback: Variant) -> Variant:
	if is_instance_valid(_state) and _state.has_method("morning_value"):
		return _state.call("morning_value", key, fallback)
	return fallback

func _complete(key: String) -> void:
	if is_instance_valid(_state) and _state.has_method("set_morning"):
		_state.call("set_morning", key, true)

func _save() -> void:
	if is_instance_valid(_state) and _state.has_method("set_morning"):
		_state.call("set_morning", "coffee_state", _coffee)
		_state.call("set_morning", "smoke_state", _smoke)
		_state.call("set_morning", "lighter_in_pocket", not _smoke in ["lighting", "lit"])

func _build_station(apartment: Node3D) -> void:
	_station = Node3D.new()
	_station.name = "MorningCoffeeSetup"
	apartment.add_child(_station)
	_station.global_position = STATION
	# Laptop occupies x7.76..8.08,z0.25..0.47. Use the clear right rear corner.
	_cylinder(_station, "ElectricKettleBase", Vector3(0.27, 0.012, -0.13), 0.085, 0.024, Color(0.08, 0.09, 0.09))
	_cylinder(_station, "Kettle", Vector3(0.27, 0.114, -0.13), 0.07, 0.18, Color(0.22, 0.24, 0.24))
	_cylinder(_station, "Lid", Vector3(0.27, 0.211, -0.13), 0.074, 0.014, Color(0.12, 0.13, 0.13))
	_cylinder(_station, "LidKnob", Vector3(0.27, 0.229, -0.13), 0.018, 0.025, Color(0.08, 0.08, 0.08))
	var spout: MeshInstance3D = _cylinder(_station, "Spout", Vector3(0.20, 0.154, -0.13), 0.018, 0.075, Color(0.3, 0.32, 0.32))
	spout.rotation.z = -0.9
	var desk: Node = apartment.get_node_or_null("Rooms/Bedroom/Desk")
	if desk == null:
		desk = apartment.find_child("Desk", true, false)
	if desk != null:
		for child: Node in desk.get_children():
			if child is MeshInstance3D and "mug" in str(child.name).to_lower():
				_desk_mugs.append(child as MeshInstance3D)
				_original_visibility.append((child as MeshInstance3D).visible)
	if _desk_mugs.is_empty():
		var fallback: MeshInstance3D = _cylinder(_station, "Mug", Vector3(0.26, 0.05, 0.11), 0.04, 0.10, Color(0.83, 0.80, 0.7))
		_desk_mugs.append(fallback)
		_original_visibility.append(true)

func _build_carried_cup() -> void:
	_cup = Node3D.new()
	_cup.name = "CarriedCoffee"
	_camera.add_child(_cup)
	_cup.position = Vector3(0.19, -0.18, -0.40)
	var origin: Vector3 = _desk_mugs[0].global_position
	for original: MeshInstance3D in _desk_mugs:
		var visual: MeshInstance3D = MeshInstance3D.new()
		visual.mesh = original.mesh
		visual.material_override = original.material_override
		_cup.add_child(visual)
		visual.transform = Transform3D(original.global_transform.basis, original.global_position - origin)
	_coffee_surface = _cylinder(_cup, "CoffeeSurface", Vector3(0, 0.051, 0), 0.033, 0.002, Color(0.10, 0.045, 0.018))

func _build_smoking() -> void:
	_smoking = Node3D.new()
	_smoking.name = "PocketCigarette"
	_camera.add_child(_smoking)
	_smoking.position = Vector3(0.16, -0.14, -0.34)
	var paper: MeshInstance3D = _cylinder(_smoking, "Paper", Vector3.ZERO, 0.005, 0.075, Color(0.88, 0.85, 0.74))
	paper.rotation.x = PI / 2.0
	var filter: MeshInstance3D = _cylinder(_smoking, "Filter", Vector3(0, 0, 0.045), 0.0052, 0.025, Color(0.57, 0.32, 0.12))
	filter.rotation.x = PI / 2.0
	_ember = _cylinder(_smoking, "Ember", Vector3(0, 0, -0.04), 0.0055, 0.006, Color(1.0, 0.22, 0.025))
	_ember.rotation.x = PI / 2.0
	var glow: StandardMaterial3D = _ember.material_override as StandardMaterial3D
	glow.emission_enabled = true
	glow.emission = Color(1.0, 0.12, 0.015)
	_lighter = Node3D.new()
	_lighter.name = "PocketLighter"
	_smoking.add_child(_lighter)
	_cylinder(_lighter, "Body", Vector3(-0.045, -0.025, -0.035), 0.014, 0.05, Color(0.18, 0.28, 0.3))
	_cylinder(_lighter, "Cap", Vector3(-0.045, 0.007, -0.035), 0.014, 0.012, Color(0.55, 0.55, 0.52))

func _cylinder(parent: Node3D, label: String, at: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var visual: MeshInstance3D = MeshInstance3D.new()
	visual.name = label
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	visual.mesh = mesh
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	visual.material_override = material
	parent.add_child(visual)
	visual.position = at
	return visual

func _sync_visuals() -> void:
	var carried: bool = _coffee in ["carried", "drinking", "empty_carried"]
	if is_instance_valid(_cup):
		_cup.visible = carried and not _smoke in ["lighting", "lit"]
		_coffee_surface.visible = _coffee != "empty_carried"
		_cup.position = Vector3(0.12, -0.08, -0.30) if _coffee == "drinking" else Vector3(0.19, -0.18, -0.40)
	for i: int in _desk_mugs.size():
		if is_instance_valid(_desk_mugs[i]):
			_desk_mugs[i].visible = _original_visibility[i] and not carried
	if is_instance_valid(_smoking):
		_smoking.visible = _smoke in ["lighting", "lit"]
		_lighter.visible = _smoke == "lighting"
		_ember.visible = _smoke == "lit"

func _exit_tree() -> void:
	if _initialized:
		_settle_active()
		_save()
	for i: int in _desk_mugs.size():
		if is_instance_valid(_desk_mugs[i]):
			_desk_mugs[i].visible = _original_visibility[i]
	for prop: Node3D in [_cup, _smoking, _station]:
		if is_instance_valid(prop):
			prop.queue_free()
	_initialized = false
