class_name FFInteractable
extends Area3D
## Place the hitbox just outside the object's solid collider, not inside walls.
## Async consumers own busy: set it true on activation, false on completion.

signal activated(target: FFInteractable)
signal focused(target: FFInteractable)

@export var action_id: String = ""
@export var prompt: String = "Use"
@export var enabled: bool = true
var busy: bool = false
var _emitting: bool = false
var _hitbox: CollisionShape3D

func _init() -> void:
	collision_layer = 2
	collision_mask = 0
	monitoring = false
	monitorable = false

func configure(size: Vector3, offset: Vector3 = Vector3.ZERO) -> void:
	collision_layer = 2
	collision_mask = 0
	monitoring = false
	monitorable = false
	if not is_instance_valid(_hitbox):
		_hitbox = get_node_or_null("InteractionShape") as CollisionShape3D
		if _hitbox == null:
			_hitbox = CollisionShape3D.new()
			_hitbox.name = "InteractionShape"
			add_child(_hitbox)
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(maxf(size.x, 0.01), maxf(size.y, 0.01), maxf(size.z, 0.01))
	_hitbox.shape = shape
	_hitbox.position = offset

func interact() -> void:
	if not enabled or busy or _emitting or is_queued_for_deletion():
		return
	_emitting = true
	activated.emit(self)
	_emitting = false

func focus() -> void:
	if enabled and not busy and not is_queued_for_deletion():
		focused.emit(self)
