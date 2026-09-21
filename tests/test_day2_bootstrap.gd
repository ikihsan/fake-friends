extends SceneTree
## Day 1 -> Day 2 bootstrap tests. Mutes persistence first so the live dev
## save is never touched, then drives the in-memory clock forward.
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
	var ps: PackedScene = load("res://scenes/world_day1.tscn")
	check(ps != null, "world loads")
	var world: Node3D = ps.instantiate()
	root.add_child(world)
	await create_timer(1.0).timeout
	var state: Node = root.get_node_or_null("GameState")
	check(state != null, "autoload GameState present")
	state.set("persistence_enabled", false)
	check(world.get_node_or_null("Day1Director") != null, "Day 1 director active on day 1")
	check(world.get_node_or_null("DayBootstrap") != null, "bootstrap present")

	# Simulate completed Day 1, then reload into Day 2 through the normal scene.
	var data: Dictionary = state.get("data")
	for f in ["cafe_meeting_completed", "market_group_departed", "maxwell_met",
			"maxwell_invitation_received", "maxwell_wrote_handbook", "day1_end_ready", "day1_completed"]:
		data["flags"][f] = true
	data["handbook_entries"]["plan.day_2.maxwell_party"] = "Join Maxwell's home party."
	data["handbook_entries"]["maria.loves_me"] = "Maria loves me."
	data["struck_entries"]["plan.day_2.cafe"] = true
	data["current_day"] = 2
	world.queue_free()
	await process_frame
	var world2: Node3D = ps.instantiate()
	root.add_child(world2)
	await create_timer(1.0).timeout
	check(world2.get_node_or_null("Day1Director") == null, "Day 1 director stays inactive on day 2")
	check(world2.get_node_or_null("Day2Director") != null, "Day 2 director active on day 2")
	var morning2 = world2.get_node_or_null("ApartmentMorning")
	check(morning2 != null, "morning present on day 2")
	if morning2 != null:
		var exit_target: Node = morning2.apartment.find_child("Interact_leave_day2", true, false)
		check(exit_target != null, "Day 2 exit endpoint exists")
		check((morning2.wake.get("in_bed")) == true, "Day 2 starts in bed")
	# Day 2 wake caption is day-aware.
	if morning2 != null:
		var caption: Label = morning2.wake.get("_caption") as Label
		check(caption != null and str(caption.text) == "Day 2 · 7:00 AM", "wake caption reads Day 2")
	world2.queue_free()
	print("Day2 bootstrap tests: ", "PASS" if failures == 0 else str(failures) + " failures")
	quit(0 if failures == 0 else 1)
