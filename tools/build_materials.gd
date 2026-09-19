class_name BOBuildMaterials
extends RefCounted

## Writes the project's material library into res://materials/.
## One table = the whole look, so the palette can be re-tuned in one place.
## Invoke via execute_script:  BOBuildMaterials.run()

const OUT := "res://materials/"

## keys:
##   albedo / normal : texture paths ("" = none)
##   color           : albedo tint (multiplies the texture)
##   rough           : roughness, rough_tex = modulate it by the albedo texture
##   tri             : triplanar repeat scale (0 = plain UV mapping)
##   sharp           : triplanar sharpness
##   metallic, spec  : metalness / specular
##   emit            : emission colour (emission on), emit_e : energy
##   alpha           : transparency on, cull = cull_mode (2 = two sided)
static func defs() -> Array:
	return [
		# ------------------------------------------------ architecture
		# Matte architectural paint: low specular so flat surfaces read as
		# painted plaster instead of picking up a broad sky sheen.
		{"name": "mat_wall", "albedo": "paint_wall.png", "normal": "paint_wall_n.png",
			"nscale": 0.22, "rough": 0.97, "rough_tex": true, "spec": 0.16,
			"tri": 0.5, "sharp": 2.0},
		{"name": "mat_ceiling", "albedo": "paint_ceiling.png", "rough": 1.0,
			"rough_tex": true, "spec": 0.12, "tri": 0.5, "sharp": 2.0},
		{"name": "mat_floor_wood", "albedo": "floor_laminate.png", "normal": "floor_laminate_n.png",
			"nscale": 0.85, "rough": 0.62, "rough_tex": true, "spec": 0.32,
			"tri": 0.8333, "sharp": 3.0},
		{"name": "mat_floor_tile", "albedo": "tile_floor.png", "normal": "tile_floor_n.png",
			"nscale": 1.0, "rough": 0.42, "rough_tex": true, "spec": 0.45,
			"tri": 1.6667, "sharp": 3.0},
		{"name": "mat_tile_wall", "albedo": "tile_wall.png", "normal": "tile_wall_n.png",
			"nscale": 0.9, "rough": 0.30, "rough_tex": true, "spec": 0.5,
			"tri": 1.0, "sharp": 3.0},
		{"name": "mat_concrete", "albedo": "concrete.png", "normal": "concrete_n.png",
			"nscale": 0.7, "rough": 0.95, "rough_tex": true, "spec": 0.18,
			"tri": 0.5, "sharp": 2.0},
		{"name": "mat_ground", "albedo": "concrete.png", "normal": "concrete_n.png",
			"color": Color(0.44, 0.43, 0.42), "nscale": 0.6, "rough": 0.98,
			"rough_tex": true, "spec": 0.12, "tri": 0.30, "sharp": 2.0},
		{"name": "mat_paint_white", "albedo": "paint_ceiling.png",
			"color": Color(0.97, 0.96, 0.94), "rough": 0.48, "rough_tex": true,
			"spec": 0.35, "tri": 0.7, "sharp": 2.0},
		{"name": "mat_door", "albedo": "paint_ceiling.png", "normal": "paint_wall_n.png",
			"color": Color(0.86, 0.84, 0.79), "nscale": 0.3, "rough": 0.55,
			"rough_tex": true, "spec": 0.38, "tri": 1.2, "sharp": 2.0},

		# ------------------------------------------------ timber
		{"name": "mat_wood", "albedo": "wood_grain.png", "normal": "wood_grain_n.png",
			"color": Color(0.47, 0.32, 0.21), "nscale": 0.45, "rough": 0.62},
		{"name": "mat_wood_light", "albedo": "wood_grain.png", "normal": "wood_grain_n.png",
			"color": Color(0.74, 0.57, 0.40), "nscale": 0.45, "rough": 0.60},

		# ------------------------------------------------ textiles
		{"name": "mat_fabric", "albedo": "fabric_weave.png", "normal": "fabric_weave_n.png",
			"color": Color(0.42, 0.47, 0.57), "nscale": 0.35, "rough": 0.95},
		{"name": "mat_bedding", "albedo": "fabric_weave.png", "normal": "fabric_weave_n.png",
			"color": Color(0.94, 0.92, 0.87), "nscale": 0.30, "rough": 0.95},
		{"name": "mat_bedding_warm", "albedo": "fabric_weave.png", "normal": "fabric_weave_n.png",
			"color": Color(0.78, 0.72, 0.66), "nscale": 0.30, "rough": 0.95},
		{"name": "mat_curtain", "albedo": "fabric_weave.png", "normal": "fabric_weave_n.png",
			"color": Color(0.88, 0.89, 0.90), "nscale": 0.28, "rough": 0.90},
		{"name": "mat_towel", "albedo": "fabric_weave.png", "normal": "fabric_weave_n.png",
			"color": Color(0.74, 0.79, 0.76), "nscale": 0.40, "rough": 0.98},
		{"name": "mat_rug", "albedo": "fabric_weave.png", "normal": "fabric_weave_n.png",
			"color": Color(0.60, 0.49, 0.43), "nscale": 0.45, "rough": 1.0},
		{"name": "mat_plant", "albedo": "fabric_weave.png", "normal": "fabric_weave_n.png",
			"color": Color(0.27, 0.43, 0.23), "nscale": 0.45, "rough": 0.85},

		# ------------------------------------------------ hard surfaces
		{"name": "mat_ceramic", "color": Color(0.95, 0.955, 0.96), "rough": 0.12, "spec": 0.6},
		{"name": "mat_porcelain_used", "color": Color(0.90, 0.905, 0.905), "rough": 0.20, "spec": 0.5},
		{"name": "mat_glass", "color": Color(0.72, 0.80, 0.85, 0.16), "rough": 0.05,
			"metallic": 0.1, "alpha": true, "cull": 2},
		# Bright, faintly tinted glass: with no planar reflection probe a dark
		# metallic mirror just reads as a black hole in the wall.
		{"name": "mat_mirror", "color": Color(0.88, 0.91, 0.93), "rough": 0.10, "metallic": 0.85},
		{"name": "mat_metal", "color": Color(0.44, 0.45, 0.47), "rough": 0.38, "metallic": 0.85},
		{"name": "mat_metal_dark", "color": Color(0.24, 0.25, 0.27), "rough": 0.42, "metallic": 0.8},
		{"name": "mat_plastic", "color": Color(0.91, 0.91, 0.90), "rough": 0.35},
		{"name": "mat_plastic_dark", "color": Color(0.17, 0.17, 0.19), "rough": 0.30},
		{"name": "mat_dark", "color": Color(0.11, 0.11, 0.12), "rough": 0.45},
		{"name": "mat_ink", "color": Color(0.12, 0.13, 0.17), "rough": 0.55},
		{"name": "mat_pot", "albedo": "fabric_weave.png", "normal": "fabric_weave_n.png",
			"color": Color(0.60, 0.38, 0.29), "nscale": 0.4, "rough": 0.85},
		{"name": "mat_screen", "color": Color(0.06, 0.07, 0.09), "rough": 0.18,
			"emit": Color(0.34, 0.42, 0.55), "emit_e": 0.35},
		{"name": "mat_lamp_glow", "color": Color(0.95, 0.89, 0.76), "rough": 0.40,
			"emit": Color(1.0, 0.88, 0.68), "emit_e": 1.1},

		# ------------------------------------------------ paper & covers
		{"name": "mat_paper", "albedo": "paper.png", "rough": 0.85},
		{"name": "mat_water", "color": Color(0.72, 0.84, 0.86, 0.45), "rough": 0.05,
			"alpha": true, "cull": 2},
		{"name": "mat_tape", "color": Color(0.90, 0.88, 0.80, 0.42), "rough": 0.22,
			"alpha": true, "cull": 2},
		{"name": "mat_book_cover", "albedo": "cover_worn.png",
			"color": Color(0.33, 0.39, 0.46), "rough": 0.68},
		{"name": "mat_book_cover_rust", "albedo": "cover_worn.png",
			"color": Color(0.56, 0.30, 0.25), "rough": 0.70},
		{"name": "mat_photo", "albedo": "../assets/generated/photo_group.png", "rough": 0.34},
	]

static func run() -> int:
	var da := DirAccess.open("res://")
	if da != null and not da.dir_exists("materials"):
		da.make_dir_recursive("materials")
	var count: int = 0
	for d in defs():
		var path: String = OUT + String(d["name"]) + ".tres"
		var err: int = _write(path, d)
		if err != OK:
			print("FAIL ", path, " err=", err)
		else:
			count += 1
	print("materials written: %d / %d" % [count, defs().size()])
	return defs().size() - count

static func _write(path: String, d: Dictionary) -> int:
	var ext: Array = []
	var lines: Array = []
	if d.has("albedo"):
		ext.append({"id": "1_albedo", "path": _tex(String(d["albedo"]))})
	if d.has("normal"):
		ext.append({"id": "2_normal", "path": _tex(String(d["normal"]))})

	var body: Array = []
	body.append("resource_name = \"%s\"" % d["name"])
	if d.has("color"):
		body.append("albedo_color = " + _col(d["color"]))
	if d.has("albedo"):
		body.append("albedo_texture = ExtResource(\"1_albedo\")")
	if d.has("normal"):
		body.append("normal_enabled = true")
		body.append("normal_texture = ExtResource(\"2_normal\")")
		body.append("normal_scale = %.2f" % d.get("nscale", 0.6))
	if d.has("metallic"):
		body.append("metallic = %.2f" % d["metallic"])
	if d.has("spec"):
		body.append("metallic_specular = %.2f" % d["spec"])
	if d.get("rough_tex", false):
		body.append("roughness_texture = ExtResource(\"1_albedo\")")
		body.append("roughness_texture_channel = 4")
	body.append("roughness = %.2f" % d.get("rough", 0.9))
	if d.has("emit"):
		body.append("emission_enabled = true")
		body.append("emission = " + _col(d["emit"]))
		body.append("emission_energy_multiplier = %.2f" % d.get("emit_e", 1.0))
	if d.get("alpha", false):
		body.append("transparency = 1")
	if d.has("cull"):
		body.append("cull_mode = %d" % d["cull"])
	if d.has("tri"):
		body.append("uv1_triplanar = true")
		var s: float = d["tri"]
		body.append("uv1_scale = Vector3(%s, %s, %s)" % [_f(s), _f(s), _f(s)])
		body.append("uv1_triplanar_sharpness = %.1f" % d.get("sharp", 2.0))

	var text: String = "[gd_resource type=\"StandardMaterial3D\" load_steps=%d format=3]\n\n" % (ext.size() + 1)
	for e in ext:
		text += "[ext_resource type=\"Texture2D\" path=\"%s\" id=\"%s\"]\n" % [e["path"], e["id"]]
	text += "\n[resource]\n"
	for l in body:
		text += l + "\n"
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(text)
	f.close()
	return OK

static func _tex(name: String) -> String:
	if name.begins_with("res://") or name.begins_with("../"):
		return name if name.begins_with("res://") else "res://" + name.substr(3)
	return "res://textures/" + name

static func _f(v: float) -> String:
	var s: String = "%.4f" % v
	while s.ends_with("0") and s.length() > 3:
		s = s.substr(0, s.length() - 1)
	return s

static func _col(c: Color) -> String:
	return "Color(%s, %s, %s, %s)" % [_f(c.r), _f(c.g), _f(c.b), _f(c.a)]
