class_name FFNPCActor
extends Node3D
## Smallest reusable staged human for Day 1 and beyond.
##
## Not a simulated agent: a deterministic stage piece with:
## - named identity (character_id + display_name)
## - clean temporary placeholder body (distinguishable colors, correct scale)
## - idle breathing (cheap sin bob, no per-frame raycasts)
## - look_at_target / walk_to waypoints (event-driven, pauses if player lags)
## - seated pose offset (legs hidden behind tables)
##
## Ownership: Day1Director owns positioning and story; this node only owns its
## own transform and visual bob. No GameState writes here.

signal arrived

const WALK_SPEED_DEFAULT: float = 1.2

var character_id: String = ""
var display_name: String = ""
var walking: bool = false
var seated: bool = false

var _path: Array[Vector3] = []
var _speed: float = WALK_SPEED_DEFAULT
var _follow_player: Node3D = null
var _max_gap: float = 8.0
var _waiting_for_player: bool = false
var _visual: Node3D = null
var _phase: float = 0.0
var _base_visual_y: float = 0.0

func setup(id: String, label: String, shirt: Color, pants: Color, skin: Color = Color(0.87, 0.72, 0.58), hair: Color = Color(0.25, 0.18, 0.12), height_scale: float = 1.0) -> void:
	character_id = id
	display_name = label
	_phase = float(abs(hash(id)) % 100) / 100.0 * TAU
	_build_body(shirt, pants, skin, hair, height_scale)

func _build_body(shirt: Color, pants: Color, skin: Color, hair: Color, hscale: float) -> void:
	_visual = Node3D.new()
	_visual.name = "Visual"
	add_child(_visual)
	_base_visual_y = 0.0
	var leg_h: float = 0.80 * hscale
	var torso_h: float = 0.60 * hscale
	var torso_y: float = leg_h + torso_h * 0.5
	var head_y: float = (leg_h + torso_h + 0.22 * hscale * 0.5) + 0.11 * hscale
	# legs
	_box(_visual, "LegL", pants, Vector3(-0.09, leg_h * 0.5, 0), Vector3(0.14 * hscale, leg_h, 0.14 * hscale))
	_box(_visual, "LegR", pants, Vector3(0.09, leg_h * 0.5, 0), Vector3(0.14 * hscale, leg_h, 0.14 * hscale))
	# torso
	_box(_visual, "Torso", shirt, Vector3(0, torso_y, 0), Vector3(0.42 * hscale, torso_h, 0.24 * hscale))
	# arms
	_box(_visual, "ArmL", shirt, Vector3(-0.27 * hscale, torso_y + 0.05, 0), Vector3(0.10 * hscale, 0.52 * hscale, 0.12 * hscale))
	_box(_visual, "ArmR", shirt, Vector3(0.27 * hscale, torso_y + 0.05, 0), Vector3(0.10 * hscale, 0.52 * hscale, 0.12 * hscale))
	# head + hair
	_box(_visual, "Head", skin, Vector3(0, head_y, 0), Vector3(0.22 * hscale, 0.22 * hscale, 0.22 * hscale))
	_box(_visual, "Hair", hair, Vector3(0, head_y + 0.12 * hscale, -0.01), Vector3(0.24 * hscale, 0.08 * hscale, 0.24 * hscale))
	# soft shadow blob (cheap readability on paving, no extra lights)
	var blob: MeshInstance3D = MeshInstance3D.new()
	blob.name = "Blob"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.30 * hscale
	cyl.bottom_radius = 0.30 * hscale
	cyl.height = 0.01
	blob.mesh = cyl
	var bm := StandardMaterial3D.new()
	bm.albedo_color = Color(0, 0, 0, 0.28)
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	blob.material_override = bm
	blob.position = Vector3(0, 0.012, 0)
	_visual.add_child(blob)

func _box(parent: Node3D, bname: String, color: Color, pos: Vector3, size: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = bname
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.92
	mi.material_override = m
	mi.position = pos
	parent.add_child(mi)
	return mi

func set_seated(value: bool) -> void:
	seated = value
	if _visual != null:
		_visual.position.y = _base_visual_y - (0.34 if value else 0.0)

func look_at_target(world_pos: Vector3) -> void:
	var d: Vector3 = world_pos - global_position
	d.y = 0.0
	if d.length_squared() < 0.0001:
		return
	var yaw: float = atan2(-d.x, -d.z)
	rotation.y = yaw

func walk_path(points: Array, speed: float = WALK_SPEED_DEFAULT, follow_player: Node3D = null, max_gap: float = 8.0) -> void:
	_path.clear()
	for p in points:
		if p is Vector3:
			_path.append(p)
	_speed = speed
	_follow_player = follow_player
	_max_gap = max_gap
	_waiting_for_player = false
	walking = not _path.is_empty()
	set_physics_process(walking)

func stop_walking() -> void:
	_path.clear()
	walking = false
	_waiting_for_player = false
	set_physics_process(false)

func is_waiting() -> bool:
	return _waiting_for_player

func _ready() -> void:
	set_physics_process(false)

func _physics_process(delta: float) -> void:
	if not walking or _path.is_empty():
		walking = false
		set_physics_process(false)
		return
	# Don't stride away from Chris: pause when the gap grows, resume when closed.
	if is_instance_valid(_follow_player):
		var gap: float = global_position.distance_to(_follow_player.global_position)
		if gap > _max_gap:
			_waiting_for_player = true
			return
		_waiting_for_player = false
	var target: Vector3 = _path[0]
	var to: Vector3 = target - global_position
	to.y = 0.0
	var dist: float = to.length()
	if dist < 0.12:
		_path.pop_front()
		if _path.is_empty():
			walking = false
			set_physics_process(false)
			arrived.emit()
		return
	var dir: Vector3 = to / dist
	var step: float = minf(_speed * delta, dist)
	global_position += dir * step
	# keep street-level Y exactly (authored waypoints carry the right Y)
	global_position.y = target.y
	var yaw: float = atan2(-dir.x, -dir.z)
	rotation.y = lerp_angle(rotation.y, yaw, minf(delta * 6.0, 1.0))

func _process(_delta: float) -> void:
	if _visual == null:
		return
	if walking and not _waiting_for_player:
		# tiny stride bob while moving
		var t: float = float(Time.get_ticks_msec()) / 1000.0 * 7.0 + _phase
		_visual.position.y = (_base_visual_y - (0.34 if seated else 0.0)) + absf(sin(t)) * 0.02
	else:
		# calm breathing when idle/seated; frozen only if tree paused
		var t2: float = float(Time.get_ticks_msec()) / 1000.0 * 1.5 + _phase
		_visual.position.y = (_base_visual_y - (0.34 if seated else 0.0)) + sin(t2) * 0.012
