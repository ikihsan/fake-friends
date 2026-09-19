class_name FFApartmentMorning
extends Node3D
## Composition root only: preserved environment + independently owned gameplay modules.
const PlayerScript = preload("res://scripts/gameplay/player/first_person.gd")
const InteractorScript = preload("res://scripts/gameplay/interaction/interactor.gd")
const Target = preload("res://scripts/gameplay/interaction/interactable.gd")
const BookScript = preload("res://scripts/gameplay/ui/handbook_view.gd")
const ThoughtsScript = preload("res://scripts/gameplay/ui/thought_presenter.gd")
const WakeScript = preload("res://scripts/gameplay/player/wake_sequence.gd")
const RitualScript = preload("res://scripts/gameplay/rituals/morning_ritual.gd")
const WardrobeScript = preload("res://scripts/gameplay/interaction/wardrobe_choice.gd")
const DoorScript = preload("res://scripts/gameplay/interaction/door_open.gd")
const EndScript = preload("res://scripts/gameplay/ui/build_endpoint.gd")

var apartment: Node3D
var player: PlayerScript
var interactor: InteractorScript
var handbook: BookScript
var thoughts: ThoughtsScript
var wake: WakeScript
var ritual: RitualScript
var endpoint: EndScript
var state: Node
var _book_prop: Node3D
var _coffee_target: Target
var _smoke_target: Target
var _drink_target: Target

func _ready() -> void:
	apartment = $Apartment
	state = get_node("/root/GameState")
	var body: CharacterBody3D = apartment.get_node("Player")
	body.set_script(PlayerScript)
	player = body as PlayerScript
	player.initialize()
	thoughts = ThoughtsScript.new()
	thoughts.name = "Thoughts"
	add_child(thoughts)
	handbook = BookScript.new()
	handbook.name = "HandbookView"
	add_child(handbook)
	handbook.opened.connect(_book_opened)
	handbook.closed.connect(_book_closed)
	handbook.thought_requested.connect(_say)
	interactor = InteractorScript.new()
	interactor.name = "Interactor"
	add_child(interactor)
	interactor.initialize(player.camera, player)
	interactor.interacted.connect(_log_interaction)
	ritual = RitualScript.new()
	ritual.name = "MorningRitual"
	add_child(ritual)
	ritual.thought_requested.connect(_say)
	ritual.initialize(apartment, player.camera)
	_setup_targets()
	var wardrobe: WardrobeScript = WardrobeScript.new()
	wardrobe.name = "WardrobeChoice"
	add_child(wardrobe)
	wardrobe.initialize(apartment.get_node("Rooms/WardrobeNook/HangingClothes"))
	wardrobe.thought_requested.connect(_say)
	var closet: DoorScript = DoorScript.new()
	add_child(closet)
	closet.initialize(apartment.get_node("Doors/ClosetDoor"), 270.0)
	var bedroom_door: DoorScript = DoorScript.new()
	add_child(bedroom_door)
	bedroom_door.initialize(apartment.get_node("Doors/BedroomDoor"), 270.0)
	endpoint = EndScript.new()
	endpoint.name = "BuildEndpoint"
	add_child(endpoint)
	endpoint.opened.connect(_endpoint_opened)
	endpoint.closed.connect(_endpoint_closed)
	wake = WakeScript.new()
	wake.name = "WakeSequence"
	add_child(wake)
	wake.initialize(player)
	wake.settled.connect(func() -> void: state.call("set_flag", "day1_awake", true))
	print("Day 1 morning ready — preserved apartment; state day=", state.get("data")["current_day"])

func _target(parent: Node3D, id: String, label: String, at: Vector3, extent: Vector3, callback: Callable) -> Target:
	var target: Target = Target.new()
	target.name = "Interact_" + id
	target.action_id = id
	target.prompt = label
	parent.add_child(target)
	target.position = at
	target.configure(extent)
	target.activated.connect(callback)
	return target

func _setup_targets() -> void:
	_book_prop = apartment.get_node("Rooms/Bedroom/Handbook")
	var book_target: Target = _target(_book_prop, "handbook", "Open handbook", Vector3(0, 0.07, 0), Vector3(0.24, 0.14, 0.31), _open_book)
	# Once it is in his pocket the prop and its prompt are both gone.
	var carried: bool = state.call("flag", "handbook_carried")
	_book_prop.visible = not carried
	book_target.enabled = not carried
	var reminder: Node3D = apartment.get_node("Rooms/Bedroom/NoteUnderPhoto")
	_target(reminder, "reminder", "Read", Vector3(0, 0, 0.03), Vector3(0.34, 0.44, 0.05), _read_reminder)
	_coffee_target = _target(apartment, "coffee", "Brew coffee", Vector3(8.26, 0.94, 0.16), Vector3(0.30, 0.34, 0.27), _coffee)
	# The window's latch is the smoke affordance; sill/cup is the coffee affordance.
	_smoke_target = _target(apartment, "window_smoke", "Smoke by the window", Vector3(8.28, 1.50, 1.99), Vector3(0.19, 0.42, 0.34), _smoke)
	_drink_target = _target(apartment, "window_coffee", "Look outside", Vector3(8.20, 1.05, 1.40), Vector3(0.21, 0.30, 0.52), _drink)
	_target(apartment, "leave", "Leave apartment", Vector3(3.80, 1.16, -0.08), Vector3(0.82, 1.80, 0.12), _leave)

func _process(_delta: float) -> void:
	if not is_instance_valid(ritual):
		return
	_coffee_target.prompt = ritual.coffee_prompt()
	_smoke_target.prompt = ritual.smoke_prompt()
	_drink_target.prompt = "Drink coffee" if state.call("morning_value", "coffee_state", "empty") == "carried" else "Look outside"
	if Input.is_action_just_pressed("handbook") and not wake.transitioning and not endpoint.is_open:
		if handbook.is_open:
			handbook.close_book()
		elif state.call("flag", "handbook_carried") and player.enabled:
			handbook.open_book()

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(endpoint) or not is_instance_valid(wake):
		return
	if not wake.in_bed and not endpoint.is_open and player.position.z < -0.04:
		_leave(null)

func _say(text: String) -> void:
	thoughts.say(text)

func _unhandled_input(event: InputEvent) -> void:
	# Read-only development probe; never moves Chris or mutates game state.
	if OS.is_debug_build() and event is InputEventKey and event.pressed and event.keycode == KEY_F9:
		print("Morning snapshot: position=", player.global_position, " yaw=", player.rotation.y, " camera=", player.camera.rotation, " target=", interactor.current_target.action_id if interactor.current_target != null else "none", " state=", state.get("data"))

func _log_interaction(target: Target) -> void:
	print("Interaction: ", target.action_id)

func _read_reminder(_hit: Target) -> void:
	if not state.call("flag", "reminder_read"):
		state.call("set_flag", "reminder_read", true)
		thoughts.say("The handbook.")
	else:
		thoughts.say("I should check it.")

func _open_book(_hit: Target) -> void:
	if wake.transitioning:
		return
	state.call("set_flag", "handbook_carried", true)
	_book_prop.hide()
	_hit.enabled = false
	handbook.open_book()

func _book_opened() -> void:
	ritual.cancel()
	player.enabled = false
	interactor.enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _book_closed() -> void:
	player.enabled = not wake.transitioning and not endpoint.is_open
	interactor.enabled = player.enabled
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _coffee(_hit: Target) -> void:
	ritual.coffee_interaction()

func _smoke(_hit: Target) -> void:
	ritual.smoke_interaction()

func _drink(_hit: Target) -> void:
	if state.call("morning_value", "coffee_state", "empty") == "carried":
		ritual.drink_interaction()
	else:
		state.call("set_morning", "window_visited", true)

func _leave(_hit: Target) -> void:
	if wake.in_bed or wake.transitioning or handbook.is_open:
		return
	state.call("set_flag", "day1_build_endpoint", true)
	endpoint.open()

func _endpoint_opened() -> void:
	ritual.cancel()
	player.enabled = false
	interactor.enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	print("Day 1 development endpoint — no world scene loaded")

func _endpoint_closed() -> void:
	player.position = Vector3(3.80, 0.04, 0.80)
	player.velocity = Vector3.ZERO
	player.enabled = true
	interactor.enabled = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
