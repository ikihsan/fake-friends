class_name FFDialoguePresenter
extends CanvasLayer
## Subtitles for spoken lines. Visually distinct from Chris's internal thoughts:
## - THOUGHTS (FFThoughtPresenter, layer 40): italic-ish cream, bottom 0.86-0.97
## - DIALOGUE (here, layer 41): speaker name in small caps + white line, 0.74-0.84
## so the two never overlap. Wake captions sit at center-bottom and are transient.
##
## Event-driven queue; no per-frame cost beyond the shared _process timer.

var _queue: Array[Dictionary] = []
var _remaining: float = 0.0
var _speaker: Label
var _line: Label

func _ready() -> void:
	layer = 41
	process_mode = Node.PROCESS_MODE_ALWAYS
	_speaker = Label.new()
	_speaker.name = "DialogueSpeaker"
	add_child(_speaker)
	_speaker.anchor_left = 0.08
	_speaker.anchor_right = 0.92
	_speaker.anchor_top = 0.735
	_speaker.anchor_bottom = 0.775
	_speaker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_speaker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_speaker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_speaker.add_theme_font_size_override("font_size", 15)
	_speaker.add_theme_color_override("font_color", Color("c9bfa8"))
	_speaker.add_theme_color_override("font_shadow_color", Color(0.07, 0.06, 0.05, 0.9))
	_speaker.add_theme_constant_override("shadow_offset_y", 2)
	_speaker.add_theme_constant_override("outline_size", 3)
	_speaker.add_theme_color_override("font_outline_color", Color(0.07, 0.06, 0.05, 0.8))
	_speaker.hide()
	_line = Label.new()
	_line.name = "DialogueLine"
	add_child(_line)
	_line.anchor_left = 0.08
	_line.anchor_right = 0.92
	_line.anchor_top = 0.775
	_line.anchor_bottom = 0.845
	_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_line.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_line.add_theme_font_size_override("font_size", 21)
	_line.add_theme_color_override("font_color", Color("ffffff"))
	_line.add_theme_color_override("font_shadow_color", Color(0.07, 0.06, 0.05, 0.9))
	_line.add_theme_constant_override("shadow_offset_y", 2)
	_line.add_theme_color_override("font_outline_color", Color(0.07, 0.06, 0.05, 0.8))
	_line.add_theme_constant_override("outline_size", 3)
	_line.hide()
	_advance()

func say(speaker: String, text: String, duration: float = 2.8) -> void:
	if text.strip_edges().is_empty():
		return
	_queue.append({"speaker": speaker.strip_edges().to_upper(), "text": text, "duration": maxf(0.4, duration)})
	if _remaining <= 0.0:
		_advance()

func say_many(lines: Array, per_line: float = 2.8) -> void:
	for entry in lines:
		if entry is Array and entry.size() >= 2:
			say(str(entry[0]), str(entry[1]), per_line)

func clear() -> void:
	_queue.clear()
	_remaining = 0.0
	_speaker.hide()
	_line.hide()

func is_idle() -> bool:
	return _queue.is_empty() and _remaining <= 0.0

func _process(delta: float) -> void:
	if _remaining > 0.0:
		_remaining -= delta
		if _remaining <= 0.0:
			_advance()

func _advance() -> void:
	if _queue.is_empty():
		_speaker.hide()
		_line.hide()
		_remaining = 0.0
		return
	var item: Dictionary = _queue.pop_front()
	_speaker.text = str(item["speaker"])
	_line.text = "“" + str(item["text"]) + "”"
	_remaining = float(item["duration"])
	_speaker.show()
	_line.show()
