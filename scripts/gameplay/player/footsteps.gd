class_name FFFootsteps
extends Node

## Turns distance walked into footstep cues.
##
## Distance is the only authority: a body pushed or sliding still steps, a body
## standing still never does, and nothing is cast while airborne. The surface ray
## is cast at most once per emitted step — never per frame.

signal footstep(surface: String)

const DEFAULT_SURFACE := "concrete"
const SURFACE_MASK := 1          # world geometry; the player's own body is excluded
const RAY_START_HEIGHT := 0.1
const RAY_LENGTH := 1.0
const TELEPORT_METRES := 1.0
const MIN_STRIDE := 0.01

var stride: float = 0.62
var enabled: bool = true
var body: CharacterBody3D
var camera: Camera3D
var _travelled: float = 0.0
var _last_position: Vector3 = Vector3.ZERO
var _has_last_position: bool = false
var _initialized: bool = false
var _query: PhysicsRayQueryParameters3D
var _exclude: Array[RID] = []

func _init() -> void:
	set_physics_process(false)

func _ready() -> void:
	set_physics_process(_initialized)

## An invalid body simply leaves this idle; it never reports anything.
func initialize(p_body: CharacterBody3D, p_camera: Camera3D) -> void:
	body = p_body
	camera = p_camera
	_travelled = 0.0
	_has_last_position = false
	_exclude.clear()
	if is_instance_valid(body):
		_exclude.append(body.get_rid())
	if _query == null:
		_query = PhysicsRayQueryParameters3D.new()
	_query.collision_mask = SURFACE_MASK
	_query.collide_with_bodies = true
	_query.collide_with_areas = false
	_query.exclude = _exclude
	_initialized = is_instance_valid(body)
	set_physics_process(_initialized)

func _physics_process(_delta: float) -> void:
	if not enabled or not _initialized or not is_instance_valid(body):
		_has_last_position = false
		return
	var here: Vector3 = body.global_position
	if not _has_last_position:
		_last_position = here
		_has_last_position = true
		return
	var moved: Vector3 = here - _last_position
	_last_position = here
	moved.y = 0.0
	if not body.is_on_floor():
		return
	var walked: float = moved.length()
	# A teleport or a re-parent jump is not walking; resync instead of counting.
	if walked <= 0.0001 or walked > TELEPORT_METRES:
		return
	_travelled += walked
	var limit: float = maxf(stride, MIN_STRIDE)
	if _travelled < limit:
		return
	_travelled = fmod(_travelled, limit)
	_emit_step()

func _emit_step() -> void:
	footstep.emit(_surface_below())

## One downward ray, sampled under the viewpoint and excluded from the player's
## own collider. Missing geometry or a missing meta both mean the default.
func _surface_below() -> String:
	if not is_instance_valid(body) or not body.is_inside_tree():
		return DEFAULT_SURFACE
	var origin: Vector3 = body.global_position
	origin.y += RAY_START_HEIGHT
	if is_instance_valid(camera) and camera.is_inside_tree():
		var view: Vector3 = camera.global_position
		origin.x = view.x
		origin.z = view.z
	var world: World3D = body.get_world_3d()
	if world == null or _query == null:
		return DEFAULT_SURFACE
	_query.from = origin
	_query.to = origin + Vector3.DOWN * RAY_LENGTH
	var hit: Dictionary = world.direct_space_state.intersect_ray(_query)
	if hit.is_empty():
		return DEFAULT_SURFACE
	var collider: Object = hit.get("collider") as Object
	if collider == null:
		return DEFAULT_SURFACE
	if not collider.has_meta("surface"):
		return DEFAULT_SURFACE
	return str(collider.get_meta("surface"))
