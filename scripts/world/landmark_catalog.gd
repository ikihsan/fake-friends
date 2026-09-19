class_name FFLandmarkCatalog
extends RefCounted

## Single source of truth for every place Chris can know about.
##
## Used by BOTH sides of the discovery loop, so the world and the handbook can
## never disagree:
##   - tools/build_neighborhood.gd places one FFLandmark per id from here,
##   - scripts/gameplay/ui/handbook_sketch.gd draws discovered ids from here.
##
## Stable ids are the save keys (GameState.data["landmarks"]). Labels are only
## ever presentation. `map` is a rough remembered position in the neighbourhood's
## X/Z metres - deliberately approximate, because the handbook is a sketch.
##
## Keep ids stable across days; add new ids, never rename old ones.

const LANDMARKS: Dictionary = {
	"apartment": {
		"label": "Apartment",
		"map": Vector2(2.0, 2.7),
		"icon": "home",
		"thought": "",
	},
	"corner_store": {
		"label": "Corner store",
		"map": Vector2(6.0, -1.1),
		"icon": "shop",
		"thought": "The corner shop. Shuttered half the time.",
	},
	"park": {
		"label": "Park",
		"map": Vector2(-14.0, 2.3),
		"icon": "park",
		"thought": "A park.",
	},
	"bus_stop": {
		"label": "Bus stop",
		"map": Vector2(-11.0, -2.6),
		"icon": "stop",
		"thought": "The bus stop. I know this corner.",
	},
	"internet_cafe": {
		"label": "Internet Cafe",
		"map": Vector2(2.5, -11.1),
		"icon": "shop",
		"thought": "Internet Cafe. That name looks familiar.",
	},
	"cafe_caffeine": {
		"label": "Cafe Caffeine",
		"map": Vector2(11.0, -11.1),
		"icon": "cafe",
		"thought": "Cafe Caffeine. This must be it.",
	},
	"market": {
		"label": "Market",
		"map": Vector2(17.5, -11.1),
		"icon": "market",
		"thought": "The market.",
	},
	"maxwell_home": {
		"label": "Maxwell's",
		"map": Vector2(6.3, -21.0),
		"icon": "home",
		"thought": "Maxwell's place.",
	},
}

## Rough remembered connections between places - drawn only when BOTH ends are
## known, so the sketch grows as a whole picture rather than as loose dots.
const PATHS: Array = [
	["apartment", "corner_store"],
	["apartment", "park"],
	["park", "bus_stop"],
	["bus_stop", "internet_cafe"],
	["internet_cafe", "cafe_caffeine"],
	["cafe_caffeine", "market"],
	["internet_cafe", "maxwell_home"],
]

static func has_id(id: String) -> bool:
	return LANDMARKS.has(id)

static func ids() -> Array:
	return LANDMARKS.keys()

static func entry(id: String) -> Dictionary:
	return LANDMARKS.get(id, {})

static func label_for(id: String) -> String:
	return str(entry(id).get("label", id))

static func map_pos(id: String) -> Vector2:
	return entry(id).get("map", Vector2.ZERO)

static func icon_for(id: String) -> String:
	return str(entry(id).get("icon", "dot"))

static func thought_for(id: String) -> String:
	return str(entry(id).get("thought", ""))
