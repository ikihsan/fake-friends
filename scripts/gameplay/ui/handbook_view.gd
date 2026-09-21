class_name FFHandbookView
extends CanvasLayer

signal opened()
signal closed()
signal thought_requested(text: String)

const StateScript = preload("res://scripts/gameplay/state/game_state.gd")
const PAPER: Texture2D = preload("res://textures/paper.png")
const INK: Color = Color("302a25")
@export var pages: Array[Resource] = StateScript.PAGE_RESOURCES.duplicate()
var is_open: bool = false
var _page_index: int = 0
var _root: Control
var _paper: TextureRect
var _title: Label
var _body: RichTextLabel
var _folio: Label
var _previous: Button
var _next: Button
var _close: Button
var _actions: HBoxContainer
var _write_btn: Button
var _strike_btn: Button
var _chooser: VBoxContainer
var _chooser_label: Label
var _confirm: VBoxContainer
var _confirm_label: Label
var _pending_kind: String = ""
var _pending_value: String = ""
var _pending_person: String = ""
var _state: Node
var _local_plan_seen: bool = false
var _old_focus: WeakRef
var _transition: Tween
var _sketch: Control

func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_state = get_node_or_null("/root/GameState")
	_build()
	_root.hide()

func open_book() -> void:
	if _root == null or is_open:
		return
	var focus: Control = get_viewport().gui_get_focus_owner()
	if focus != null:
		_old_focus = weakref(focus)
	is_open = true
	if _transition != null:
		_transition.kill()
	_layout()
	_root.modulate.a = 0.0
	_root.show()
	_transition = create_tween()
	_transition.tween_property(_root, "modulate:a", 1.0, 0.16)
	var resting_position: Vector2 = _paper.position
	_paper.position.y += 12.0
	_transition.parallel().tween_property(_paper, "position", resting_position, 0.16)
	_render_page()
	_close.disabled = false
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_close.grab_focus()
	opened.emit()

func close_book() -> void:
	if not is_open:
		return
	is_open = false
	if _transition != null:
		_transition.kill()
	# Disable the fading panel immediately; closing still restores control synchronously.
	_previous.disabled = true
	_next.disabled = true
	_close.disabled = true
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition = create_tween()
	_transition.tween_property(_root, "modulate:a", 0.0, 0.12)
	_transition.tween_callback(_root.hide)
	if _old_focus != null:
		var focus: Control = _old_focus.get_ref() as Control
		if focus != null and focus.is_visible_in_tree():
			focus.grab_focus()
	closed.emit()

func _input(event: InputEvent) -> void:
	if not is_open:
		return
	if event.is_action_pressed("book_close"):
		# Esc backs out of the write flow first; the book itself stays open.
		if _confirm.visible or _chooser.visible:
			_hide_write_flow()
			get_viewport().set_input_as_handled()
			return
		close_book()
	elif event.is_action_pressed("page_next"):
		_turn(1)
	elif event.is_action_pressed("page_previous"):
		_turn(-1)
	else:
		return
	get_viewport().set_input_as_handled()

func _build() -> void:
	_root = Control.new()
	_root.name = "Handbook"
	add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.05, 0.04, 0.03, 0.38)
	_root.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paper = TextureRect.new()
	_paper.name = "Paper"
	_paper.texture = PAPER
	_paper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_paper.stretch_mode = TextureRect.STRETCH_SCALE
	_root.add_child(_paper)
	_paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var binding: Control = preload("res://scripts/gameplay/ui/handbook_binding.gd").new()
	_paper.add_child(binding)
	binding.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin: MarginContainer = MarginContainer.new()
	_paper.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 40 if side == "left" else 32)
	var column: VBoxContainer = VBoxContainer.new()
	margin.add_child(column)
	column.add_theme_constant_override("separation", 16)
	var heading: Label = _make_label("H A N D B O O K", 16)
	column.add_child(heading)
	_title = _make_label("", 32)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_title)
	_sketch = preload("res://scripts/gameplay/ui/handbook_sketch.gd").new()
	_sketch.name = "ApartmentSketch"
	_sketch.custom_minimum_size.y = 170
	column.add_child(_sketch)
	_sketch.hide()
	_body = RichTextLabel.new()
	_body.name = "Entries"
	_body.bbcode_enabled = true
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_theme_color_override("default_color", INK)
	_body.add_theme_font_size_override("normal_font_size", 24)
	_body.add_theme_constant_override("line_separation", 9)
	column.add_child(_body)
	_folio = _make_label("", 16)
	column.add_child(_folio)
	_build_write_flow(column)
	var navigation: HBoxContainer = HBoxContainer.new()
	navigation.add_theme_constant_override("separation", 12)
	column.add_child(navigation)
	_previous = _make_button("Previous", navigation, _turn.bind(-1))
	_next = _make_button("Next", navigation, _turn.bind(1))
	_close = _make_button("Close", navigation, close_book)
	_root.resized.connect(_layout)
	_layout()

func _layout() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var book_size: Vector2 = Vector2(minf(760.0, viewport_size.x - 24.0), minf(650.0, viewport_size.y * 0.81))
	_paper.size = book_size
	_paper.position = Vector2((viewport_size.x - book_size.x) * 0.5, viewport_size.y * 0.035)

func _make_label(text: String, font_size: int) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", INK)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _make_button(text: String, parent: Control, callback: Callable) -> Button:
	var button: Button = Button.new()
	button.name = text
	button.text = text
	button.flat = true
	button.custom_minimum_size.y = 44
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", Color("805637"))
	button.add_theme_color_override("font_focus_color", INK)
	button.add_theme_color_override("font_pressed_color", INK)
	button.add_theme_color_override("font_disabled_color", Color(0.2, 0.17, 0.14, 0.4))
	parent.add_child(button)
	button.pressed.connect(callback)
	return button

func _turn(direction: int) -> void:
	if pages.is_empty():
		return
	_page_index = clampi(_page_index + direction, 0, pages.size() - 1)
	_render_page()

func _render_page() -> void:
	if pages.is_empty():
		_sketch.hide()
		_title.text = "Handbook"
		_body.text = ""
		return
	_page_index = clampi(_page_index, 0, pages.size() - 1)
	var page: Resource = pages[_page_index]
	_title.text = str(page.get("title"))
	var page_id: String = str(page.get("page_id"))
	var kind: String = str(page.get("kind"))
	var entries: Dictionary = _displayed_entries()
	var saved: Dictionary = StateScript.default_data()
	if _state != null:
		saved = _state.get("data")
	_sketch.visible = kind == "map"
	var lines: PackedStringArray = []
	var struck: Dictionary = saved.get("struck_entries", {})
	for entry_id: String in entries:
		var prose: String = str(entries[entry_id]).replace("[", "[lb]")
		if struck.get(entry_id, false) == true:
			prose = "[s]" + prose + "[/s]"
		lines.append(prose)
	var judgments: Dictionary = saved.get("judgments", {})
	if judgments.has(page_id):
		# Permanent hand: same paper, slightly warmer ink, slanted.
		lines.append("[color=#6b4a2f][i]" + str(judgments[page_id]).replace("[", "[lb]") + "[/i][/color]")
	_body.text = "\n\n".join(lines)
	if _state != null:
		_state.call("mark_handbook_read", page_id, entries.keys())
	_day2_beats(page_id, kind, entries, saved)
	_hide_write_flow()
	_refresh_actions(page_id, kind)
	_folio.text = "%02d / %02d" % [_page_index + 1, pages.size()]
	_previous.disabled = _page_index == 0
	_next.disabled = _page_index == pages.size() - 1
	if kind == "plan" and not _local_plan_seen:
		_local_plan_seen = true
		if _state == null or not bool(_state.call("flag", "handbook_first_plan_read")):
			if _state != null:
				_state.call("set_flag", "handbook_first_plan_read", true)
			# Connect to ThoughtPresenter.say; its queue supplies the restrained timing.
			thought_requested.emit("Tomorrow’s plan...")
			thought_requested.emit("Did I write this yesterday?")

## Day 2 first-read beats. Chris assumes his previous self wrote everything;
## the player gets no provenance, no flashback, no author marker.
func _day2_beats(page_id: String, kind: String, entries: Dictionary, saved: Dictionary) -> void:
	if _state == null or int(saved.get("current_day", 1)) < 2:
		return
	if kind == "plan" and not bool(_state.call("flag", "day2_plan_seen")):
		_state.call("set_flag", "day2_plan_seen", true)
		thought_requested.emit("Maxwell's place.")
	elif page_id == "maria" and entries.has("maria.loves_me") and not bool(_state.call("flag", "day2_maria_seen")):
		_state.call("set_flag", "day2_maria_seen", true)
		thought_requested.emit("Maria...?")
		thought_requested.emit("I don't remember finding that out.")
		thought_requested.emit("That's why I write things down.")

## The statements as currently displayed on this page (base text + runtime
## overrides). Shared by rendering and by strike eligibility so the two can
## never disagree about what is on the page.
func _displayed_entries() -> Dictionary:
	if pages.is_empty():
		return {}
	var page: Resource = pages[clampi(_page_index, 0, pages.size() - 1)]
	var page_id: String = str(page.get("page_id"))
	var kind: String = str(page.get("kind"))
	var entries: Dictionary = (page.get("entries") as Dictionary).duplicate(true)
	var saved: Dictionary = StateScript.default_data()
	if _state != null:
		saved = _state.get("data")
	if kind == "map":
		return saved.get("landmarks", {"apartment": "Apartment"}).duplicate(true)
	var overrides: Dictionary = saved.get("handbook_entries", {})
	for entry_id: String in overrides:
		if entries.has(entry_id) or entry_id.begins_with(page_id + "."):
			entries[entry_id] = overrides[entry_id]
		elif kind == "plan" and entry_id.begins_with("plan."):
			# Tomorrow's Plan collects every plan.* runtime entry (e.g. the
			# Day 1 Maxwell invite), so story additions appear without a
			# second discovery path. Person pages stay strictly page_id.*.
			entries[entry_id] = overrides[entry_id]
	return entries

## Strikeable right now: persistent statements on friend pages only. Plan
## completion is automatic story state (free), map labels and titles are
## structural, judgments are classifications — none of those consume the write.
func strike_candidates() -> Array[String]:
	var out: Array[String] = []
	if pages.is_empty():
		return out
	var page: Resource = pages[clampi(_page_index, 0, pages.size() - 1)]
	if str(page.get("kind")) != "person":
		return out
	var struck: Dictionary = {}
	if _state != null:
		struck = (_state.get("data") as Dictionary).get("struck_entries", {})
	for entry_id: String in _displayed_entries():
		if struck.get(entry_id, false) != true:
			out.append(entry_id)
	return out

func _build_write_flow(column: VBoxContainer) -> void:
	_actions = HBoxContainer.new()
	_actions.name = "WriteActions"
	_actions.add_theme_constant_override("separation", 12)
	column.add_child(_actions)
	_write_btn = _make_button("Write", _actions, _on_write_pressed)
	_strike_btn = _make_button("Strike out", _actions, _on_strike_pressed)
	_chooser = VBoxContainer.new()
	_chooser.name = "WriteChooser"
	_chooser.add_theme_constant_override("separation", 6)
	column.add_child(_chooser)
	_chooser_label = _make_label("", 18)
	_chooser.add_child(_chooser_label)
	_confirm = VBoxContainer.new()
	_confirm.name = "WriteConfirm"
	_confirm.add_theme_constant_override("separation", 6)
	column.add_child(_confirm)
	_confirm_label = _make_label("", 20)
	_confirm_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirm.add_child(_confirm_label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_confirm.add_child(row)
	_make_button("Confirm", row, _on_write_confirmed)
	_make_button("Cancel", row, _hide_write_flow)
	_chooser.hide()
	_confirm.hide()
	_actions.hide()

## One permanent action per day, shared by judgments and strikes. Hidden
## entirely before Day 2 and on structural pages; disabled once spent.
func _refresh_actions(page_id: String, kind: String) -> void:
	if _actions == null:
		return
	var day_two: bool = _state != null and int((_state.get("data") as Dictionary).get("current_day", 1)) >= 2
	if not day_two or kind != "person":
		_actions.hide()
		return
	_actions.show()
	var can: bool = bool(_state.call("can_use_permanent_write"))
	_write_btn.disabled = not can
	_strike_btn.disabled = not can or strike_candidates().is_empty()

func _hide_write_flow() -> void:
	_pending_kind = ""
	_pending_value = ""
	_pending_person = ""
	if is_instance_valid(_chooser):
		for child: Node in _chooser.get_children():
			if child is Button:
				(child as Button).queue_free()
		_chooser.hide()
	if is_instance_valid(_confirm):
		_confirm.hide()

func _on_write_pressed() -> void:
	if _write_btn.disabled:
		return
	_show_word_chooser()

func _on_strike_pressed() -> void:
	if _strike_btn.disabled:
		return
	var candidates: Array[String] = strike_candidates()
	if candidates.is_empty():
		return
	if candidates.size() == 1:
		_show_strike_confirm(candidates[0])
		return
	_show_candidate_chooser(candidates)

func _show_word_chooser() -> void:
	_hide_write_flow()
	_confirm.hide()
	var page: Resource = pages[_page_index]
	_pending_person = str(page.get("page_id"))
	_chooser_label.text = "Write about " + str(page.get("title")) + ":"
	for word: String in StateScript.JUDGMENT_WORDS:
		var option: Button = _make_button(word, _chooser, _on_word_chosen.bind(word))
		option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chooser.show()
	(_chooser.get_children().back() as Button).grab_focus()

func _show_candidate_chooser(candidates: Array[String]) -> void:
	_hide_write_flow()
	_confirm.hide()
	_chooser_label.text = "Strike out:"
	var shown: Dictionary = _displayed_entries()
	for entry_id: String in candidates:
		var label_text: String = str(shown.get(entry_id, entry_id))
		if label_text.length() > 90:
			label_text = label_text.left(90) + "…"
		var option: Button = _make_button(label_text, _chooser, _on_candidate_chosen.bind(entry_id))
		option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chooser.show()

func _on_word_chosen(word: String) -> void:
	_pending_kind = "judgment"
	_pending_value = word
	var page: Resource = pages[_page_index]
	_confirm_label.text = "Write \"" + word + "\" about " + str(page.get("title")) + "?"
	_chooser.hide()
	_confirm.show()

func _on_candidate_chosen(entry_id: String) -> void:
	_show_strike_confirm(entry_id)

func _show_strike_confirm(entry_id: String) -> void:
	_hide_write_flow()
	_pending_kind = "strike"
	_pending_value = entry_id
	var label_text: String = str(_displayed_entries().get(entry_id, entry_id))
	if label_text.length() > 140:
		label_text = label_text.left(140) + "…"
	_confirm_label.text = "Strike out \"" + label_text + "\"?"
	_confirm.show()

func _on_write_confirmed() -> void:
	if _state == null or _pending_kind.is_empty():
		_hide_write_flow()
		return
	if _pending_kind == "judgment":
		_state.call("player_write_judgment", _pending_person, _pending_value)
	elif _pending_kind == "strike":
		_state.call("player_strike_entry", _pending_value)
	_render_page()
	_close.grab_focus()
