extends Node

const Interactable = preload("res://scripts/gameplay/interaction/interactable.gd")
const Controller = preload("res://scripts/gameplay/player/first_person.gd")
const Interactor = preload("res://scripts/gameplay/interaction/interactor.gd")

func test_hitbox_and_activation_gates() -> void:
	var target: Interactable = Interactable.new()
	target.configure(Vector3.ONE)
	target.configure(Vector3(2, 3, 4), Vector3.UP)
	assert(target.get_child_count() == 1)
	assert(target.collision_layer == 2 and target.collision_mask == 0)
	assert(not target.monitoring)
	assert(target.get_child(0).shape.size == Vector3(2, 3, 4))
	var calls: Array[int] = [0]
	target.activated.connect(func(_target): calls[0] += 1)
	target.busy = true
	target.interact()
	target.busy = false
	target.enabled = false
	target.interact()
	assert(calls[0] == 0)
	target.enabled = true
	target.interact()
	assert(calls[0] == 1)
	target.free()

func test_explicit_runtime_initialization_and_locks() -> void:
	var body: CharacterBody3D = CharacterBody3D.new()
	var cam: Camera3D = Camera3D.new()
	cam.name = "PlayerCamera"
	body.add_child(cam)
	body.set_script(Controller)
	body.enabled = false
	body.initialize()
	assert(body.camera == cam)
	body.velocity = Vector3.ONE
	body._physics_process(0.1)
	assert(body.velocity == Vector3.ZERO)
	body.enabled = true
	body.movement_enabled = false
	body.velocity = Vector3.ONE
	body._physics_process(0.1)
	assert(body.velocity == Vector3.ZERO)
	var interactor: Interactor = Interactor.new()
	interactor.initialize(cam, body)
	assert(interactor.camera == cam and interactor.player == body)
	assert(InputMap.has_action("interact"))
	interactor.free()
	body.free()
