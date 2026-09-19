class_name BOBuildLighting
extends RefCounted

## Writes the time-of-day lighting presets into res://lighting/.
## Morning is the tuned, shipping look; the other three are working starting
## points so Day / Evening / Night can be dialled in later without touching code.
## Invoke via execute_script:  BOBuildLighting.run()

const OUT := "res://lighting/"
const PRESET := preload("res://scripts/lighting/lighting_preset.gd")

static func specs() -> Array:
	return [
		# ------------------------------------------------------- MORNING
		# Low sun in the east-north-east: it comes in through the bedroom
		# window and rakes across the photo wall.  Cool sky bounce, warm
		# direct light, lamps off except the bathroom fixture.
		{
			"preset_name": "morning",
			"sun_rotation_degrees": Vector3(-22, 110, 0),
			"sun_color": Color(1.0, 0.93, 0.80),
			"sun_energy": 2.4,
			"sun_angular_distance": 0.7,
			"sun_shadows": true,
			"sun_shadow_blur": 0.6,
			"sky_top_color": Color(0.30, 0.52, 0.85),
			"sky_horizon_color": Color(0.76, 0.83, 0.88),
			"sky_ground_horizon_color": Color(0.62, 0.62, 0.58),
			"sky_ground_bottom_color": Color(0.30, 0.29, 0.27),
			"sky_energy": 1.15,
			"fill_rotation_degrees": Vector3(-38, 96, 0),
			"fill_color": Color(0.95, 0.94, 0.90),
			"fill_energy": 0.46,
			"ambient_color": Color(0.66, 0.67, 0.70),
			"ambient_energy": 0.38,
			"tonemap_exposure": 1.05,
			"ssao_enabled": true,
			"ssao_intensity": 0.30,
			"ssil_enabled": false,
			"ssil_intensity": 0.0,
			"glow_enabled": true,
			"glow_bloom": 0.02,
			"glow_hdr_threshold": 1.25,
			"default_light_scale": 0.0,
			"light_scales": {
				"Bathroom": 0.85,
				"Exterior": 0.0,
			},
		},
		# ----------------------------------------------------------- DAY
		# High sun from the south: flat, bright, no raking shafts indoors.
		{
			"preset_name": "day",
			"sun_rotation_degrees": Vector3(-58, 150, 0),
			"sun_color": Color(1.0, 0.97, 0.92),
			"sun_energy": 2.6,
			"sun_angular_distance": 0.8,
			"sun_shadows": true,
			"sun_shadow_blur": 0.8,
			"sky_top_color": Color(0.24, 0.48, 0.88),
			"sky_horizon_color": Color(0.78, 0.86, 0.92),
			"sky_ground_horizon_color": Color(0.66, 0.66, 0.62),
			"sky_ground_bottom_color": Color(0.32, 0.31, 0.29),
			"sky_energy": 1.25,
			"fill_rotation_degrees": Vector3(-55, 140, 0),
			"fill_color": Color(0.95, 0.95, 0.96),
			"fill_energy": 0.75,
			"ambient_color": Color(0.72, 0.73, 0.75),
			"ambient_energy": 0.92,
			"tonemap_exposure": 1.0,
			"ssao_enabled": true,
			"ssao_intensity": 0.40,
			"ssil_enabled": false,
			"ssil_intensity": 0.0,
			"glow_enabled": true,
			"glow_bloom": 0.01,
			"glow_hdr_threshold": 1.4,
			"default_light_scale": 0.0,
			"light_scales": {"Bathroom": 0.55},
		},
		# ------------------------------------------------------- EVENING
		# Low amber sun from the west, lamps coming on as the interior cools.
		{
			"preset_name": "evening",
			"sun_rotation_degrees": Vector3(-12, 250, 0),
			"sun_color": Color(1.0, 0.72, 0.48),
			"sun_energy": 1.5,
			"sun_angular_distance": 2.0,
			"sun_shadows": true,
			"sun_shadow_blur": 1.4,
			"sky_top_color": Color(0.20, 0.28, 0.50),
			"sky_horizon_color": Color(0.86, 0.60, 0.42),
			"sky_ground_horizon_color": Color(0.42, 0.36, 0.34),
			"sky_ground_bottom_color": Color(0.18, 0.17, 0.18),
			"sky_energy": 0.9,
			"fill_rotation_degrees": Vector3(-22, 245, 0),
			"fill_color": Color(1.0, 0.86, 0.74),
			"fill_energy": 0.25,
			"ambient_color": Color(0.48, 0.48, 0.54),
			"ambient_energy": 0.55,
			"tonemap_exposure": 1.0,
			"ssao_enabled": true,
			"ssao_intensity": 0.50,
			"ssil_enabled": false,
			"ssil_intensity": 0.0,
			"glow_enabled": true,
			"glow_bloom": 0.05,
			"glow_hdr_threshold": 1.1,
			"default_light_scale": 0.0,
			"light_scales": {
				"Hall": 0.75,
				"Bathroom": 0.85,
				"BedsideLamp": 0.85,
				"Bedroom": 0.5,
				"WardrobeNook": 0.7,
				"Closet": 0.4,
				"Exterior": 0.6,
			},
		},
		# --------------------------------------------------------- NIGHT
		# Moonlight through the window; the apartment lit by its own fixtures.
		{
			"preset_name": "night",
			"sun_rotation_degrees": Vector3(-55, 40, 0),
			"sun_color": Color(0.62, 0.72, 0.95),
			"sun_energy": 0.30,
			"sun_angular_distance": 1.2,
			"sun_shadows": true,
			"sun_shadow_blur": 1.0,
			"sky_top_color": Color(0.02, 0.03, 0.07),
			"sky_horizon_color": Color(0.06, 0.08, 0.14),
			"sky_ground_horizon_color": Color(0.05, 0.05, 0.07),
			"sky_ground_bottom_color": Color(0.02, 0.02, 0.03),
			"sky_energy": 0.5,
			"ambient_color": Color(0.20, 0.23, 0.32),
			"ambient_energy": 0.34,
			"tonemap_exposure": 1.05,
			"ssao_enabled": true,
			"ssao_intensity": 0.55,
			"ssil_enabled": false,
			"ssil_intensity": 0.5,
			"glow_enabled": true,
			"glow_bloom": 0.08,
			"glow_hdr_threshold": 1.0,
			"default_light_scale": 0.0,
			"light_scales": {
				"Hall": 1.0,
				"Bathroom": 0.9,
				"BedsideLamp": 0.95,
				"Bedroom": 0.6,
				"WardrobeNook": 0.7,
				"Closet": 0.4,
				"Exterior": 1.0,
			},
		},
	]

static func run() -> int:
	var da := DirAccess.open("res://")
	if da != null and not da.dir_exists("lighting"):
		da.make_dir_recursive("lighting")
	var fails: int = 0
	for spec in specs():
		var p = PRESET.new()
		for k in spec.keys():
			p.set(k, spec[k])
		var path: String = OUT + String(p.preset_name) + ".tres"
		var err: int = ResourceSaver.save(p, path)
		if err != OK:
			print("FAIL ", path, " err=", err)
			fails += 1
		else:
			print("  %-28s sun=%s energy=%.2f" % [path, str(p.sun_rotation_degrees), p.sun_energy])
	print("lighting presets written: %d / %d" % [specs().size() - fails, specs().size()])
	return fails
