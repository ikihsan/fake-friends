class_name FFBuildEndpoint
extends CanvasLayer
## Development end-of-slice overlay. Its wording is set by whoever opens it, so a
## later pass can retarget the same overlay without touching this file.

signal opened()
signal closed()

const DEFAULT_TITLE: String = "END OF CURRENT BUILD"
const DEFAULT_BODY: String = "Day 1 continues beyond the apartment in a future build."
const DEFAULT_BUTTON: String = "Step back"

var is_open: bool = false
var _root: Control
var _title: Label
var _body: Label
var _button: Button

func _ready() -> void:
	layer = 45
	_root = Control.new()
	add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.06, 0.055, 0.05, 0.92)
	_root.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box: VBoxContainer = VBoxContainer.new()
	_root.add_child(box)
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.offset_left = -330
	box.offset_right = 330
	box.offset_top = -110
	box.offset_bottom = 110
	box.add_theme_constant_override("separation", 22)
	_title = Label.new()
	_title.text = DEFAULT_TITLE
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.add_theme_font_size_override("font_size", 26)
	box.add_child(_title)
	_body = Label.new()
	_body.text = DEFAULT_BODY
	_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_body)
	_button = Button.new()
	_button.text = DEFAULT_BUTTON
	box.add_child(_button)
	_button.pressed.connect(close)
	_root.hide()

## Retarget the overlay for a different end-of-slice marker.
func set_message(title: String, body: String, button: String = "") -> void:
	_title.text = title
	_body.text = body
	_button.text = button if not button.is_empty() else DEFAULT_BUTTON

func open() -> void:
	if is_open:
		return
	is_open = true
	_root.show()
	opened.emit()

func close() -> void:
	if not is_open:
		return
	is_open = false
	_root.hide()
	closed.emit()
