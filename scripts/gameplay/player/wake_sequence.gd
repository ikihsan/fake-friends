class_name FFWakeSequence
extends CanvasLayer

const PlayerScript = preload("res://scripts/gameplay/player/first_person.gd")
signal settled()
var player: PlayerScript
var in_bed: bool = true
var transitioning: bool = true
var _fade: ColorRect
var _caption: Label

func initialize(body: PlayerScript) -> void:
	player = body
	layer = 50
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_caption = Label.new()
	add_child(_caption)
	_caption.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_caption.offset_left = -300
	_caption.offset_right = 300
	_caption.offset_top = -72
	_caption.offset_bottom = -20
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player.enabled = false
	player.movement_enabled = false
	player.position = Vector3(6.50, 0.0, 0.55)
	(player.get_node("Shape") as CollisionShape3D).disabled = true
	player.rotation.y = PI
	player.camera.position = Vector3(0.0, 0.82, 0.0)
	player.camera.look_at(Vector3(6.50, 1.34, 3.50))
	_caption.text = "Day 1 · 7:00 AM"
	var tween: Tween = create_tween()
	tween.tween_interval(0.35)
	tween.tween_property(_fade, "color:a", 0.0, 1.2)
	tween.tween_callback(_eyes_open)

func _eyes_open() -> void:
	transitioning = false
	player.enabled = true
	_caption.text = "7:00 AM     ·     Space — Get up"

## Skip the wake-up altogether. Used by scenes that place Chris somewhere other
## than his bed (dev scenes now, a later "continue the day" load later): the body
## gets its collision back and normal control, and the black overlay is cleared.
## Standing up normally does the same thing through _move_to_bedside().
func skip() -> void:
	in_bed = false
	transitioning = false
	var shape: CollisionShape3D = player.get_node_or_null("Shape") as CollisionShape3D
	if shape != null:
		shape.disabled = false
	player.enabled = true
	player.movement_enabled = true
	set_process(false)
	if _fade != null:
		_fade.color.a = 0.0
	if _caption != null:
		_caption.hide()

func _process(_delta: float) -> void:
	if in_bed and not transitioning and player.enabled and Input.is_action_just_pressed("stand_up"):
		stand()

func stand() -> void:
	if transitioning or not in_bed:
		return
	transitioning = true
	player.enabled = false
	var tween: Tween = create_tween()
	tween.tween_property(_fade, "color:a", 1.0, 0.18)
	tween.tween_callback(_move_to_bedside)
	tween.tween_property(_fade, "color:a", 0.0, 0.35)
	tween.tween_callback(_finish)

func _move_to_bedside() -> void:
	# Validated clear space at the foot of the bed. No collision swept through furniture.
	player.position = Vector3(6.50, 0.04, 2.95)
	player.camera.position = Vector3(0, 1.65, 0)
	player.camera.rotation = Vector3.ZERO
	(player.get_node("Shape") as CollisionShape3D).disabled = false

func _finish() -> void:
	in_bed = false
	transitioning = false
	player.enabled = true
	player.movement_enabled = true
	_caption.text = "WASD — Move     ·     Mouse — Look     ·     E — Interact"
	var tween: Tween = create_tween()
	tween.tween_interval(5.0)
	tween.tween_property(_caption, "modulate:a", 0.0, 0.6)
	settled.emit()
