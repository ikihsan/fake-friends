class_name FFBuildEndpoint
extends CanvasLayer
signal opened()
signal closed()
var is_open: bool = false
var _root: Control

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
	box.offset_left = -290
	box.offset_right = 290
	box.offset_top = -95
	box.offset_bottom = 95
	box.add_theme_constant_override("separation", 28)
	var text: Label = Label.new()
	text.text = "END OF CURRENT BUILD\n\nDay 1 continues beyond the apartment in a future build."
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(text)
	var back: Button = Button.new()
	back.text = "Stay in apartment"
	box.add_child(back)
	back.pressed.connect(close)
	_root.hide()

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
