class_name FFGameState
extends Node

const SCHEMA_VERSION: int = 1
const SAVE_PATH: String = "user://fake_friends_state_v1.json"
const PAGE_RESOURCES: Array[Resource] = [
	preload("res://resources/handbook/sofia.tres"),
	preload("res://resources/handbook/maxwell.tres"),
	preload("res://resources/handbook/maria.tres"),
	preload("res://resources/handbook/bobby.tres"),
	preload("res://resources/handbook/tomorrow_plan.tres"),
	preload("res://resources/handbook/map.tres")
]
## Set false BEFORE adding a test instance to the tree; tests never need disk access.
var persistence_enabled: bool = true
var data: Dictionary = default_data()
var _save_blocked: bool = false

static func default_data() -> Dictionary:
	return {"schema_version": SCHEMA_VERSION, "current_day": 1, "outfits": {},
		"plans": {"2": "Meet Sofia and Bobby at Cafe Caffeine."},
		"handbook_entries": {}, "struck_entries": {}, "landmarks": {"apartment": "Apartment"},
		"judgments": {}, "permanent_writing_used": {}, "plan_completion": {}, "flags": {}, "morning_by_day": {}, "events": []}

func _ready() -> void:
	if persistence_enabled:
		load_game()

func set_flag(key: String, value: bool = true) -> void:
	data["flags"][key] = value
	save_game()

func flag(key: String) -> bool:
	return data["flags"].get(key, false) == true

func set_outfit(id: String) -> void:
	data["outfits"][str(int(data["current_day"]))] = id
	save_game()

func outfit() -> String:
	return str(data["outfits"].get(str(int(data["current_day"])), ""))

func set_morning(key: String, value: Variant) -> void:
	var day: String = str(int(data["current_day"]))
	if not data["morning_by_day"].has(day):
		data["morning_by_day"][day] = {}
	data["morning_by_day"][day][key] = value
	save_game()

func morning_value(key: String, default_value: Variant = null) -> Variant:
	return data["morning_by_day"].get(str(int(data["current_day"])), {}).get(key, default_value)

## Future writing API; Day 1 is strictly read-only. One permanent edit per day.
func write_entry(entry_id: String, text: String, permanent: bool = false) -> bool:
	if int(data["current_day"]) <= 1 or entry_id.is_empty():
		return false
	if permanent and data["permanent_writing_used"].get(str(int(data["current_day"])), false) == true:
		return false
	data["handbook_entries"][entry_id] = text
	if permanent:
		data["permanent_writing_used"][str(int(data["current_day"]))] = true
	save_game()
	return true

func strike_entry(entry_id: String, struck: bool = true) -> bool:
	if int(data["current_day"]) <= 1:
		return false
	data["struck_entries"][entry_id] = struck
	save_game()
	return true

## Story-system writes (Maxwell on Day 1, future scripted events). These bypass
## the Day 1 player read-only guard on purpose: the PLAYER cannot write on Day 1,
## but the WORLD can leave marks he finds later. Idempotent: same id+text never
## duplicates, reload-safe. Uses the same runtime layer (handbook_entries /
## struck_entries), never mutates source .tres resources.
## Stable Day 1 IDs:
##   "plan.day_2.cafe" (source) -> struck complete
##   "plan.day_2.maxwell_party" -> "Join Maxwell's home party."
##   "maria.loves_me" -> "Maria loves me."
func story_write_entry(entry_id: String, text: String) -> bool:
	if entry_id.is_empty():
		return false
	if str(data["handbook_entries"].get(entry_id, "")) == text:
		return true
	data["handbook_entries"][entry_id] = text
	save_game()
	return true

func story_strike_entry(entry_id: String, struck: bool = true) -> bool:
	if entry_id.is_empty():
		return false
	if data["struck_entries"].get(entry_id, false) == struck:
		return true
	data["struck_entries"][entry_id] = struck
	save_game()
	return true

func set_plan_completed(day: int, completed: bool = true) -> void:
	data["plan_completion"][str(maxi(1, day))] = completed
	save_game()

func plan_completed(day: int) -> bool:
	return data["plan_completion"].get(str(maxi(1, day)), false) == true

## Batch read markers into a single save; repeated renders are idempotent.
func mark_handbook_read(page_id: String, entry_ids: Array) -> void:
	var changed: bool = false
	var keys: Array[String] = ["handbook_page_" + page_id]
	for entry_id: Variant in entry_ids:
		keys.append("handbook_entry_" + str(entry_id))
	for key: String in keys:
		if not flag(key):
			data["flags"][key] = true
			changed = true
	if changed:
		save_game()

func set_judgment(person_id: String, text: String) -> void:
	data["judgments"][person_id] = text
	save_game()

func discover_landmark(id: String, label: String) -> void:
	data["landmarks"][id] = label
	save_game()

func load_game() -> void:
	if not persistence_enabled:
		return
	var loaded: Dictionary = _read_save(SAVE_PATH)
	if loaded.is_empty() and FileAccess.file_exists(SAVE_PATH):
		# Never overwrite an unreadable/newer save, even if a backup can be read.
		_save_blocked = true
		push_warning("Fake Friends: save unreadable or unsupported; original preserved. Saving disabled this session.")
	if loaded.is_empty():
		loaded = _read_save(SAVE_PATH + ".bak")
	if not loaded.is_empty():
		data = normalize_data(loaded)

static func normalize_data(source: Dictionary) -> Dictionary:
	var result: Dictionary = default_data()
	for key: String in result:
		if key == "schema_version" or not source.has(key):
			continue
		if key == "current_day":
			if typeof(source[key]) in [TYPE_INT, TYPE_FLOAT]:
				result[key] = maxi(1, int(source[key]))
		elif typeof(source[key]) == typeof(result[key]):
			result[key] = source[key].duplicate(true) if source[key] is Dictionary or source[key] is Array else source[key]
	var day: String = str(int(result["current_day"]))
	# Legacy saves cannot identify the edit day: conservatively charge the saved day only.
	if source.get("permanent_writing_used") is bool and source["permanent_writing_used"]:
		result["permanent_writing_used"][day] = true
	if source.get("morning") is Dictionary and not result["morning_by_day"].has(day):
		result["morning_by_day"][day] = source["morning"].duplicate(true)
	for key: String in ["permanent_writing_used", "plan_completion", "morning_by_day"]:
		var cleaned: Dictionary = {}
		for raw_day: Variant in result[key]:
			var day_text: String = str(raw_day)
			if not day_text.is_valid_int() or int(day_text) < 1:
				continue
			var value: Variant = result[key][raw_day]
			if key == "morning_by_day":
				if value is Dictionary:
					cleaned[str(int(day_text))] = value.duplicate(true)
			elif value is bool:
				cleaned[str(int(day_text))] = value
		result[key] = cleaned
	return result

func _read_save(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > 4194304:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return {}
	var version: Variant = parsed.get("schema_version", 0)
	if not typeof(version) in [TYPE_INT, TYPE_FLOAT] or int(version) != SCHEMA_VERSION:
		return {}
	return parsed

func save_game() -> void:
	if not persistence_enabled or _save_blocked:
		return
	data["schema_version"] = SCHEMA_VERSION
	var temp_path: String = SAVE_PATH + ".tmp"
	var file: FileAccess = FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_warning("Fake Friends: could not open temporary save.")
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	var error: Error = file.get_error()
	file.close()
	if error != OK or _read_save(temp_path).is_empty():
		push_warning("Fake Friends: temporary save failed; previous save retained.")
		return
	if FileAccess.file_exists(SAVE_PATH):
		if DirAccess.copy_absolute(SAVE_PATH, SAVE_PATH + ".bak") != OK:
			push_warning("Fake Friends: backup failed; previous save retained.")
			return
	if DirAccess.rename_absolute(temp_path, SAVE_PATH) != OK:
		push_warning("Fake Friends: save replacement failed; previous save retained.")
