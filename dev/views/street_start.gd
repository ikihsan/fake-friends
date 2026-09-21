extends Node3D
## Development scene: Chris starts at street level so the outdoor neighbourhood
## can be exercised without replaying the whole morning. The shipped scene is
## res://scenes/world_day1.tscn; nothing here is part of the game.

## Where the dev walk begins: the foot of the apartment stairs by default.
@export var spawn: Vector3 = Vector3(-5.4, -2.9, 5.6)

func _ready() -> void:
	var world: FFWorldDay1 = $World as FFWorldDay1
	world.dev_street_spawn = spawn
	world.call("_place_at_street")
