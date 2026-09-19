extends SceneTree
## Run in a disposable project (see run_state_ui_isolation.sh), never the live save tree.
const StateScript = preload("res://scripts/gameplay/state/game_state.gd")
const BookScript = preload("res://scripts/gameplay/ui/handbook_view.gd")
var failures: int = 0

func _init() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	var state: Node = StateScript.new()
	state.persistence_enabled = false
	state.name = "GameState"
	root.add_child(state)
	var other: Node = StateScript.new()
	other.persistence_enabled = false
	check(not state.write_entry("sofia.test", "No", true), "Day 1 must be read-only")
	state.data["current_day"] = 2
	check(state.write_entry("sofia.test", "Yes", true), "First permanent edit today")
	check(not state.write_entry("sofia.test", "No", true), "Second permanent edit blocked")
	check(state.write_entry("sofia.note", "Pencil"), "Pencil not blocked by permanent quota")
	state.set_morning("coffee_state", "carried")
	state.set_plan_completed(2)
	state.data["current_day"] = 3
	check(state.write_entry("sofia.test", "New day", true), "New day restores allowance")
	check(state.morning_value("coffee_state", "empty") == "empty", "Morning resets by day")
	check(not state.plan_completed(3) and state.plan_completed(2), "Plans isolated by day")
	state.data["current_day"] = 2
	check(state.morning_value("coffee_state") == "carried", "Prior morning retained")
	check(not state.write_entry("sofia.test", "No", true), "Returning day retains quota")
	check(other.data["handbook_entries"].is_empty(), "Instances must not share defaults")
	var legacy: Dictionary = {"current_day": 4, "permanent_writing_used": true, "morning": {"coffee_state": "ready"}, "flags": {"old": true}}
	var migrated: Dictionary = StateScript.normalize_data(legacy)
	check(migrated["permanent_writing_used"] == {"4": true}, "Legacy boolean charged only to saved day")
	check(migrated["morning_by_day"]["4"]["coffee_state"] == "ready", "Legacy morning migration")
	migrated["flags"]["old"] = false
	migrated["morning_by_day"]["4"]["coffee_state"] = "empty"
	check(legacy["flags"]["old"] and legacy["morning"]["coffee_state"] == "ready", "Normalization must deep copy")
	check(StateScript.normalize_data({"permanent_writing_used": false})["permanent_writing_used"].is_empty(), "Unused legacy allowance remains available")
	var roundtrip: Dictionary = StateScript.normalize_data(JSON.parse_string(JSON.stringify(state.data)))
	check(roundtrip["permanent_writing_used"] == {"2": true, "3": true}, "JSON daily quota roundtrip")
	var malformed: Dictionary = StateScript.normalize_data({"morning_by_day": {"2": false}, "permanent_writing_used": {"bad": true, "2": "yes"}})
	check(malformed["morning_by_day"].is_empty() and malformed["permanent_writing_used"].is_empty(), "Malformed daily values rejected")
	var book: CanvasLayer = BookScript.new()
	root.add_child(book)
	book.open_book()
	check(state.flag("handbook_page_sofia"), "Page render read flag")
	var entries: Dictionary = book.pages[0].entries.duplicate(true)
	for entry: String in entries:
		check(state.flag("handbook_entry_" + entry), "Entry render read flag")
	book._page_index = book.pages.size() - 1
	book._render_page()
	check(book._sketch.visible and state.flag("handbook_page_map"), "Map sketch and read marker")
	book.close_book()
	book.open_book()
	book.close_book()
	book.open_book()
	await create_timer(0.35).timeout
	check(book.is_open and book._root.visible and is_equal_approx(book._root.modulate.a, 1.0), "Rapid reopen cancels stale close callback")
	check(book.pages[0].entries == entries, "Page resource not mutated")
	book.close_book()
	await create_timer(0.2).timeout
	check(not book._root.visible, "Close fade finishes")
	book.free()
	state.free()
	other.free()
	print("State/UI isolation tests: ", "PASS" if failures == 0 else str(failures) + " failures")
	quit(0 if failures == 0 else 1)
