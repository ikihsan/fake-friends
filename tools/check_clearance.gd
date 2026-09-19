class_name BOCheckClearance
extends RefCounted

## Blockout sanity check: reports furniture / fittings whose world AABB overlaps
## a wall, floor or facade volume, which usually means a prefab is poking through
## a wall.  Invoke via execute_script:  BOCheckClearance.run()

const SCENE := "res://scenes/apartment_blockout.tscn"

## Shell pieces that furniture legitimately rests on or touches.
const IGNORE_SHELL := ["Ground", "FloorSlab_L1", "FloorSlab_L2", "Roof",
	"LandingSlab", "LandingCeiling", "FloorFinishes"]
## Object names that are deliberately fixed onto a wall surface (or are thin
## flat things laid on the floor), so touching a wall volume is intended.
const IGNORE_OBJECTS := ["Lamp", "Doormat", "Number", "Shoe", "Plant",
	"Socket", "Switch", "Mirror", "MedicineCabinet", "TowelHooks", "ToiletPaper",
	"Hook", "WallPhotograph", "NoteUnderPhoto", "WallClock", "CoatHooks",
	"BathMat", "Rug", "Meter", "ShowerCurtain", "Curtains"]

const MIN_VOLUME := 0.002

static func run() -> int:
	var ps: PackedScene = load(SCENE)
	if ps == null:
		print("cannot load ", SCENE)
		return 1
	var inst: Node3D = ps.instantiate()

	var shell: Array = []
	var objects: Array = []
	_collect(inst, Transform3D.IDENTITY, "", shell, objects)

	print("shell volumes: %d   objects checked: %d" % [shell.size(), objects.size()])
	var problems: int = 0
	for o in objects:
		var oa: AABB = o["aabb"]
		for s in shell:
			var sa: AABB = s["aabb"]
			var v: float = _overlap_volume(oa, sa)
			if v > MIN_VOLUME:
				print("OVERLAP %.3f m3 : %s  <->  %s" % [v, o["name"], s["name"]])
				problems += 1
				break
	if problems == 0:
		print("clearance check: no furniture/wall intersections")
	return problems

static func _collect(n: Node, xf: Transform3D, path: String, shell: Array, objects: Array) -> void:
	var t: Transform3D = xf
	if n is Node3D:
		t = xf * (n as Node3D).transform
	var p: String = path + "/" + String(n.name)

	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		var aabb: AABB = t * (n as MeshInstance3D).get_aabb()
		if _is_shell(p):
			shell.append({"name": p, "aabb": aabb})
		elif _is_object(n, p):
			objects.append({"name": p, "aabb": aabb})

	for c in n.get_children():
		_collect(c, t, p, shell, objects)

static func _is_shell(p: String) -> bool:
	if not p.contains("/Shell/") and not p.contains("/Exterior/"):
		return false
	for ig in IGNORE_SHELL:
		if p.contains("/" + ig + "/") or p.ends_with("/" + ig):
			return false
	return true

static func _is_object(n: Node, p: String) -> bool:
	if not (p.contains("/Rooms/") or p.contains("/Doors/")):
		return false
	for ig in IGNORE_OBJECTS:
		if p.contains(ig):
			return false
	return true

static func _overlap_volume(a: AABB, b: AABB) -> float:
	var mn: Vector3 = Vector3(maxf(a.position.x, b.position.x), maxf(a.position.y, b.position.y),
		maxf(a.position.z, b.position.z))
	var mx: Vector3 = Vector3(minf(a.end.x, b.end.x), minf(a.end.y, b.end.y),
		minf(a.end.z, b.end.z))
	var d: Vector3 = mx - mn
	if d.x <= 0.01 or d.y <= 0.01 or d.z <= 0.01:
		return 0.0
	return d.x * d.y * d.z
