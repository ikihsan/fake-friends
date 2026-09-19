class_name FFAudioDirector
extends Node

## The single owner of every sound hook in the game.
##
## No audio asset exists yet, and none is required: a cue is a named hook, not a
## file. When no AudioStreamPlayer answers a cue the cue is still valid — it is
## recorded in a small ring of recent misses and logged at most ONCE per distinct
## cue name, so a silent game never errors, never warns and never spams.
##
## Players are matched by node name: an AudioStreamPlayer/AudioStreamPlayer3D
## named "coffee_brew" answers the "coffee_brew" cue. Adding the node later is
## enough, because the lookup happens at cue time.

signal cue_played(cue: String)

const ZoneScript = preload("res://scripts/world/ambience_zone.gd")

const MISSING_HISTORY := 8

var _zones: Array[ZoneScript] = []
var _players: Dictionary = {}
var _reported_missing: Dictionary = {}
var _missing: Array[String] = []
var _active_ambience: String = ""

## Connects every FFAmbienceZone found under zone_root and indexes the players
## already in this director's own subtree. Safe to call again after adding zones.
func initialize(zone_root: Node) -> void:
	_scan_players()
	if zone_root == null:
		return
	for zone: ZoneScript in _find_zones(zone_root):
		_connect_zone(zone)

## The one entry point for sound. Always emits cue_played; plays something only
## when a matching stream exists.
func play_cue(cue: String) -> void:
	if cue.is_empty():
		return
	var player: Node = _player_for(cue)
	if player == null or not _has_stream(player):
		_note_missing(cue)
	else:
		_start_player(player)
	cue_played.emit(cue)

## Feeds any object exposing sound_requested (the morning ritual, doors, ...)
## into play_cue. Objects without that signal are ignored, not reported.
func connect_emitter(emitter: Object) -> void:
	if emitter == null or not emitter.has_signal("sound_requested"):
		return
	if emitter.is_connected("sound_requested", play_cue):
		return
	emitter.connect("sound_requested", play_cue)

func zones() -> Array[ZoneScript]:
	var out: Array[ZoneScript] = []
	out.append_array(_zones)
	return out

## The last MISSING_HISTORY cues that had no player, oldest first.
func missing_cues() -> Array[String]:
	var out: Array[String] = []
	out.append_array(_missing)
	return out

func active_ambience() -> String:
	return _active_ambience

func _connect_zone(zone: ZoneScript) -> void:
	if zone == null or _zones.has(zone):
		return
	_zones.append(zone)
	if not zone.entered.is_connected(_on_zone_entered):
		zone.entered.connect(_on_zone_entered)
	if not zone.exited.is_connected(_on_zone_exited):
		zone.exited.connect(_on_zone_exited)

func _on_zone_entered(cue: String) -> void:
	if cue.is_empty() or cue == _active_ambience:
		return
	_stop_player(_active_ambience)
	_active_ambience = cue
	play_cue(cue)

func _on_zone_exited(cue: String) -> void:
	if cue.is_empty() or cue != _active_ambience:
		return
	_stop_player(cue)
	_active_ambience = ""

func _find_zones(node: Node) -> Array[ZoneScript]:
	var out: Array[ZoneScript] = []
	if node is ZoneScript:
		out.append(node)
	for child: Node in node.get_children():
		out.append_array(_find_zones(child))
	return out

func _scan_players() -> void:
	_players.clear()
	_collect_players(self)

func _collect_players(node: Node) -> void:
	for child: Node in node.get_children():
		if _is_player(child) and _has_stream(child):
			_players[String(child.name)] = child
		_collect_players(child)

## Cached name match first; a miss is searched again, so players may be added at
## any time. This runs on cue events only, never per frame.
func _player_for(cue: String) -> Node:
	var cached: Node = _players.get(cue) as Node
	if is_instance_valid(cached):
		return cached
	var found: Node = find_child(cue, true, false)
	if found == null or not _is_player(found):
		return null
	_players[cue] = found
	return found

func _is_player(node: Node) -> bool:
	return node is AudioStreamPlayer or node is AudioStreamPlayer2D or node is AudioStreamPlayer3D

## A player without a stream is as silent as no player at all.
func _has_stream(node: Node) -> bool:
	if node is AudioStreamPlayer:
		return (node as AudioStreamPlayer).stream != null
	if node is AudioStreamPlayer2D:
		return (node as AudioStreamPlayer2D).stream != null
	if node is AudioStreamPlayer3D:
		return (node as AudioStreamPlayer3D).stream != null
	return false

func _start_player(node: Node) -> void:
	if node is AudioStreamPlayer:
		(node as AudioStreamPlayer).play()
	elif node is AudioStreamPlayer2D:
		(node as AudioStreamPlayer2D).play()
	elif node is AudioStreamPlayer3D:
		(node as AudioStreamPlayer3D).play()

func _stop_player(cue: String) -> void:
	if cue.is_empty():
		return
	var player: Node = _player_for(cue)
	if player == null or not _has_stream(player):
		return
	if player is AudioStreamPlayer:
		(player as AudioStreamPlayer).stop()
	elif player is AudioStreamPlayer2D:
		(player as AudioStreamPlayer2D).stop()
	elif player is AudioStreamPlayer3D:
		(player as AudioStreamPlayer3D).stop()

func _note_missing(cue: String) -> void:
	_missing.append(cue)
	while _missing.size() > MISSING_HISTORY:
		_missing.remove_at(0)
	if _reported_missing.has(cue):
		return
	_reported_missing[cue] = true
	print("[FFAudioDirector] cue '%s' has no stream — hook logged only" % cue)
