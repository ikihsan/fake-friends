class_name FFAmbienceZone
extends Area3D

## A place that wants a particular ambience cue running ("ambience_street",
## "ambience_park", "ambience_cafe"). This node only DETECTS the player and
## reports the cue; FFAudioDirector owns what, if anything, actually plays, so
## the same zone works in any scene and stays silent until a stream exists.

signal entered(cue: String)
signal exited(cue: String)

@export var cue: String = ""

var _shape: CollisionShape3D

func _init() -> void:
	_configure_area()

func _ready() -> void:
	_configure_area()

## Box trigger volume, in the same style as FFInteractable.configure().
func configure(extent: Vector3, offset: Vector3 = Vector3.ZERO) -> void:
	_configure_area()
	if not is_instance_valid(_shape):
		_shape = get_node_or_null("AmbienceShape") as CollisionShape3D
		if _shape == null:
			_shape = CollisionShape3D.new()
			_shape.name = "AmbienceShape"
			add_child(_shape)
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(maxf(extent.x, 0.1), maxf(extent.y, 0.1), maxf(extent.z, 0.1))
	_shape.shape = shape
	_shape.position = offset

## A zone with an empty cue is inert; it never reports a nameless ambience.
func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and not cue.is_empty():
		entered.emit(cue)

func _on_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D and not cue.is_empty():
		exited.emit(cue)

## Safe to call from _init (before tree entry), _ready and configure.
func _configure_area() -> void:
	collision_layer = 0
	collision_mask = 1          # the player CharacterBody3D sits on layer 1
	monitoring = true
	monitorable = false
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)
