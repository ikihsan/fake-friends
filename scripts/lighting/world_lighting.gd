class_name WorldLighting
extends Node3D

## Preset type, preloaded so this script never depends on the editor's global
## class-name cache being warm (tools run before the editor rescans scripts).
const Preset := preload("res://scripts/lighting/lighting_preset.gd")

## Applies a LightingPreset to the sun, the WorldEnvironment and every lamp in
## the apartment.  Nothing here is gameplay logic — it is the switch that later
## Day / Evening / Night states (or a story beat) can throw.
##
## Usage:  $Lighting.apply_preset("evening")

@export var sun: DirectionalLight3D
## Shadowless sky-fill light (see LightingPreset.fill_energy).
@export var fill: DirectionalLight3D
@export var world_environment: WorldEnvironment
## Subtree that is scanned for OmniLight3D lamps (normally the apartment root,
## so lamps living inside prefabs such as the ceiling fan are included too).
@export var light_root: Node
@export var presets: Array[Preset] = []
@export var active_preset: String = "morning"

var _lights: Array[OmniLight3D] = []
var _base_energy: Array[float] = []

func _ready() -> void:
	_collect_lights()
	apply_preset(active_preset)

## Names of every preset assigned to this node.
func preset_names() -> Array[String]:
	var out: Array[String] = []
	for p in presets:
		if p != null:
			out.append(p.preset_name)
	return out

func find_preset(preset_name: String) -> Preset:
	for p in presets:
		if p != null and p.preset_name == preset_name:
			return p
	return null

## Apply a preset by name. Unknown names are reported and ignored.
func apply_preset(preset_name: String) -> void:
	var p: Preset = find_preset(preset_name)
	if p == null:
		push_warning("WorldLighting: no preset named '%s' (have %s)" % [preset_name, preset_names()])
		return
	active_preset = p.preset_name
	_apply_sun(p)
	_apply_fill(p)
	if world_environment != null:
		world_environment.environment = build_environment(p)
	_apply_lights(p)

## Time of day can also be driven by a 0..24 hour value; this maps to the
## closest named preset and keeps the door open for a continuous cycle later.
func apply_hour(hour: float) -> void:
	var h: float = fmod(hour + 24.0, 24.0)
	var slot: String = "night"
	if h >= 5.0 and h < 10.0:
		slot = "morning"
	elif h >= 10.0 and h < 16.5:
		slot = "day"
	elif h >= 16.5 and h < 20.5:
		slot = "evening"
	apply_preset(slot)

# ------------------------------------------------------------------ internals

func _collect_lights() -> void:
	_lights.clear()
	_base_energy.clear()
	var root: Node = light_root
	if root == null:
		root = get_parent()
	if root == null:
		return
	_gather(root)
	for l in _lights:
		_base_energy.append(l.light_energy)

func _gather(n: Node) -> void:
	if n is OmniLight3D:
		_lights.append(n as OmniLight3D)
	for c in n.get_children():
		_gather(c)

func _apply_sun(p: Preset) -> void:
	if sun == null:
		return
	sun.rotation_degrees = p.sun_rotation_degrees
	sun.light_color = p.sun_color
	sun.light_energy = p.sun_energy
	sun.light_angular_distance = p.sun_angular_distance
	sun.shadow_enabled = p.sun_shadows
	sun.shadow_blur = p.sun_shadow_blur

func _apply_fill(p: Preset) -> void:
	if fill == null:
		return
	fill.rotation_degrees = p.fill_rotation_degrees
	fill.light_color = p.fill_color
	fill.light_energy = p.fill_energy
	fill.visible = p.fill_energy > 0.001

func _apply_lights(p: Preset) -> void:
	for i in _lights.size():
		var l: OmniLight3D = _lights[i]
		if not is_instance_valid(l):
			continue
		var mult: float = _scale_for(l, p)
		l.light_energy = _base_energy[i] * mult
		# lamps that are off also stop casting shadows
		l.visible = mult > 0.001

func _scale_for(light: Node, p: Preset) -> float:
	var names: Array[String] = []
	var n: Node = light
	while n != null:
		names.append(String(n.name))
		n = n.get_parent()
	for key in p.light_scales.keys():
		for an in names:
			if an == String(key):
				return float(p.light_scales[key])
	var path: String = String(light.get_path()) if light.is_inside_tree() else ""
	for key in p.light_scales.keys():
		if path.contains(String(key)):
			return float(p.light_scales[key])
	return p.default_light_scale

## Build (or rebuild) the Environment described by a preset. Static so the scene
## builder can bake the morning look into the .tscn as well.
static func build_environment(p: Preset) -> Environment:
	var env := Environment.new()
	var sky := Sky.new()
	var psm := ProceduralSkyMaterial.new()
	psm.sky_top_color = p.sky_top_color
	psm.sky_horizon_color = p.sky_horizon_color
	psm.ground_horizon_color = p.sky_ground_horizon_color
	psm.ground_bottom_color = p.sky_ground_bottom_color
	psm.sky_energy_multiplier = p.sky_energy
	psm.ground_energy_multiplier = p.sky_energy * 0.7
	psm.sun_angle_max = p.sky_sun_angle_max
	psm.sun_curve = 0.12
	sky.sky_material = psm
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = p.ambient_color
	env.ambient_light_energy = p.ambient_energy
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_white = 2.0
	env.tonemap_exposure = p.tonemap_exposure
	env.ssao_enabled = p.ssao_enabled
	env.ssao_intensity = p.ssao_intensity
	# short radius: contact shading in corners without clouding flat surfaces
	env.ssao_radius = 0.6
	env.ssao_power = 1.2
	env.ssil_enabled = p.ssil_enabled
	env.ssil_intensity = p.ssil_intensity
	env.glow_enabled = p.glow_enabled
	env.glow_bloom = p.glow_bloom
	env.glow_hdr_threshold = p.glow_hdr_threshold
	env.glow_intensity = 0.5
	env.glow_strength = 1.0
	env.fog_enabled = false
	return env
