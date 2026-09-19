class_name LightingPreset
extends Resource

## One time-of-day lighting state: sun, sky, ambient, post-processing and the
## multipliers applied to every interior/exterior lamp.
##
## The game is NOT baked into morning — WorldLighting picks a preset by name at
## runtime, so Day / Evening / Night (and any later story state) can be swapped
## with a single call:  $Lighting.apply_preset("evening")

@export var preset_name: String = "morning"

@export_group("Sun")
@export var sun_rotation_degrees: Vector3 = Vector3(-22, 110, 0)
@export var sun_color: Color = Color(1.0, 0.93, 0.80)
@export var sun_energy: float = 2.2
## Bigger values give softer, hazier shadows (like morning haze).
@export var sun_angular_distance: float = 1.5
@export var sun_shadows: bool = true
@export var sun_shadow_blur: float = 1.0

@export_group("Sky fill")
## Shadowless secondary light standing in for the bright sky dome: it gives the
## interior directional form without faking a spotlight on anything.
@export var fill_rotation_degrees: Vector3 = Vector3(-38, 96, 0)
@export var fill_color: Color = Color(0.92, 0.93, 0.96)
## 0 = no sky fill (e.g. at night, when only the lamps should read).
@export var fill_energy: float = 0.0

@export_group("Sky")
@export var sky_top_color: Color = Color(0.30, 0.52, 0.85)
@export var sky_horizon_color: Color = Color(0.74, 0.82, 0.88)
@export var sky_ground_horizon_color: Color = Color(0.62, 0.62, 0.58)
@export var sky_ground_bottom_color: Color = Color(0.30, 0.29, 0.27)
@export var sky_energy: float = 1.15
@export var sky_sun_angle_max: float = 8.0

@export_group("Ambient and tone")
@export var ambient_color: Color = Color(0.56, 0.63, 0.72)
@export var ambient_energy: float = 0.62
@export var tonemap_exposure: float = 1.0
@export var ssao_enabled: bool = true
@export var ssao_intensity: float = 1.2
@export var ssil_enabled: bool = true
@export var ssil_intensity: float = 0.6
@export var glow_enabled: bool = true
@export var glow_bloom: float = 0.02
@export var glow_hdr_threshold: float = 1.3

@export_group("Interior lights")
## Multiplier for every lamp that no rule below matches.
@export var default_light_scale: float = 0.0
## Ancestor node name -> multiplier, e.g. {"Bathroom": 0.85, "Exterior": 0.0}
## Matching walks up from each lamp, so a lamp inside the ceiling-fan prefab is
## controlled by the "Bedroom" or "CeilingFan" entry.
@export var light_scales: Dictionary = {}
