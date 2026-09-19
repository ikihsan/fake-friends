extends "res://scripts/gameplay/ui/handbook_sketch.gd"

# Temporary verification probe: counts real _draw() deliveries.
var draw_count: int = 0

func _draw() -> void:
	draw_count += 1
	super()
