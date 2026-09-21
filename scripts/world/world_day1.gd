class_name FFWorldDay1
extends Node3D

## Day 1 world composition. It owns everything that spans the apartment and the
## street, and nothing that belongs to either on its own:
##   - landmark discovery (FFDiscoveryService + FFLandmark in the neighbourhood)
##   - the cafe door and the cafe arrival trigger
##   - audio cues and footsteps
## The apartment keeps its own morning systems (FFApartmentMorning) untouched, and
## is simply instanced next to the neighbourhood at the same world coordinates, so
## walking out of the front door and down the stairs is seamless.

const DiscoveryScript = preload("res://scripts/world/discovery_service.gd")
const DoorScript = preload("res://scripts/gameplay/interaction/door_open.gd")
const AudioScript = preload("res://scripts/world/audio_director.gd")
const StepsScript = preload("res://scripts/gameplay/player/footsteps.gd")
const DirectorScript = preload("res://scripts/story/day1_director.gd")

var morning: FFApartmentMorning
var neighborhood: Node3D
var discovery: DiscoveryScript
var audio: AudioScript
var steps: StepsScript
var director: Node
var state: Node

## Development aid only: when set (X != 0) Chris starts at street level instead of
## in bed, so the exterior can be exercised without replaying the whole morning.
## Left at zero in the shipped scene; res://dev/views/street_start.tscn sets it.
@export var dev_street_spawn: Vector3 = Vector3.ZERO

func _ready() -> void:
	morning = $ApartmentMorning as FFApartmentMorning
	neighborhood = $Neighborhood as Node3D
	state = get_node("/root/GameState")

	_audio()
	_discovery()
	_doors()
	_day1_story()

	# The apartment's floor is the ground plane of the whole world; tell the
	# footstep system what that surface is called.
	var ground: Node = morning.apartment.get_node_or_null("Shell/Ground/Body")
	if ground is StaticBody3D:
		(ground as StaticBody3D).set_meta("surface", "wood")

	if dev_street_spawn != Vector3.ZERO:
		_place_at_street()

	print("Day 1 world ready — neighbourhood + apartment; known landmarks=",
		discovery.known_ids())

func _place_at_street() -> void:
	var body: CharacterBody3D = morning.player
	# The wake sequence keeps the body's collision shape disabled while Chris is
	# lying down (so he can be posed inside the bed without being pushed out).
	# Skipping the wake must hand that collision back, or he falls through the
	# world the moment he is placed anywhere else.
	morning.wake.skip()
	body.position = dev_street_spawn
	body.rotation_degrees = Vector3(0, 180, 0)
	body.camera.position = Vector3(0, 1.65, 0)
	body.camera.rotation = Vector3.ZERO
	print("DEV street spawn at ", dev_street_spawn)

# ------------------------------------------------------------------ audio ----

func _audio() -> void:
	audio = AudioScript.new()
	audio.name = "AudioDirector"
	add_child(audio)
	audio.initialize(neighborhood)
	audio.connect_emitter(morning.ritual)
	steps = StepsScript.new()
	steps.name = "Footsteps"
	morning.player.add_child(steps)
	steps.initialize(morning.player, morning.player.camera)
	steps.footstep.connect(audio.play_cue)

# -------------------------------------------------------------- discovery ----

func _discovery() -> void:
	discovery = DiscoveryScript.new()
	discovery.name = "DiscoveryService"
	add_child(discovery)
	discovery.initialize(neighborhood, state)
	discovery.thought_requested.connect(_say)
	discovery.landmark_discovered.connect(_on_landmark_discovered)

func _on_landmark_discovered(id: String, place_label: String) -> void:
	print("Landmark discovered: %s (%s)" % [id, place_label])
	state.call("set_flag", "discovered_" + id, true)

func _say(text: String) -> void:
	morning.thoughts.say(text)

# ------------------------------------------------------------------ doors ----

func _doors() -> void:
	# Cafe Caffeine's leaf: hinged at the west jamb, opens inward (265 deg).
	var cafe_door: Node3D = neighborhood.get_node_or_null("CafeCaffeine/CafeDoor") as Node3D
	if cafe_door != null:
		var door: DoorScript = DoorScript.new()
		door.name = "CafeDoorControl"
		add_child(door)
		door.initialize(cafe_door, 265.0)

# ----------------------------------------------------------- Day 1 story ----

## Day 1 playable story: Cafe Caffeine -> walk -> Market -> home.
## Replaces the old development endpoint (order_coffee overlay) with the real
## Sofia/Bobby/Maxwell staging. The room, counter and four-seat table are reused
## as-is; this only adds actors and beats.
func _day1_story() -> void:
	director = DirectorScript.new()
	director.name = "Day1Director"
	add_child(director)
	director.initialize(morning)
