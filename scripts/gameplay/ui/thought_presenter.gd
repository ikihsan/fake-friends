class_name FFThoughtPresenter
extends CanvasLayer

var _queue: Array[Dictionary] = []
var _remaining: float = 0.0
var _label: Label

func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_label = Label.new()
	_label.name = "ThoughtSubtitle"
	add_child(_label)
	_label.anchor_left = 0.08
	_label.anchor_right = 0.92
	_label.anchor_top = 0.86
	_label.anchor_bottom = 0.97
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", 22)
	_label.add_theme_color_override("font_color", Color("f4eddb"))
	_label.add_theme_color_override("font_shadow_color", Color(0.07, 0.06, 0.05, 0.9))
	_label.add_theme_constant_override("shadow_offset_y", 2)
	_label.add_theme_color_override("font_outline_color", Color(0.07, 0.06, 0.05, 0.8))
	_label.add_theme_constant_override("outline_size", 3)
	_label.hide()
	_advance()

## Interrupt replaces the current thought AND pending queue. Empty text is ignored.
func say(text: String, duration: float = 2.5, interrupt: bool = false) -> void:
	if text.strip_edges().is_empty():
		return
	if interrupt:
		_queue.clear()
		_remaining = 0.0
	_queue.append({"text": text, "duration": maxf(0.1, duration)})
	if _label != null and _remaining <= 0.0:
		_advance()

func _process(delta: float) -> void:
	if _remaining > 0.0:
		_remaining -= delta
		if _remaining <= 0.0:
			_advance()

func _advance() -> void:
	if _queue.is_empty():
		_label.hide()
		_remaining = 0.0
		return
	var item: Dictionary = _queue.pop_front()
	_label.text = str(item["text"])
	_remaining = float(item["duration"])
	_label.show()
