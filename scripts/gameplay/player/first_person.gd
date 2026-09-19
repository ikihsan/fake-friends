class_name FFFirstPerson
extends CharacterBody3D
## Runtime attachment is supported: set_script(), then initialize().

@onready var camera: Camera3D = $PlayerCamera
@export var speed: float = 1.8
@export var mouse_sensitivity: float = 0.002
@export var gravity: float = 9.8
var enabled: bool = true
var movement_enabled: bool = true
var _initialized: bool = false

func _ready() -> void:
	initialize()

func initialize() -> void:
	camera = get_node_or_null("PlayerCamera") as Camera3D
	set_physics_process(true)
	set_process_unhandled_input(true)
	if not _initialized:
		_ensure_action("move_forward", KEY_W)
		_ensure_action("move_back", KEY_S)
		_ensure_action("move_left", KEY_A)
		_ensure_action("move_right", KEY_D)
		if enabled:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_initialized = true

## Defaults are session-only; existing project bindings are never replaced.
static func _ensure_action(action: StringName, key: Key) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action, event)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	if not enabled:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and is_instance_valid(camera):
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotation.x = clampf(camera.rotation.x - event.relative.y * mouse_sensitivity, deg_to_rad(-85.0), deg_to_rad(85.0))

func _physics_process(delta: float) -> void:
	# Bed/cinematic locks freeze gravity too, preserving the authored pose.
	if not enabled or not movement_enabled:
		velocity = Vector3.ZERO
		return
	var axes: Vector2 = Vector2.ZERO
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		axes = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction: Vector3 = global_basis * Vector3(axes.x, 0.0, axes.y)
	direction.y = 0.0
	direction = direction.normalized() * axes.length()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
	move_and_slide()
