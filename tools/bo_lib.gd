class_name BOLib
extends RefCounted

## Blockout library.
##
## Shared material table, primitive builders (box / cylinder / light / wall run)
## and the modular prefab definitions used by tools/build_prefabs.gd and
## tools/build_apartment.gd.
##
## CONVENTIONS
##  - Metric units. Y is up, floor of the apartment is Y = 0.
##  - Prefabs are modelled around their own origin: floor at y = 0, and any
##    prefab that faces a direction faces +Z ("back" side sits at -Z).
##    Place with BOLib.place(root, path, name, pos, yaw) where
##    yaw 0 = back against a wall on the low-Z side (front looks +Z),
##    yaw 180 = back against a wall on the high-Z side,
##    yaw 90 = back against a wall on the low-X side, front looks +X,
##    yaw -90 = back against a wall on the high-X side, front looks -X.
##  - Boxes with a rotation get their own BoxMesh (unit-mesh + node scale is
##    only used for axis aligned boxes, where scale/rotation order is moot).

const MAT_DIR := "res://materials/"

const MAT := {
	# architecture
	"wall": "mat_wall.tres",
	"floor_wood": "mat_floor_wood.tres",
	"floor_tile": "mat_floor_tile.tres",
	"tile_wall": "mat_tile_wall.tres",
	"ceiling": "mat_ceiling.tres",
	"concrete": "mat_concrete.tres",
	"ground": "mat_ground.tres",
	"paint_white": "mat_paint_white.tres",
	"door": "mat_door.tres",
	# timber and textiles
	"wood": "mat_wood.tres",
	"wood_light": "mat_wood_light.tres",
	"fabric": "mat_fabric.tres",
	"bedding": "mat_bedding.tres",
	"bedding_warm": "mat_bedding_warm.tres",
	"curtain": "mat_curtain.tres",
	"towel": "mat_towel.tres",
	"rug": "mat_rug.tres",
	"plant": "mat_plant.tres",
	# hard surfaces and fittings
	"ceramic": "mat_ceramic.tres",
	"porcelain_used": "mat_porcelain_used.tres",
	"glass": "mat_glass.tres",
	"water": "mat_water.tres",
	"mirror": "mat_mirror.tres",
	"metal": "mat_metal.tres",
	"metal_dark": "mat_metal_dark.tres",
	"plastic": "mat_plastic.tres",
	"plastic_dark": "mat_plastic_dark.tres",
	"dark": "mat_dark.tres",
	"ink": "mat_ink.tres",
	"pot": "mat_pot.tres",
	"lamp_glow": "mat_lamp_glow.tres",
	"screen": "mat_screen.tres",
	# paper, covers and art
	"paper": "mat_paper.tres",
	"tape": "mat_tape.tres",
	"book_cover": "mat_book_cover.tres",
	"book_cover_rust": "mat_book_cover_rust.tres",
	"photo": "mat_photo.tres",
}

static var _unit_box: BoxMesh

# ---------------------------------------------------------------- materials --

static func _unit_mesh() -> BoxMesh:
	if _unit_box == null:
		_unit_box = BoxMesh.new()
		_unit_box.size = Vector3.ONE
	return _unit_box

static func mat(key: String) -> Material:
	if not MAT.has(key):
		push_error("BOLib: unknown material key '%s'" % key)
		return null
	return load(MAT_DIR + MAT[key])

# --------------------------------------------------------------- primitives --

static func box(parent: Node3D, name: String, mat_key: String, pos: Vector3,
		size: Vector3, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	if rot_deg == Vector3.ZERO:
		mi.mesh = _unit_mesh()
		mi.scale = size
	else:
		var bm := BoxMesh.new()
		bm.size = size
		mi.mesh = bm
		mi.rotation_degrees = rot_deg
	mi.position = pos
	mi.material_override = mat(mat_key)
	parent.add_child(mi)
	return mi

static func cyl(parent: Node3D, name: String, mat_key: String, pos: Vector3,
		radius: float, height: float, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = height
	cm.radial_segments = 12
	cm.rings = 1
	mi.mesh = cm
	mi.rotation_degrees = rot_deg
	mi.position = pos
	mi.material_override = mat(mat_key)
	parent.add_child(mi)
	return mi

static func label3d(parent: Node3D, name: String, text: String, pos: Vector3,
		rot_deg: Vector3, pixel_size: float, font_size: int, col: Color,
		shaded: bool = false) -> Label3D:
	var lb := Label3D.new()
	lb.name = name
	lb.text = text
	lb.position = pos
	lb.rotation_degrees = rot_deg
	lb.pixel_size = pixel_size
	lb.font_size = font_size
	lb.modulate = col
	lb.shaded = shaded
	lb.outline_size = 0
	lb.double_sided = false
	lb.no_depth_test = false
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	parent.add_child(lb)
	return lb

static func omni(parent: Node3D, name: String, pos: Vector3, energy: float,
		light_range: float, col: Color, shadows: bool) -> OmniLight3D:
	var li := OmniLight3D.new()
	li.name = name
	li.position = pos
	li.light_energy = energy
	li.omni_range = light_range
	li.light_color = col
	li.shadow_enabled = shadows
	parent.add_child(li)
	return li

## Static box collider: a StaticBody3D holding one BoxShape3D of the given size.
static func collider(parent: Node3D, name: String, pos: Vector3, size: Vector3) -> StaticBody3D:
	var sb := StaticBody3D.new()
	sb.name = name
	sb.position = pos
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	sb.add_child(cs)
	parent.add_child(sb)
	return sb

## Give every descendant (and instanced-scene root) of `n` the given owner so a
## PackedScene can be packed from the tree. Instanced scene interiors are left
## alone - their own owner chain must stay intact.
static func fix_owners(n: Node, root: Node) -> void:
	for c in n.get_children():
		c.owner = root
		if c.scene_file_path.is_empty():
			fix_owners(c, root)

## Instance a prefab scene and orient it.
static func place(root: Node3D, prefab: String, name: String, pos: Vector3,
		yaw_deg: float = 0.0, extra_rot: Vector3 = Vector3.ZERO) -> Node3D:
	var ps: PackedScene = load("res://prefabs/%s.tscn" % prefab)
	if ps == null:
		push_error("BOLib.place: missing prefab '%s'" % prefab)
		return null
	var inst: Node3D = ps.instantiate()
	inst.name = name
	inst.position = pos
	inst.rotation_degrees = Vector3(extra_rot.x, yaw_deg + extra_rot.y, extra_rot.z)
	root.add_child(inst)
	return inst

# --------------------------------------------------------- walls and floors --

## Build a wall run as a group of boxes, cutting rectangular openings out of it.
## axis "x": wall runs along X (a0..a1), thickness spans Z (b0..b1).
## axis "z": wall runs along Z (a0..a1), thickness spans X (b0..b1).
## openings: Array of [a_start, a_end, y_start, y_end].
## Returns the container node (meshes + one StaticBody3D with a shape per piece).
static func wall(parent: Node3D, name: String, mat_key: String, axis: String,
		a0: float, a1: float, b0: float, b1: float, y0: float, y1: float,
		openings: Array = [], collide: bool = true) -> Node3D:
	var cont := Node3D.new()
	cont.name = name
	parent.add_child(cont)

	var segs: Array = []
	var sorted_ops: Array = openings.duplicate()
	sorted_ops.sort_custom(func(x, y): return x[0] < y[0])
	var cur: float = a0
	for o in sorted_ops:
		var oa0: float = o[0]
		var oa1: float = o[1]
		var oy0: float = o[2]
		var oy1: float = o[3]
		if oa0 > cur:
			segs.append([cur, oa0, y0, y1])
		if oy0 > y0:
			segs.append([oa0, oa1, y0, oy0])
		if oy1 < y1:
			segs.append([oa0, oa1, oy1, y1])
		cur = maxf(cur, oa1)
	if cur < a1:
		segs.append([cur, a1, y0, y1])

	var body := StaticBody3D.new()
	body.name = "Body"
	cont.add_child(body)
	var i: int = 0
	for s in segs:
		var ac: float = (s[0] + s[1]) * 0.5
		var yc: float = (s[2] + s[3]) * 0.5
		var sa: float = s[1] - s[0]
		var sy: float = s[3] - s[2]
		var pos: Vector3
		var size: Vector3
		if axis == "x":
			pos = Vector3(ac, yc, (b0 + b1) * 0.5)
			size = Vector3(sa, sy, b1 - b0)
		else:
			pos = Vector3((b0 + b1) * 0.5, yc, ac)
			size = Vector3(b1 - b0, sy, sa)
		box(cont, "Seg%d" % i, mat_key, pos, size)
		if collide:
			var cs := CollisionShape3D.new()
			cs.name = "Shape%d" % i
			var shape := BoxShape3D.new()
			shape.size = size
			cs.shape = shape
			cs.position = pos
			body.add_child(cs)
		i += 1
	return cont

## A floor / ceiling slab (one box + one static collider).
static func slab(parent: Node3D, name: String, mat_key: String, x0: float, x1: float,
		z0: float, z1: float, y_top: float, thickness: float, collide: bool = true) -> Node3D:
	var cont := Node3D.new()
	cont.name = name
	parent.add_child(cont)
	var size := Vector3(x1 - x0, thickness, z1 - z0)
	var pos := Vector3((x0 + x1) * 0.5, y_top - thickness * 0.5, (z0 + z1) * 0.5)
	box(cont, "Slab", mat_key, pos, size)
	if collide:
		collider(cont, "Body", pos, size)
	return cont

# ---------------------------------------------------------------- light rig --
# Sky, sun and ambient are owned by scripts/lighting/ (WorldLighting +
# LightingPreset), so that morning / day / evening / night stay swappable.

# ------------------------------------------------------------------ prefabs --

## The original blockout prefab table.  Kept as the base layer: the art pass in
## tools/bo_prefabs.gd overrides individual entries (bed, sofa, toilet, ...) and
## adds the lived-in props.  See prefab_defs() below.
static func _blockout_defs() -> Dictionary:
	return {
		"bed": {
			"boxes": [
				["Frame", "wood", Vector3(0, 0.16, 0), Vector3(1.40, 0.32, 2.00)],
				["Mattress", "bedding", Vector3(0, 0.46, 0), Vector3(1.30, 0.28, 1.90)],
				["Duvet", "fabric", Vector3(0, 0.62, 0.35), Vector3(1.34, 0.10, 1.28)],
				["PillowL", "bedding", Vector3(-0.33, 0.67, -0.72), Vector3(0.52, 0.14, 0.34)],
				["PillowR", "bedding", Vector3(0.33, 0.67, -0.72), Vector3(0.52, 0.14, 0.34)],
				["Headboard", "wood", Vector3(0, 0.62, -1.02), Vector3(1.40, 1.24, 0.06)],
			],
			"collision": [Vector3(0, 0.34, 0), Vector3(1.40, 0.68, 2.10)],
		},
		"bedside_table": {
			"boxes": [
				["Body", "wood", Vector3(0, 0.25, 0), Vector3(0.45, 0.50, 0.45)],
				["Top", "wood_light", Vector3(0, 0.52, 0), Vector3(0.49, 0.04, 0.49)],
				["Drawer", "dark", Vector3(0, 0.34, 0.24), Vector3(0.36, 0.14, 0.02)],
				["Knob", "metal", Vector3(0, 0.34, 0.26), Vector3(0.03, 0.03, 0.02)],
			],
			"collision": [Vector3(0, 0.28, 0), Vector3(0.49, 0.56, 0.45)],
		},
		# "handbook" is defined in tools/bo_prefabs.gd (art pass).
		"table_lamp": {
			"boxes": [
				["Base", "metal", Vector3(0, 0.02, 0), Vector3(0.15, 0.04, 0.15)],
				["Stem", "metal", Vector3(0, 0.17, 0), Vector3(0.03, 0.26, 0.03)],
				["Shade", "lamp_glow", Vector3(0, 0.38, 0), Vector3(0.24, 0.20, 0.24)],
			],
			"lights": [[Vector3(0, 0.38, 0), 0.9, 3.5, Color(1.0, 0.87, 0.7), false]],
		},
		"ceiling_fan": {
			"boxes": [
				["Rod", "metal", Vector3(0, -0.10, 0), Vector3(0.035, 0.20, 0.035)],
				["Motor", "metal", Vector3(0, -0.24, 0), Vector3(0.26, 0.12, 0.26)],
				["Globe", "lamp_glow", Vector3(0, -0.35, 0), Vector3(0.17, 0.11, 0.17)],
				["Blade0", "wood_light", Vector3(0.36, -0.28, 0), Vector3(0.62, 0.02, 0.14)],
				["Blade1", "wood_light", Vector3(-0.18, -0.28, 0.31), Vector3(0.62, 0.02, 0.14),
					Vector3(0, 120, 0)],
				["Blade2", "wood_light", Vector3(-0.18, -0.28, -0.31), Vector3(0.62, 0.02, 0.14),
					Vector3(0, 240, 0)],
			],
			"lights": [[Vector3(0, -0.42, 0), 1.5, 7.0, Color(1.0, 0.9, 0.76), true]],
		},
		"desk": {
			"boxes": [
				["Top", "wood_light", Vector3(0, 0.74, 0), Vector3(1.20, 0.04, 0.60)],
				["SideL", "wood", Vector3(-0.56, 0.37, 0), Vector3(0.06, 0.74, 0.56)],
				["SideR", "wood", Vector3(0.56, 0.37, 0), Vector3(0.06, 0.74, 0.56)],
				["BackPanel", "wood", Vector3(0, 0.48, -0.28), Vector3(1.06, 0.40, 0.03)],
				["LaptopBase", "dark", Vector3(0.12, 0.78, 0.06), Vector3(0.32, 0.02, 0.22)],
				["LaptopLid", "dark", Vector3(0.12, 0.89, -0.04), Vector3(0.32, 0.22, 0.02)],
				["Mug", "ceramic", Vector3(-0.30, 0.79, 0.10), Vector3(0.08, 0.10, 0.08)],
			],
			"collision": [Vector3(0, 0.38, 0), Vector3(1.20, 0.76, 0.60)],
		},
		"chair": {
			"boxes": [
				["Seat", "wood", Vector3(0, 0.45, 0), Vector3(0.45, 0.06, 0.45)],
				["Backrest", "wood", Vector3(0, 0.76, -0.20), Vector3(0.45, 0.52, 0.05)],
				["Leg0", "wood", Vector3(-0.18, 0.21, 0.18), Vector3(0.05, 0.42, 0.05)],
				["Leg1", "wood", Vector3(0.18, 0.21, 0.18), Vector3(0.05, 0.42, 0.05)],
				["Leg2", "wood", Vector3(-0.18, 0.21, -0.18), Vector3(0.05, 0.42, 0.05)],
				["Leg3", "wood", Vector3(0.18, 0.21, -0.18), Vector3(0.05, 0.42, 0.05)],
			],
			"collision": [Vector3(0, 0.45, 0), Vector3(0.45, 0.92, 0.45)],
		},
		"wardrobe_unit": {
			"boxes": [
				["Carcass", "wood", Vector3(0, 1.00, 0), Vector3(1.20, 2.00, 0.60)],
				["DoorL", "door", Vector3(-0.29, 1.00, 0.31), Vector3(0.58, 1.90, 0.03)],
				["DoorR", "door", Vector3(0.29, 1.00, 0.31), Vector3(0.58, 1.90, 0.03)],
				["HandleL", "metal", Vector3(0.06, 1.05, 0.34), Vector3(0.02, 0.16, 0.03)],
				["HandleR", "metal", Vector3(-0.06, 1.05, 0.34), Vector3(0.02, 0.16, 0.03)],
			],
			"collision": [Vector3(0, 1.00, 0), Vector3(1.20, 2.00, 0.62)],
		},
		"hang_rail": {
			"boxes": [
				["SideL", "wood", Vector3(-0.53, 1.00, 0), Vector3(0.04, 2.00, 0.55)],
				["SideR", "wood", Vector3(0.53, 1.00, 0), Vector3(0.04, 2.00, 0.55)],
				["Top", "wood", Vector3(0, 1.97, 0), Vector3(1.10, 0.06, 0.55)],
				["Back", "wood", Vector3(0, 1.00, -0.27), Vector3(1.10, 2.00, 0.02)],
				["Shirt1", "fabric", Vector3(-0.36, 1.28, 0), Vector3(0.20, 0.86, 0.36)],
				["Shirt2", "bedding", Vector3(-0.12, 1.28, 0), Vector3(0.20, 0.86, 0.36)],
				["Shirt3", "door", Vector3(0.12, 1.28, 0), Vector3(0.20, 0.86, 0.36)],
				["Shirt4", "bedding", Vector3(0.36, 1.28, 0), Vector3(0.20, 0.86, 0.36)],
			],
			"cyls": [["Rail", "metal", Vector3(0, 1.72, 0), 0.02, 1.00, Vector3(0, 0, 90)]],
			"collision": [Vector3(0, 1.00, 0), Vector3(1.10, 2.00, 0.57)],
		},
		"mirror_full": {
			"boxes": [
				["Frame", "wood", Vector3(0, 0, 0), Vector3(0.80, 1.80, 0.06)],
				["Glass", "mirror", Vector3(0, 0, 0.04), Vector3(0.70, 1.70, 0.01)],
			],
		},
		"laundry_basket": {
			"boxes": [
				["Body", "fabric", Vector3(0, 0.31, 0), Vector3(0.40, 0.62, 0.40)],
				["Rim", "door", Vector3(0, 0.63, 0), Vector3(0.44, 0.04, 0.44)],
				["Clothes", "bedding", Vector3(0, 0.68, 0), Vector3(0.34, 0.10, 0.34)],
			],
			"collision": [Vector3(0, 0.33, 0), Vector3(0.44, 0.66, 0.44)],
		},
		"sofa": {
			"boxes": [
				["Base", "fabric", Vector3(0, 0.22, 0), Vector3(1.60, 0.44, 0.90)],
				["Back", "fabric", Vector3(0, 0.64, -0.32), Vector3(1.60, 0.60, 0.26)],
				["ArmL", "fabric", Vector3(-0.72, 0.52, 0), Vector3(0.16, 0.60, 0.90)],
				["ArmR", "fabric", Vector3(0.72, 0.52, 0), Vector3(0.16, 0.60, 0.90)],
				["CushionL", "bedding", Vector3(-0.42, 0.50, 0.08), Vector3(0.66, 0.14, 0.58)],
				["CushionR", "bedding", Vector3(0.42, 0.50, 0.08), Vector3(0.66, 0.14, 0.58)],
			],
			"collision": [Vector3(0, 0.45, 0), Vector3(1.60, 0.92, 0.90)],
		},
		"coffee_table": {
			"boxes": [
				["Top", "wood_light", Vector3(0, 0.40, 0), Vector3(0.80, 0.04, 0.60)],
				["Leg0", "wood", Vector3(-0.34, 0.19, 0.24), Vector3(0.05, 0.38, 0.05)],
				["Leg1", "wood", Vector3(0.34, 0.19, 0.24), Vector3(0.05, 0.38, 0.05)],
				["Leg2", "wood", Vector3(-0.34, 0.19, -0.24), Vector3(0.05, 0.38, 0.05)],
				["Leg3", "wood", Vector3(0.34, 0.19, -0.24), Vector3(0.05, 0.38, 0.05)],
				["Magazine", "paint_white", Vector3(0.16, 0.43, 0.02), Vector3(0.18, 0.02, 0.24)],
				["Mug", "ceramic", Vector3(-0.20, 0.46, -0.08), Vector3(0.08, 0.09, 0.08)],
			],
			"collision": [Vector3(0, 0.21, 0), Vector3(0.80, 0.42, 0.60)],
		},
		"tv_unit": {
			"boxes": [
				["Carcass", "wood", Vector3(0, 0.25, 0), Vector3(1.30, 0.50, 0.45)],
				["Top", "wood_light", Vector3(0, 0.51, 0), Vector3(1.34, 0.03, 0.49)],
				["Stand", "dark", Vector3(0, 0.58, 0), Vector3(0.24, 0.12, 0.18)],
				["TVBody", "dark", Vector3(0, 0.86, 0), Vector3(0.94, 0.56, 0.07)],
				["Screen", "screen", Vector3(0, 0.87, 0.045), Vector3(0.86, 0.48, 0.01)],
			],
			"collision": [Vector3(0, 0.30, 0), Vector3(1.30, 0.62, 0.45)],
		},
		"wall_clock": {
			"cyls": [
				["Body", "wood", Vector3(0, 0, 0.03), 0.15, 0.06, Vector3(90, 0, 0)],
				["Face", "paint_white", Vector3(0, 0, 0.062), 0.13, 0.01, Vector3(90, 0, 0)],
				["HandH", "metal", Vector3(0, 0, 0.072), 0.008, 0.10, Vector3(0, 0, 0)],
				["HandV", "metal", Vector3(0.02, 0, 0.072), 0.008, 0.07, Vector3(0, 0, 90)],
			],
		},
		"shoe_rack": {
			"boxes": [
				["SideL", "wood", Vector3(-0.44, 0.42, 0), Vector3(0.04, 0.84, 0.35)],
				["SideR", "wood", Vector3(0.44, 0.42, 0), Vector3(0.04, 0.84, 0.35)],
				["ShelfLow", "wood", Vector3(0, 0.06, 0), Vector3(0.84, 0.04, 0.35)],
				["ShelfMid", "wood", Vector3(0, 0.40, 0), Vector3(0.84, 0.04, 0.35)],
				["ShelfTop", "wood_light", Vector3(0, 0.84, 0), Vector3(0.90, 0.04, 0.35)],
				["Shoe1", "dark", Vector3(-0.22, 0.11, 0), Vector3(0.13, 0.09, 0.28)],
				["Shoe2", "dark", Vector3(0.24, 0.11, 0.02), Vector3(0.13, 0.09, 0.28)],
				["Shoe3", "dark", Vector3(-0.18, 0.45, 0), Vector3(0.13, 0.09, 0.28)],
			],
			"collision": [Vector3(0, 0.43, 0), Vector3(0.90, 0.86, 0.35)],
		},
		"coat_hooks": {
			"boxes": [
				["Board", "wood", Vector3(0, 0, 0), Vector3(0.70, 0.12, 0.03)],
				["Hook0", "metal", Vector3(-0.25, -0.03, 0.05), Vector3(0.02, 0.10, 0.07)],
				["Hook1", "metal", Vector3(0, -0.03, 0.05), Vector3(0.02, 0.10, 0.07)],
				["Hook2", "metal", Vector3(0.25, -0.03, 0.05), Vector3(0.02, 0.10, 0.07)],
				["Coat", "fabric", Vector3(-0.22, -0.46, 0.07), Vector3(0.34, 0.80, 0.06)],
				["Scarf", "bedding", Vector3(0.24, -0.36, 0.07), Vector3(0.18, 0.60, 0.05)],
			],
		},
		"sink_unit": {
			"boxes": [
				["Basin", "ceramic", Vector3(0, 0.82, 0), Vector3(0.55, 0.14, 0.45)],
				["Pedestal", "ceramic", Vector3(0, 0.40, 0), Vector3(0.18, 0.76, 0.18)],
				["Tap", "metal", Vector3(0, 0.92, -0.15), Vector3(0.04, 0.12, 0.04)],
				["Spout", "metal", Vector3(0, 0.97, -0.08), Vector3(0.03, 0.03, 0.14)],
			],
			"collision": [Vector3(0, 0.45, 0), Vector3(0.55, 0.90, 0.45)],
		},
		"toilet": {
			"boxes": [
				["Tank", "ceramic", Vector3(0, 0.72, -0.26), Vector3(0.42, 0.40, 0.18)],
				["Bowl", "ceramic", Vector3(0, 0.40, 0.04), Vector3(0.38, 0.40, 0.52)],
				["Seat", "ceramic", Vector3(0, 0.62, 0.04), Vector3(0.40, 0.05, 0.48)],
				["Base", "ceramic", Vector3(0, 0.15, 0.06), Vector3(0.24, 0.30, 0.36)],
			],
			"collision": [Vector3(0, 0.35, 0), Vector3(0.42, 0.92, 0.70)],
		},
		"shower_unit": {
			"boxes": [
				["Tray", "ceramic", Vector3(0, 0.045, 0), Vector3(0.90, 0.09, 0.90)],
				["Mixer", "metal", Vector3(0, 1.05, -0.42), Vector3(0.16, 0.06, 0.06)],
				["Head", "metal", Vector3(0, 1.86, -0.34), Vector3(0.10, 0.03, 0.16)],
			],
			"cyls": [["Riser", "metal", Vector3(0, 1.45, -0.42), 0.015, 0.80, Vector3.ZERO]],
			"collision": [Vector3(0, 0.05, 0), Vector3(0.90, 0.10, 0.90)],
		},
		"medicine_cabinet": {
			"boxes": [
				["Body", "paint_white", Vector3(0, 0, 0), Vector3(0.55, 0.45, 0.16)],
				["Door", "mirror", Vector3(0, 0, 0.085), Vector3(0.50, 0.40, 0.01)],
				["Handle", "metal", Vector3(0.20, 0, 0.10), Vector3(0.02, 0.08, 0.02)],
			],
		},
		"wall_mirror": {
			"boxes": [
				["Frame", "metal", Vector3(0, 0, 0), Vector3(0.58, 0.73, 0.03)],
				["Glass", "mirror", Vector3(0, 0, 0.02), Vector3(0.52, 0.67, 0.01)],
			],
		},
		"towel_hooks": {
			"boxes": [
				["Rail", "metal", Vector3(0, 0, 0), Vector3(0.50, 0.03, 0.06)],
				["Towel1", "bedding", Vector3(-0.12, -0.36, 0.05), Vector3(0.20, 0.72, 0.02)],
				["Towel2", "fabric", Vector3(0.15, -0.32, 0.05), Vector3(0.16, 0.64, 0.02)],
			],
		},
		"plant_pot": {
			"boxes": [
				["Pot", "door", Vector3(0, 0.16, 0), Vector3(0.32, 0.32, 0.32)],
				["Soil", "dark", Vector3(0, 0.33, 0), Vector3(0.26, 0.03, 0.26)],
				["Foliage", "plant", Vector3(0, 0.54, 0), Vector3(0.44, 0.42, 0.44)],
				["Foliage2", "plant", Vector3(0.03, 0.78, -0.02), Vector3(0.30, 0.30, 0.30),
					Vector3(0, 38, 0)],
				["Foliage3", "plant", Vector3(-0.06, 0.90, 0.05), Vector3(0.20, 0.22, 0.20)],
			],
		},
		"shoes_pair": {
			"boxes": [
				["ShoeL", "dark", Vector3(-0.09, 0.045, 0), Vector3(0.12, 0.09, 0.26)],
				["ShoeR", "dark", Vector3(0.09, 0.045, 0), Vector3(0.12, 0.09, 0.26)],
			],
		},
		"doormat": {
			"boxes": [
				["Mat", "fabric", Vector3(0, 0.015, 0), Vector3(0.60, 0.03, 0.90)],
			],
		},
		"wall_lamp_ext": {
			"boxes": [
				["Bracket", "metal", Vector3(0, 0.08, -0.05), Vector3(0.06, 0.06, 0.10)],
				["Housing", "metal", Vector3(0, 0, 0.05), Vector3(0.20, 0.10, 0.18)],
				["Lens", "lamp_glow", Vector3(0, -0.06, 0.05), Vector3(0.17, 0.03, 0.15)],
			],
			"lights": [[Vector3(0, -0.22, 0.12), 1.4, 7.0, Color(1.0, 0.88, 0.72), false]],
		},
		"photo_frame": {
			"boxes": [
				["Frame", "wood", Vector3(0, 0, 0), Vector3(0.62, 0.46, 0.04)],
				["MatBoard", "bedding", Vector3(0, 0, 0.022), Vector3(0.56, 0.40, 0.008)],
				["Photo", "dark", Vector3(0, 0, 0.030), Vector3(0.46, 0.32, 0.012)],
			],
		},
		# "reminder" is defined in tools/bo_prefabs.gd (art pass).
	}

## The complete prefab table: blockout base, overridden and extended by the
## art-pass data in tools/bo_prefabs.gd.
static func prefab_defs() -> Dictionary:
	var d: Dictionary = _blockout_defs()
	d.merge(BOPrefabs.defs(), true)
	return d

## Build one prefab tree (root Node3D, floor at y = 0).
static func build_prefab(key: String) -> Node3D:
	var defs: Dictionary = prefab_defs()
	if not defs.has(key):
		push_error("BOLib.build_prefab: unknown prefab '%s'" % key)
		return null
	var d: Dictionary = defs[key]
	var root := Node3D.new()
	root.name = key
	if d.has("boxes"):
		var bi: int = 0
		for b in d["boxes"]:
			var rot: Vector3 = b[4] if b.size() > 4 else Vector3.ZERO
			box(root, "B%d_%s" % [bi, b[0]], b[1], b[2], b[3], rot)
			bi += 1
	if d.has("cyls"):
		var ci: int = 0
		for c in d["cyls"]:
			var rot: Vector3 = c[5] if c.size() > 5 else Vector3.ZERO
			cyl(root, "C%d_%s" % [ci, c[0]], c[1], c[2], c[3], c[4], rot)
			ci += 1
	if d.has("labels"):
		var li: int = 0
		for l in d["labels"]:
			var shaded: bool = l[6] if l.size() > 6 else false
			label3d(root, "L%d" % li, l[0], l[1], l[2], l[3], l[4], l[5], shaded)
			li += 1
	if d.has("lights"):
		var oi: int = 0
		for o in d["lights"]:
			omni(root, "O%d" % oi, o[0], o[1], o[2], o[3], o[4])
			oi += 1
	if d.has("collision"):
		collider(root, "Collision", d["collision"][0], d["collision"][1])
	return root
