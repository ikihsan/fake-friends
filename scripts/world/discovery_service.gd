class_name FFDiscoveryService
extends Node

## Turns "Chris walked into a place" into persistent knowledge.
##
## GameState stays the single authority: this service never keeps its own copy
## of what is known, it asks GameState every time, which makes discovery
## idempotent (arriving twice, or reloading a save, can never duplicate a place).

signal landmark_discovered(id: String, label: String)
signal thought_requested(text: String)

var state: Node
var _registered: Array[FFLandmark] = []

## `world_root` is scanned for FFLandmark nodes; landmarks added later can be
## handed over with register().
func initialize(world_root: Node, state_node: Node) -> void:
	state = state_node
	for landmark: FFLandmark in _find(world_root):
		register(landmark)

func register(landmark: FFLandmark) -> void:
	if landmark == null or _registered.has(landmark):
		return
	_registered.append(landmark)
	landmark.player_entered.connect(_on_player_entered)

func is_known(id: String) -> bool:
	if state == null or not FFLandmarkCatalog.has_id(id):
		return false
	var data: Dictionary = state.get("data")
	var known: Dictionary = data.get("landmarks", {})
	return known.has(id)

func known_ids() -> Array:
	var out: Array = []
	if state == null:
		return out
	var data: Dictionary = state.get("data")
	for id: String in (data.get("landmarks", {}) as Dictionary).keys():
		out.append(id)
	return out

func _on_player_entered(landmark: FFLandmark) -> void:
	var id: String = landmark.landmark_id
	if id.is_empty() or not FFLandmarkCatalog.has_id(id):
		push_warning("FFDiscoveryService: landmark with unknown id '%s'" % id)
		return
	if is_known(id):
		return
	var place_label: String = FFLandmarkCatalog.label_for(id)
	if state != null and state.has_method("discover_landmark"):
		state.call("discover_landmark", id, place_label)
	landmark_discovered.emit(id, place_label)
	var line: String = FFLandmarkCatalog.thought_for(id)
	if not line.is_empty():
		thought_requested.emit(line)

func _find(node: Node) -> Array[FFLandmark]:
	var out: Array[FFLandmark] = []
	if node is FFLandmark:
		out.append(node)
	for child: Node in node.get_children():
		out.append_array(_find(child))
	return out
