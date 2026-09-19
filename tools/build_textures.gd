class_name BOBuildTextures
extends RefCounted

## Generates the project's procedural texture library into res://textures/.
## Everything is seamless and tileable; the pattern textures (planks, tiles)
## are drawn as height + albedo pairs, organic ones come from seamless noise.
##
## Invoke via execute_script:  BOBuildTextures.run()
## then re-import with:  godot --headless --import

const OUT := "res://textures/"

static func run() -> int:
	var da := DirAccess.open("res://")
	if da != null and not da.dir_exists("textures"):
		da.make_dir_recursive("textures")
	_paint_wall()
	_paint_ceiling()
	_floor_laminate()
	_tile_floor()
	_tile_wall()
	_concrete()
	_paper()
	_wood_grain()
	_fabric_weave()
	_cover_worn()
	print("--- textures written to ", OUT)
	return 0

# ------------------------------------------------------------------ helpers --

## A seamless grayscale noise field, 1 byte per pixel (FORMAT_L8 data).
static func _noise_bytes(seed_val: int, freq: float, size: int, octaves: int = 3,
		gain: float = 0.5) -> PackedByteArray:
	var n := FastNoiseLite.new()
	n.seed = seed_val
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.frequency = freq
	n.fractal_type = FastNoiseLite.FRACTAL_FBM
	n.fractal_octaves = octaves
	n.fractal_gain = gain
	n.fractal_lacunarity = 2.0
	var img: Image = n.get_seamless_image(size, size)
	return img.get_data()

static func _blank(size: int) -> PackedByteArray:
	var b := PackedByteArray()
	b.resize(size * size * 4)
	b.fill(255)
	return b

static func _put(buf: PackedByteArray, size: int, x: int, y: int, c: Color) -> void:
	var i: int = (y * size + x) * 4
	buf[i] = int(clampf(c.r, 0.0, 1.0) * 255.0)
	buf[i + 1] = int(clampf(c.g, 0.0, 1.0) * 255.0)
	buf[i + 2] = int(clampf(c.b, 0.0, 1.0) * 255.0)
	buf[i + 3] = 255

## Writes the texture, passing it through a gentle down/up resample first:
## pixel-level noise would otherwise read as static once tiled over a wall,
## while the drawn patterns (grout, plank seams) survive it.
static func _save_rgba(buf: PackedByteArray, size: int, name: String) -> Image:
	var img := Image.create_from_data(size, size, false, Image.FORMAT_RGBA8, buf)
	var small: int = maxi(16, int(size * 0.6))
	img.resize(small, small, Image.INTERPOLATE_LANCZOS)
	img.resize(size, size, Image.INTERPOLATE_LANCZOS)
	var err: int = img.save_png(OUT + name)
	print("  %-22s %dpx  err=%d" % [name, size, err])
	return img

## Sobel normal map from a height field (0..255, wrapping).
static func _normal_from(height: PackedByteArray, size: int, strength: float) -> PackedByteArray:
	var out := _blank(size)
	for y in size:
		var ym: int = (y - 1 + size) % size
		var yp: int = (y + 1) % size
		for x in size:
			var xm: int = (x - 1 + size) % size
			var xp: int = (x + 1) % size
			var dx: float = (float(height[y * size + xp]) - float(height[y * size + xm])) / 255.0
			var dy: float = (float(height[yp * size + x]) - float(height[ym * size + x])) / 255.0
			var n := Vector3(-dx * strength, -dy * strength, 1.0).normalized()
			_put(out, size, x, y, Color(n.x * 0.5 + 0.5, n.y * 0.5 + 0.5, n.z * 0.5 + 0.5))
	return out

## Soft dark radial stain, used for weathering on concrete.
static func _stain(px: int, py: int, cx: int, cy: int, radius: float, size: int) -> float:
	var dx: float = float(px - cx)
	var dy: float = float(py - cy)
	# wrap-aware distance so stains stay seamless
	if dx > size * 0.5:
		dx -= size
	if dx < -size * 0.5:
		dx += size
	if dy > size * 0.5:
		dy -= size
	if dy < -size * 0.5:
		dy += size
	var d: float = sqrt(dx * dx + dy * dy) / radius
	if d >= 1.0:
		return 0.0
	return (1.0 - d) * (1.0 - d)

# -------------------------------------------------------------- wall paint --

static func _paint_wall() -> void:
	var size: int = 512
	var buf := _blank(size)
	var h := PackedByteArray()
	h.resize(size * size)
	var mottle := _noise_bytes(1101, 0.006, size, 3, 0.55)
	var med := _noise_bytes(1102, 0.038, size, 2, 0.5)
	var fine := _noise_bytes(1103, 0.55, size, 1, 0.5)
	var streak := _noise_bytes(1104, 0.22, size, 2, 0.5)
	var base := Color(0.905, 0.884, 0.848)   # warm off-white, lightly aged
	for y in size:
		var sy: int = (y / 4) * size          # smear horizontally -> roller bands
		for x in size:
			var i: int = y * size + x
			var v: float = 1.0
			v += (float(mottle[i]) - 128.0) / 128.0 * 0.017
			v += (float(med[i]) - 128.0) / 128.0 * 0.007
			v += (float(streak[sy + x]) - 128.0) / 128.0 * 0.008
			if fine[i] > 243:
				v -= 0.022
			var c := Color(base.r * v, base.g * v, base.b * v)
			_put(buf, size, x, y, c)
			h[i] = int(clampf((float(mottle[i]) - 128.0) / 128.0 * 0.5 + 0.5, 0.0, 1.0) * 255.0)
	_save_rgba(buf, size, "paint_wall.png")
	# near-flat normal map: painted plaster should not show relief when a low
	# sun rakes along it
	_save_rgba(_normal_from(h, size, 0.10), size, "paint_wall_n.png")

static func _paint_ceiling() -> void:
	var size: int = 256
	var buf := _blank(size)
	var mottle := _noise_bytes(1201, 0.008, size, 3, 0.5)
	var fine := _noise_bytes(1202, 0.6, size, 1, 0.5)
	var base := Color(0.955, 0.950, 0.935)
	for y in size:
		for x in size:
			var i: int = y * size + x
			var v: float = 1.0 + (float(mottle[i]) - 128.0) / 128.0 * 0.012
			if fine[i] > 240:
				v -= 0.02
			_put(buf, size, x, y, Color(base.r * v, base.g * v, base.b * v))
	_save_rgba(buf, size, "paint_ceiling.png")

# ----------------------------------------------------------- floor boards --

static func _floor_laminate() -> void:
	var size: int = 512
	var planks: int = 4
	var ph: int = size / planks                 # 128 px = 0.30 m at a 1.2 m tile
	var buf := _blank(size)
	var h := PackedByteArray()
	h.resize(size * size)
	var grain_a := _noise_bytes(2101, 0.010, size, 3, 0.5)
	var grain_b := _noise_bytes(2102, 0.13, size, 2, 0.5)
	var mottle := _noise_bytes(2103, 0.006, size, 2, 0.5)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	# one tone + one end-joint set per plank
	var tones: Array = []
	var joints: Array = []
	for p in planks:
		tones.append(1.0 + rng.randf_range(-0.075, 0.075))
		var j: Array = []
		var count: int = rng.randi_range(1, 2)
		for k in count:
			j.append(rng.randi_range(60, size - 60))
		joints.append(j)
	for y in size:
		var p: int = y / ph
		var in_plank: int = y - p * ph
		var tone: float = tones[p]
		for x in size:
			var i: int = y * size + x
			var v: float = tone
			# long grain streaks + fine grain, kept gentle so a modest floor
			# never reads as stained
			v += (float(grain_a[(y * size) + x]) - 128.0) / 128.0 * 0.030
			v += (float(grain_b[i]) - 128.0) / 128.0 * 0.014
			v += (float(mottle[i]) - 128.0) / 128.0 * 0.010
			var groove: float = 0.0
			# seam between planks
			if in_plank <= 1 or in_plank >= ph - 1:
				groove = 1.0
				v *= 0.72
			# end joints
			for jx in joints[p]:
				var d: int = absi(x - jx)
				if d <= 1:
					groove = 1.0
					v *= 0.74
			var base := Color(0.590, 0.455, 0.335)   # warm mid oak, modest laminate
			_put(buf, size, x, y, Color(base.r * v, base.g * v, base.b * v))
			h[i] = 60 if groove > 0.0 else int(clampf((float(grain_b[i]) - 128.0) / 128.0 * 0.35 + 0.65, 0.0, 1.0) * 255.0)
	_save_rgba(buf, size, "floor_laminate.png")
	_save_rgba(_normal_from(h, size, 2.2), size, "floor_laminate_n.png")

# --------------------------------------------------------------- ceramics --

static func _tile_floor() -> void:
	var size: int = 512
	var tile: int = 168        # 0.20 m at a 0.6 m tile
	var grout: int = 4
	var buf := _blank(size)
	var h := PackedByteArray()
	h.resize(size * size)
	var speck := _noise_bytes(3101, 0.5, size, 1, 0.5)
	var mottle := _noise_bytes(3102, 0.01, size, 2, 0.5)
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var tone: Array = []
	for t in 9:
		tone.append(1.0 + rng.randf_range(-0.035, 0.035))
	for y in size:
		var ty: int = y / tile
		var iy: int = y - ty * tile
		for x in size:
			var i: int = y * size + x
			var tx: int = x / tile
			var ix: int = x - tx * tile
			var idx: int = (ty % 3) * 3 + (tx % 3)
			var is_grout: bool = iy < grout or ix < grout
			var v: float = tone[idx]
			v += (float(mottle[i]) - 128.0) / 128.0 * 0.012
			v += (float(speck[i]) - 128.0) / 128.0 * 0.010
			var c: Color
			var hh: int = 150
			if is_grout:
				c = Color(0.700, 0.690, 0.665)
				c = Color(c.r * v, c.g * v, c.b * v)
				hh = 40
			else:
				c = Color(0.820, 0.805, 0.775)   # warm light ceramic
				c = Color(c.r * v, c.g * v, c.b * v)
				# soft bevel: brighter top/left, darker bottom/right
				if iy < grout + 3 or ix < grout + 3:
					c = c.lightened(0.05)
				if iy > tile - 4 or ix > tile - 4:
					c = c.darkened(0.06)
			_put(buf, size, x, y, c)
			h[i] = hh
	_save_rgba(buf, size, "tile_floor.png")
	_save_rgba(_normal_from(h, size, 2.6), size, "tile_floor_n.png")

static func _tile_wall() -> void:
	var size: int = 512
	var tile: int = 128        # 0.25 m at a 1.0 m tile
	var grout: int = 2
	var buf := _blank(size)
	var h := PackedByteArray()
	h.resize(size * size)
	var mottle := _noise_bytes(3201, 0.012, size, 2, 0.5)
	var speck := _noise_bytes(3202, 0.45, size, 1, 0.5)
	var rng := RandomNumberGenerator.new()
	rng.seed = 33
	var tone: Array = []
	for t in 16:
		tone.append(1.0 + rng.randf_range(-0.022, 0.022))
	for y in size:
		var ty: int = y / tile
		var iy: int = y - ty * tile
		for x in size:
			var i: int = y * size + x
			var tx: int = x / tile
			var ix: int = x - tx * tile
			var idx: int = (ty % 4) * 4 + (tx % 4)
			var is_grout: bool = iy < grout or ix < grout
			var v: float = tone[idx]
			v += (float(mottle[i]) - 128.0) / 128.0 * 0.010
			v += (float(speck[i]) - 128.0) / 128.0 * 0.008
			var c: Color
			var hh: int = 165
			if is_grout:
				c = Color(0.760, 0.755, 0.740)
				hh = 30
			else:
				c = Color(0.905, 0.902, 0.885)
				if iy < grout + 2 or ix < grout + 2:
					c = c.lightened(0.04)
				if iy > tile - 3 or ix > tile - 3:
					c = c.darkened(0.05)
			c = Color(c.r * v, c.g * v, c.b * v)
			_put(buf, size, x, y, c)
			h[i] = hh
	_save_rgba(buf, size, "tile_wall.png")
	_save_rgba(_normal_from(h, size, 2.4), size, "tile_wall_n.png")

# --------------------------------------------------------------- concrete --

static func _concrete() -> void:
	var size: int = 512
	var buf := _blank(size)
	var h := PackedByteArray()
	h.resize(size * size)
	var patch := _noise_bytes(4101, 0.004, size, 3, 0.55)
	var med := _noise_bytes(4102, 0.018, size, 2, 0.5)
	var agg := _noise_bytes(4103, 0.30, size, 2, 0.5)
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var stains: Array = []
	for s in 4:
		stains.append([rng.randi_range(0, size - 1), rng.randi_range(0, size - 1),
			rng.randf_range(110.0, 210.0), rng.randf_range(0.05, 0.10)])
	var pits: Array = []
	for p in 34:
		pits.append([rng.randi_range(0, size - 1), rng.randi_range(0, size - 1)])
	for y in size:
		for x in size:
			var i: int = y * size + x
			var v: float = 1.0
			v += (float(patch[i]) - 128.0) / 128.0 * 0.055
			v += (float(med[i]) - 128.0) / 128.0 * 0.022
			# aggregate fleck, kept low-contrast: this is a surface, not gravel
			if agg[i] > 206:
				v += 0.022
			elif agg[i] < 52:
				v -= 0.022
			# weather stains
			for s in stains:
				v -= _stain(x, y, s[0], s[1], s[2], size) * s[3]
			var pit: bool = false
			for p in pits:
				var dx: int = absi(x - p[0])
				var dy: int = absi(y - p[1])
				if dx <= 1 and dy <= 1:
					pit = true
			if pit:
				v -= 0.14
			var base := Color(0.655, 0.645, 0.618)
			_put(buf, size, x, y, Color(base.r * v, base.g * v, base.b * v))
			h[i] = 25 if pit else int(clampf((float(agg[i]) - 128.0) / 128.0 * 0.4 + 0.62, 0.0, 1.0) * 255.0)
	_save_rgba(buf, size, "concrete.png")
	_save_rgba(_normal_from(h, size, 1.4), size, "concrete_n.png")

# ------------------------------------------------------------------ paper --

static func _paper() -> void:
	var size: int = 256
	var buf := _blank(size)
	var fib := _noise_bytes(5101, 0.55, size, 2, 0.5)
	var mottle := _noise_bytes(5102, 0.02, size, 2, 0.5)
	for y in size:
		for x in size:
			var i: int = y * size + x
			var v: float = 1.0
			v += (float(fib[i]) - 128.0) / 128.0 * 0.020
			v += (float(mottle[i]) - 128.0) / 128.0 * 0.015
			# slight handling darkening toward the edges of the sheet
			var ex: float = minf(float(x), float(size - 1 - x)) / (size * 0.5)
			var ey: float = minf(float(y), float(size - 1 - y)) / (size * 0.5)
			var edge: float = minf(ex, ey)
			if edge < 0.12:
				v -= (0.12 - edge) / 0.12 * 0.05
			_put(buf, size, x, y, Color(0.940 * v, 0.922 * v, 0.882 * v))
	_save_rgba(buf, size, "paper.png")

# ------------------------------------------------------------ wood & cloth --

## Neutral detail texture: multiply it with albedo_color to get any timber tone.
static func _wood_grain() -> void:
	var size: int = 256
	var buf := _blank(size)
	var h := PackedByteArray()
	h.resize(size * size)
	var grain := _noise_bytes(6101, 0.012, size, 3, 0.5)
	var fine := _noise_bytes(6102, 0.22, size, 2, 0.5)
	for y in size:
		var sy: int = (y / 3) * size              # streak along X
		for x in size:
			var i: int = y * size + x
			var v: float = 0.82
			v += (float(grain[sy + x]) - 128.0) / 128.0 * 0.16
			v += (float(fine[i]) - 128.0) / 128.0 * 0.05
			_put(buf, size, x, y, Color(v, v * 0.985, v * 0.96))
			h[i] = int(clampf(v, 0.0, 1.0) * 255.0)
	_save_rgba(buf, size, "wood_grain.png")
	_save_rgba(_normal_from(h, size, 0.8), size, "wood_grain_n.png")

## Neutral woven cloth: multiply with albedo_color for any fabric colour.
static func _fabric_weave() -> void:
	var size: int = 512
	var buf := _blank(size)
	var h := PackedByteArray()
	h.resize(size * size)
	var mottle := _noise_bytes(7101, 0.02, size, 2, 0.5)
	var fuzz := _noise_bytes(7102, 0.55, size, 1, 0.5)
	var thread: int = 3
	for y in size:
		for x in size:
			var i: int = y * size + x
			var warp: bool = (x / thread) % 2 == 0
			var weft: bool = (y / thread) % 2 == 0
			var v: float = 0.89
			# irregular mottle carries the cloth look; the regular weave stays
			# near-flat so large sheets never read as a printed pattern
			if warp == weft:
				v += 0.005
			else:
				v -= 0.004
			v += (float(mottle[i]) - 128.0) / 128.0 * 0.028
			v += (float(fuzz[i]) - 128.0) / 128.0 * 0.014
			_put(buf, size, x, y, Color(v, v, v))
			h[i] = int(clampf(v, 0.0, 1.0) * 255.0)
	_save_rgba(buf, size, "fabric_weave.png")
	_save_rgba(_normal_from(h, size, 0.9), size, "fabric_weave_n.png")

## Neutral scuffed/worn surface with darker edges, for book covers and cases.
static func _cover_worn() -> void:
	var size: int = 256
	var buf := _blank(size)
	var wear := _noise_bytes(8101, 0.02, size, 3, 0.5)
	var scuff := _noise_bytes(8102, 0.35, size, 2, 0.5)
	for y in size:
		for x in size:
			var i: int = y * size + x
			var v: float = 0.86
			v += (float(wear[i]) - 128.0) / 128.0 * 0.09
			v += (float(scuff[i]) - 128.0) / 128.0 * 0.035
			var ex: float = minf(float(x), float(size - 1 - x)) / (size * 0.5)
			var ey: float = minf(float(y), float(size - 1 - y)) / (size * 0.5)
			var edge: float = minf(ex, ey)
			if edge < 0.10:
				# rubbed, lighter corners and edges
				v += (0.10 - edge) / 0.10 * 0.10
			_put(buf, size, x, y, Color(v, v * 0.99, v * 0.98))
	_save_rgba(buf, size, "cover_worn.png")
