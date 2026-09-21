class_name BOBuildNeighborhood
extends RefCounted

## Builds the compact outdoor neighbourhood around the preserved apartment and
## saves it as res://scenes/neighborhood.tscn
##
## Invoke via execute_script:  BOBuildNeighborhood.run()
##
## The apartment building already exists in res://scenes/apartment_blockout.tscn
## (X -4.80..8.70, Z -0.25..5.60) and Chris lives on its upper floor, reached by
## the external staircase at its west end.  The neighbourhood is therefore built
## at STREET LEVEL, which is the ground plane's Y = -2.90 - the same world
## coordinates, so leaving the apartment is seamless: no scene transition, no
## fade, the player simply walks down the stairs into the street.
##
## This scene deliberately does NOT include a ground slab: the preserved
## apartment scene already provides one covering X -30..20, Z -25..20, and a
## second coplanar slab would z-fight.  Anything that uses neighbourhood.tscn on
## its own must supply ground at Y = -2.90.
##
## PLAN (street level, all metres)
##
##   NORTH ROW OF SHOPS  (fronting south at Z = -11.1)
##   corner shop  laundry  phone repair   [INTERNET CAFE]  alley  [CAFE CAFFEINE]  [MARKET]
##   -22        -18     -13    -12     -7   -6   -1   0        5   7.6          14.5   15   20
##   ------------------------------------------------------------------------------------ 
##   MAIN STREET   roadway Z -9.5..-3.5, footpaths either side      X -22..19
##   ------------------------------------------------------------------------------------
##   south footpath Z -3.5..-1.9 | arcade + apartment building X -4.8..8.7 | houses 10..19
##   ------------------------------------------------------------------------------------
##   PARK  X -22..-6, Z -1.9..6.5   (north gate onto the street, south gate onto the lane)
##   ------------------------------------------------------------------------------------
##   SOUTH LANE  roadway Z 6.5..10, X -22..2   <- the external staircase lands beside it
##   ------------------------------------------------------------------------------------
##   houses south of the lane (Z 11.5..16.5)
##
## Day 1 route: apartment -> walkway -> west stairs -> south lane -> park (south to
## north) -> main street -> bus stop -> Internet Cafe -> Cafe Caffeine.

const LIB := preload("res://tools/bo_lib.gd")
const Ambience := preload("res://scripts/world/ambience_zone.gd")
const Landmark := preload("res://scripts/world/landmark.gd")
const Catalog := preload("res://scripts/world/landmark_catalog.gd")

# ---------------------------------------------------------------- levels ----
const G := -2.90              # street level (the existing ground plane's top)
const SURF := 0.022           # surface finish thickness: sits 2 cm proud of the ground
const H := 3.20               # shop / house wall height above street level
const T := 0.30               # exterior wall thickness

# ------------------------------------------------------- main street (E-W) --
const ST_X0 := -22.0
const ST_X1 := 19.0
const ST_S := -3.5            # south kerb line (roadway edge)
const ST_N := -9.5            # north kerb line
const FP_S0 := -3.5           # south footpath
const FP_S1 := -1.9
const FP_N0 := -11.1          # north footpath
const FP_N1 := -9.5

# ------------------------------------------------------- south lane (E-W) --
const LN_X0 := -22.0
const LN_X1 := 2.0
const LN_N := 6.5
const LN_S := 10.0
const LN_FP0 := 5.6           # lane's north footpath, along the building's south face
const LN_FP1 := 6.5

# ----------------------------------------------------------- park (west) ----
const PK_X0 := -22.0
const PK_X1 := -6.0
const PK_Z0 := -1.9
const PK_Z1 := 6.5
const PK_PATH_X0 := -15.2     # north-south path
const PK_PATH_X1 := -13.2
const PK_PATH_Z0 := 1.6       # east-west path
const PK_PATH_Z1 := 3.4

# ------------------------------------------------------------ north row -----
const NR_FACE := -11.1        # shop fronts

# --------------------------------------------------------------- cafe -------
const CF_X0 := 7.6
const CF_X1 := 14.5
const CF_Z0 := -18.0
const CF_Z1 := -11.1
const CF_CEIL := 3.20
const CF_DOOR_X0 := 9.8
const CF_DOOR_X1 := 10.8

# ------------------------------------------------------- Maxwell's alley ----
const AL_X0 := 5.4
const AL_X1 := 7.2
const AL_Z0 := -20.0

# ------------------------------------------------------------- materials ----
static var _unit_box: BoxMesh
static var _cache: Dictionary = {}

static func _unit() -> BoxMesh:
	if _unit_box == null:
		_unit_box = BoxMesh.new()
		_unit_box.size = Vector3.ONE
	return _unit_box

## A tinted copy of one of the project's procedural materials, so the outdoor
## palette stays part of the same texture library instead of a second one.
static func mat_tint(base: String, tint: Color, rough: float = 0.95) -> StandardMaterial3D:
	var key: String = "%s|%s|%f" % [base, tint.to_html(false), rough]
	if _cache.has(key):
		return _cache[key]
	var src: StandardMaterial3D = LIB.mat(base) as StandardMaterial3D
	var m: StandardMaterial3D = src.duplicate() as StandardMaterial3D
	m.albedo_color = tint
	m.roughness = rough
	_cache[key] = m
	return m

static func m_asphalt() -> StandardMaterial3D:
	return mat_tint("concrete", Color(0.235, 0.235, 0.250), 0.97)

static func m_paving() -> StandardMaterial3D:
	return mat_tint("concrete", Color(0.640, 0.620, 0.585), 0.94)

static func m_kerb() -> StandardMaterial3D:
	return mat_tint("concrete", Color(0.720, 0.700, 0.660), 0.93)

static func m_grass() -> StandardMaterial3D:
	return mat_tint("ground", Color(0.360, 0.520, 0.240), 0.99)

static func m_hedge() -> StandardMaterial3D:
	return mat_tint("plant", Color(0.300, 0.460, 0.230), 0.98)

static func m_roof() -> StandardMaterial3D:
	return mat_tint("concrete", Color(0.400, 0.290, 0.235), 0.94)

static func m_shutter() -> StandardMaterial3D:
	return mat_tint("metal", Color(0.520, 0.545, 0.555), 0.72)

static func m_sign_dark() -> StandardMaterial3D:
	return mat_tint("paint_white", Color(0.130, 0.150, 0.170), 0.80)

static func m_awning() -> StandardMaterial3D:
	return mat_tint("fabric", Color(0.760, 0.290, 0.230), 0.95)

static func m_recess() -> StandardMaterial3D:
	return mat_tint("dark", Color(0.130, 0.125, 0.120), 0.99)

# ---------------------------------------------------------------- builder ----

static func run(save_path: String = "res://scenes/neighborhood.tscn") -> Dictionary:
	_write_prefabs()

	var root := Node3D.new()
	root.name = "Neighborhood"

	_surfaces(root)
	_park(root)
	_apartment_frontage(root)
	_north_row(root)
	_south_side(root)
	_west_block(root)
	_maxwell(root)
	_street_furniture(root)
	_cafe(root)
	_landmarks(root)
	_ambience(root)

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

# -------------------------------------------------------------- surfaces ----

## One paved / painted surface: a thin slab that carries its own collision and a
## `surface` meta, so FFFootsteps can name what Chris is walking on.
static func _surface(parent: Node3D, name: String, material: Material, x0: float,
		x1: float, z0: float, z1: float, surface: String) -> void:
	var cont := Node3D.new()
	cont.name = name
	parent.add_child(cont)
	var size := Vector3(x1 - x0, SURF, z1 - z0)
	var pos := Vector3((x0 + x1) * 0.5, G + SURF * 0.5, (z0 + z1) * 0.5)
	_mbo(cont, "Surface", material, pos, size)
	var body := LIB.collider(cont, "Body", pos, size)
	body.set_meta("surface", surface)

static func _surfaces(root: Node3D) -> void:
	var s := Node3D.new()
	s.name = "Surfaces"
	root.add_child(s)

	# main street
	_surface(s, "StreetRoadway", m_asphalt(), ST_X0, ST_X1, ST_N, ST_S, "asphalt")
	_surface(s, "StreetFootpathSouth", m_paving(), ST_X0, ST_X1, FP_S0, FP_S1, "paving")
	_surface(s, "StreetFootpathNorth", m_paving(), ST_X0, ST_X1, FP_N0, FP_N1, "paving")
	# kerbs (thin raised strips, walk-over height)
	_mbo(s, "KerbSouth", m_kerb(), Vector3((ST_X0 + ST_X1) * 0.5, G + 0.07, ST_S - 0.08),
		Vector3(ST_X1 - ST_X0, 0.14, 0.16))
	_mbo(s, "KerbNorth", m_kerb(), Vector3((ST_X0 + ST_X1) * 0.5, G + 0.07, ST_N + 0.08),
		Vector3(ST_X1 - ST_X0, 0.14, 0.16))
	# south lane, and the short path from the staircase landing to the lane
	_surface(s, "LaneRoadway", m_asphalt(), LN_X0, LN_X1, LN_N, LN_S, "asphalt")
	_surface(s, "LaneFootpath", m_paving(), LN_X0, LN_X1, LN_FP0, LN_FP1, "paving")
	_surface(s, "StairApproach", m_paving(), -6.10, -4.70, 5.05, LN_N, "paving")
	# Maxwell's alley
	_surface(s, "Alley", m_paving(), AL_X0, AL_X1, AL_Z0, NR_FACE, "paving")
	# arcade floor under the apartment walkway
	_surface(s, "Arcade", m_paving(), -6.00, 9.20, -1.90, -0.25, "paving")

# ------------------------------------------------------------------ park ----

static func _park(root: Node3D) -> void:
	var p := Node3D.new()
	p.name = "Park"
	root.add_child(p)

	_surface(p, "Lawn", m_grass(), PK_X0, PK_X1, PK_Z0, PK_Z1, "grass")
	_surface(p, "PathNorthSouth", m_paving(), PK_PATH_X0, PK_PATH_X1, PK_Z0, PK_Z1, "paving")
	_surface(p, "PathEastWest", m_paving(), PK_X0, PK_X1, PK_PATH_Z0, PK_PATH_Z1, "paving")
	_surface(p, "EntranceNorth", m_paving(), PK_PATH_X0 - 0.6, PK_PATH_X1 + 0.6,
		FP_S0 - 0.2, PK_Z0 + 0.05, "paving")

	# low perimeter wall, open at the two gates
	var wy: float = G + 0.46
	_wall(p, "WallSouthA", PK_X0, PK_PATH_X0 - 0.2, PK_Z1 - 0.18, PK_Z1, wy)
	_wall(p, "WallSouthB", PK_PATH_X1 + 0.2, PK_X1, PK_Z1 - 0.18, PK_Z1, wy)
	_wall(p, "WallWest", PK_X0, PK_X0 + 0.18, PK_Z0, PK_Z1, wy, true)
	_wall(p, "WallEastA", PK_X1 - 0.18, PK_X1, PK_Z0, PK_PATH_Z0 - 0.2, wy, true)
	_wall(p, "WallEastB", PK_X1 - 0.18, PK_X1, PK_PATH_Z1 + 0.2, PK_Z1, wy, true)

	LIB.place(p, "bench", "BenchA", Vector3(-18.4, G, 4.6), 90.0)
	LIB.place(p, "bench", "BenchB", Vector3(-16.4, G, 0.2), 270.0)
	LIB.place(p, "bench", "BenchC", Vector3(-9.2, G, 2.5), 90.0)
	LIB.place(p, "nb_tree", "TreeA", Vector3(-20.2, G, 0.6), 12.0)
	LIB.place(p, "nb_tree", "TreeB", Vector3(-18.0, G, -0.9), 200.0)
	LIB.place(p, "nb_tree", "TreeC", Vector3(-10.4, G, -0.8), 88.0)
	LIB.place(p, "nb_tree", "TreeD", Vector3(-8.0, G, 4.9), 150.0)
	LIB.place(p, "nb_tree", "TreeE", Vector3(-20.6, G, 3.2), 300.0)
	LIB.place(p, "nb_planter", "PlanterPark", Vector3(-13.0, G, -1.2), 0.0)
	LIB.omni(p, "ParkLampGlow", Vector3(-14.2, G + 2.6, 2.5), 0.55, 6.0,
		Color(1.0, 0.90, 0.74), false)

# ---------------------------------------------------- apartment frontage ----

## The ground floor under the preserved walkway: a row of shuttered shop units
## with one open corner shop, so the building's base reads as a real shophouse
## block instead of a hollow shell.  Nothing structural is touched.
static func _apartment_frontage(root: Node3D) -> void:
	var f := Node3D.new()
	f.name = "Frontage"
	root.add_child(f)

	var face: float = -0.25      # the building's existing ground-floor facade plane
	var shut_y: float = G + 1.55

	# shuttered units west of the corner shop
	_shuttered_unit(f, "UnitWest", -3.80, 1.60, face, "PHONE REPAIR")
	_shuttered_unit(f, "UnitMid", 1.80, 3.00, face, "")
	# the corner shop: shutter up, counter, goods, warm light
	_corner_shop(f, 3.20, 6.20, face)
	_shuttered_unit(f, "UnitEast", 6.40, 8.50, face, "TAILOR")

	# fascia band running the length of the arcade, and its awning lip
	_mbo(f, "Fascia", m_sign_dark(), Vector3(2.2, shut_y + 0.62, face + 0.03),
		Vector3(12.4, 0.34, 0.06))
	_mbo(f, "ArcadeEdge", m_kerb(), Vector3(1.6, G + 0.06, -1.82), Vector3(15.2, 0.12, 0.14))

static func _shuttered_unit(parent: Node3D, name: String, x0: float, x1: float,
		face: float, sign: String) -> void:
	var u := Node3D.new()
	u.name = name
	parent.add_child(u)
	var w: float = x1 - x0
	var cx: float = (x0 + x1) * 0.5
	# recessed opening, rolled shutter above, goods-less dark interior
	_mbo(u, "Recess", m_recess(), Vector3(cx, G + 1.05, face + 0.10),
		Vector3(w - 0.30, 2.10, 0.02))
	_mbo(u, "Shutter", m_shutter(), Vector3(cx, G + 2.32, face + 0.14),
		Vector3(w - 0.24, 0.34, 0.08))
	_mbo(u, "ShutterRail", m_shutter(), Vector3(cx, G + 0.62, face + 0.13),
		Vector3(w - 0.24, 0.16, 0.06))
	_mbo(u, "PierW", m_sign_dark(), Vector3(x0 + 0.09, G + 1.10, face + 0.05),
		Vector3(0.18, 2.20, 0.10))
	_mbo(u, "PierE", m_sign_dark(), Vector3(x1 - 0.09, G + 1.10, face + 0.05),
		Vector3(0.18, 2.20, 0.10))
	if not sign.is_empty():
		_sign(u, "Sign", sign, Vector3(cx, G + 2.72, face - 0.02), 180.0, minf(w - 0.5, 2.6), 0.30)

## The one open unit: shutter rolled up, lit interior, counter and stock.
static func _corner_shop(parent: Node3D, x0: float, x1: float, face: float) -> void:
	var k := Node3D.new()
	k.name = "CornerShop"
	parent.add_child(k)
	var w: float = x1 - x0
	var cx: float = (x0 + x1) * 0.5
	_mbo(k, "Interior", m_recess(), Vector3(cx, G + 1.15, face + 0.10),
		Vector3(w - 0.30, 2.30, 0.02))
	# stock shelves, readable through the opening
	_mbo(k, "Shelf", LIB.mat("wood"), Vector3(cx, G + 1.60, face + 0.28),
		Vector3(w - 0.60, 0.05, 0.30))
	for i: int in 6:
		var bx: float = x0 + 0.45 + float(i) * 0.36
		_mbo(k, "Goods%d" % i, LIB.mat("plastic"),
			Vector3(bx, G + 1.72, face + 0.28), Vector3(0.14, 0.20, 0.14))
	_mbo(k, "Counter", LIB.mat("wood_light"), Vector3(cx, G + 0.98, face + 0.22),
		Vector3(w - 0.50, 0.08, 0.34))
	_mbo(k, "CounterFront", LIB.mat("wood"), Vector3(cx, G + 0.49, face + 0.36),
		Vector3(w - 0.50, 0.98, 0.06))
	_mbo(k, "RolledShutter", m_shutter(), Vector3(cx, G + 2.44, face + 0.12),
		Vector3(w - 0.20, 0.26, 0.14))
	_mbo(k, "PierW", m_sign_dark(), Vector3(x0 + 0.09, G + 1.20, face + 0.05),
		Vector3(0.18, 2.40, 0.10))
	_mbo(k, "PierE", m_sign_dark(), Vector3(x1 - 0.09, G + 1.20, face + 0.05),
		Vector3(0.18, 2.40, 0.10))
	_sign(k, "Sign", "CORNER SHOP", Vector3(cx, G + 2.78, face - 0.02), 180.0, w - 0.5, 0.30)
	LIB.omni(k, "ShopGlow", Vector3(cx, G + 2.05, face + 0.30), 0.85, 3.2,
		Color(1.0, 0.86, 0.66), false)
	LIB.omni(k, "Spill", Vector3(cx, G + 1.60, face - 0.70), 0.35, 3.0,
		Color(1.0, 0.88, 0.72), false)

# ------------------------------------------------------------- north row ----

static func _north_row(root: Node3D) -> void:
	var r := Node3D.new()
	r.name = "NorthRow"
	root.add_child(r)

	# laundry, phone repair, closed unit - low shop buildings fronting the street
	_shop_block(r, "Laundry", -22.0, -13.0, NR_FACE, -18.0, "LAUNDRY", true, 3)
	_shop_block(r, "PhoneRepair", -12.0, -7.0, NR_FACE, -16.0, "PHONE REPAIR", true, 2)
	_shop_block(r, "ClosedUnit", -6.0, -1.0, NR_FACE, -15.0, "", true, 0)
	# the internet cafe: exterior only this session, readable from the street
	_internet_cafe(r)
	# the market hall, east end
	_market(r)

## A simple shop building: four walls, a roof and a glass front with a sign.
## `interior` false leaves the front recessed and dark (a closed unit).
static func _shop_block(parent: Node3D, name: String, x0: float, x1: float,
		z_front: float, z_back: float, sign: String, glazed: bool, screens: int) -> void:
	var b := Node3D.new()
	b.name = name
	parent.add_child(b)
	var top: float = G + H
	LIB.wall(b, "Back", "wall", "x", x0, x1, z_back, z_back + T, G, top)
	LIB.wall(b, "West", "wall", "z", z_back, z_front, x0, x0 + T, G, top)
	LIB.wall(b, "East", "wall", "z", z_back, z_front, x1 - T, x1, G, top)
	var ops: Array = []
	if glazed:
		ops.append([x0 + 0.55, x1 - 0.55, G + 0.85, G + 2.35])
	else:
		ops.append([x0 + 0.45, x1 - 0.45, G + 0.35, G + 2.20])
	LIB.wall(b, "Front", "wall", "x", x0, x1, z_front, z_front + T, G, top, ops)
	LIB.slab(b, "Roof", "concrete", x0 - 0.12, x1 + 0.12, z_back - 0.12, z_front + 0.12,
		top, 0.22)
	if glazed:
		_mbo(b, "Glass", LIB.mat("glass"), Vector3((x0 + x1) * 0.5, G + 1.60, z_front + 0.12),
			Vector3(x1 - x0 - 1.10, 1.50, 0.04))
		_mbo(b, "Recess", m_recess(), Vector3((x0 + x1) * 0.5, G + 1.60, z_front + 0.30),
			Vector3(x1 - x0 - 1.10, 1.50, 0.02))
	else:
		_mbo(b, "Shutter", m_shutter(), Vector3((x0 + x1) * 0.5, G + 1.28, z_front + 0.16),
			Vector3(x1 - x0 - 0.90, 1.86, 0.06))
	for i: int in screens:
		_mbo(b, "Unit%d" % i, LIB.mat("plastic_dark"),
			Vector3(x0 + 0.85 + float(i) * 0.62, G + 1.35, z_front + 0.34),
			Vector3(0.46, 0.60, 0.42))
	if not sign.is_empty():
		_sign(b, "Sign", sign, Vector3((x0 + x1) * 0.5, G + 2.62, z_front - 0.02),
			180.0, minf(x1 - x0 - 1.0, 4.4), 0.34)
	LIB.omni(b, "ShopGlow", Vector3((x0 + x1) * 0.5, G + 2.10, z_front + 0.55), 0.40, 3.4,
		Color(1.0, 0.87, 0.70), false)

static func _internet_cafe(parent: Node3D) -> void:
	var b := Node3D.new()
	b.name = "InternetCafe"
	parent.add_child(b)
	var x0: float = 0.0
	var x1: float = 5.0
	var z_front: float = NR_FACE
	var z_back: float = -15.0
	var top: float = G + H
	LIB.wall(b, "Back", "wall", "x", x0, x1, z_back, z_back + T, G, top)
	LIB.wall(b, "West", "wall", "z", z_back, z_front, x0, x0 + T, G, top)
	LIB.wall(b, "East", "wall", "z", z_back, z_front, x1 - T, x1, G, top)
	LIB.wall(b, "Front", "wall", "x", x0, x1, z_front, z_front + T, G, top,
		[[x0 + 0.45, x1 - 0.45, G + 0.25, G + 2.45]])
	LIB.slab(b, "Roof", "concrete", x0 - 0.12, x1 + 0.12, z_back - 0.12, z_front + 0.12,
		top, 0.22)
	# dark interior with a grid of screens behind the glass
	_mbo(b, "Interior", m_recess(), Vector3((x0 + x1) * 0.5, G + 1.35, z_front + 0.32),
		Vector3(x1 - x0 - 0.90, 2.20, 0.02))
	for i: int in 8:
		var col: float = float(i % 4)
		var row: float = float(i / 4)
		_mbo(b, "Screen%d" % i, LIB.mat("screen"),
			Vector3(x0 + 0.95 + col * 0.85, G + 1.25 + row * 0.10, z_front + 0.38),
			Vector3(0.42, 0.30, 0.06))
	_mbo(b, "Glass", LIB.mat("glass"), Vector3((x0 + x1) * 0.5, G + 1.35, z_front + 0.14),
		Vector3(x1 - x0 - 0.90, 2.20, 0.04))
	_sign(b, "Sign", "INTERNET CAFE", Vector3((x0 + x1) * 0.5, G + 2.78, z_front - 0.02),
		180.0, 4.2, 0.40)
	LIB.omni(b, "ScreenGlow", Vector3((x0 + x1) * 0.5, G + 1.60, z_front + 0.60), 0.55, 3.6,
		Color(0.62, 0.78, 1.0), false)

static func _market(parent: Node3D) -> void:
	var m := Node3D.new()
	m.name = "Market"
	parent.add_child(m)
	var x0: float = 15.0
	var x1: float = 20.0
	var z_front: float = NR_FACE
	var z_back: float = -17.0
	var top: float = G + 3.60
	LIB.wall(m, "Back", "wall", "x", x0, x1, z_back, z_back + T, G, top)
	LIB.wall(m, "West", "wall", "z", z_back, z_front, x0, x0 + T, G, top)
	LIB.wall(m, "East", "wall", "z", z_back, z_front, x1 - T, x1, G, top)
	# open front: only a beam over the entrance
	_mbo(m, "Beam", LIB.mat("concrete"), Vector3((x0 + x1) * 0.5, G + 3.05, z_front - 0.15),
		Vector3(x1 - x0, 0.30, 0.30))
	LIB.slab(m, "Roof", "concrete", x0 - 0.15, x1 + 0.15, z_back - 0.15, z_front + 0.15,
		top, 0.24)
	_mbo(m, "Interior", m_recess(), Vector3((x0 + x1) * 0.5, G + 1.50, z_back + 0.40),
		Vector3(x1 - x0 - 0.90, 3.00, 0.02))
	LIB.place(m, "nb_stall", "StallW", Vector3(x0 + 1.20, G, z_front - 1.30), 0.0)
	LIB.place(m, "nb_stall", "StallE", Vector3(x1 - 1.20, G, z_front - 1.30), 0.0)
	LIB.place(m, "nb_stall", "StallBack", Vector3((x0 + x1) * 0.5, G, z_back + 1.60), 0.0)
	_mbo(m, "Crates", LIB.mat("wood_light"), Vector3((x0 + x1) * 0.5, G + 0.24,
		z_front - 2.55), Vector3(1.10, 0.48, 0.70))
	_sign(m, "Sign", "MARKET", Vector3((x0 + x1) * 0.5, G + 3.42, z_front - 0.20),
		180.0, 3.0, 0.42)

# ------------------------------------------------------------ south side ----

static func _south_side(root: Node3D) -> void:
	var s := Node3D.new()
	s.name = "SouthSide"
	root.add_child(s)
	# houses east of the apartment, on the street's south side
	_house(s, "HouseE1", 10.0, 14.0, -1.9, 3.0, "wall", 2.90)
	_house(s, "HouseE2", 15.0, 19.0, -1.9, 3.5, "paint_white", 3.20)
	# houses south of the lane, closing the view behind the park
	_house(s, "HouseS1", -20.0, -15.0, 11.5, 16.5, "wall", 2.90)
	_house(s, "HouseS2", -13.0, -8.0, 11.5, 16.0, "paint_white", 3.10)
	_house(s, "HouseS3", -6.0, -1.0, 11.5, 16.5, "wall", 2.90)
	# low compound walls along the lane
	_wall(s, "LaneWallS1", -21.4, -14.2, 10.9, 11.1, G + 0.80)
	_wall(s, "LaneWallS2", -12.6, -1.4, 10.9, 11.1, G + 0.80)

## A simple two-storey house shell: solid mass, roof cap, door and windows.
static func _house(parent: Node3D, name: String, x0: float, x1: float, z0: float,
		z1: float, mat_key: String, height: float) -> void:
	var h := Node3D.new()
	h.name = name
	parent.add_child(h)
	var top: float = G + height
	var size := Vector3(x1 - x0, height, z1 - z0)
	var pos := Vector3((x0 + x1) * 0.5, G + height * 0.5, (z0 + z1) * 0.5)
	_mbo(h, "Mass", LIB.mat(mat_key), pos, size)
	LIB.collider(h, "Body", pos, size)
	LIB.slab(h, "Roof", "concrete", x0 - 0.20, x1 + 0.20, z0 - 0.20, z1 + 0.20, top + 0.16, 0.18)
	# a door and two windows on the street-facing side
	_mbo(h, "Door", LIB.mat("door"), Vector3((x0 + x1) * 0.5, G + 1.00, z0 - 0.03),
		Vector3(0.92, 2.00, 0.06))
	_mbo(h, "WinW", LIB.mat("dark"), Vector3(x0 + 1.10, G + 1.70, z0 - 0.03),
		Vector3(0.90, 0.90, 0.05))
	_mbo(h, "WinE", LIB.mat("dark"), Vector3(x1 - 1.10, G + 1.70, z0 - 0.03),
		Vector3(0.90, 0.90, 0.05))
	_mbo(h, "Eave", m_roof(), Vector3((x0 + x1) * 0.5, top + 0.06, z0 - 0.30),
		Vector3(x1 - x0 + 0.40, 0.10, 0.60))

# ------------------------------------------------------------- west block ----

static func _west_block(root: Node3D) -> void:
	var w := Node3D.new()
	w.name = "WestBlock"
	root.add_child(w)
	_house(w, "WestHouse", -26.5, -23.0, -6.0, 2.0, "wall", 3.40)
	_wall(w, "WestCompound", -22.6, -22.4, -6.0, 6.5, G + 1.10, true)
	LIB.place(w, "nb_tree", "TreeWest", Vector3(-22.0, G, -7.6), 40.0)

# --------------------------------------------------------------- Maxwell ----

static func _maxwell(root: Node3D) -> void:
	var m := Node3D.new()
	m.name = "MaxwellHome"
	root.add_child(m)
	# compound wall along the alley's end, with a gate
	_wall(m, "CompoundW", 2.0, AL_X0, -20.2, -20.0, G + 1.70)
	_wall(m, "CompoundE", AL_X1, 11.0, -20.2, -20.0, G + 1.70)
	_house(m, "MaxwellHouse", 4.0, 8.6, -24.4, -21.0, "wall", 3.00)
	LIB.place(m, "nb_tree", "TreeMaxwell", Vector3(10.0, G, -21.6), 120.0)
	LIB.place(m, "nb_scooter", "ScooterMaxwell", Vector3(9.6, G, -20.9), 250.0)

# --------------------------------------------------------- street detail ----

static func _street_furniture(root: Node3D) -> void:
	var f := Node3D.new()
	f.name = "StreetFurniture"
	root.add_child(f)

	# utility poles along the street's south side, wires between them
	var poles: Array[float] = [-20.0, -11.0, -2.0, 7.0, 16.0]
	for px: float in poles:
		LIB.place(f, "nb_pole", "Pole_%d" % int(px), Vector3(px, G, ST_S - 0.55), 0.0)
	for i: int in poles.size() - 1:
		var a: float = poles[i]
		var b: float = poles[i + 1]
		var span: float = b - a
		for k: int in 3:
			LIB.box(f, "Wire_%d_%d" % [i, k], "metal_dark",
				Vector3((a + b) * 0.5, G + 6.05 - float(k) * 0.16, ST_S - 0.55),
				Vector3(span, 0.025, 0.025), Vector3(0, 0, -0.6 + float(k) * 0.6))

	# street lamps at two poles
	LIB.omni(f, "StreetLampGlow", Vector3(-11.0, G + 6.20, ST_S - 0.55), 0.0, 9.0,
		Color(1.0, 0.90, 0.76), false)

	# the bus stop: shelter, bench and a post, on the park's corner
	var bs := Node3D.new()
	bs.name = "BusStop"
	f.add_child(bs)
	LIB.place(bs, "nb_shelter", "Shelter", Vector3(-11.0, G, ST_S - 1.15), 180.0)
	LIB.place(bs, "bench", "Bench", Vector3(-11.0, G, ST_S - 1.05), 0.0)
	_sign(bs, "StopSign", "BUS STOP", Vector3(-9.3, G + 2.35, ST_S - 0.55), 180.0, 1.1, 0.26)

	# junction street sign at the lane mouth
	_sign(f, "StreetSign", "JALAN MELATI", Vector3(-14.0, G + 2.55, ST_S - 0.55),
		180.0, 2.2, 0.28)

	# parked vehicles, bins and trees along the street
	LIB.place(f, "nb_car", "CarA", Vector3(-16.0, G, ST_S - 1.10), 88.0)
	LIB.place(f, "nb_car", "CarB", Vector3(12.5, G, ST_N + 1.10), 268.0)
	LIB.place(f, "nb_scooter", "ScooterA", Vector3(2.6, G, ST_S - 1.15), 92.0)
	LIB.place(f, "nb_scooter", "ScooterB", Vector3(-6.0, G, ST_S - 1.20), 84.0)
	LIB.place(f, "nb_bin", "BinA", Vector3(-2.0, G, ST_S - 0.70), 0.0)
	LIB.place(f, "nb_bin", "BinB", Vector3(9.0, G, ST_N + 0.70), 0.0)
	LIB.place(f, "nb_tree", "TreeStreetA", Vector3(-19.0, G, ST_S - 0.80), 20.0)
	LIB.place(f, "nb_tree", "TreeStreetB", Vector3(4.0, G, ST_S - 0.85), 100.0)
	LIB.place(f, "nb_tree", "TreeStreetC", Vector3(-7.5, G, ST_N + 0.85), 260.0)
	LIB.place(f, "nb_planter", "PlanterA", Vector3(0.6, G, ST_N + 0.75), 0.0)
	LIB.place(f, "nb_planter", "PlanterB", Vector3(15.6, G, ST_N + 0.75), 0.0)

	# --- the one piece of walkability the preserved apartment cannot provide ---
	# The external staircase rises 0.181 m per step, which a bare move_and_slide
	# capsule cannot climb (it treats the riser as a wall). The staircase belongs
	# to the preserved apartment scene, so the neighbourhood carries a thin sloped
	# walking surface laid over the flight instead: one ramp collider, tucked
	# under the step geometry, that keeps both the descent and the climb smooth.
	# Its ends sit a couple of centimetres below the walkway and the bottom pad,
	# so there is no lip in either direction.
	_stair_ramp(root)

## Sloped walk surface over the apartment's external staircase (X -6.00..-4.80,
## top step at Z -0.25 Y 0, bottom pad at Z 3.91 Y -2.90).
static func _stair_ramp(root: Node3D) -> void:
	var r := Node3D.new()
	r.name = "StairRamp"
	root.add_child(r)
	var top_z: float = -0.35
	var top_y: float = G + 2.87        # just under the walkway deck
	var bot_z: float = 4.30
	var bot_y: float = G - 0.02        # just under the bottom pad
	var run: float = bot_z - top_z
	var rise: float = bot_y - top_y
	var length: float = sqrt(run * run + rise * rise) + 0.10
	var angle: float = rad_to_deg(atan2(-rise, run))
	var centre := Vector3(-5.40, (top_y + bot_y) * 0.5, (top_z + bot_z) * 0.5)
	var body: StaticBody3D = LIB.collider(r, "RampBody", centre,
		Vector3(1.16, 0.14, length))
	body.rotation_degrees = Vector3(angle, 0.0, 0.0)
	body.set_meta("surface", "concrete")

# ------------------------------------------------------------------ cafe ----

## Cafe Caffeine: exterior shell plus the compact interior the next session needs
## - entrance, counter, window bench, three tables (one four-seat target table
## for Sofia, Bobby and Chris) and a clear door-to-counter service route.
static func _cafe(root: Node3D) -> void:
	var c := Node3D.new()
	c.name = "CafeCaffeine"
	root.add_child(c)

	var top: float = G + CF_CEIL
	# south (front) wall: door + two shop windows
	LIB.wall(c, "Front", "wall", "x", CF_X0, CF_X1, CF_Z1 - T, CF_Z1, G, top, [
		[CF_DOOR_X0, CF_DOOR_X1, G, G + 2.20],
		[8.10, 9.50, G + 0.95, G + 2.35],
		[11.10, 13.90, G + 0.95, G + 2.35],
	])
	LIB.wall(c, "Back", "wall", "x", CF_X0, CF_X1, CF_Z0, CF_Z0 + T, G, top)
	LIB.wall(c, "West", "wall", "z", CF_Z0, CF_Z1, CF_X0, CF_X0 + T, G, top)
	LIB.wall(c, "East", "wall", "z", CF_Z0, CF_Z1, CF_X1 - T, CF_X1, G, top)
	LIB.slab(c, "Roof", "concrete", CF_X0 - 0.15, CF_X1 + 0.15, CF_Z0 - 0.15, CF_Z1 + 0.15,
		top, 0.24)
	# interior floor finish
	LIB.slab(c, "Floor", "floor_tile", CF_X0 + T, CF_X1 - T, CF_Z0 + T, CF_Z1 - T,
		G + 0.024, 0.02, false)

	# glass and window frames in the front openings
	for w: Array in [[8.10, 9.50], [11.10, 13.90]]:
		_mbo(c, "WinGlass_%d" % int(w[0]), LIB.mat("glass"),
			Vector3((w[0] + w[1]) * 0.5, G + 1.65, CF_Z1 - 0.16),
			Vector3(w[1] - w[0], 1.40, 0.04))
		_mbo(c, "WinFrame_%d" % int(w[0]), LIB.mat("paint_white"),
			Vector3((w[0] + w[1]) * 0.5, G + 1.65, CF_Z1 - 0.10),
			Vector3(w[1] - w[0] + 0.10, 0.06, 0.10))
	# the door leaf: pivot at the west jamb, opens inward into the cafe
	var pivot := Node3D.new()
	pivot.name = "CafeDoor"
	pivot.position = Vector3(CF_DOOR_X0, G, CF_Z1 - 0.15)
	pivot.rotation_degrees = Vector3(0, 180, 0)
	c.add_child(pivot)
	_mbo(pivot, "Panel", LIB.mat("door"), Vector3(-0.50, 1.06, 0), Vector3(1.00, 2.12, 0.05))
	_mbo(pivot, "Glaze", LIB.mat("glass"), Vector3(-0.50, 1.55, 0.03), Vector3(0.74, 0.70, 0.02))
	_mbo(pivot, "Handle", LIB.mat("metal"), Vector3(-0.92, 1.02, -0.06), Vector3(0.05, 0.05, 0.10))
	var door_body := LIB.collider(pivot, "Body", Vector3(-0.50, 1.06, 0), Vector3(1.00, 2.12, 0.06))

	# counter along the back wall, with a shelf, machine and cups
	_mbo(c, "Counter", LIB.mat("wood_light"), Vector3(10.60, G + 1.00, -16.72),
		Vector3(4.00, 0.10, 0.56))
	_mbo(c, "CounterFront", LIB.mat("wood"), Vector3(10.60, G + 0.50, -16.44),
		Vector3(4.00, 1.00, 0.06))
	_mbo(c, "BackShelf", LIB.mat("wood"), Vector3(10.60, G + 1.70, -17.48),
		Vector3(4.20, 0.06, 0.30))
	for i: int in 5:
		_mbo(c, "Cup%d" % i, LIB.mat("ceramic"),
			Vector3(9.10 + float(i) * 0.62, G + 1.11, -16.72), Vector3(0.09, 0.11, 0.09))
	_mbo(c, "Machine", LIB.mat("metal"), Vector3(12.60, G + 1.20, -16.95),
		Vector3(0.60, 0.40, 0.44))
	_mbo(c, "Grinder", LIB.mat("plastic_dark"), Vector3(8.90, G + 1.15, -16.90),
		Vector3(0.22, 0.30, 0.22))
	# menu board on the back wall
	_sign(c, "Menu", "COFFEE", Vector3(11.30, G + 2.30, CF_Z0 + T + 0.02), 0.0, 1.8, 0.30)

	# window bench along the front glass
	_mbo(c, "BenchTop", LIB.mat("wood_light"), Vector3(12.50, G + 0.46, -11.86),
		Vector3(2.60, 0.07, 0.46))
	_mbo(c, "BenchLegW", LIB.mat("wood"), Vector3(11.30, G + 0.23, -11.86),
		Vector3(0.08, 0.46, 0.42))
	_mbo(c, "BenchLegE", LIB.mat("wood"), Vector3(13.70, G + 0.23, -11.86),
		Vector3(0.08, 0.46, 0.42))

	# three tables: T1 is the four-seat table by the west window (the meeting
	# table for the next session), T2 and T3 are ordinary two-seat tables.
	LIB.place(c, "nb_table", "Table1", Vector3(9.30, G, -13.30), 0.0)
	LIB.place(c, "chair", "T1ChairS", Vector3(9.30, G, -12.60), 180.0)
	LIB.place(c, "chair", "T1ChairN", Vector3(9.30, G, -14.00), 0.0)
	LIB.place(c, "chair", "T1ChairW", Vector3(8.65, G, -13.30), 90.0)
	LIB.place(c, "chair", "T1ChairE", Vector3(9.95, G, -13.30), 270.0)
	LIB.place(c, "nb_table", "Table2", Vector3(12.90, G, -14.60), 0.0)
	LIB.place(c, "chair", "T2ChairA", Vector3(12.90, G, -13.90), 180.0)
	LIB.place(c, "chair", "T2ChairB", Vector3(12.90, G, -15.30), 0.0)
	LIB.place(c, "nb_table", "Table3", Vector3(9.60, G, -15.90), 0.0)
	LIB.place(c, "chair", "T3ChairA", Vector3(9.60, G, -15.20), 180.0)
	LIB.place(c, "chair", "T3ChairB", Vector3(9.60, G, -16.60), 0.0)

	# back room door (kept shut: background only this session)
	_mbo(c, "BackDoor", LIB.mat("door"), Vector3(13.90, G + 1.05, CF_Z0 + T + 0.03),
		Vector3(0.90, 2.10, 0.06))
	# plants and a coat rail by the door
	LIB.place(c, "plant_pot", "CafePlantA", Vector3(8.20, G, -17.30), 0.0)
	LIB.place(c, "plant_pot", "CafePlantB", Vector3(14.10, G, -11.60), 0.0)

	# exterior signage and awning
	_sign(c, "Sign", "CAFE CAFFEINE", Vector3((CF_X0 + CF_X1) * 0.5, G + 2.92, CF_Z1 - 0.05),
		180.0, 5.0, 0.46)
	_mbo(c, "Awning", m_awning(), Vector3((CF_X0 + CF_X1) * 0.5, G + 2.62, CF_Z1 + 0.42),
		Vector3(CF_X1 - CF_X0 - 0.40, 0.08, 1.00), Vector3(-12, 0, 0))
	_mbo(c, "AwningFascia", m_awning(), Vector3((CF_X0 + CF_X1) * 0.5, G + 2.52, CF_Z1 + 0.88),
		Vector3(CF_X1 - CF_X0 - 0.40, 0.22, 0.06))

	# interior lighting: warm, ordinary
	LIB.omni(c, "CafeLampW", Vector3(9.60, G + 2.85, -13.60), 1.35, 6.5,
		Color(1.0, 0.88, 0.72), true)
	LIB.omni(c, "CafeLampE", Vector3(12.60, G + 2.85, -15.60), 1.20, 6.5,
		Color(1.0, 0.89, 0.74), true)
	LIB.omni(c, "CounterGlow", Vector3(10.60, G + 2.30, -16.60), 0.75, 4.0,
		Color(1.0, 0.86, 0.68), false)
	# exterior spill so the entrance reads at street level
	LIB.omni(c, "EntranceSpill", Vector3(10.30, G + 2.40, CF_Z1 + 0.60), 0.55, 4.5,
		Color(1.0, 0.90, 0.78), false)

# -------------------------------------------------------------- landmarks ----

static func _landmarks(root: Node3D) -> void:
	var l := Node3D.new()
	l.name = "Landmarks"
	root.add_child(l)
	# id, centre, extent
	_landmark(l, "apartment", Vector3(3.80, G + 1.20, -1.20), Vector3(4.0, 3.0, 3.0))
	_landmark(l, "corner_store", Vector3(4.70, G + 1.40, -1.10), Vector3(4.5, 3.0, 2.6))
	_landmark(l, "park", Vector3(-14.0, G + 1.50, 2.30), Vector3(15.0, 3.5, 8.0))
	_landmark(l, "bus_stop", Vector3(-11.0, G + 1.50, -2.60), Vector3(3.6, 3.5, 3.0))
	_landmark(l, "internet_cafe", Vector3(2.50, G + 1.50, -10.10), Vector3(6.4, 3.5, 3.4))
	_landmark(l, "cafe_caffeine", Vector3(11.00, G + 1.50, -10.40), Vector3(7.6, 3.5, 3.6))
	_landmark(l, "market", Vector3(17.50, G + 1.50, -10.10), Vector3(5.4, 3.5, 3.4))
	_landmark(l, "maxwell_home", Vector3(6.30, G + 1.50, -21.00), Vector3(9.0, 3.5, 4.0))

static func _landmark(parent: Node3D, id: String, pos: Vector3, extent: Vector3) -> void:
	if not Catalog.has_id(id):
		push_error("BOBuildNeighborhood: '%s' is not in FFLandmarkCatalog" % id)
		return
	var node: Area3D = Landmark.new()
	node.name = "Landmark_" + id
	node.set("landmark_id", id)
	parent.add_child(node)
	node.position = pos
	node.call("configure", extent)

# --------------------------------------------------------------- ambience ----

static func _ambience(root: Node3D) -> void:
	var a := Node3D.new()
	a.name = "Ambience"
	root.add_child(a)
	_zone(a, "Street", "ambience_street", Vector3(-1.5, G + 3.0, -6.5), Vector3(40.0, 6.0, 9.0))
	_zone(a, "Park", "ambience_park", Vector3(-14.0, G + 3.0, 2.3), Vector3(16.0, 6.0, 8.4))
	_zone(a, "Lane", "ambience_lane", Vector3(-10.0, G + 3.0, 8.2), Vector3(24.0, 6.0, 3.5))
	_zone(a, "Cafe", "ambience_cafe", Vector3(11.0, G + 1.5, -14.5), Vector3(7.0, 3.0, 6.6))

static func _zone(parent: Node3D, name: String, cue: String, pos: Vector3,
		extent: Vector3) -> void:
	var z: Area3D = Ambience.new()
	z.name = "Zone" + name
	z.set("cue", cue)
	parent.add_child(z)
	z.position = pos
	z.call("configure", extent)

# ---------------------------------------------------------------- helpers ----

## Box with an explicit material (LIB.box only takes a material key).
static func _mbo(parent: Node3D, name: String, material: Material, pos: Vector3,
		size: Vector3, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	if rot_deg == Vector3.ZERO:
		mi.mesh = _unit()
		mi.scale = size
	else:
		var bm := BoxMesh.new()
		bm.size = size
		mi.mesh = bm
		mi.rotation_degrees = rot_deg
	mi.position = pos
	mi.material_override = material
	parent.add_child(mi)
	return mi

## Low wall / compound wall: `along_x` true means it runs along X.
static func _wall(parent: Node3D, name: String, a0: float, a1: float, b0: float,
		b1: float, y_top: float, along_x: bool = false) -> void:
	var size: Vector3
	var pos: Vector3
	if along_x:
		size = Vector3(b1 - b0, y_top - G, a1 - a0)
		pos = Vector3((b0 + b1) * 0.5, G + (y_top - G) * 0.5, (a0 + a1) * 0.5)
	else:
		size = Vector3(a1 - a0, y_top - G, b1 - b0)
		pos = Vector3((a0 + a1) * 0.5, G + (y_top - G) * 0.5, (b0 + b1) * 0.5)
	_mbo(parent, name, m_paving(), pos, size)
	LIB.collider(parent, name + "Body", pos, size)

## A shop / street sign board with 3D text on it.
static func _sign(parent: Node3D, name: String, text: String, pos: Vector3, yaw: float,
		width: float, height: float) -> void:
	var board := Node3D.new()
	board.name = name
	board.position = pos
	board.rotation_degrees = Vector3(0, yaw, 0)
	parent.add_child(board)
	_mbo(board, "Board", m_sign_dark(), Vector3.ZERO, Vector3(width, height, 0.06))
	LIB.label3d(board, "Text", text, Vector3(0, 0, 0.045), Vector3.ZERO,
		minf(height * 0.010, width / maxf(float(text.length()) * 0.62, 1.0)), 64,
		Color(0.94, 0.93, 0.88), true)

# -------------------------------------------------------- neighbourhood props --
# Repeated outdoor props are generated as instanced prefab scenes, so the street
# pays for one mesh per prop rather than one per copy.

static func _write_prefabs() -> void:
	for def: Dictionary in _prefab_defs():
		_save_prefab(def)

static func _save_prefab(def: Dictionary) -> void:
	var root := Node3D.new()
	root.name = def["name"]
	for b: Array in def.get("boxes", []):
		LIB.box(root, b[0], b[1], b[2], b[3], b[4] if b.size() > 4 else Vector3.ZERO)
	for c: Array in def.get("cyls", []):
		LIB.cyl(root, c[0], c[1], c[2], c[3], c[4], c[5] if c.size() > 5 else Vector3.ZERO)
	for col: Array in def.get("collision", []):
		LIB.collider(root, "Body" + str(root.get_child_count()), col[0], col[1])
	LIB.fix_owners(root, root)
	var ps := PackedScene.new()
	if ps.pack(root) != OK:
		print("FAIL pack: ", def["name"])
		root.free()
		return
	var path: String = "res://prefabs/%s.tscn" % def["name"]
	var err: int = ResourceSaver.save(ps, path)
	if err != OK:
		print("FAIL save: ", path)
	root.free()

static func _prefab_defs() -> Array:
	return [
		{
			"name": "nb_tree",
			"cyls": [["Trunk", "wood", Vector3(0, 1.30, 0), 0.13, 2.60, Vector3.ZERO]],
			"boxes": [
				["Canopy0", "plant", Vector3(0, 2.85, 0), Vector3(2.40, 0.90, 2.40)],
				["Canopy1", "plant", Vector3(-0.35, 3.35, 0.20), Vector3(1.70, 0.70, 1.70)],
				["Canopy2", "plant", Vector3(0.40, 3.60, -0.25), Vector3(1.30, 0.60, 1.30)],
			],
			"collision": [[Vector3(0, 1.30, 0), Vector3(0.30, 2.60, 0.30)]],
		},
		{
			"name": "bench",
			"boxes": [
				["Seat", "wood_light", Vector3(0, 0.45, 0), Vector3(1.80, 0.08, 0.44)],
				["Back", "wood_light", Vector3(0, 0.78, -0.20), Vector3(1.80, 0.40, 0.06)],
				["LegA", "metal_dark", Vector3(-0.72, 0.22, 0), Vector3(0.08, 0.44, 0.40)],
				["LegB", "metal_dark", Vector3(0.72, 0.22, 0), Vector3(0.08, 0.44, 0.40)],
			],
			"collision": [[Vector3(0, 0.30, 0), Vector3(1.80, 0.60, 0.46)]],
		},
		{
			"name": "nb_pole",
			"cyls": [["Pole", "concrete", Vector3(0, 3.30, 0), 0.09, 6.60, Vector3.ZERO]],
			"boxes": [
				["Crossarm", "metal_dark", Vector3(0, 6.10, 0), Vector3(1.60, 0.07, 0.07)],
				["LampArm", "metal_dark", Vector3(0.55, 5.60, 0), Vector3(0.90, 0.06, 0.06)],
				["LampHead", "metal_dark", Vector3(0.95, 5.52, 0), Vector3(0.30, 0.12, 0.18)],
			],
			"collision": [[Vector3(0, 3.30, 0), Vector3(0.24, 6.60, 0.24)]],
		},
		{
			"name": "nb_table",
			"cyls": [
				["Top", "wood_light", Vector3(0, 0.74, 0), 0.42, 0.06, Vector3.ZERO],
				["Stem", "metal_dark", Vector3(0, 0.38, 0), 0.05, 0.72, Vector3.ZERO],
				["Base", "metal_dark", Vector3(0, 0.03, 0), 0.24, 0.05, Vector3.ZERO],
			],
			"collision": [[Vector3(0, 0.74, 0), Vector3(0.84, 0.12, 0.84)]],
		},
		{
			"name": "nb_car",
			"boxes": [
				["Body", "plastic", Vector3(0, 0.62, 0), Vector3(1.70, 0.62, 4.10)],
				["Cabin", "glass", Vector3(0, 1.14, -0.15), Vector3(1.54, 0.52, 2.10)],
				["BumperF", "metal_dark", Vector3(0, 0.52, 2.10), Vector3(1.66, 0.22, 0.12)],
				["BumperB", "metal_dark", Vector3(0, 0.52, -2.10), Vector3(1.66, 0.22, 0.12)],
			],
			"cyls": [
				["WheelA", "plastic_dark", Vector3(-0.86, 0.33, 1.35), 0.33, 0.20, Vector3(0, 0, 90)],
				["WheelB", "plastic_dark", Vector3(0.86, 0.33, 1.35), 0.33, 0.20, Vector3(0, 0, 90)],
				["WheelC", "plastic_dark", Vector3(-0.86, 0.33, -1.35), 0.33, 0.20, Vector3(0, 0, 90)],
				["WheelD", "plastic_dark", Vector3(0.86, 0.33, -1.35), 0.33, 0.20, Vector3(0, 0, 90)],
			],
			"collision": [[Vector3(0, 0.72, 0), Vector3(1.76, 1.44, 4.20)]],
		},
		{
			"name": "nb_scooter",
			"boxes": [
				["Frame", "plastic", Vector3(0, 0.55, 0), Vector3(0.34, 0.30, 1.30)],
				["Seat", "plastic_dark", Vector3(0, 0.76, -0.30), Vector3(0.32, 0.14, 0.60)],
				["Basket", "metal", Vector3(0, 0.86, 0.62), Vector3(0.34, 0.26, 0.30)],
			],
			"cyls": [
				["WheelF", "plastic_dark", Vector3(0, 0.24, 0.66), 0.24, 0.12, Vector3(0, 0, 90)],
				["WheelB", "plastic_dark", Vector3(0, 0.24, -0.66), 0.24, 0.12, Vector3(0, 0, 90)],
				["Bar", "metal_dark", Vector3(0, 1.00, 0.58), 0.03, 0.60, Vector3(0, 0, 90)],
			],
			"collision": [[Vector3(0, 0.45, 0), Vector3(0.50, 0.90, 1.60)]],
		},
		{
			"name": "nb_bin",
			"cyls": [["Body", "metal_dark", Vector3(0, 0.42, 0), 0.24, 0.84, Vector3.ZERO]],
			"boxes": [["Lid", "metal", Vector3(0, 0.87, 0), Vector3(0.56, 0.08, 0.56)]],
			"collision": [[Vector3(0, 0.42, 0), Vector3(0.52, 0.84, 0.52)]],
		},
		{
			"name": "nb_planter",
			"boxes": [
				["Pot", "concrete", Vector3(0, 0.28, 0), Vector3(1.00, 0.56, 1.00)],
				["Hedge", "plant", Vector3(0, 0.82, 0), Vector3(0.86, 0.60, 0.86)],
			],
			"collision": [[Vector3(0, 0.28, 0), Vector3(1.00, 0.56, 1.00)]],
		},
		{
			"name": "nb_shelter",
			"boxes": [
				["Roof", "metal", Vector3(0, 2.42, 0), Vector3(3.40, 0.08, 1.40)],
				["Back", "glass", Vector3(0, 1.30, 0.66), Vector3(3.40, 1.70, 0.05)],
				["SideW", "metal_dark", Vector3(-1.66, 1.30, 0), Vector3(0.08, 1.70, 1.30)],
				["SideE", "metal_dark", Vector3(1.66, 1.30, 0), Vector3(0.08, 1.70, 1.30)],
			],
			"collision": [[Vector3(0, 1.20, 0.70), Vector3(3.40, 2.40, 0.10)]],
		},
		{
			"name": "nb_stall",
			"boxes": [
				["Counter", "wood_light", Vector3(0, 0.90, 0), Vector3(2.20, 0.10, 1.00)],
				["Front", "wood", Vector3(0, 0.45, 0.48), Vector3(2.20, 0.90, 0.06)],
				["Roof", "fabric", Vector3(0, 2.20, 0), Vector3(2.60, 0.08, 1.60)],
				["PostW", "metal_dark", Vector3(-1.20, 1.10, 0.70), Vector3(0.08, 2.20, 0.08)],
				["PostE", "metal_dark", Vector3(1.20, 1.10, 0.70), Vector3(0.08, 2.20, 0.08)],
				["CrateA", "wood_light", Vector3(-0.55, 1.08, -0.10), Vector3(0.50, 0.26, 0.40)],
				["CrateB", "wood_light", Vector3(0.60, 1.08, -0.10), Vector3(0.50, 0.26, 0.40)],
			],
			"collision": [[Vector3(0, 0.50, 0.20), Vector3(2.20, 1.00, 0.70)]],
		},
	]

static func _count(n: Node) -> int:
	var c: int = 1
	for ch in n.get_children():
		c += _count(ch)
	return c
