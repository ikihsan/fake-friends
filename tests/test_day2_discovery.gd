extends SceneTree
## Day 2 discovery beats: first plan read and first Maria page read trigger
## restrained Chris thoughts exactly once. No Maxwell reveal, no provenance.
const StateScript = preload("res://scripts/gameplay/state/game_state.gd")
const BookScript = preload("res://scripts/gameplay/ui/handbook_view.gd")
var failures: int = 0
var heard: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
	else:
		print("PASS: ", message)

func _init() -> void:
	call_deferred("_run")

func _page_index(book: CanvasLayer, page_id: String) -> int:
	for i in book.pages.size():
		if str(book.pages[i].get("page_id")) == page_id:
			return i
	return -1

func _run() -> void:
	var state: Node = StateScript.new()
	state.persistence_enabled = false
	state.name = "GameState"
	root.add_child(state)
	# Simulate post-Day-1 history.
	state.data["current_day"] = 2
	state.call("set_flag", "handbook_first_plan_read", true)
	state.call("story_write_entry", "plan.day_2.maxwell_party", "Join Maxwell's home party.")
	state.call("story_write_entry", "maria.loves_me", "Maria loves me.")
	state.call("story_strike_entry", "plan.day_2.cafe", true)

	var book: CanvasLayer = BookScript.new()
	root.add_child(book)
	book._state = state
	book.thought_requested.connect(func(t: String) -> void: heard.append(t))

	book._page_index = _page_index(book, "tomorrow_plan")
	book._render_page()
	check(state.call("flag", "day2_plan_seen"), "plan first-read flagged")
	check(heard == ["Maxwell's place."], "plan beat is one restrained thought")

	heard.clear()
	book._page_index = _page_index(book, "maria")
	book._render_page()
	check(state.call("flag", "day2_maria_seen"), "maria first-read flagged")
	check(heard == ["Maria...?", "I don't remember finding that out.", "That's why I write things down."],
		"maria beat trusts the handbook, never Maxwell")

	# Second visits stay silent.
	heard.clear()
	book._render_page()
	check(heard.is_empty(), "maria beat fires once")

	# Day 1 is untouched: no flags, no thoughts.
	var old: Node = StateScript.new()
	old.persistence_enabled = false
	old.name = "GameState1"
	root.add_child(old)
	old.data["current_day"] = 1
	var book1: CanvasLayer = BookScript.new()
	root.add_child(book1)
	book1._state = old
	var heard1: Array[String] = []
	book1.thought_requested.connect(func(t: String) -> void: heard1.append(t))
	book1._page_index = _page_index(book1, "maria")
	book1._render_page()
	check(not old.call("flag", "day2_maria_seen"), "no day-2 flag on day 1")
	check(heard1.is_empty(), "no day-2 thoughts on day 1")

	print("Day2 discovery tests: ", "PASS" if failures == 0 else str(failures) + " failures")
	quit(0 if failures == 0 else 1)
