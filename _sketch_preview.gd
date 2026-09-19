extends Control
# TEMPORARY preview harness. Not part of the game; delete/move out after use.

const SKETCH = preload("res://scripts/gameplay/ui/handbook_sketch.gd")
const PAPER: Color = Color("e9e2d2")
const INK: Color = Color("302a25")

var _sketch: Control
var _state: Node
var _t: float = 0.0
var _stage: int = 0

func _ready() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.05, 0.04, 0.03, 1.0)
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_state = get_node_or_null("/root/GameState")
	_state.set("persistence_enabled", false)
	_state.get("data")["landmarks"] = {"apartment": "Apartment"}
	var page: ColorRect = ColorRect.new()
	page.color = PAPER
	page.position = Vector2(40, 200)
	page.size = Vector2(760, 260)
	add_child(page)
	_sketch = SKETCH.new()
	_sketch.position = Vector2(40 + 36, 200 + 45)
	_sketch.size = Vector2(688, 170)
	add_child(_sketch)

func _process(delta: float) -> void:
	_t += delta
	var marks: Dictionary = _state.get("data")["landmarks"]
	if _stage == 0 and _t > 0.30:
		marks["corner_store"] = "Corner store"
		marks["park"] = "Park"
		_stage = 1
		_sketch.queue_redraw()
	elif _stage == 1 and _t > 0.60:
		marks["bus_stop"] = "Bus stop"
		marks["internet_cafe"] = "Internet Cafe"
		_stage = 2
		_sketch.queue_redraw()
	elif _stage == 2 and _t > 0.90:
		marks["cafe_caffeine"] = "Cafe Caffeine"
		marks["market"] = "Market"
		marks["maxwell_home"] = "Maxwell's"
		_stage = 3
		_sketch.queue_redraw()
