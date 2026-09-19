class_name FFLandmark
extends Area3D

## A place Chris can recognise. This node only DETECTS arrival and reports it;
## the persistent side (GameState) belongs to FFDiscoveryService, so the same
## component can be reused by any scene or any later day.
##
## Ids come from FFLandmarkCatalog and are the save keys. Never invent an id
## inline - add it to the catalog so the handbook map can draw it too.

signal player_entered(landmark: FFLandmark)

@export var landmark_id: String = ""

func _ready() -> void:
	add_to_group("landmarks")
	collision_layer = 0
	collision_mask = 1          # the player CharacterBody3D sits on layer 1
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)

## Box trigger volume, in the same style as FFInteractable.configure().
func configure(extent: Vector3, offset: Vector3 = Vector3.ZERO) -> void:
	var cs: CollisionShape3D = get_node_or_null("LandmarkShape") as CollisionShape3D
	if cs == null:
		cs = CollisionShape3D.new()
		cs.name = "LandmarkShape"
		add_child(cs)
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(maxf(extent.x, 0.1), maxf(extent.y, 0.1), maxf(extent.z, 0.1))
	cs.shape = shape
	cs.position = offset

func label() -> String:
	return FFLandmarkCatalog.label_for(landmark_id)

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		player_entered.emit(self)
