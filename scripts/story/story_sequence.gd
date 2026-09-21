class_name FFStorySequence
extends RefCounted
## Tiny deterministic helpers shared by Day 1 beats (and future days).
## No state here; GameState remains the persistent authority.

## Wait until the player body is within radius of a world point, or until
## timeout_sec passes (timeout <= 0 means wait forever). Polls on a short
## timer so idle cost is negligible.
static func wait_proximity(player: Node3D, point: Vector3, radius: float, timeout_sec: float = 0.0) -> bool:
	var elapsed: float = 0.0
	while is_instance_valid(player):
		if player.global_position.distance_to(point) <= radius:
			return true
		if timeout_sec > 0.0 and elapsed >= timeout_sec:
			return false
		await player.get_tree().create_timer(0.15).timeout
		elapsed += 0.15
	return false

static func wait_seconds(tree: SceneTree, seconds: float) -> void:
	await tree.create_timer(seconds).timeout

## Wait until the dialogue presenter is idle (queue drained) or timeout.
static func wait_dialogue_idle(dialogue: FFDialoguePresenter, timeout_sec: float = 20.0) -> void:
	var elapsed: float = 0.0
	while not dialogue.is_idle():
		if elapsed >= timeout_sec:
			return
		await dialogue.get_tree().create_timer(0.2).timeout
		elapsed += 0.2

static func wait_thoughts_idle(thoughts: FFThoughtPresenter, timeout_sec: float = 12.0) -> void:
	# Thoughts drain at ~2.5s per line; wait generously but bounded.
	var elapsed: float = 0.0
	while elapsed < timeout_sec:
		# FFThoughtPresenter has no idle query; bound by queued durations.
		await thoughts.get_tree().create_timer(0.5).timeout
		elapsed += 0.5
		# Heuristic: after enough time for 3 lines, assume drained.
		if elapsed >= 6.0:
			# Peek: if label hidden, queue is empty.
			var lbl: Label = thoughts.get_node_or_null("ThoughtSubtitle") as Label
			if lbl == null or not lbl.visible:
				return
	return
