extends SceneTree
## Day 2 handbook write UI: contextual Write/Strike actions, eligibility, and
## rendering of judgments and strikes. State transitions go through GameState.
const StateScript = preload("res://scripts/gameplay/state/game_state.gd")
const BookScript = preload("res://scripts/gameplay/ui/handbook_view.gd")
var failures: int = 0

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
	state.data["current_day"] = 2
	state.call("story_write_entry", "maria.loves_me", "Maria loves me.")

	var book: CanvasLayer = BookScript.new()
	root.add_child(book)
	book._state = state

	# Friend page: story claim is a strike candidate, actions visible.
	book._page_index = _page_index(book, "maria")
	book._render_page()
	check(book.call("strike_candidates").has("maria.loves_me"), "maria claim is strike-eligible")
	check(book.get("_actions").visible, "actions visible on friend page")
	check(book.get("_write_btn").disabled == false, "write enabled while quota fresh")

	# Map page: structural, never strikeable, no actions.
	book._page_index = _page_index(book, "map")
	book._render_page()
	check((book.call("strike_candidates") as Array).is_empty(), "map has no candidates")
	check(not book.get("_actions").visible, "actions hidden on map page")

	# Plan page: automatic story strikes only, no player actions.
	book._page_index = _page_index(book, "tomorrow_plan")
	book._render_page()
	check((book.call("strike_candidates") as Array).is_empty(), "plan has no candidates")
	check(not book.get("_actions").visible, "actions hidden on plan page")

	# Judgment flow: write, render handwritten, quota consumed.
	book._page_index = _page_index(book, "maria")
	book._render_page()
	check(state.call("player_write_judgment", "maria", "UNSURE"), "judgment write accepted")
	book._render_page()
	check(str(book.get("_body").text).find("UNSURE") >= 0, "judgment renders on the page")
	check(book.get("_write_btn").disabled, "actions disabled after write")

	# Strike flow on a fresh day: text stays, crossed out.
	var other: Node = StateScript.new()
	other.persistence_enabled = false
	other.name = "GameState2"
	root.add_child(other)
	other.data["current_day"] = 2
	other.call("story_write_entry", "maria.loves_me", "Maria loves me.")
	var book2: CanvasLayer = BookScript.new()
	root.add_child(book2)
	book2._state = other
	book2._page_index = _page_index(book2, "maria")
	book2._render_page()
	check(other.call("player_strike_entry", "maria.loves_me"), "strike accepted")
	book2._render_page()
	check(str(book2.get("_body").text).find("[s]Maria loves me.[/s]") >= 0, "strike renders crossed out, text kept")
	check((book2.call("strike_candidates") as Array).is_empty() or not (book2.call("strike_candidates") as Array).has("maria.loves_me"),
		"struck entry leaves the candidate list")

	# Day 1: no player write UI at all.
	var old: Node = StateScript.new()
	old.persistence_enabled = false
	old.name = "GameState1"
	root.add_child(old)
	old.data["current_day"] = 1
	var book1: CanvasLayer = BookScript.new()
	root.add_child(book1)
	book1._state = old
	book1._page_index = _page_index(book1, "sofia")
	book1._render_page()
	check(not book1.get("_actions").visible, "no write UI on day 1")

	print("Day2 handbook UI tests: ", "PASS" if failures == 0 else str(failures) + " failures")
	quit(0 if failures == 0 else 1)
