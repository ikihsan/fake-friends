class_name BOBuildViews
extends RefCounted

## Builds the five verification cameras as tiny scenes that instance the
## apartment blockout, each with one camera aimed at a specific spot.
## They carry no logic - they exist so the blockout can be photographed and
## re-checked later.  Invoke via execute_script:  BOBuildViews.run()

const APT := "res://scenes/apartment_blockout.tscn"
const LIB := preload("res://tools/bo_lib.gd")

static func views() -> Array:
	return [
		{
			"file": "res://dev/views/00_overview_plan.tscn",
			"name": "View00OverviewPlan",
			"pos": Vector3(4.20, 8.60, 2.60),
			"target": Vector3(4.20, 0.00, 2.55),
			"up": Vector3(0, 0, -1),
			"apt": "res://dev/views/dollhouse_shell.tscn",
		},
		{
			"file": "res://dev/views/00b_overview_angle.tscn",
			"name": "View00bOverviewAngle",
			"pos": Vector3(11.0, 8.40, 11.5),
			"target": Vector3(3.60, 0.20, 2.40),
			"apt": "res://dev/views/dollhouse_shell.tscn",
		},
		{
			"file": "res://dev/views/01_wake_in_bed.tscn",
			"name": "View01WakeInBed",
			"pos": Vector3(6.50, 0.82, 0.55),   # head on the pillow, lying down
			"target": Vector3(6.50, 1.34, 3.50), # the framed photo + taped note
		},
		{
			"file": "res://dev/views/01b_photo_wall.tscn",
			"name": "View01bPhotoWall",
			"pos": Vector3(6.50, 1.55, 0.95),
			"target": Vector3(6.50, 1.42, 3.45),
		},
		{
			"file": "res://dev/views/02_bedroom_doorway.tscn",
			"name": "View02BedroomDoorway",
			"pos": Vector3(4.90, 1.65, 1.75),
			"target": Vector3(7.60, 1.15, 1.35),
		},
		{
			"file": "res://dev/views/03_hall_center.tscn",
			"name": "View03HallCenter",
			"pos": Vector3(2.25, 1.65, 1.70),
			"target": Vector3(2.70, 1.05, 5.20),
		},
		{
			"file": "res://dev/views/04_front_door.tscn",
			"name": "View04FrontDoor",
			"pos": Vector3(3.80, 1.65, 2.30),
			"target": Vector3(3.80, 1.25, -0.60),
		},
		{
			"file": "res://dev/views/06_bathroom.tscn",
			"name": "View06Bathroom",
			"pos": Vector3(3.35, 1.55, 3.82),
			"target": Vector3(4.10, 0.85, 4.85),
		},
		{
			"file": "res://dev/views/07_wardrobe_nook.tscn",
			"name": "View07WardrobeNook",
			"pos": Vector3(5.15, 1.50, 3.72),
			"target": Vector3(5.95, 0.95, 4.85),
		},
		{
			"file": "res://dev/views/05_landing.tscn",
			"name": "View05Landing",
			"pos": Vector3(7.60, 1.65, -1.05),
			"target": Vector3(-4.60, 1.30, -0.95),
		},
	]

static func run() -> int:
	var da := DirAccess.open("res://")
	if da != null:
		if not da.dir_exists("dev"):
			da.make_dir_recursive("dev")
		if not da.dir_exists("dev/views"):
			da.make_dir_recursive("dev/views")

	# extra pass: same blockout without the roof / ceiling slabs, so an overview
	# camera can look straight into the plan
	BOBuildApartment.omit_upper_cover = true
	BOBuildApartment.run("res://dev/views/dollhouse_shell.tscn")
	BOBuildApartment.omit_upper_cover = false

	var fails: int = 0
	for v in views():
		var root := Node3D.new()
		root.name = v["name"]

		var apt: String = v["apt"] if v.has("apt") else APT
		var ps: PackedScene = load(apt)
		if ps == null:
			print("cannot load ", apt)
			return 1
		var inst: Node3D = ps.instantiate()
		inst.name = "ApartmentBlockout"
		root.add_child(inst)

		# yield camera control to the vantage camera
		for c in _all_cameras(inst):
			c.current = false

		# optional: hide shell pieces so an overview can see inside
		if v.has("hide"):
			for hname in v["hide"]:
				var hn: Node = inst.find_child(hname, true, false)
				if hn is Node3D:
					hn.visible = false

		var cam := Camera3D.new()
		cam.name = "VantageCamera"
		cam.fov = 70.0
		cam.current = true
		root.add_child(cam)
		var up: Vector3 = v["up"] if v.has("up") else Vector3.UP
		cam.look_at_from_position(v["pos"], v["target"], up)

		LIB.fix_owners(root, root)
		var scene := PackedScene.new()
		var perr: int = scene.pack(root)
		if perr != OK:
			print("pack failed: ", v["file"], perr)
			fails += 1
			continue
		var serr: int = ResourceSaver.save(scene, v["file"])
		if serr != OK:
			print("save failed: ", v["file"], serr)
			fails += 1
		else:
			print("ok %s  pos=%s" % [v["file"], str(v["pos"])])
		root.free()
	print("view scenes built, failures=%d" % fails)
	return fails

static func _all_cameras(n: Node) -> Array:
	var out: Array = []
	if n is Camera3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_all_cameras(c))
	return out
