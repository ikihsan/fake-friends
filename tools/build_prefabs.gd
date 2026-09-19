class_name BOBuildPrefabs
extends RefCounted

## Generates every modular blockout prefab into res://prefabs/.
## Invoke via execute_script:  BOBuildPrefabs.run()

const LIB := preload("res://tools/bo_lib.gd")

static func run() -> int:
	var da := DirAccess.open("res://")
	if da != null and not da.dir_exists("prefabs"):
		da.make_dir_recursive("prefabs")

	var defs: Dictionary = LIB.prefab_defs()
	var keys: Array = defs.keys()
	keys.sort()
	var ok_count: int = 0
	for k in keys:
		var root: Node3D = LIB.build_prefab(k)
		if root == null:
			print("FAIL build: ", k)
			continue
		LIB.fix_owners(root, root)
		var ps := PackedScene.new()
		var perr: int = ps.pack(root)
		if perr != OK:
			print("FAIL pack: %s (%d)" % [k, perr])
			continue
		var path := "res://prefabs/%s.tscn" % k
		var serr: int = ResourceSaver.save(ps, path)
		if serr != OK:
			print("FAIL save: %s (%d)" % [k, serr])
			continue
		print("ok %-18s nodes=%d" % [k, _count(root)])
		root.free()
		ok_count += 1

	print("---")
	print("prefabs written: %d / %d" % [ok_count, keys.size()])

	# verify each file loads back
	var bad: int = 0
	for k in keys:
		var p := "res://prefabs/%s.tscn" % k
		if not ResourceLoader.exists(p):
			print("MISSING after save: ", p)
			bad += 1
			continue
		var scn: PackedScene = load(p)
		if scn == null:
			print("UNLOADABLE: ", p)
			bad += 1
			continue
		var inst: Node = scn.instantiate()
		if inst == null:
			print("NO INSTANTIATE: ", p)
			bad += 1
			continue
		print("load ok %-18s nodes=%d" % [k, _count(inst)])
		inst.free()
	print("verify failures: %d" % bad)
	return bad

static func _count(n: Node) -> int:
	var c: int = 1
	for ch in n.get_children():
		c += _count(ch)
	return c
