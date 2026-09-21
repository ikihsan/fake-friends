extends SceneTree
## Sandboxed end-to-end save/reload verification for the Day 2 slice.
## Run with a scratch XDG_DATA_HOME so the real dev save is never touched:
##   XDG_DATA_HOME=/tmp/ffsb1 godot --headless --path . -s res://tests/day2_sandbox_verify.gd
## MODE env selects the phase:
##   setup_full   fresh Day 1 -> complete -> advance to 2 -> Maria beat -> TRUST Sofia
##   verify_full  assert Case 1/2/3 survive a real engine restart + disk reload
##   setup_strike fresh -> Day 2 -> strike Maria claim (Case 4 setup)
##   verify_strike assert Case 4 survived restart
##   setup_none   fresh -> Day 2, no write (Case 5 setup)
##   verify_none  assert write still available after restart (Case 5)
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

func _state() -> Node:
	return root.get_node_or_null("GameState")

func _render(book: CanvasLayer, page_id: String) -> void:
	for i in book.pages.size():
		if str(book.pages[i].get("page_id")) == page_id:
			book._page_index = i
	book._render_page()

func _run() -> void:
	var mode: String = OS.get_environment("MODE")
	var state: Node = _state()
	if state == null:
		push_error("autoload GameState missing")
		quit(1)
		return
	match mode:
		"setup_full":
			var d: Dictionary = state.get("data")
			check(int(d.get("current_day", 0)) == 1 and not state.call("flag", "day1_completed"), "sandbox starts fresh on day 1")
			check(not state.call("can_use_permanent_write"), "Case 6: Day 1 has no permanent write")
			for f in ["cafe_meeting_started", "cafe_coffee_ordered", "cafe_story_done",
					"cafe_meeting_completed", "market_group_departed", "maxwell_met", "maxwell_candy",
					"maxwell_invitation_received", "day1_cafe_plan_done", "maxwell_wrote_handbook",
					"day1_end_ready", "day1_completed"]:
				state.call("set_flag", f, true)
			state.call("story_write_entry", "plan.day_2.maxwell_party", "Join Maxwell's home party.")
			state.call("story_write_entry", "maria.loves_me", "Maria loves me.")
			state.call("story_strike_entry", "plan.day_2.cafe", true)
			state.call("advance_day", 2)
			check(int((state.get("data") as Dictionary).get("current_day", 0)) == 2, "transition advances the clock")
			var book: CanvasLayer = BookScript.new()
			root.add_child(book)
			book._state = state
			var heard: Array[String] = []
			book.thought_requested.connect(func(t: String) -> void: heard.append(t))
			_render(book, "maria")
			check(state.call("flag", "day2_maria_seen"), "Maria beat fires on real save")
			check(state.call("player_write_judgment", "sofia", "TRUST"), "TRUST Sofia written")
			book.queue_free()
		"verify_full":
			var d2: Dictionary = state.get("data")
			check(int(d2.get("current_day", 0)) == 2, "Case 1: still Day 2 after restart")
			check(state.call("flag", "day1_completed"), "Case 1: Day 1 history kept")
			check(str(d2.get("handbook_entries", {}).get("maria.loves_me", "")) == "Maria loves me.", "Case 2: Maria entry survives")
			check(str(d2.get("judgments", {}).get("sofia", "")) == "TRUST", "Case 3: TRUST survives restart")
			check(not state.call("can_use_permanent_write"), "Case 3: allowance stays consumed")
			check(d2.get("struck_entries", {}).get("plan.day_2.cafe", false) == true, "Cafe plan strike survives")
		"setup_strike":
			state.call("advance_day", 2)
			state.call("story_write_entry", "maria.loves_me", "Maria loves me.")
			check(state.call("player_strike_entry", "maria.loves_me"), "Case 4: strike a persistent claim")
		"verify_strike":
			var d3: Dictionary = state.get("data")
			check(d3.get("struck_entries", {}).get("maria.loves_me", false) == true, "Case 4: strike survives restart")
			check(not state.call("can_use_permanent_write"), "Case 4: write consumed")
			check(str(d3.get("handbook_entries", {}).get("maria.loves_me", "")) == "Maria loves me.", "Case 4: struck text kept")
		"setup_none":
			state.call("advance_day", 2)
			check(state.call("can_use_permanent_write"), "Case 5 setup: write available")
		"verify_none":
			check(int((state.get("data") as Dictionary).get("current_day", 0)) == 2, "Case 5: still Day 2")
			check(state.call("can_use_permanent_write"), "Case 5: unused write survives restart")
		_:
			push_error("MODE env required: setup_full|verify_full|setup_strike|verify_strike|setup_none|verify_none")
			quit(1)
			return
	print("Sandbox %s: " % mode, "PASS" if failures == 0 else str(failures) + " failures")
	quit(0 if failures == 0 else 1)
