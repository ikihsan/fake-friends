class_name FFDayBootstrap
extends Node
## Smallest day router. The world owns composition (apartment + neighbourhood);
## this picks the story layer from GameState.current_day and nothing else.
## Day 1 keeps its completed director verbatim; Day 2 gets its own director.
## No chapter framework, no duplicated scenes.

const Day1Script = preload("res://scripts/story/day1_director.gd")
const Day2Script = preload("res://scripts/story/day2_director.gd")

var day1: Node
var day2: Node

func initialize(p_morning) -> void:
	var state: Node = p_morning.state
	var day: int = int((state.get("data") as Dictionary).get("current_day", 1))
	# Directors expect to hang directly off the world (they resolve
	# "Neighborhood" from their parent), so adopt them there, not here.
	var world: Node = get_parent()
	if day < 2:
		day1 = Day1Script.new()
		day1.name = "Day1Director"
		world.add_child(day1)
		day1.initialize(p_morning)
	else:
		day2 = Day2Script.new()
		day2.name = "Day2Director"
		world.add_child(day2)
		day2.initialize(p_morning)
