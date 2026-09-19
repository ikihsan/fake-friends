class_name BOPrefabs
extends RefCounted

## PREFAB DATA — the art pass.
##
## Pure data, no helpers, so that bo_lib.gd can depend on it without a cyclic
## class reference.  Keys here override the original blockout definitions in
## BOLib._blockout_defs() (bed, sofa, toilet ... get their final art-pass
## geometry) and add every new lived-in prop.
##
## Conventions (unchanged from the blockout): metres, prefab floor at y = 0,
## "back" against the wall on the -Z side, front facing +Z.
## Entry shapes:
##   "boxes": [name, material, position, size, optional rotation]
##   "cyls" : [name, material, position, radius, height, optional rotation]
##   "labels": [text, position, rotation, pixel_size, font_size, colour, shaded]
##   "lights": [position, energy, range, colour, shadows]
##   "collision": [centre, size]

static func defs() -> Dictionary:
	return {

# ============================================================== BEDROOM =====

		# Double bed, head at -Z.  Sheets, duvet with fold ridges, creased
		# pillows and a folded throw at the foot.  Footprint unchanged.
		"bed": {
			"boxes": [
				["Frame", "wood", Vector3(0, 0.16, 0), Vector3(1.40, 0.32, 2.00)],
				["Mattress", "bedding", Vector3(0, 0.44, 0), Vector3(1.32, 0.26, 1.92)],
				["FittedSheet", "bedding", Vector3(0, 0.575, 0), Vector3(1.36, 0.05, 1.96)],
				["Duvet", "bedding_warm", Vector3(0, 0.645, 1.28), Vector3(1.38, 0.10, 1.54),
					Vector3(0.4, 0, 0)],
				["DuvetFold1", "bedding_warm", Vector3(0.012, 0.706, 0.86), Vector3(1.34, 0.045, 0.30),
					Vector3(2.5, 0, 0.8)],
				["DuvetFold2", "bedding_warm", Vector3(-0.014, 0.702, 1.42), Vector3(1.32, 0.040, 0.26),
					Vector3(-2.0, 0, -0.6)],
				["DuvetFold3", "bedding_warm", Vector3(0.008, 0.700, 1.92), Vector3(1.30, 0.038, 0.22),
					Vector3(2.8, 0, 1.0)],
				["TurnedSheet", "bedding", Vector3(0, 0.630, 0.44), Vector3(1.36, 0.07, 0.24)],
				["FoldRidge", "bedding", Vector3(0, 0.688, 0.58), Vector3(1.30, 0.03, 0.06)],
				["PillowL", "bedding", Vector3(-0.34, 0.70, -0.72), Vector3(0.58, 0.16, 0.36),
					Vector3(-4, 0, 0)],
				["PillowLCrease", "bedding", Vector3(-0.34, 0.778, -0.70),
					Vector3(0.50, 0.03, 0.20), Vector3(-4, 0, 0)],
				["PillowR", "bedding", Vector3(0.34, 0.70, -0.72), Vector3(0.58, 0.16, 0.36),
					Vector3(-6, 0, 1.5)],
				["PillowRCrease", "bedding", Vector3(0.34, 0.778, -0.70),
					Vector3(0.50, 0.03, 0.20), Vector3(-6, 0, 1.5)],
				["FoldedThrow", "rug", Vector3(0, 0.72, 1.80), Vector3(1.10, 0.09, 0.42),
					Vector3(-1, 0, 0)],
				["Headboard", "wood", Vector3(0, 0.62, -1.03), Vector3(1.44, 1.24, 0.06)],
				["HeadboardRail", "wood_light", Vector3(0, 1.25, -1.03), Vector3(1.44, 0.05, 0.10)],
			],
			"collision": [Vector3(0, 0.34, 0), Vector3(1.40, 0.68, 2.10)],
		},

		"bedside_table": {
			"boxes": [
				["Body", "wood", Vector3(0, 0.25, 0), Vector3(0.45, 0.50, 0.45)],
				["Top", "wood_light", Vector3(0, 0.52, 0), Vector3(0.49, 0.04, 0.49)],
				["Drawer", "wood_light", Vector3(0, 0.34, 0.235), Vector3(0.38, 0.15, 0.02)],
				["DrawerGap", "dark", Vector3(0, 0.42, 0.24), Vector3(0.34, 0.006, 0.01)],
				["Knob", "metal", Vector3(0, 0.34, 0.255), Vector3(0.028, 0.028, 0.03)],
				["Shelf", "wood", Vector3(0, 0.06, 0.18), Vector3(0.38, 0.02, 0.09)],
			],
			"collision": [Vector3(0, 0.28, 0), Vector3(0.49, 0.56, 0.45)],
		},

		# The handbook: worn cloth cover, cream page block, rust bookmark tab.
		"handbook": {
			"boxes": [
				["CoverBottom", "book_cover", Vector3(0, 0.004, 0), Vector3(0.17, 0.008, 0.24)],
				["Pages", "paper", Vector3(0.003, 0.021, 0), Vector3(0.162, 0.030, 0.230)],
				["PageEdge", "paper", Vector3(0.084, 0.021, 0), Vector3(0.006, 0.026, 0.226)],
				["CoverTop", "book_cover", Vector3(0, 0.038, 0), Vector3(0.17, 0.008, 0.24)],
				["Spine", "book_cover", Vector3(-0.082, 0.021, 0), Vector3(0.008, 0.042, 0.24)],
				["BookmarkTab", "book_cover_rust", Vector3(0.048, 0.042, -0.135),
					Vector3(0.024, 0.004, 0.062)],
			],
			"labels": [
				["HANDBOOK", Vector3(0.008, 0.045, 0.012), Vector3(-90, 0, 0), 0.0008, 48,
					Color(0.88, 0.87, 0.84), true],
			],
		},

		"pen": {
			"boxes": [
				["Barrel", "plastic_dark", Vector3(0, 0.006, 0), Vector3(0.012, 0.012, 0.138)],
				["Grip", "plastic", Vector3(0, 0.006, -0.03), Vector3(0.013, 0.013, 0.04)],
				["Cap", "plastic", Vector3(0, 0.006, -0.062), Vector3(0.013, 0.013, 0.042)],
				["Clip", "metal", Vector3(0.008, 0.013, -0.058), Vector3(0.004, 0.006, 0.03)],
			],
		},

		"phone": {
			"boxes": [
				["Body", "plastic_dark", Vector3(0, 0.006, 0), Vector3(0.072, 0.012, 0.148)],
				["Screen", "dark", Vector3(0, 0.0125, 0), Vector3(0.064, 0.002, 0.136)],
				["CameraBump", "plastic_dark", Vector3(-0.022, 0.0145, -0.056),
					Vector3(0.026, 0.005, 0.026)],
			],
		},

		# Loose charging cable curling from the wall socket to the phone.
		"charging_cable": {
			"boxes": [
				["Plug", "plastic", Vector3(0, 0.018, -0.09), Vector3(0.030, 0.030, 0.048)],
				["Cable0", "plastic_dark", Vector3(0, 0.006, -0.02), Vector3(0.011, 0.010, 0.14)],
				["Cable1", "plastic_dark", Vector3(0.045, 0.006, 0.055), Vector3(0.10, 0.010, 0.011)],
				["Cable2", "plastic_dark", Vector3(0.088, 0.006, 0.115), Vector3(0.011, 0.010, 0.13)],
				["Cable3", "plastic_dark", Vector3(0.048, 0.006, 0.172), Vector3(0.092, 0.010, 0.011)],
				["Connector", "plastic_dark", Vector3(0.002, 0.006, 0.215), Vector3(0.018, 0.010, 0.026)],
			],
		},

		"power_socket": {
			"boxes": [
				["Plate", "plastic", Vector3(0, 0, 0.006), Vector3(0.146, 0.086, 0.012)],
				["SocketL", "dark", Vector3(-0.036, 0.004, 0.013), Vector3(0.05, 0.05, 0.004)],
				["SocketR", "dark", Vector3(0.036, 0.004, 0.013), Vector3(0.05, 0.05, 0.004)],
				["RockerL", "plastic", Vector3(-0.036, 0.004, 0.016), Vector3(0.022, 0.03, 0.004)],
				["RockerR", "plastic", Vector3(0.036, 0.004, 0.016), Vector3(0.022, 0.03, 0.004)],
			],
		},

		"light_switch": {
			"boxes": [
				["Plate", "plastic", Vector3(0, 0, 0.005), Vector3(0.086, 0.086, 0.010)],
				["Rocker", "plastic", Vector3(0, 0, 0.012), Vector3(0.030, 0.048, 0.008)],
			],
		},

		"glass_water": {
			"boxes": [
				["Glass", "glass", Vector3(0, 0.048, 0), Vector3(0.066, 0.096, 0.066)],
				["Water", "water", Vector3(0, 0.036, 0), Vector3(0.058, 0.058, 0.058)],
			],
		},

		"book_stack": {
			"boxes": [
				["Book1", "book_cover", Vector3(0, 0.015, 0), Vector3(0.15, 0.030, 0.21)],
				["Book2", "book_cover_rust", Vector3(0.010, 0.045, -0.006),
					Vector3(0.14, 0.028, 0.20), Vector3(0, 6, 0)],
				["Book3", "paper", Vector3(-0.006, 0.072, 0.010), Vector3(0.13, 0.024, 0.19),
					Vector3(0, -4, 0)],
			],
		},

		"papers": {
			"boxes": [
				["Sheet1", "paper", Vector3(0, 0.002, 0), Vector3(0.21, 0.004, 0.297)],
				["Sheet2", "paper", Vector3(0.008, 0.006, 0.005), Vector3(0.21, 0.004, 0.297),
					Vector3(0, 3, 0)],
				["Sheet3", "paper", Vector3(-0.007, 0.010, -0.004), Vector3(0.21, 0.004, 0.297),
					Vector3(0, -2, 0)],
			],
		},

		"ceiling_fan": {
			"boxes": [
				["Canopy", "metal", Vector3(0, -0.015, 0), Vector3(0.14, 0.03, 0.14)],
				["Rod", "metal", Vector3(0, -0.10, 0), Vector3(0.035, 0.20, 0.035)],
				["Motor", "metal", Vector3(0, -0.24, 0), Vector3(0.26, 0.12, 0.26)],
				["Globe", "lamp_glow", Vector3(0, -0.36, 0), Vector3(0.17, 0.11, 0.17)],
				["Bracket0", "metal_dark", Vector3(0.14, -0.28, 0), Vector3(0.10, 0.03, 0.10)],
				["Bracket1", "metal_dark", Vector3(-0.07, -0.28, 0.121), Vector3(0.10, 0.03, 0.10),
					Vector3(0, 120, 0)],
				["Bracket2", "metal_dark", Vector3(-0.07, -0.28, -0.121), Vector3(0.10, 0.03, 0.10),
					Vector3(0, 240, 0)],
				["Blade0", "wood_light", Vector3(0.36, -0.28, 0), Vector3(0.62, 0.018, 0.14)],
				["Blade1", "wood_light", Vector3(-0.18, -0.28, 0.31), Vector3(0.62, 0.018, 0.14),
					Vector3(0, 120, 0)],
				["Blade2", "wood_light", Vector3(-0.18, -0.28, -0.31), Vector3(0.62, 0.018, 0.14),
					Vector3(0, 240, 0)],
				["PullChain", "metal", Vector3(0.10, -0.45, 0.06), Vector3(0.006, 0.16, 0.006)],
				["ChainBead", "metal", Vector3(0.10, -0.53, 0.06), Vector3(0.02, 0.02, 0.02)],
			],
			"lights": [[Vector3(0, -0.42, 0), 1.5, 7.0, Color(1.0, 0.9, 0.76), true]],
		},

		"desk": {
			"boxes": [
				["Top", "wood_light", Vector3(0, 0.74, 0), Vector3(1.20, 0.04, 0.60)],
				["SideL", "wood", Vector3(-0.56, 0.37, 0), Vector3(0.06, 0.74, 0.56)],
				["SideR", "wood", Vector3(0.56, 0.37, 0), Vector3(0.06, 0.74, 0.56)],
				["BackPanel", "wood", Vector3(0, 0.48, -0.28), Vector3(1.06, 0.40, 0.03)],
				["LaptopBase", "plastic_dark", Vector3(0.12, 0.78, 0.06), Vector3(0.32, 0.02, 0.22)],
				["LaptopLid", "plastic_dark", Vector3(0.12, 0.89, -0.04), Vector3(0.32, 0.22, 0.02)],
				["LaptopScreen", "screen", Vector3(0.12, 0.89, -0.028), Vector3(0.28, 0.18, 0.004)],
				["Mug", "ceramic", Vector3(-0.30, 0.79, 0.10), Vector3(0.08, 0.10, 0.08)],
				["MugHandle", "ceramic", Vector3(-0.35, 0.79, 0.10), Vector3(0.02, 0.05, 0.02)],
				["LampBase", "metal_dark", Vector3(-0.44, 0.77, 0.20), Vector3(0.11, 0.02, 0.11)],
				["LampStem", "metal_dark", Vector3(-0.44, 0.90, 0.20), Vector3(0.02, 0.26, 0.02)],
				["LampHead", "lamp_glow", Vector3(-0.44, 1.03, 0.15), Vector3(0.13, 0.08, 0.13)],
			],
			"collision": [Vector3(0, 0.38, 0), Vector3(1.20, 0.76, 0.60)],
		},

		# Chair with a shirt left draped over the back.
		"chair": {
			"boxes": [
				["Seat", "wood", Vector3(0, 0.45, 0), Vector3(0.45, 0.06, 0.45)],
				["Backrest", "wood", Vector3(0, 0.76, -0.20), Vector3(0.45, 0.52, 0.05)],
				["Leg0", "wood", Vector3(-0.18, 0.21, 0.18), Vector3(0.05, 0.42, 0.05)],
				["Leg1", "wood", Vector3(0.18, 0.21, 0.18), Vector3(0.05, 0.42, 0.05)],
				["Leg2", "wood", Vector3(-0.18, 0.21, -0.18), Vector3(0.05, 0.42, 0.05)],
				["Leg3", "wood", Vector3(0.18, 0.21, -0.18), Vector3(0.05, 0.42, 0.05)],
				["ShirtShoulder", "fabric", Vector3(0.01, 0.98, -0.20), Vector3(0.42, 0.06, 0.16)],
				["ShirtFront", "fabric", Vector3(0.01, 0.72, -0.255), Vector3(0.38, 0.46, 0.05),
					Vector3(0, 0, 1.5)],
				["ShirtBack", "fabric", Vector3(0.01, 0.70, -0.15), Vector3(0.38, 0.42, 0.05),
					Vector3(0, 0, -1.0)],
			],
			"collision": [Vector3(0, 0.45, 0), Vector3(0.45, 0.92, 0.45)],
		},

# ========================================================= WARDROBE NOOK ====

		"wardrobe_unit": {
			"boxes": [
				["Carcass", "wood", Vector3(0, 1.00, 0), Vector3(1.20, 2.00, 0.60)],
				["Top", "wood", Vector3(0, 2.02, 0), Vector3(1.24, 0.04, 0.62)],
				["DoorL", "door", Vector3(-0.29, 1.00, 0.31), Vector3(0.58, 1.90, 0.03)],
				["DoorR", "door", Vector3(0.29, 1.00, 0.31), Vector3(0.58, 1.90, 0.03)],
				["DoorGap", "dark", Vector3(0, 1.00, 0.325), Vector3(0.014, 1.86, 0.004)],
				["HandleL", "metal", Vector3(0.06, 1.05, 0.34), Vector3(0.02, 0.16, 0.03)],
				["HandleR", "metal", Vector3(-0.06, 1.05, 0.34), Vector3(0.02, 0.16, 0.03)],
			],
			"collision": [Vector3(0, 1.00, 0), Vector3(1.24, 2.04, 0.62)],
		},

		# Open hanging rail: four clearly separated outfits with different
		# silhouettes and colours, ready to become a clothes-selection area.
		"hang_rail": {
			"boxes": [
				["SideL", "wood", Vector3(-0.53, 1.00, 0), Vector3(0.04, 2.00, 0.55)],
				["SideR", "wood", Vector3(0.53, 1.00, 0), Vector3(0.04, 2.00, 0.55)],
				["Top", "wood", Vector3(0, 1.97, 0), Vector3(1.10, 0.06, 0.55)],
				["Back", "wood", Vector3(0, 1.00, -0.27), Vector3(1.10, 2.00, 0.02)],
				["Coat", "fabric", Vector3(-0.40, 1.16, 0), Vector3(0.24, 1.06, 0.38)],
				["CoatCollar", "fabric", Vector3(-0.40, 1.72, 0.01), Vector3(0.26, 0.07, 0.40)],
				["Shirt", "bedding", Vector3(-0.14, 1.32, 0.01), Vector3(0.20, 0.80, 0.34)],
				["Cardigan", "rug", Vector3(0.13, 1.24, -0.01), Vector3(0.22, 0.92, 0.36)],
				["Jacket", "towel", Vector3(0.40, 1.26, 0.01), Vector3(0.22, 0.86, 0.38)],
			],
			"cyls": [["Rail", "metal", Vector3(0, 1.72, 0), 0.02, 1.00, Vector3(0, 0, 90)]],
			"collision": [Vector3(0, 1.00, 0), Vector3(1.10, 2.00, 0.57)],
		},

		"folded_clothes": {
			"boxes": [
				["Fold1", "bedding", Vector3(0, 0.020, 0), Vector3(0.30, 0.040, 0.24)],
				["Fold2", "fabric", Vector3(0.004, 0.062, -0.005), Vector3(0.29, 0.040, 0.23),
					Vector3(0, 3, 0)],
				["Fold3", "rug", Vector3(-0.004, 0.104, 0.004), Vector3(0.30, 0.040, 0.24),
					Vector3(0, -2, 0)],
				["Fold4", "towel", Vector3(0.002, 0.146, 0), Vector3(0.28, 0.040, 0.22)],
			],
		},

		"mirror_full": {
			"boxes": [
				["FrameTop", "wood", Vector3(0, 0.90, 0), Vector3(0.84, 0.06, 0.05)],
				["FrameBottom", "wood", Vector3(0, -0.90, 0), Vector3(0.84, 0.06, 0.05)],
				["FrameL", "wood", Vector3(-0.40, 0, 0), Vector3(0.06, 1.74, 0.05)],
				["FrameR", "wood", Vector3(0.40, 0, 0), Vector3(0.06, 1.74, 0.05)],
				["Glass", "mirror", Vector3(0, 0, 0.012), Vector3(0.72, 1.72, 0.008)],
			],
		},

		"laundry_basket": {
			"boxes": [
				["Body", "fabric", Vector3(0, 0.30, 0), Vector3(0.38, 0.60, 0.38)],
				["RimFold", "fabric", Vector3(0, 0.61, 0), Vector3(0.42, 0.06, 0.42)],
				["Clothes1", "bedding", Vector3(0, 0.66, 0.02), Vector3(0.30, 0.09, 0.28),
					Vector3(0, 8, 0)],
				["Clothes2", "towel", Vector3(-0.02, 0.70, -0.03), Vector3(0.22, 0.07, 0.22),
					Vector3(0, -14, 0)],
			],
			"collision": [Vector3(0, 0.33, 0), Vector3(0.44, 0.66, 0.44)],
		},

		"shoes_pair": {
			"boxes": [
				["SoleL", "dark", Vector3(-0.085, 0.020, 0), Vector3(0.10, 0.030, 0.26),
					Vector3(0, 5, 0)],
				["UpperL", "plastic_dark", Vector3(-0.085, 0.062, -0.02),
					Vector3(0.095, 0.058, 0.20), Vector3(0, 5, 0)],
				["ToeL", "plastic_dark", Vector3(-0.085, 0.050, 0.10), Vector3(0.09, 0.05, 0.07),
					Vector3(0, 5, 0)],
				["SoleR", "dark", Vector3(0.085, 0.020, 0.01), Vector3(0.10, 0.030, 0.26),
					Vector3(0, -6, 0)],
				["UpperR", "plastic_dark", Vector3(0.085, 0.062, -0.01),
					Vector3(0.095, 0.058, 0.20), Vector3(0, -6, 0)],
				["ToeR", "plastic_dark", Vector3(0.085, 0.050, 0.11), Vector3(0.09, 0.05, 0.07),
					Vector3(0, -6, 0)],
			],
		},

		"clothes_hook": {
			"boxes": [
				["Plate", "wood", Vector3(0, 0, 0), Vector3(0.10, 0.12, 0.03)],
				["Peg", "metal", Vector3(0, -0.02, 0.05), Vector3(0.02, 0.02, 0.08)],
				["BagHandle", "fabric", Vector3(0, -0.075, 0.085), Vector3(0.09, 0.09, 0.02)],
				["Bag", "fabric", Vector3(0, -0.28, 0.09), Vector3(0.26, 0.34, 0.09)],
				["BagFlap", "fabric", Vector3(0, -0.16, 0.115), Vector3(0.24, 0.12, 0.04)],
			],
		},

		"tray_items": {
			"boxes": [
				["Dish", "ceramic", Vector3(0, 0.012, 0), Vector3(0.12, 0.024, 0.12)],
				["DishInner", "dark", Vector3(0, 0.020, 0), Vector3(0.10, 0.010, 0.10)],
				["Watch", "metal", Vector3(0.012, 0.030, 0.004), Vector3(0.032, 0.012, 0.032)],
				["WatchStrap", "fabric", Vector3(0.012, 0.030, 0.030), Vector3(0.020, 0.008, 0.030)],
				["Ring", "metal", Vector3(-0.030, 0.028, -0.022), Vector3(0.018, 0.004, 0.018)],
			],
		},

# ================================================================= HALL =====

		"sofa": {
			"boxes": [
				["Base", "fabric", Vector3(0, 0.22, 0), Vector3(1.60, 0.44, 0.90)],
				["Back", "fabric", Vector3(0, 0.64, -0.32), Vector3(1.60, 0.60, 0.26)],
				["ArmL", "fabric", Vector3(-0.72, 0.52, 0), Vector3(0.16, 0.60, 0.90)],
				["ArmR", "fabric", Vector3(0.72, 0.52, 0), Vector3(0.16, 0.60, 0.90)],
				["SeatCushionL", "bedding", Vector3(-0.42, 0.50, 0.08), Vector3(0.66, 0.14, 0.58),
					Vector3(2, 0, 0)],
				["SeatCushionR", "bedding", Vector3(0.42, 0.50, 0.08), Vector3(0.66, 0.14, 0.58),
					Vector3(-3, 0, 0)],
				["BackCushionL", "bedding_warm", Vector3(-0.40, 0.72, -0.18),
					Vector3(0.60, 0.40, 0.14), Vector3(-6, 0, 0)],
				["BackCushionR", "bedding_warm", Vector3(0.40, 0.72, -0.18),
					Vector3(0.60, 0.40, 0.14), Vector3(-5, 0, 2)],
				["Throw", "rug", Vector3(0.62, 0.62, 0.06), Vector3(0.30, 0.10, 0.80),
					Vector3(0, 0, -4)],
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
				["Shelf", "wood", Vector3(0, 0.10, 0), Vector3(0.62, 0.02, 0.42)],
				["Magazine", "paper", Vector3(0.16, 0.43, 0.02), Vector3(0.18, 0.02, 0.24),
					Vector3(0, -6, 0)],
				["Coaster", "wood", Vector3(-0.22, 0.415, 0.16), Vector3(0.09, 0.008, 0.09)],
				["Mug", "ceramic", Vector3(-0.22, 0.46, 0.16), Vector3(0.08, 0.09, 0.08)],
				["Bowl", "ceramic", Vector3(0.24, 0.435, -0.15), Vector3(0.14, 0.05, 0.14)],
			],
			"collision": [Vector3(0, 0.21, 0), Vector3(0.80, 0.42, 0.60)],
		},

		"remote": {
			"boxes": [
				["Body", "plastic_dark", Vector3(0, 0.012, 0), Vector3(0.05, 0.024, 0.18)],
				["Buttons", "plastic", Vector3(0, 0.025, 0.04), Vector3(0.036, 0.004, 0.08)],
				["Dpad", "plastic", Vector3(0, 0.025, -0.03), Vector3(0.028, 0.004, 0.04)],
			],
		},

		"tv_unit": {
			"boxes": [
				["Carcass", "wood", Vector3(0, 0.25, 0), Vector3(1.30, 0.50, 0.45)],
				["Top", "wood_light", Vector3(0, 0.51, 0), Vector3(1.34, 0.03, 0.49)],
				["DoorGap", "dark", Vector3(0, 0.25, 0.228), Vector3(0.014, 0.42, 0.004)],
				["HandleL", "metal", Vector3(0.05, 0.25, 0.235), Vector3(0.02, 0.10, 0.02)],
				["HandleR", "metal", Vector3(-0.05, 0.25, 0.235), Vector3(0.02, 0.10, 0.02)],
				["Stand", "plastic_dark", Vector3(0, 0.58, 0), Vector3(0.26, 0.12, 0.20)],
				["TVBody", "plastic_dark", Vector3(0, 0.86, 0), Vector3(0.94, 0.56, 0.06)],
				["Screen", "screen", Vector3(0, 0.87, 0.032), Vector3(0.88, 0.50, 0.006)],
				["SetTopBox", "plastic_dark", Vector3(-0.45, 0.545, 0), Vector3(0.22, 0.05, 0.16)],
				["SetTopLed", "screen", Vector3(-0.45, 0.55, 0.075), Vector3(0.03, 0.01, 0.004)],
				["BookOnTop", "book_cover_rust", Vector3(0.42, 0.545, 0), Vector3(0.14, 0.03, 0.20)],
			],
			"collision": [Vector3(0, 0.30, 0), Vector3(1.34, 0.62, 0.49)],
		},

		"wall_clock": {
			"cyls": [
				["Body", "wood", Vector3(0, 0, 0.03), 0.15, 0.06, Vector3(90, 0, 0)],
				["Face", "paper", Vector3(0, 0, 0.062), 0.13, 0.01, Vector3(90, 0, 0)],
			],
			"boxes": [
				["MarkT", "metal", Vector3(0, 0.09, 0.07), Vector3(0.022, 0.012, 0.006)],
				["MarkB", "metal", Vector3(0, -0.09, 0.07), Vector3(0.022, 0.012, 0.006)],
				["MarkL", "metal", Vector3(-0.09, 0, 0.07), Vector3(0.012, 0.022, 0.006)],
				["MarkR", "metal", Vector3(0.09, 0, 0.07), Vector3(0.012, 0.022, 0.006)],
				["HandH", "metal_dark", Vector3(0, 0.032, 0.073), Vector3(0.008, 0.07, 0.006)],
				["HandM", "metal_dark", Vector3(0.035, 0, 0.073), Vector3(0.075, 0.008, 0.006)],
				["Centre", "metal", Vector3(0, 0, 0.076), Vector3(0.018, 0.018, 0.008)],
			],
		},

		"coat_hooks": {
			"boxes": [
				["Board", "wood", Vector3(0, 0, 0), Vector3(0.70, 0.12, 0.03)],
				["Hook0", "metal", Vector3(-0.25, -0.03, 0.05), Vector3(0.02, 0.10, 0.07)],
				["Hook1", "metal", Vector3(0, -0.03, 0.05), Vector3(0.02, 0.10, 0.07)],
				["Hook2", "metal", Vector3(0.25, -0.03, 0.05), Vector3(0.02, 0.10, 0.07)],
				["CoatShoulder", "fabric", Vector3(-0.22, -0.08, 0.07), Vector3(0.36, 0.08, 0.08)],
				["Coat", "fabric", Vector3(-0.22, -0.46, 0.07), Vector3(0.34, 0.80, 0.06)],
				["BagHandle", "rug", Vector3(0.02, -0.08, 0.075), Vector3(0.07, 0.08, 0.02)],
				["Bag", "rug", Vector3(0.02, -0.26, 0.08), Vector3(0.20, 0.28, 0.08)],
				["Scarf", "bedding", Vector3(0.24, -0.36, 0.07), Vector3(0.16, 0.60, 0.05)],
			],
		},

		"shoe_rack": {
			"boxes": [
				["SideL", "wood", Vector3(-0.44, 0.42, 0), Vector3(0.04, 0.84, 0.35)],
				["SideR", "wood", Vector3(0.44, 0.42, 0), Vector3(0.04, 0.84, 0.35)],
				["ShelfLow", "wood", Vector3(0, 0.06, 0), Vector3(0.84, 0.04, 0.35)],
				["ShelfMid", "wood", Vector3(0, 0.40, 0), Vector3(0.84, 0.04, 0.35)],
				["ShelfTop", "wood_light", Vector3(0, 0.84, 0), Vector3(0.90, 0.04, 0.35)],
				["Shoe1", "dark", Vector3(-0.22, 0.11, 0), Vector3(0.12, 0.09, 0.27),
					Vector3(0, 6, 0)],
				["Shoe2", "dark", Vector3(0.24, 0.11, 0.02), Vector3(0.12, 0.09, 0.27),
					Vector3(0, -8, 0)],
				["Shoe3", "dark", Vector3(-0.18, 0.45, 0), Vector3(0.12, 0.09, 0.27),
					Vector3(0, 4, 0)],
				["Basket", "fabric", Vector3(0.16, 0.94, 0), Vector3(0.26, 0.16, 0.30)],
			],
			"collision": [Vector3(0, 0.43, 0), Vector3(0.90, 0.86, 0.35)],
		},

		"keys": {
			"boxes": [
				["Ring", "metal", Vector3(0, 0.005, 0), Vector3(0.04, 0.008, 0.03)],
				["Key1", "metal", Vector3(0.02, 0.006, 0.05), Vector3(0.014, 0.006, 0.075),
					Vector3(0, 12, 0)],
				["Key2", "metal", Vector3(-0.012, 0.006, 0.055), Vector3(0.014, 0.006, 0.07),
					Vector3(0, -8, 0)],
				["Key3", "metal_dark", Vector3(0.004, 0.006, 0.05), Vector3(0.012, 0.006, 0.06),
					Vector3(0, 30, 0)],
				["Fob", "plastic_dark", Vector3(-0.03, 0.006, 0.018), Vector3(0.03, 0.008, 0.05)],
			],
		},

		"rug": {
			"boxes": [
				["Base", "rug", Vector3(0, 0.008, 0), Vector3(1.10, 0.016, 0.70)],
				["Inner", "fabric", Vector3(0, 0.017, 0), Vector3(0.94, 0.012, 0.56)],
			],
		},

		"table_lamp": {
			"boxes": [
				["Base", "metal_dark", Vector3(0, 0.015, 0), Vector3(0.16, 0.03, 0.16)],
				["Stem", "metal_dark", Vector3(0, 0.18, 0), Vector3(0.025, 0.30, 0.025)],
				["Shade", "lamp_glow", Vector3(0, 0.40, 0), Vector3(0.26, 0.22, 0.26)],
				["ShadeTop", "lamp_glow", Vector3(0, 0.50, 0), Vector3(0.20, 0.02, 0.20)],
			],
			"lights": [[Vector3(0, 0.40, 0), 0.9, 3.5, Color(1.0, 0.87, 0.7), false]],
		},

# ============================================================ BATHROOM =====

		# Pedestal basin built as a rim + walls + bowl floor so the bowl reads
		# as a recess (the rim top is the surface props sit on, at y = 0.91).
		"sink_unit": {
			"boxes": [
				["WallFront", "ceramic", Vector3(0, 0.84, 0.205), Vector3(0.56, 0.14, 0.05)],
				["WallBack", "ceramic", Vector3(0, 0.84, -0.205), Vector3(0.56, 0.14, 0.05)],
				["WallLeft", "ceramic", Vector3(-0.255, 0.84, 0), Vector3(0.05, 0.14, 0.36)],
				["WallRight", "ceramic", Vector3(0.255, 0.84, 0), Vector3(0.05, 0.14, 0.36)],
				["BowlFloor", "porcelain_used", Vector3(0, 0.785, 0), Vector3(0.46, 0.03, 0.36)],
				["Pedestal", "ceramic", Vector3(0, 0.40, 0), Vector3(0.18, 0.72, 0.18)],
				["TapBase", "metal", Vector3(0, 0.93, -0.20), Vector3(0.05, 0.06, 0.05)],
				["Tap", "metal", Vector3(0, 1.00, -0.20), Vector3(0.03, 0.12, 0.03)],
				["Spout", "metal", Vector3(0, 1.05, -0.13), Vector3(0.025, 0.025, 0.13)],
				["Handle", "metal", Vector3(0.05, 0.97, -0.20), Vector3(0.05, 0.02, 0.02)],
			],
			"collision": [Vector3(0, 0.45, 0), Vector3(0.56, 0.92, 0.46)],
		},

		"toilet": {
			"boxes": [
				["Tank", "ceramic", Vector3(0, 0.72, -0.26), Vector3(0.42, 0.40, 0.18)],
				["TankLid", "ceramic", Vector3(0, 0.93, -0.26), Vector3(0.44, 0.04, 0.20)],
				["Flush", "metal", Vector3(0, 0.955, -0.26), Vector3(0.06, 0.012, 0.06)],
				["Bowl", "ceramic", Vector3(0, 0.40, 0.04), Vector3(0.38, 0.40, 0.52)],
				["Seat", "ceramic", Vector3(0, 0.62, 0.04), Vector3(0.40, 0.05, 0.48)],
				["Lid", "porcelain_used", Vector3(0, 0.655, 0.04), Vector3(0.40, 0.03, 0.48)],
				["Base", "ceramic", Vector3(0, 0.15, 0.06), Vector3(0.24, 0.30, 0.36)],
			],
			"collision": [Vector3(0, 0.35, 0), Vector3(0.42, 0.92, 0.70)],
		},

		"shower_unit": {
			"boxes": [
				["Tray", "ceramic", Vector3(0, 0.045, 0), Vector3(0.90, 0.09, 0.90)],
				["TrayLip", "ceramic", Vector3(0, 0.09, 0), Vector3(0.94, 0.02, 0.94)],
				["Mixer", "metal", Vector3(0, 1.05, -0.42), Vector3(0.16, 0.06, 0.06)],
				["Head", "metal", Vector3(0, 1.86, -0.34), Vector3(0.10, 0.03, 0.16)],
				["Bottle", "plastic", Vector3(0.34, 0.24, -0.30), Vector3(0.07, 0.24, 0.07)],
				["BottleCap", "plastic_dark", Vector3(0.34, 0.375, -0.30), Vector3(0.04, 0.03, 0.04)],
			],
			"cyls": [["Riser", "metal", Vector3(0, 1.45, -0.42), 0.015, 0.80, Vector3.ZERO]],
			"collision": [Vector3(0, 0.05, 0), Vector3(0.90, 0.10, 0.90)],
		},

		"shower_curtain": {
			"boxes": [
				["Fold1", "curtain", Vector3(0.05, -0.95, 0.012), Vector3(0.16, 1.88, 0.018)],
				["Fold2", "curtain", Vector3(0.22, -0.95, -0.012), Vector3(0.16, 1.88, 0.018)],
				["Fold3", "curtain", Vector3(0.39, -0.95, 0.012), Vector3(0.16, 1.88, 0.018)],
				["Hem", "curtain", Vector3(0.22, -1.89, 0), Vector3(0.50, 0.04, 0.03)],
			],
			"cyls": [["Rail", "metal", Vector3(0, 0, 0), 0.012, 1.00, Vector3(0, 0, 90)]],
		},

		"medicine_cabinet": {
			"boxes": [
				["Body", "paint_white", Vector3(0, 0, 0), Vector3(0.55, 0.45, 0.16)],
				["DoorFrame", "paint_white", Vector3(0, 0, 0.085), Vector3(0.53, 0.43, 0.010)],
				["Mirror", "mirror", Vector3(0, 0, 0.092), Vector3(0.49, 0.39, 0.008)],
				["Handle", "metal", Vector3(0.20, 0, 0.100), Vector3(0.02, 0.08, 0.02)],
			],
		},

		"wall_mirror": {
			"boxes": [
				["Frame", "metal", Vector3(0, 0, 0), Vector3(0.58, 0.73, 0.03)],
				["Glass", "mirror", Vector3(0, 0, 0.018), Vector3(0.54, 0.69, 0.008)],
			],
		},

		"towel_hooks": {
			"boxes": [
				["Rail", "metal", Vector3(0, 0, 0), Vector3(0.50, 0.03, 0.06)],
				["Towel1Fold", "towel", Vector3(-0.12, -0.02, 0.06), Vector3(0.20, 0.06, 0.03)],
				["Towel1", "towel", Vector3(-0.12, -0.36, 0.05), Vector3(0.20, 0.72, 0.02)],
				["Towel2Fold", "towel", Vector3(0.15, -0.04, 0.06), Vector3(0.16, 0.08, 0.03)],
				["Towel2", "towel", Vector3(0.15, -0.18, 0.05), Vector3(0.16, 0.36, 0.02)],
			],
		},

		"toiletries": {
			"boxes": [
				["Cup", "ceramic", Vector3(0, 0.045, 0), Vector3(0.07, 0.09, 0.07)],
				["Brush", "plastic", Vector3(0.012, 0.115, 0), Vector3(0.012, 0.10, 0.012),
					Vector3(0, 0, 8)],
				["BrushHead", "plastic", Vector3(0.020, 0.168, 0), Vector3(0.014, 0.03, 0.012)],
				["Dish", "ceramic", Vector3(0.13, 0.008, 0), Vector3(0.11, 0.016, 0.09)],
				["Soap", "ceramic", Vector3(0.13, 0.024, 0), Vector3(0.08, 0.018, 0.06),
					Vector3(0, 12, 0)],
			],
		},

		"toilet_paper": {
			"boxes": [
				["Bracket", "metal", Vector3(0, 0, 0), Vector3(0.14, 0.03, 0.06)],
				["Arm", "metal", Vector3(0.05, 0, 0.075), Vector3(0.02, 0.02, 0.10)],
				["Flap", "paper", Vector3(0.05, -0.062, 0.155), Vector3(0.10, 0.09, 0.008)],
			],
			"cyls": [["Roll", "paper", Vector3(0.05, 0, 0.14), 0.055, 0.10, Vector3(90, 0, 0)]],
		},

		"bin_small": {
			"boxes": [
				["Body", "plastic", Vector3(0, 0.14, 0), Vector3(0.20, 0.28, 0.20)],
				["Rim", "plastic_dark", Vector3(0, 0.28, 0), Vector3(0.22, 0.02, 0.22)],
				["Lid", "plastic_dark", Vector3(0, 0.30, 0), Vector3(0.21, 0.02, 0.21)],
			],
		},

		"bath_mat": {
			"boxes": [
				["Mat", "towel", Vector3(0, 0.008, 0), Vector3(0.45, 0.016, 0.75)],
			],
		},

# ================================================================ GREENERY ==

		# Potted plant: flat leaf slabs at varied angles read as foliage where
		# stacked cubes read as boxes.
		"plant_pot": {
			"boxes": [
				["Pot", "door", Vector3(0, 0.16, 0), Vector3(0.32, 0.32, 0.32)],
				["PotRim", "door", Vector3(0, 0.315, 0), Vector3(0.35, 0.04, 0.35)],
				["Soil", "dark", Vector3(0, 0.33, 0), Vector3(0.26, 0.03, 0.26)],
				["Leaf0", "plant", Vector3(0, 0.50, 0), Vector3(0.46, 0.10, 0.30),
					Vector3(0, 12, 4)],
				["Leaf1", "plant", Vector3(0.02, 0.62, 0.01), Vector3(0.40, 0.09, 0.26),
					Vector3(0, -34, -5)],
				["Leaf2", "plant", Vector3(-0.02, 0.73, -0.01), Vector3(0.34, 0.08, 0.22),
					Vector3(0, 58, 6)],
				["Leaf3", "plant", Vector3(0.01, 0.83, 0.01), Vector3(0.26, 0.07, 0.17),
					Vector3(0, -18, -7)],
				["Leaf4", "plant", Vector3(0, 0.91, 0), Vector3(0.18, 0.06, 0.12),
					Vector3(0, 30, 5)],
			],
		},

# ======================================================= PHOTO WALL =========

		# Believable frame: four timber members, a paper mount and a separate
		# "Photo" node whose material (mat_photo) can be swapped on its own.
		"photo_frame": {
			"boxes": [
				["FrameTop", "wood", Vector3(0, 0.205, 0), Vector3(0.62, 0.05, 0.035)],
				["FrameBottom", "wood", Vector3(0, -0.205, 0), Vector3(0.62, 0.05, 0.035)],
				["FrameLeft", "wood", Vector3(-0.285, 0, 0), Vector3(0.05, 0.36, 0.035)],
				["FrameRight", "wood", Vector3(0.285, 0, 0), Vector3(0.05, 0.36, 0.035)],
				["Backing", "wood", Vector3(0, 0, -0.012), Vector3(0.56, 0.40, 0.012)],
				["Mount", "paper", Vector3(0, 0, 0.008), Vector3(0.53, 0.37, 0.006)],
				["Photo", "photo", Vector3(0, 0.005, 0.013), Vector3(0.40, 0.30, 0.004)],
			],
		},

		# The reminder: a taped sheet, printed text with hand-drawn underline.
		"reminder": {
			"boxes": [
				["Paper", "paper", Vector3(0, 0, 0), Vector3(0.30, 0.40, 0.005)],
				["TapeTL", "tape", Vector3(-0.115, 0.185, 0.004), Vector3(0.075, 0.045, 0.002)],
				["TapeTR", "tape", Vector3(0.115, 0.185, 0.004), Vector3(0.075, 0.045, 0.002)],
				["TapeBL", "tape", Vector3(-0.115, -0.185, 0.004), Vector3(0.075, 0.045, 0.002)],
				["TapeBR", "tape", Vector3(0.115, -0.185, 0.004), Vector3(0.075, 0.045, 0.002)],
				["Underline", "ink", Vector3(0, -0.136, 0.006), Vector3(0.215, 0.006, 0.002)],
				["Underline2", "ink", Vector3(0.022, -0.148, 0.006), Vector3(0.130, 0.005, 0.002)],
			],
			"labels": [
				["DON'T\nFORGET.\nREAD THE\nHANDBOOK.", Vector3(0, 0.02, 0.008), Vector3.ZERO,
					0.0010, 48, Color(0.12, 0.13, 0.17), true],
			],
		},
	}
