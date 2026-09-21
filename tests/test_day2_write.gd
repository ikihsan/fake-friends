extends SceneTree
## Day 2 permanent-write API tests. Runs with persistence disabled and an
## explicit state instance, so the live dev save is never touched.
const StateScript = preload("res://scripts/gameplay/state/game_state.gd")
var failures: int = 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
	else:
		print("PASS: ", message)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var state: Node = StateScript.new()
	state.persistence_enabled = false
	state.name = "GameState"
	root.add_child(state)

	# Day 1: permanent writing unavailable.
	state.data["current_day"] = 1
	check(not state.call("can_use_permanent_write"), "Day 1 has no permanent write")
	check(not state.call("player_write_judgment", "sofia", "TRUST"), "Day 1 judgment blocked")
	check(not state.call("player_strike_entry", "maria.loves_me"), "Day 1 strike blocked")
	check((state.get("data") as Dictionary)["judgments"].is_empty(), "Day 1 judgments untouched")

	# Day 2: one write available.
	state.data["current_day"] = 2
	check(state.call("can_use_permanent_write"), "Fresh Day 2 has one write")
	check(state.call("player_write_judgment", "sofia", "TRUST"), "Day 2 judgment works")
	check((state.get("data") as Dictionary)["judgments"].get("sofia") == "TRUST", "Judgment persists in state")
	check(not state.call("can_use_permanent_write"), "Write consumed after judgment")
	check(not state.call("player_write_judgment", "bobby", "UNSURE"), "Second judgment blocked")
	check(not state.call("player_strike_entry", "maria.loves_me"), "Strike blocked after judgment used")

	# Fresh Day 2: strike path instead.
	var other: Node = StateScript.new()
	other.persistence_enabled = false
	other.name = "GameState2"
	root.add_child(other)
	other.data["current_day"] = 2
	other.call("story_write_entry", "maria.loves_me", "Maria loves me.")
	check(other.call("player_strike_entry", "maria.loves_me"), "Day 2 strike works")
	check((other.get("data") as Dictionary)["struck_entries"].get("maria.loves_me", false) == true, "Strike persists in state")
	check(not other.call("can_use_permanent_write"), "Write consumed after strike")

	# New day restores allowance; old judgments survive.
	other.data["current_day"] = 3
	check(other.call("can_use_permanent_write"), "New day restores allowance")

	state.free()
	other.free()
	print("Day2 write API tests: ", "PASS" if failures == 0 else str(failures) + " failures")
	quit(0 if failures == 0 else 1)
