class_name BOBuildApartment
extends RefCounted

## Builds the modular blockout of the first-floor apartment + external landing,
## staircase and building shell, then saves it as res://scenes/apartment_blockout.tscn
##
## Invoke via execute_script:  BOBuildApartment.run()
##
## PLAN (all metres, interior face coordinates, apartment floor at Y = 0)
##
##   Z ^          party wall                                    east facade
##     |   +----------------+-----------------------+---------------+
##  0.0|   |  HALL 4.5x3.5  |      BEDROOM          |               |
##     |   |  (tv, sofa,    |      3.8x3.5          |   window      |
##     |   |   bathroom <-  |  bed / desk / photo   |               |
##  3.5|   |   window ^     +-----------------------+---------------+
##     |   |   living ext  | BATH 2.15x1.7 |NOOK 1.8x1.7| CLOSET    |
##  5.35   +---------------+-------+-------+------------+-----------+
##        X=0            2.2     2.35    4.5/4.65    6.45/6.6     8.45
##
## Front door is in the north facade (the landing corridor side).

const LIB := preload("res://tools/bo_lib.gd")
const WL := preload("res://scripts/lighting/world_lighting.gd")

## When true the second-floor slab, the roof and the landing ceiling are left
## out, so a camera above the building can see straight into the blockout
## ("dollhouse" pass). Set temporarily by tools/build_views.gd.
static var omit_upper_cover: bool = false

# ---- heights and thicknesses
const CEIL := 2.60
const DOOR_H := 2.10
const T_INT := 0.15
const T_EXT := 0.25
const SILL := 0.90
const HEAD := 2.10

# ---- interior X grid
const XW := 0.00        # west interior face (party wall)
const X_BATH_E := 4.50  # bathroom east interior face
const X_WARD_W := 4.65  # wardrobe nook west interior face
const X_NOOK_E := 6.45  # wardrobe nook east interior face
const X_CLO_W := 6.60   # closet west interior face
const XE := 8.45        # east interior face

# ---- interior Z grid
const ZN := 0.00        # north interior face (facade, front door)
const Z_HALL_S := 3.50  # hall / bedroom south interior face
const Z_SB_N := 3.65    # south band north face
const ZS := 5.35        # south interior face

# ---- building shell
const BLDG_W := -4.80   # west outer face of the whole building
const BLDG_E := 8.70    # east outer face
const FACADE_N := -0.25 # north outer face (landing side)
const FACADE_S := 5.60  # south outer face
const GROUND_Y := -2.90
const LEVEL2 := 2.85    # top of the second-floor slab (apartment ceiling = 2.60)
const ROOF_Y := 5.60

# ---- landing / stairs
const LAND_W := -6.00
const LAND_E := 9.20
const LAND_S := -1.75   # outer edge (railing)
const STAIR_STEPS := 16
const STAIR_RISE := 0.18125
const STAIR_RUN := 0.26

# ---- front door opening
const FDOOR_X0 := 3.30
const FDOOR_X1 := 4.30
# ---- neighbour door centres (west to east); ours is the easternmost
const DOOR_CENTERS := [-3.40, -1.00, 1.40, 3.80]

static func run(save_path: String = "res://scenes/apartment_blockout.tscn") -> Dictionary:
	var root := Node3D.new()
	root.name = "ApartmentBlockout"

	_shell(root)
	_openings(root)
	_doors(root)
	_rooms(root)
	_exterior(root)
	_lighting(root)
	_player(root)

	LIB.fix_owners(root, root)
	var ps := PackedScene.new()
	var perr: int = ps.pack(root)
	if perr != OK:
		print("PACK FAILED: ", perr)
		return {"ok": false}
	var da := DirAccess.open("res://")
	if da != null and not da.dir_exists("scenes"):
		da.make_dir_recursive("scenes")
	var serr: int = ResourceSaver.save(ps, save_path)
	print("saved %s -> %d" % [save_path, serr])
	var stats := {"ok": serr == OK, "path": save_path, "nodes": _count(root)}
	root.free()
	return stats

# =============================================================== ==============
#  SHELL: ground, slabs, facades, interior walls, floor finishes
# =============================================================== ==============

static func _shell(root: Node3D) -> void:
	var sh := Node3D.new()
	sh.name = "Shell"
	root.add_child(sh)

	# ground
	LIB.slab(sh, "Ground", "ground", -30.0, 20.0, -25.0, 20.0, GROUND_Y, 0.50)

	# structural first-floor slab = the apartment floor
	LIB.slab(sh, "FloorSlab_L1", "concrete", BLDG_W, BLDG_E, FACADE_N, FACADE_S, 0.0, 0.25)
	if not omit_upper_cover:
		# second-floor slab = our ceiling (drawn from above, no collision needed)
		LIB.slab(sh, "FloorSlab_L2", "concrete", BLDG_W, BLDG_E, FACADE_N, FACADE_S, LEVEL2, 0.25, false)
		# roof
		LIB.slab(sh, "Roof", "concrete", BLDG_W, BLDG_E, FACADE_N, FACADE_S, ROOF_Y, 0.20, false)

	# --- facades
	# north facade (landing side): 4 apartment doors, front door is ours (X 3.30..4.30)
	var f_ops: Array = []
	for c in DOOR_CENTERS:
		f_ops.append([c - 0.50, c + 0.50, 0.0, DOOR_H])
	LIB.wall(sh, "FacadeNorth", "concrete", "x", BLDG_W, BLDG_E, FACADE_N, 0.0,
		GROUND_Y, ROOF_Y - 0.20, f_ops)
	if not omit_upper_cover:
		# east facade: bedroom window (Z 1.00..2.20)
		LIB.wall(sh, "FacadeEast", "concrete", "z", FACADE_N, FACADE_S, XE, BLDG_E,
			GROUND_Y, ROOF_Y - 0.20, [[1.00, 2.20, SILL, HEAD]])
		# south facade: living-room window (X 0.85..2.05)
		LIB.wall(sh, "FacadeSouth", "concrete", "x", BLDG_W, BLDG_E, ZS, FACADE_S,
			GROUND_Y, ROOF_Y - 0.20, [[0.85, 2.05, SILL, HEAD]])
		# west facade of the building
		LIB.wall(sh, "FacadeWest", "concrete", "z", FACADE_N, FACADE_S, BLDG_W, BLDG_W + T_EXT,
			GROUND_Y, ROOF_Y - 0.20)
	else:
		# dollhouse pass: thin stub walls so the room boxes still read as rooms
		LIB.wall(sh, "FacadeEast", "concrete", "z", FACADE_N, FACADE_S, XE, BLDG_E,
			GROUND_Y, 0.06, [[1.00, 2.20, 0.0, 0.02]])
		LIB.wall(sh, "FacadeSouth", "concrete", "x", BLDG_W, BLDG_E, ZS, FACADE_S,
			GROUND_Y, 0.06, [[0.85, 2.05, 0.0, 0.02]])
		LIB.wall(sh, "FacadeWest", "concrete", "z", FACADE_N, FACADE_S, BLDG_W, BLDG_W + T_EXT,
			GROUND_Y, 0.06)

	# --- interior partitions
	# party wall to the neighbouring apartment
	LIB.wall(sh, "PartyWall", "wall", "z", 0.0, ZS, -T_EXT, 0.0, 0.0, CEIL)
	# divider: hall | bedroom  and  bathroom | wardrobe nook  (bedroom door Z 1.30..2.20)
	LIB.wall(sh, "DividerX4_5", "wall", "z", 0.0, ZS, X_BATH_E, X_WARD_W, 0.0, CEIL,
		[[1.30, 2.20, 0.0, DOOR_H]])
	# hall south wall / south band north wall (bathroom door X 2.95..3.85)
	LIB.wall(sh, "HallSouth", "wall", "x", 2.20, X_BATH_E, Z_HALL_S, Z_SB_N, 0.0, CEIL,
		[[2.95, 3.85, 0.0, DOOR_H]])
	# bedroom south wall (wardrobe doorway X 4.80..5.70, closet door X 7.30..8.20)
	LIB.wall(sh, "BedroomSouth", "wall", "x", X_WARD_W, XE, Z_HALL_S, Z_SB_N, 0.0, CEIL,
		[[4.80, 5.70, 0.0, DOOR_H], [7.30, 8.20, 0.0, DOOR_H]])
	# bathroom west wall (living extension | bathroom)
	LIB.wall(sh, "BathWest", "wall", "z", Z_SB_N, ZS, 2.20, 2.35, 0.0, CEIL)
	# wardrobe nook east wall (nook | closet)
	LIB.wall(sh, "NookEast", "wall", "z", Z_SB_N, ZS, X_NOOK_E, X_CLO_W, 0.0, CEIL)

	# --- painted linings on the interior faces of the exterior walls.  The
	# structural facades are bare concrete, which is right outside and wrong in
	# a living room, so the apartment gets its own plaster surface.
	if not omit_upper_cover:
		var lin := Node3D.new()
		lin.name = "WallLinings"
		sh.add_child(lin)
		LIB.wall(lin, "North", "wall", "x", XW, XE, ZN, ZN + 0.02, 0.0, CEIL,
			[[FDOOR_X0, FDOOR_X1, 0.0, DOOR_H]], false)
		LIB.wall(lin, "South", "wall", "x", XW, XE, ZS - 0.02, ZS, 0.0, CEIL,
			[[0.85, 2.05, SILL, HEAD]], false)
		LIB.wall(lin, "East", "wall", "z", ZN, ZS, XE - 0.02, XE, 0.0, CEIL,
			[[1.00, 2.20, SILL, HEAD]], false)

	# --- floor finishes (2 cm proud of the structural slab, no collision)
	var fin := Node3D.new()
	fin.name = "FloorFinishes"
	sh.add_child(fin)
	var wood: Array = [
		[0.0, 2.20, 0.0, 3.50],          # hall west half
		[2.20, X_BATH_E, 0.0, 3.50],     # hall east half
		[0.0, 2.20, Z_SB_N, ZS],         # living extension
		[X_WARD_W, XE, 0.0, 3.50],       # bedroom
		[X_WARD_W, X_NOOK_E, Z_SB_N, ZS],# wardrobe nook
		[X_CLO_W, XE, Z_SB_N, ZS],       # closet
		[X_BATH_E, X_WARD_W, 1.30, 2.20],# bedroom doorway threshold
		[4.80, 5.70, Z_HALL_S, Z_SB_N],  # wardrobe doorway threshold
		[7.30, 8.20, Z_HALL_S, Z_SB_N],  # closet doorway threshold
	]
	var wi: int = 0
	for r in wood:
		LIB.slab(fin, "Wood%d" % wi, "floor_wood", r[0], r[1], r[2], r[3], 0.021, 0.02, false)
		wi += 1
	LIB.slab(fin, "TileBath", "floor_tile", 2.35, X_BATH_E, Z_SB_N, ZS, 0.021, 0.02, false)
	LIB.slab(fin, "TileSill", "floor_tile", 2.95, 3.85, Z_HALL_S, Z_SB_N, 0.021, 0.02, false)

	# Painted ceiling over the apartment: the structural slab above stays bare
	# concrete (correct for the building, wrong for a living room).
	if not omit_upper_cover:
		var ceil_fin := Node3D.new()
		ceil_fin.name = "CeilingFinish"
		sh.add_child(ceil_fin)
		LIB.slab(ceil_fin, "Ceiling", "ceiling", XW, XE, ZN, ZS, CEIL, 0.02, false)
	LIB.slab(fin, "Doormat_Sill", "concrete", FDOOR_X0, FDOOR_X1, FACADE_N, 0.0, 0.03, 0.03, false)

	# --- facade window panels for the hollow upper/ground floors (decoration only)
	if omit_upper_cover:
		return
	_facade_window(sh, "FN_G_W", Vector3(-2.90, -1.65, FACADE_N), 1.20, 0.90, "x", -1.0)
	_facade_window(sh, "FN_G_E", Vector3(6.10, -1.65, FACADE_N), 1.20, 0.90, "x", -1.0)
	_facade_window(sh, "FN_L2_1", Vector3(-2.40, 4.10, FACADE_N), 1.20, 1.10, "x", -1.0)
	_facade_window(sh, "FN_L2_2", Vector3(1.10, 4.10, FACADE_N), 1.20, 1.10, "x", -1.0)
	_facade_window(sh, "FN_L2_3", Vector3(5.60, 4.10, FACADE_N), 1.20, 1.10, "x", -1.0)
	_facade_window(sh, "FE_L2_1", Vector3(BLDG_E, 4.10, 1.10), 1.20, 1.10, "z", 1.0)
	_facade_window(sh, "FE_L2_2", Vector3(BLDG_E, 4.10, 3.60), 1.20, 1.10, "z", 1.0)
	_facade_window(sh, "FS_G_1", Vector3(-3.00, -1.65, FACADE_S), 1.20, 0.90, "x", 1.0)
	_facade_window(sh, "FS_G_2", Vector3(3.00, -1.65, FACADE_S), 1.20, 0.90, "x", 1.0)
	_facade_window(sh, "FS_L2_1", Vector3(1.60, 4.10, FACADE_S), 1.20, 1.10, "x", 1.0)
	_facade_window(sh, "FS_L2_2", Vector3(6.00, 4.10, FACADE_S), 1.20, 1.10, "x", 1.0)
	_facade_window(sh, "FW_G_1", Vector3(BLDG_W, -1.65, 1.80), 1.20, 0.90, "z", -1.0)
	_facade_window(sh, "FW_L2_1", Vector3(BLDG_W, 4.10, 2.00), 1.20, 1.10, "z", -1.0)

## A recessed-looking window on a solid facade (frame + dark glass, no opening).
static func _facade_window(parent: Node3D, name: String, pos: Vector3, w: float, h: float,
		axis: String, out_sign: float) -> void:
	var n := Node3D.new()
	n.name = name
	parent.add_child(n)
	var frame_size: Vector3
	var glass_size: Vector3
	var frame_pos: Vector3
	var glass_pos: Vector3
	if axis == "x":
		frame_size = Vector3(w, h, 0.06)
		glass_size = Vector3(w - 0.16, h - 0.16, 0.03)
		frame_pos = Vector3(pos.x, pos.y, pos.z + out_sign * 0.03)
		glass_pos = Vector3(pos.x, pos.y, pos.z + out_sign * 0.05)
	else:
		frame_size = Vector3(0.06, h, w)
		glass_size = Vector3(0.03, h - 0.16, w - 0.16)
		frame_pos = Vector3(pos.x + out_sign * 0.03, pos.y, pos.z)
		glass_pos = Vector3(pos.x + out_sign * 0.05, pos.y, pos.z)
	LIB.box(n, "Frame", "paint_white", frame_pos, frame_size)
	LIB.box(n, "Glass", "dark", glass_pos, glass_size)
	if axis == "x":
		LIB.box(n, "Bar", "paint_white", glass_pos + Vector3(0, 0, out_sign * 0.01),
			Vector3(w - 0.16, 0.05, 0.04))
	else:
		LIB.box(n, "Bar", "paint_white", glass_pos + Vector3(out_sign * 0.01, 0, 0),
			Vector3(0.04, 0.05, w - 0.16))

# =============================================================== ==============
#  OPENINGS: real windows, casings, door leaves
# =============================================================== ==============

static func _openings(root: Node3D) -> void:
	var ow := Node3D.new()
	ow.name = "Openings"
	root.add_child(ow)

	# bedroom window, east facade, Z 1.00..2.20 (wall X 8.45..8.70, opens inward -X)
	_window_unit(ow, "WindowBedroom", "z", 1.60, 1.20, XE, XE + T_EXT, SILL, HEAD, -1.0)
	_curtains(ow, "CurtainsBedroom", "z", 1.60, 1.20, XE, -1.0, 2.22)
	# living-room window, south facade, X 0.85..2.05 (wall Z 5.35..5.60, opens inward -Z)
	_window_unit(ow, "WindowLiving", "x", 1.45, 1.20, ZS, ZS + T_EXT, SILL, HEAD, -1.0)
	_blind(ow, "BlindLiving", "x", 1.45, 1.20, ZS, -1.0, 2.22)

	# interior casings
	_casing(ow, "CaseBedroom", "z", 1.30, 2.20, X_BATH_E, X_WARD_W, DOOR_H)
	_casing(ow, "CaseBathroom", "x", 2.95, 3.85, Z_HALL_S, Z_SB_N, DOOR_H)
	_casing(ow, "CaseWardrobe", "x", 4.80, 5.70, Z_HALL_S, Z_SB_N, DOOR_H)
	_casing(ow, "CaseCloset", "x", 7.30, 8.20, Z_HALL_S, Z_SB_N, DOOR_H)
	_casing(ow, "CaseFrontDoor", "x", FDOOR_X0, FDOOR_X1, FACADE_N, 0.0, DOOR_H, 0.10)

## A real window: jambs, head, sill slab protruding into the room, glass + mullion.
static func _window_unit(parent: Node3D, name: String, axis: String, a_center: float,
		width: float, b0: float, b1: float, sill: float, head: float,
		inward: float) -> void:
	var n := Node3D.new()
	n.name = name
	parent.add_child(n)
	var half: float = width * 0.5
	var bt: float = b1 - b0
	var bmid: float = (b0 + b1) * 0.5
	var jamb: float = 0.06
	var y_mid: float = (sill + head) * 0.5
	var h: float = head - sill
	if axis == "x":
		LIB.box(n, "JambW", "paint_white", Vector3(a_center - half + jamb * 0.5, y_mid, bmid),
			Vector3(jamb, h, bt + 0.02))
		LIB.box(n, "JambE", "paint_white", Vector3(a_center + half - jamb * 0.5, y_mid, bmid),
			Vector3(jamb, h, bt + 0.02))
		LIB.box(n, "Head", "paint_white", Vector3(a_center, head - jamb * 0.5, bmid),
			Vector3(width, jamb, bt + 0.02))
		LIB.box(n, "Sill", "paint_white", Vector3(a_center, sill + 0.02, b0 + inward * 0.10),
			Vector3(width + 0.16, 0.04, bt + 0.24))
		LIB.box(n, "SillNose", "paint_white",
			Vector3(a_center, sill + 0.015, b0 + inward * 0.22), Vector3(width + 0.16, 0.05, 0.05))
		LIB.box(n, "Apron", "paint_white",
			Vector3(a_center, sill - 0.035, b0 + inward * 0.035), Vector3(width + 0.16, 0.07, 0.03))
		LIB.box(n, "Glass", "glass", Vector3(a_center, y_mid, bmid),
			Vector3(width - 0.12, h - 0.12, 0.02))
		LIB.box(n, "Mullion", "paint_white", Vector3(a_center, y_mid, bmid),
			Vector3(0.05, h - 0.12, 0.04))
		LIB.box(n, "Latch", "metal", Vector3(a_center + half - 0.12, y_mid, b0 + inward * 0.045),
			Vector3(0.05, 0.03, 0.05))
	else:
		LIB.box(n, "JambN", "paint_white", Vector3(bmid, y_mid, a_center - half + jamb * 0.5),
			Vector3(bt + 0.02, h, jamb))
		LIB.box(n, "JambS", "paint_white", Vector3(bmid, y_mid, a_center + half - jamb * 0.5),
			Vector3(bt + 0.02, h, jamb))
		LIB.box(n, "Head", "paint_white", Vector3(bmid, head - jamb * 0.5, a_center),
			Vector3(bt + 0.02, jamb, width))
		LIB.box(n, "Sill", "paint_white", Vector3(b0 + inward * 0.10, sill + 0.02, a_center),
			Vector3(bt + 0.24, 0.04, width + 0.16))
		LIB.box(n, "SillNose", "paint_white",
			Vector3(b0 + inward * 0.22, sill + 0.015, a_center), Vector3(0.05, 0.05, width + 0.16))
		LIB.box(n, "Apron", "paint_white",
			Vector3(b0 + inward * 0.035, sill - 0.035, a_center), Vector3(0.03, 0.07, width + 0.16))
		LIB.box(n, "Glass", "glass", Vector3(bmid, y_mid, a_center),
			Vector3(0.02, h - 0.12, width - 0.12))
		LIB.box(n, "Mullion", "paint_white", Vector3(bmid, y_mid, a_center),
			Vector3(0.04, h - 0.12, 0.05))
		LIB.box(n, "Latch", "metal", Vector3(b0 + inward * 0.045, y_mid, a_center + half - 0.12),
			Vector3(0.05, 0.03, 0.05))

## Hanging curtains: rod with finials and brackets, plus two gathered panels
## that hang in soft folds either side of the window (light stays clear).
static func _curtains(parent: Node3D, name: String, axis: String, a_center: float,
		width: float, b_face: float, inward: float, rod_y: float) -> void:
	var n := Node3D.new()
	n.name = name
	parent.add_child(n)
	var b: float = b_face + inward * 0.13          # fabric hangs just off the wall
	var rod_b: float = b_face + inward * 0.11
	var rod_len: float = width + 0.62
	var panel_h: float = 1.72
	var panel_y: float = rod_y - 0.07 - panel_h * 0.5
	var off: float = width * 0.5 + 0.16
	var folds: Array = [-0.032, 0.026, -0.026, 0.032]
	var i: int = 0
	if axis == "x":
		LIB.cyl(n, "Rod", "metal", Vector3(a_center, rod_y, rod_b), 0.014, rod_len,
			Vector3(0, 0, 90))
		LIB.cyl(n, "FinialW", "metal", Vector3(a_center - rod_len * 0.5 - 0.03, rod_y, rod_b),
			0.03, 0.05, Vector3(0, 0, 90))
		LIB.cyl(n, "FinialE", "metal", Vector3(a_center + rod_len * 0.5 + 0.03, rod_y, rod_b),
			0.03, 0.05, Vector3(0, 0, 90))
		LIB.box(n, "BracketW", "metal", Vector3(a_center - width * 0.5 - 0.22, rod_y,
			b_face + inward * 0.06), Vector3(0.05, 0.05, 0.12))
		LIB.box(n, "BracketE", "metal", Vector3(a_center + width * 0.5 + 0.22, rod_y,
			b_face + inward * 0.06), Vector3(0.05, 0.05, 0.12))
		for side in [-1.0, 1.0]:
			var ax: float = a_center + side * off
			for f in folds:
				LIB.box(n, "Fold%d" % i, "curtain", Vector3(ax, panel_y, b + f * inward),
					Vector3(0.086, panel_h, 0.05))
				i += 1
			LIB.box(n, "Hem%d" % i, "curtain",
				Vector3(ax, panel_y - panel_h * 0.5 + 0.035, b), Vector3(0.35, 0.07, 0.07))
			i += 1
	else:
		LIB.cyl(n, "Rod", "metal", Vector3(rod_b, rod_y, a_center), 0.014, rod_len,
			Vector3(90, 0, 0))
		LIB.cyl(n, "FinialN", "metal", Vector3(rod_b, rod_y, a_center - rod_len * 0.5 - 0.03),
			0.03, 0.05, Vector3(90, 0, 0))
		LIB.cyl(n, "FinialS", "metal", Vector3(rod_b, rod_y, a_center + rod_len * 0.5 + 0.03),
			0.03, 0.05, Vector3(90, 0, 0))
		LIB.box(n, "BracketN", "metal", Vector3(b_face + inward * 0.06, rod_y,
			a_center - width * 0.5 - 0.22), Vector3(0.12, 0.05, 0.05))
		LIB.box(n, "BracketS", "metal", Vector3(b_face + inward * 0.06, rod_y,
			a_center + width * 0.5 + 0.22), Vector3(0.12, 0.05, 0.05))
		for side in [-1.0, 1.0]:
			var az: float = a_center + side * off
			for f in folds:
				LIB.box(n, "Fold%d" % i, "curtain", Vector3(b + f * inward, panel_y, az),
					Vector3(0.05, panel_h, 0.086))
				i += 1
			LIB.box(n, "Hem%d" % i, "curtain",
				Vector3(b, panel_y - panel_h * 0.5 + 0.035, az), Vector3(0.07, 0.07, 0.35))
			i += 1

## Top-mounted blind / valance (used where furniture sits under the window).
static func _blind(parent: Node3D, name: String, axis: String, a_center: float,
		width: float, b_face: float, inward: float, rod_y: float) -> void:
	var n := Node3D.new()
	n.name = name
	parent.add_child(n)
	var b: float = b_face + inward * 0.07
	if axis == "x":
		LIB.cyl(n, "Rod", "metal", Vector3(a_center, rod_y, b), 0.014, width + 0.30, Vector3(0, 0, 90))
		LIB.box(n, "Blind", "fabric", Vector3(a_center, rod_y - 0.13, b),
			Vector3(width + 0.10, 0.22, 0.05))
	else:
		LIB.cyl(n, "Rod", "metal", Vector3(b, rod_y, a_center), 0.014, width + 0.30, Vector3(90, 0, 0))
		LIB.box(n, "Blind", "fabric", Vector3(b, rod_y - 0.13, a_center),
			Vector3(0.05, 0.22, width + 0.10))

## Painted casing around a doorway (two jambs + head).
static func _casing(parent: Node3D, name: String, axis: String, a0: float, a1: float,
		b0: float, b1: float, door_h: float, extra: float = 0.0) -> void:
	var n := Node3D.new()
	n.name = name
	parent.add_child(n)
	var mid: float = (b0 + b1) * 0.5
	var jt: float = 0.06
	if axis == "x":
		LIB.box(n, "JambW", "paint_white", Vector3(a0 + jt * 0.5, door_h * 0.5, mid),
			Vector3(jt, door_h, (b1 - b0) + extra))
		LIB.box(n, "JambE", "paint_white", Vector3(a1 - jt * 0.5, door_h * 0.5, mid),
			Vector3(jt, door_h, (b1 - b0) + extra))
		LIB.box(n, "Head", "paint_white", Vector3((a0 + a1) * 0.5, door_h + jt * 0.5, mid),
			Vector3(a1 - a0, jt, (b1 - b0) + extra))
	else:
		LIB.box(n, "JambN", "paint_white", Vector3(mid, door_h * 0.5, a0 + jt * 0.5),
			Vector3((b1 - b0) + extra, door_h, jt))
		LIB.box(n, "JambS", "paint_white", Vector3(mid, door_h * 0.5, a1 - jt * 0.5),
			Vector3((b1 - b0) + extra, door_h, jt))
		LIB.box(n, "Head", "paint_white", Vector3(mid, door_h + jt * 0.5, (a0 + a1) * 0.5),
			Vector3((b1 - b0) + extra, jt, a1 - a0))

## A door leaf hinged at `hinge`, spanning `width` from the hinge in -X local,
## rotated `yaw` degrees (0 = leaf in the wall plane extending -X).
static func _leaf(parent: Node3D, name: String, hinge: Vector3, yaw: float,
		width: float, height: float, limit: float, mat_key: String) -> void:
	var pivot := Node3D.new()
	pivot.name = name
	pivot.position = hinge
	pivot.rotation_degrees = Vector3(0, yaw, 0)
	parent.add_child(pivot)
	LIB.box(pivot, "Panel", mat_key, Vector3(-width * 0.5, height * 0.5, 0),
		Vector3(width, height, 0.05))
	LIB.box(pivot, "Handle", "metal", Vector3(-width + 0.09, 1.02, -0.05),
		Vector3(0.04, 0.04, 0.09))
	LIB.box(pivot, "Handle2", "metal", Vector3(-width + 0.09, 1.02, 0.05),
		Vector3(0.04, 0.04, 0.09))
	var sb := StaticBody3D.new()
	sb.name = "Body"
	pivot.add_child(sb)
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var shape := BoxShape3D.new()
	shape.size = Vector3(width, height, 0.06)
	cs.shape = shape
	cs.position = Vector3(-width * 0.5, height * 0.5, 0)
	sb.add_child(cs)

static func _doors(root: Node3D) -> void:
	var dr := Node3D.new()
	dr.name = "Doors"
	root.add_child(dr)
	# ours: front door standing open into the hall (hinge on the east jamb)
	_leaf(dr, "FrontDoor", Vector3(FDOOR_X1 - 0.02, 0.0, -0.125), 88.0, 0.98, 2.06, DOOR_H, "door")
	# bedroom door, opens into the bedroom
	_leaf(dr, "BedroomDoor", Vector3(4.575, 0.0, 1.30), 175.0, 0.88, 2.06, DOOR_H, "door")
	# bathroom door, opens into the hall
	_leaf(dr, "BathroomDoor", Vector3(2.95, 0.0, 3.575), 260.0, 0.88, 2.06, DOOR_H, "door")
	# closet door, kept closed
	_leaf(dr, "ClosetDoor", Vector3(7.30, 0.0, 3.575), 180.0, 0.88, 2.06, DOOR_H, "door")

# =============================================================== ==============
#  ROOMS: furniture
# =============================================================== ==============

static func _rooms(root: Node3D) -> void:
	var rooms := Node3D.new()
	rooms.name = "Rooms"
	root.add_child(rooms)

	# ------------------------------------------------------------------ HALL
	var hall := Node3D.new()
	hall.name = "Hall"
	rooms.add_child(hall)

	# television against the north facade wall, facing south down the room
	LIB.place(hall, "tv_unit", "TVUnit", Vector3(1.10, 0.0, 0.225), 0.0)
	LIB.place(hall, "book_stack", "BooksOnTV", Vector3(0.60, 0.525, 0.22), 0.0)
	# shoe rack + coat hooks on the facade wall, just west of the front door
	LIB.place(hall, "shoe_rack", "ShoeRack", Vector3(2.65, 0.0, 0.175), 0.0)
	LIB.place(hall, "keys", "KeysByDoor", Vector3(2.78, 0.86, 0.16), -22.0)
	LIB.place(hall, "coat_hooks", "CoatHooks", Vector3(2.65, 1.72, 0.02), 0.0)
	LIB.place(hall, "light_switch", "HallSwitch", Vector3(3.08, 1.22, 0.02), 0.0)
	# wall clock on the hall's south wall
	LIB.place(hall, "wall_clock", "WallClock", Vector3(2.55, 1.65, Z_HALL_S), 180.0)
	# sofa + coffee table in the living extension, back to the south window
	LIB.place(hall, "rug", "LivingRug", Vector3(1.15, 0.022, 4.25), 90.0)
	LIB.place(hall, "sofa", "Sofa", Vector3(1.15, 0.0, 4.90), 180.0)
	LIB.place(hall, "coffee_table", "CoffeeTable", Vector3(1.15, 0.0, 4.10), 0.0)
	LIB.place(hall, "remote", "TVRemote", Vector3(1.44, 0.42, 4.30), 34.0)
	LIB.place(hall, "plant_pot", "PlantHall", Vector3(0.35, 0.0, 3.80), 0.0)
	LIB.place(hall, "power_socket", "HallSocket", Vector3(4.48, 0.30, 2.60), -90.0)

	# --------------------------------------------------------------- BEDROOM
	var bed := Node3D.new()
	bed.name = "Bedroom"
	rooms.add_child(bed)
	# bed: head to the north wall, so waking up faces the photo on the south wall
	LIB.place(bed, "bed", "Bed", Vector3(6.50, 0.0, 1.15), 0.0)
	LIB.place(bed, "bedside_table", "BedsideTable", Vector3(5.55, 0.0, 0.225), 0.0)
	LIB.place(bed, "table_lamp", "BedsideLamp", Vector3(5.42, 0.54, 0.20), 0.0)
	# within arm's reach of the pillow: handbook, pen, phone on its cable,
	# a glass of water, and the socket the cable comes from
	LIB.place(bed, "handbook", "Handbook", Vector3(5.70, 0.54, 0.33), 24.0)
	LIB.place(bed, "pen", "Pen", Vector3(5.50, 0.54, 0.38), 14.0)
	LIB.place(bed, "phone", "Phone", Vector3(5.62, 0.54, 0.16), -6.0)
	LIB.place(bed, "charging_cable", "ChargingCable", Vector3(5.83, 0.54, 0.16), -90.0)
	LIB.place(bed, "glass_water", "WaterGlass", Vector3(5.38, 0.54, 0.42), 0.0)
	LIB.place(bed, "power_socket", "BedSocket", Vector3(5.90, 0.30, 0.02), 0.0)
	LIB.place(bed, "desk", "Desk", Vector3(7.80, 0.0, 0.30), 0.0)
	LIB.place(bed, "papers", "DeskPapers", Vector3(7.42, 0.76, 0.40), 8.0)
	LIB.place(bed, "book_stack", "DeskBooks", Vector3(7.52, 0.76, 0.16), -8.0)
	LIB.place(bed, "chair", "Chair", Vector3(7.80, 0.0, 0.95), 176.0)
	LIB.place(bed, "laundry_basket", "LaundryBedroom", Vector3(4.92, 0.0, 0.38), 0.0)
	LIB.place(bed, "light_switch", "BedroomSwitch", Vector3(4.67, 1.22, 2.36), 90.0)
	LIB.place(bed, "power_socket", "DeskSocket", Vector3(7.10, 0.30, 0.02), 0.0)
	LIB.place(bed, "ceiling_fan", "CeilingFan", Vector3(6.50, CEIL, 1.75), 0.0)
	# the framed group photo on the south wall + the taped note under it
	LIB.place(bed, "photo_frame", "WallPhotograph", Vector3(6.50, 1.62, Z_HALL_S - 0.02), 180.0)
	LIB.place(bed, "reminder", "NoteUnderPhoto", Vector3(6.50, 1.12, Z_HALL_S - 0.017),
		180.0, Vector3(0, 0, 4))

	# --------------------------------------------------------- WARDROBE NOOK
	var ward := Node3D.new()
	ward.name = "WardrobeNook"
	rooms.add_child(ward)
	LIB.place(ward, "wardrobe_unit", "Wardrobe", Vector3(5.55, 0.0, 4.99), 180.0)
	LIB.place(ward, "folded_clothes", "FoldedClothes", Vector3(5.42, 2.04, 4.92), 8.0)
	LIB.place(ward, "tray_items", "Tray", Vector3(5.92, 2.04, 4.92), -12.0)
	LIB.place(ward, "hang_rail", "HangingClothes", Vector3(6.175, 0.0, 4.20), -90.0)
	LIB.place(ward, "mirror_full", "Mirror", Vector3(4.72, 1.20, 4.60), 90.0)
	LIB.place(ward, "clothes_hook", "NookHook", Vector3(4.68, 1.78, 4.02), 90.0)
	LIB.place(ward, "laundry_basket", "LaundryNook", Vector3(4.95, 0.0, 5.05), 0.0)
	LIB.place(ward, "shoes_pair", "ShoesNook", Vector3(5.30, 0.0, 3.95), 12.0)
	LIB.place(ward, "shoes_pair", "ShoesNook2", Vector3(5.80, 0.0, 4.10), -25.0)
	LIB.place(ward, "shoes_pair", "ShoesNook3", Vector3(5.05, 0.0, 4.65), 40.0)

	# -------------------------------------------------------------- BATHROOM
	var bath := Node3D.new()
	bath.name = "Bathroom"
	rooms.add_child(bath)
	_bath_tiling(bath)
	LIB.place(bath, "sink_unit", "Sink", Vector3(4.275, 0.0, 4.175), -90.0)
	LIB.place(bath, "toiletries", "Toiletries", Vector3(3.95, 0.95, 5.25), 0.0)
	LIB.place(bath, "wall_mirror", "Mirror", Vector3(4.47, 1.45, 4.175), -90.0)
	LIB.place(bath, "medicine_cabinet", "MedicineCabinet", Vector3(4.42, 1.98, 4.175), -90.0)
	LIB.place(bath, "toilet", "Toilet", Vector3(4.05, 0.0, 5.00), 180.0)
	LIB.place(bath, "toilet_paper", "ToiletPaper", Vector3(4.48, 0.70, 4.75), -90.0)
	LIB.place(bath, "shower_unit", "Shower", Vector3(2.85, 0.0, 4.80), 180.0)
	LIB.place(bath, "shower_curtain", "ShowerCurtain", Vector3(2.85, 2.05, 4.42), 0.0)
	LIB.place(bath, "towel_hooks", "TowelHooks", Vector3(2.40, 1.68, 3.95), 90.0)
	LIB.place(bath, "bath_mat", "BathMat", Vector3(3.65, 0.022, 4.10), 0.0)
	LIB.place(bath, "bin_small", "Bin", Vector3(3.58, 0.022, 4.95), 0.0)

	# ---------------------------------------------------------------- CLOSET
	var clo := Node3D.new()
	clo.name = "Closet"
	rooms.add_child(clo)
	LIB.place(clo, "wardrobe_unit", "Wardrobe", Vector3(7.35, 0.0, 4.99), 180.0)
	LIB.place(clo, "folded_clothes", "StoredLinen", Vector3(7.12, 2.04, 4.90), -6.0)
	# built-in shelving on the east wall
	var shelf := Node3D.new()
	shelf.name = "Shelves"
	clo.add_child(shelf)
	LIB.box(shelf, "SideN", "wood", Vector3(8.25, 1.00, 3.72), Vector3(0.40, 2.00, 0.05))
	LIB.box(shelf, "SideS", "wood", Vector3(8.25, 1.00, 5.28), Vector3(0.40, 2.00, 0.05))
	var sy: Array = [0.40, 1.00, 1.60, 2.10]
	var si: int = 0
	for y in sy:
		LIB.box(shelf, "Shelf%d" % si, "wood", Vector3(8.25, y, 4.50), Vector3(0.40, 0.05, 1.60))
		si += 1
	LIB.box(shelf, "BoxA", "wood_light", Vector3(8.25, 0.55, 3.95), Vector3(0.32, 0.26, 0.36))
	LIB.box(shelf, "BoxB", "door", Vector3(8.25, 1.15, 4.55), Vector3(0.30, 0.24, 0.30))
	LIB.box(shelf, "BoxC", "dark", Vector3(8.25, 1.75, 5.00), Vector3(0.28, 0.22, 0.28))
	LIB.place(clo, "shoes_pair", "ShoesCloset", Vector3(6.80, 0.0, 4.10), 30.0)

## Ceramic wall tiling for the bathroom: 1 cm panels laid over the painted
## partitions up to 2.10 m, with painted wall above - no structural change.
static func _bath_tiling(parent: Node3D) -> void:
	var t := Node3D.new()
	t.name = "WallTiles"
	parent.add_child(t)
	var h: float = 2.10
	var yc: float = h * 0.5
	var zt: float = 0.02
	# north wall, either side of the door (opening X 2.95..3.85)
	LIB.box(t, "NorthW", "tile_wall", Vector3(2.65, yc, Z_SB_N + 0.01), Vector3(0.60, h, zt))
	LIB.box(t, "NorthE", "tile_wall", Vector3(4.175, yc, Z_SB_N + 0.01), Vector3(0.65, h, zt))
	# south wall
	LIB.box(t, "South", "tile_wall", Vector3(3.425, yc, ZS - 0.01), Vector3(2.15, h, zt))
	# west and east walls
	LIB.box(t, "West", "tile_wall", Vector3(2.35 + 0.01, yc, 4.50), Vector3(zt, h, 1.70))
	LIB.box(t, "East", "tile_wall", Vector3(X_BATH_E - 0.01, yc, 4.50), Vector3(zt, h, 1.70))

# =============================================================== ==============
#  EXTERIOR: landing, railings, stairs, apartment doors, lived-in details
# =============================================================== ==============

static func _exterior(root: Node3D) -> void:
	var ext := Node3D.new()
	ext.name = "Exterior"
	root.add_child(ext)

	# --- concrete landing slab + the slab above it (covered walkway)
	LIB.slab(ext, "LandingSlab", "concrete", LAND_W, LAND_E, LAND_S, FACADE_N, 0.0, 0.25)
	if not omit_upper_cover:
		LIB.slab(ext, "LandingCeiling", "concrete", LAND_W, LAND_E, LAND_S, FACADE_N, LEVEL2, 0.25, false)
	# support columns from the ground
	for cx in [-5.60, -3.20, -0.40, 2.40, 5.20, 8.00]:
		LIB.box(ext, "Col_%s" % str(cx), "concrete", Vector3(cx, (LEVEL2 + GROUND_Y) * 0.5, -1.60),
			Vector3(0.24, LEVEL2 - GROUND_Y, 0.24))
		LIB.collider(ext, "ColBody_%s" % str(cx),
			Vector3(cx, (LEVEL2 + GROUND_Y) * 0.5, -1.60), Vector3(0.24, LEVEL2 - GROUND_Y, 0.24))

	# --- metal railings along the open edge and the west end
	_railing(ext, "RailNorth", Vector3(LAND_W, 0.0, LAND_S), Vector3(LAND_E, 0.0, LAND_S), 1.05)
	_railing(ext, "RailWest", Vector3(LAND_W, 0.0, LAND_S), Vector3(LAND_W, 0.0, FACADE_N + 0.25), 1.05)

	# --- external concrete staircase along the west side of the building
	_stairs(ext)

	# --- four apartment doors on the landing
	var di: int = 1
	for c in DOOR_CENTERS:
		_apartment_door(ext, c, di, di == 4)
		di += 1

	# --- utility pipes hugging the underside of the walkway slab + vertical drops
	LIB.cyl(ext, "PipeRun", "metal", Vector3((BLDG_W + BLDG_E) * 0.5, 2.56, FACADE_N - 0.09),
		0.04, BLDG_E - BLDG_W, Vector3(0, 0, 90))
	for px in [-4.40, 2.90, 8.30]:
		LIB.cyl(ext, "Drop_%s" % str(px), "metal",
			Vector3(px, (2.52 + GROUND_Y) * 0.5, FACADE_N - 0.09), 0.05, 2.52 - GROUND_Y, Vector3.ZERO)
		LIB.cyl(ext, "Elbow_%s" % str(px), "metal",
			Vector3(px, 2.52, FACADE_N - 0.045), 0.05, 0.10, Vector3(90, 0, 0))

	# --- utility / meter box beside the doors (functional, not decorative)
	LIB.box(ext, "MeterBox", "metal_dark", Vector3(5.30, 1.40, FACADE_N - 0.08),
		Vector3(0.34, 0.44, 0.16))
	LIB.box(ext, "MeterLid", "metal_dark", Vector3(5.30, 1.40, FACADE_N - 0.17),
		Vector3(0.30, 0.40, 0.02))
	LIB.box(ext, "MeterDial", "dark", Vector3(5.30, 1.40, FACADE_N - 0.185),
		Vector3(0.14, 0.10, 0.01))

	# --- lived-in details
	LIB.place(ext, "shoes_pair", "ShoesDoor4", Vector3(3.00, 0.0, -0.62), 8.0)
	LIB.place(ext, "shoes_pair", "ShoesDoor2", Vector3(-0.60, 0.0, -0.60), -14.0)
	LIB.place(ext, "plant_pot", "PlantCorridorE", Vector3(8.70, 0.0, -0.48), 0.0)
	LIB.place(ext, "plant_pot", "PlantBetween", Vector3(-0.05, 0.0, -0.46), 0.0)
	LIB.place(ext, "plant_pot", "PlantWest", Vector3(-4.55, 0.0, -0.48), 0.0)
	LIB.place(ext, "plant_pot", "PlantGround", Vector3(-6.90, GROUND_Y, 0.20), 0.0)

## Post-and-rail metal railing between two points (axis aligned).
static func _railing(parent: Node3D, name: String, a: Vector3, b: Vector3, height: float) -> void:
	var n := Node3D.new()
	n.name = name
	parent.add_child(n)
	var length: float = a.distance_to(b)
	var along_x: bool = absf(b.x - a.x) > absf(b.z - a.z)
	var mid := (a + b) * 0.5
	if along_x:
		LIB.box(n, "TopRail", "metal", Vector3(mid.x, a.y + height, mid.z), Vector3(length, 0.05, 0.05))
		LIB.box(n, "MidRail", "metal", Vector3(mid.x, a.y + height - 0.45, mid.z),
			Vector3(length, 0.035, 0.035))
		var count: int = int(length / 1.50)
		for i in count + 1:
			var x: float = a.x + (length / float(count)) * float(i)
			LIB.box(n, "Post%d" % i, "metal", Vector3(x, a.y + height * 0.5, mid.z),
				Vector3(0.06, height, 0.06))
		LIB.collider(n, "RailBody", Vector3(mid.x, a.y + height * 0.5, mid.z),
			Vector3(length, height, 0.08))
	else:
		LIB.box(n, "TopRail", "metal", Vector3(mid.x, a.y + height, mid.z), Vector3(0.05, 0.05, length))
		LIB.box(n, "MidRail", "metal", Vector3(mid.x, a.y + height - 0.45, mid.z),
			Vector3(0.035, 0.035, length))
		var count2: int = int(length / 1.50)
		for i in count2 + 1:
			var z: float = a.z + (length / float(count2)) * float(i)
			LIB.box(n, "Post%d" % i, "metal", Vector3(mid.x, a.y + height * 0.5, z),
				Vector3(0.06, height, 0.06))
		LIB.collider(n, "RailBody", Vector3(mid.x, a.y + height * 0.5, mid.z),
			Vector3(0.08, height, length))

## External concrete staircase: solid stepped mass along the west wall, with a
## sloped guard rail on the outer side and a pad at the bottom.
static func _stairs(parent: Node3D) -> void:
	var n := Node3D.new()
	n.name = "Stairs"
	parent.add_child(n)
	var x0: float = LAND_W            # -6.00
	var x1: float = BLDG_W            # -4.80, flush with the building's west wall
	var top_z: float = FACADE_N       # landing edge, -0.25
	for i in range(1, STAIR_STEPS + 1):
		var z1: float = top_z + STAIR_RUN * float(i)
		var z0: float = z1 - STAIR_RUN
		var y_top: float = -STAIR_RISE * float(i)
		var h: float = y_top - GROUND_Y
		LIB.box(n, "Step%d" % i, "concrete",
			Vector3((x0 + x1) * 0.5, y_top - h * 0.5, (z0 + z1) * 0.5),
			Vector3(x1 - x0, h, STAIR_RUN))
		LIB.collider(n, "StepBody%d" % i,
			Vector3((x0 + x1) * 0.5, y_top - h * 0.5, (z0 + z1) * 0.5),
			Vector3(x1 - x0, h, STAIR_RUN))
	# bottom pad
	var pad_z: float = top_z + STAIR_RUN * float(STAIR_STEPS)
	LIB.box(n, "Pad", "concrete", Vector3((x0 + x1) * 0.5, GROUND_Y - 0.10, pad_z + 0.60),
		Vector3(1.20, 0.20, 1.20))
	LIB.collider(n, "PadBody", Vector3((x0 + x1) * 0.5, GROUND_Y - 0.10, pad_z + 0.60),
		Vector3(1.20, 0.20, 1.20))

	# sloped guard along the outer (west) edge of the flight
	var run: float = STAIR_RUN * float(STAIR_STEPS)
	var rise: float = STAIR_RISE * float(STAIR_STEPS)
	var slope_len: float = sqrt(run * run + rise * rise)
	var ang: float = rad_to_deg(atan2(rise, run))
	var mid_y: float = -rise * 0.5
	var mid_z: float = top_z + run * 0.5
	# unit perpendicular to the flight, pointing up and toward +Z
	var sa: float = sin(deg_to_rad(ang))
	var ca: float = cos(deg_to_rad(ang))
	var gy: float = mid_y + 0.55 * ca
	var gz: float = mid_z + 0.55 * sa
	LIB.box(n, "Guard", "concrete", Vector3(x0 - 0.05, gy, gz),
		Vector3(0.10, 1.05, slope_len), Vector3(ang, 0, 0))
	LIB.cyl(n, "HandRail", "metal", Vector3(x0 - 0.05, gy + 1.05 * ca, gz + 1.05 * sa),
		0.03, slope_len, Vector3(90.0 + ang, 0, 0))

## One apartment door: recessed leaf, casing, number, lamp, doormat.
static func _apartment_door(parent: Node3D, cx: float, number: int, is_ours: bool) -> void:
	var n := Node3D.new()
	n.name = "AptDoor%d" % number
	parent.add_child(n)
	# leaf (closed for the neighbours, removed for ours - ours is modelled open in Doors)
	if not is_ours:
		LIB.box(n, "Leaf", "door", Vector3(cx, 1.04, -0.16), Vector3(0.98, 2.06, 0.06))
		LIB.box(n, "Handle", "metal", Vector3(cx + 0.40, 1.02, -0.13), Vector3(0.05, 0.05, 0.10))
		LIB.collider(n, "Body", Vector3(cx, 1.04, -0.16), Vector3(0.98, 2.06, 0.06))
	# number plate above the door, facing the corridor
	LIB.label3d(n, "Number", str(number), Vector3(cx, 2.26, FACADE_N - 0.02),
		Vector3(0, 180, 0), 0.0035, 64, Color(0.92, 0.92, 0.88))
	# bulkhead lamp above the door
	LIB.place(n, "wall_lamp_ext", "Lamp", Vector3(cx, 2.42, FACADE_N), 180.0)
	# doormat in front of the door
	LIB.place(n, "doormat", "Doormat", Vector3(cx, 0.0, -0.72), 0.0)

# =============================================================== ==============
#  LIGHTING AND PLAYER REFERENCE
# =============================================================== ==============

static func _lighting(root: Node3D) -> void:
	var lit := Node3D.new()
	lit.name = "Lighting"
	lit.set_script(WL)
	root.add_child(lit)

	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	lit.add_child(we)

	# The scene ships in its MORNING state: a low sun in the east-north-east
	# that comes through the bedroom window and rakes across the photo wall.
	# Every value below is re-applied from a LightingPreset at runtime, so
	# evening / night (or a story beat) only needs apply_preset("evening").
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-22, 110, 0)
	sun.light_color = Color(1.0, 0.93, 0.80)
	sun.light_energy = 2.0
	sun.light_angular_distance = 0.7
	sun.shadow_enabled = true
	sun.shadow_blur = 0.6
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	# Tight biases and a short shadow range: with 0.15 m partitions, a loose
	# bias makes sunlight leak straight through the walls.
	sun.directional_shadow_max_distance = 32.0
	sun.shadow_bias = 0.02
	sun.shadow_normal_bias = 0.7
	lit.add_child(sun)

	# Shadowless sky fill: gives interior surfaces their directional shading
	# (a window's worth of soft light) without a fake spotlight.
	var fill := DirectionalLight3D.new()
	fill.name = "Fill"
	fill.rotation_degrees = Vector3(-38, 96, 0)
	fill.light_color = Color(0.92, 0.93, 0.96)
	fill.light_energy = 0.5
	fill.light_angular_distance = 4.0
	fill.shadow_enabled = false
	lit.add_child(fill)

	# base energies: the presets scale these per room
	_ceiling_light(lit, "Hall", Vector3(2.25, CEIL, 1.60), 1.5, 7.5, true)
	_ceiling_light(lit, "Bedroom", Vector3(7.30, CEIL, 2.60), 1.1, 6.5, false)
	_ceiling_light(lit, "WardrobeNook", Vector3(5.55, CEIL, 4.50), 0.8, 4.0, false)
	_ceiling_light(lit, "Bathroom", Vector3(3.40, CEIL, 4.40), 0.9, 4.0, false)
	_ceiling_light(lit, "Closet", Vector3(7.50, CEIL, 4.50), 0.5, 3.5, false)

	var presets: Array = []
	for pname in ["morning", "day", "evening", "night"]:
		var p: Resource = load("res://lighting/%s.tres" % pname)
		if p != null:
			presets.append(p)
		else:
			push_warning("WorldLighting: missing preset " + pname)
	lit.presets.assign(presets)   # typed Array[LightingPreset] export
	lit.sun = sun
	lit.fill = fill
	lit.world_environment = we
	lit.light_root = root
	lit.active_preset = "morning"
	we.environment = WL.build_environment(presets[0]) if presets.size() > 0 else Environment.new()

static func _ceiling_light(parent: Node3D, name: String, pos: Vector3, energy: float,
		light_range: float, shadows: bool) -> void:
	var n := Node3D.new()
	n.name = name
	parent.add_child(n)
	LIB.box(n, "Rose", "paint_white", pos + Vector3(0, -0.03, 0), Vector3(0.28, 0.06, 0.28))
	LIB.omni(n, "Light", pos + Vector3(0, -0.12, 0), energy, light_range,
		Color(1.0, 0.93, 0.82), shadows)

## Scale reference / spawn marker: an invisible 1.75 m capsule body with an
## eye-height camera. No logic is attached - this is a blockout.
static func _player(root: Node3D) -> void:
	var p := CharacterBody3D.new()
	p.name = "Player"
	# standing reference beside the foot of the bed (the player wakes here)
	p.position = Vector3(6.50, 0.0, 2.95)
	p.rotation_degrees = Vector3(0, 0, 0)
	root.add_child(p)
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var cap := CapsuleShape3D.new()
	cap.height = 1.75
	cap.radius = 0.30
	cs.shape = cap
	cs.position = Vector3(0, 0.875, 0)
	p.add_child(cs)
	var cam := Camera3D.new()
	cam.name = "PlayerCamera"
	cam.position = Vector3(0, 1.65, 0)
	cam.fov = 70.0
	cam.current = true
	p.add_child(cam)

static func _count(n: Node) -> int:
	var c: int = 1
	for ch in n.get_children():
		c += _count(ch)
	return c
