extends Control
## The Map page: the neighbourhood as Chris remembers it, drawn by hand.
##
## Rules this file exists to keep — read before changing it:
##  - A place is drawn ONLY while its id is a key in GameState.data["landmarks"].
##    Undiscovered places leave no trace at all: no dot, no "?", no empty outline.
##    With no GameState reachable, only the flat is known.
##  - The live player position is never drawn, and there is deliberately no
##    compass, arrow, waypoint or heading. This is remembered geography, not
##    navigation.
##  - Positions and links come only from FFLandmarkCatalog, so the world and the
##    handbook can never disagree. A link is drawn only when BOTH of its ends are
##    known, which is what lets the sketch grow into a connected picture.
##  - Wobble is seeded from the id (FNV-1a), never from an unseeded RNG, so a
##    stroke is identical on every redraw and the sketch never shimmers.
##  - State is read fresh inside _draw(), so opening the handbook late, or after
##    a discovery, shows everything known at that moment.
##  - Everything drawn is fitted to the page with one uniform scale, so the
##    picture grows as places are added and can never overflow the page.
##
## Nothing here prints, polls or tracks anything: the page is rebuilt only when
## it is resized or shown, and only from what the save already remembers.

const INK: Color = Color("302a25")
const PENCIL: Color = Color(0.19, 0.16, 0.14, 0.22)
## The light pencil pass is offset, not colour-shifted: the old floor plan's trick.
const PENCIL_FROM: Vector2 = Vector2(0.8, 0.6)
const PENCIL_TO: Vector2 = Vector2(-0.6, 0.7)
const INK_WIDTH: float = 1.4
const THIN_WIDTH: float = 0.8

## Page margin (px, inside this Control's rect) and the smallest area the fit is
## ever allowed to cover (metres). The minimum is what keeps a one-place sketch
## from magnifying until it fills the page; every later place shrinks the scale.
const MARGIN: Vector2 = Vector2(14.0, 16.0)
const MIN_SPAN: float = 12.0
## The fit is inflated by this much so names have paper around the drawing to sit
## on: a sketch whose strokes touch the page edge leaves nowhere to write the
## names, and a name must never be dropped just because the page is crowded.
const LABEL_SLACK: float = 1.22

## Icons: half-size in metres, then the pixel range that keeps them readable
## whether one place is known or all of them are.
const ICON_METRES: float = 1.4
const ICON_MIN_PX: float = 4.5
const ICON_MAX_PX: float = 11.0

const FONT_MIN_SIZE: int = 9
const FONT_MAX_SIZE: int = 12
## Clearance between a place and its name.
const LABEL_GAP: float = 3.0
## The flat, in local floor-plan metres (from tools/build_apartment.gd), centred
## on its own map position so it sits on the sketch at its true size.
const APARTMENT_ID: String = "apartment"
const PLAN_SIZE: Vector2 = Vector2(8.45, 5.35)
const PLAN_CENTRE: Vector2 = Vector2(4.225, 2.675)
const WALLS: Array[Vector4] = [
	Vector4(0, 0, 3.3, 0), Vector4(4.3, 0, 8.45, 0),
	Vector4(8.45, 0, 8.45, 5.35), Vector4(8.45, 5.35, 0, 5.35), Vector4(0, 5.35, 0, 0),
	Vector4(4.575, 0, 4.575, 1.3), Vector4(4.575, 2.2, 4.575, 5.35),
	Vector4(2.275, 3.575, 2.95, 3.575), Vector4(3.85, 3.575, 4.8, 3.575),
	Vector4(5.7, 3.575, 7.3, 3.575), Vector4(8.2, 3.575, 8.45, 3.575),
	Vector4(2.275, 3.575, 2.275, 5.35), Vector4(6.525, 3.575, 6.525, 5.35)
]

## What a missing GameState means: he knows his own flat and nothing else.
const ONLY_THE_FLAT: Dictionary = {APARTMENT_ID: "Apartment"}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Belt and braces for "never overflow the page": the fit already keeps every
	# stroke inside, and this catches a stray label if it ever does not.
	clip_contents = true
	resized.connect(queue_redraw)
	# Fires when the book opens, when the page is turned to the map and when the
	# panel is hidden again, so the sketch is rebuilt from current state each time.
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed() -> void:
	queue_redraw()

func _draw() -> void:
	var known: Array[String] = _known_ids()
	if known.is_empty():
		return
	var view: Rect2 = _usable_rect()
	if view.size.x < 24.0 or view.size.y < 24.0:
		return
	var bounds: Rect2 = _map_bounds(known)
	var span: Vector2 = Vector2(maxf(bounds.size.x * LABEL_SLACK, MIN_SPAN), maxf(bounds.size.y * LABEL_SLACK, MIN_SPAN))
	var unit: float = minf(view.size.x / span.x, view.size.y / span.y)
	var centre: Vector2 = bounds.get_center()
	var page_centre: Vector2 = view.get_center()
	var icon_size: float = clampf(unit * ICON_METRES, ICON_MIN_PX, ICON_MAX_PX)
	var font: Font = _label_font()
	var font_size: int = _label_font_size(unit)
	# Remembered links first, so a stroke sits under the places it joins.
	var link_marks: PackedVector2Array = PackedVector2Array()
	for pair: Array in FFLandmarkCatalog.PATHS:
		if pair.size() < 2:
			continue
		var from_id: String = str(pair[0])
		var to_id: String = str(pair[1])
		if not known.has(from_id) or not known.has(to_id):
			continue
		link_marks.append_array(_draw_link(from_id, to_id, centre, unit, page_centre, icon_size))
	# Then the places themselves.
	for id: String in known:
		var at: Vector2 = _to_page(centre, unit, page_centre, FFLandmarkCatalog.map_pos(id))
		if id == APARTMENT_ID:
			_draw_apartment(id, at, unit)
		else:
			_draw_icon(id, at, icon_size)
	# Names last, on top of every stroke, each kept off the places and off the
	# names already placed.
	var taken: Array[Rect2] = _place_boxes(known, centre, unit, page_centre, icon_size)
	for id: String in known:
		var at: Vector2 = _to_page(centre, unit, page_centre, FFLandmarkCatalog.map_pos(id))
		var half: float = PLAN_SIZE.y * unit * 0.5 if id == APARTMENT_ID else icon_size * 1.1
		taken.append(_place_label(id, at, half, font, font_size, view, taken, link_marks))

## Ids Chris actually knows, straight from GameState on every redraw. An id only
## counts when it is a key in data["landmarks"] AND the catalog can place it, so a
## stale save key can never make the sketch invent a position.
func _known_ids() -> Array[String]:
	var landmarks: Dictionary = _saved_landmarks()
	var ids: Array[String] = []
	for id_value: Variant in FFLandmarkCatalog.ids():
		var id: String = str(id_value)
		if landmarks.has(id) and FFLandmarkCatalog.has_id(id):
			ids.append(id)
	return ids

func _saved_landmarks() -> Dictionary:
	var state: Node = get_node_or_null("/root/GameState")
	if state == null:
		return ONLY_THE_FLAT
	var raw: Variant = state.get("data")
	if not (raw is Dictionary):
		return ONLY_THE_FLAT
	var landmarks: Variant = (raw as Dictionary).get("landmarks")
	if not (landmarks is Dictionary):
		return ONLY_THE_FLAT
	return landmarks

func _usable_rect() -> Rect2:
	return Rect2(MARGIN, size - MARGIN * 2.0)

## Everything drawn, in map metres: the flat contributes its real footprint, every
## other place the room its icon needs.
func _map_bounds(ids: Array[String]) -> Rect2:
	var first: String = ids[0]
	var bounds: Rect2 = Rect2(FFLandmarkCatalog.map_pos(first), Vector2.ZERO)
	for id: String in ids:
		var pos: Vector2 = FFLandmarkCatalog.map_pos(id)
		if id == APARTMENT_ID:
			bounds = bounds.merge(Rect2(pos - PLAN_CENTRE, PLAN_SIZE))
		else:
			bounds = bounds.merge(Rect2(pos - Vector2(ICON_METRES, ICON_METRES), Vector2(ICON_METRES, ICON_METRES) * 2.0))
	return bounds

## Map metres to page pixels: X right, Z down, as the old floor plan had it.
func _to_page(centre: Vector2, unit: float, page_centre: Vector2, point: Vector2) -> Vector2:
	return page_centre + (point - centre) * unit

func _label_font() -> Font:
	var font: Font = get_theme_default_font()
	if font == null:
		font = ThemeDB.fallback_font
	return font

## Names shrink with the sketch: a crowded neighbourhood gets smaller writing
## rather than overlapping writing.
func _label_font_size(unit: float) -> int:
	return clampi(int(roundf(unit * 1.25)), FONT_MIN_SIZE, FONT_MAX_SIZE)

## ----- strokes -------------------------------------------------------------

## One hand-drawn line: a few slightly-off segments in ink, plus the lighter
## offset pencil pass. Everything comes from the passed RNG, which is seeded from
## the place's id, so a redraw repeats the same imperfection exactly.
func _ink_line(rng: RandomNumberGenerator, from: Vector2, to: Vector2, width: float) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	var length: float = from.distance_to(to)
	if length < 3.0:
		points.append(from)
		points.append(to)
	else:
		var wobble: float = clampf(length * 0.03, 0.3, 2.2)
		var normal: Vector2 = (to - from).normalized().orthogonal()
		var steps: int = 4
		for i: int in steps + 1:
			var t: float = float(i) / float(steps)
			var offset: float = 0.0
			if i > 0 and i < steps:
				offset = rng.randf_range(-wobble, wobble)
			points.append(from.lerp(to, t) + normal * offset)
	draw_polyline(points, INK, width, true)
	draw_polyline(_pencil_pass(points), PENCIL, maxf(width * 0.6, 0.6), true)

## A rough arc or full circle (from_angle to to_angle, radii nudged by the RNG).
func _ink_arc(rng: RandomNumberGenerator, centre: Vector2, radius: float, from_angle: float, to_angle: float) -> void:
	if radius <= 1.0:
		return
	var points: PackedVector2Array = PackedVector2Array()
	var steps: int = 8
	for i: int in steps + 1:
		var t: float = float(i) / float(steps)
		var angle: float = from_angle + (to_angle - from_angle) * t
		var r: float = radius
		if i > 0 and i < steps:
			r += rng.randf_range(-radius * 0.09, radius * 0.09)
		points.append(centre + Vector2(cos(angle), sin(angle)) * r)
	draw_polyline(points, INK, INK_WIDTH, true)
	draw_polyline(_pencil_pass(points), PENCIL, maxf(INK_WIDTH * 0.6, 0.6), true)

## The same shape a little to one side and a different weight, as if traced twice.
func _pencil_pass(points: PackedVector2Array) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	var count: int = points.size()
	for i: int in count:
		var t: float = 0.0 if count <= 1 else float(i) / float(count - 1)
		out.append(points[i] + PENCIL_FROM.lerp(PENCIL_TO, t))
	return out

## ----- links ---------------------------------------------------------------

## Returns the points of the stroke it drew, so the names can avoid them.
func _draw_link(from_id: String, to_id: String, centre: Vector2, unit: float, page_centre: Vector2, icon_size: float) -> PackedVector2Array:
	var from_at: Vector2 = _to_page(centre, unit, page_centre, FFLandmarkCatalog.map_pos(from_id))
	var to_at: Vector2 = _to_page(centre, unit, page_centre, FFLandmarkCatalog.map_pos(to_id))
	var direction: Vector2 = to_at - from_at
	var length: float = direction.length()
	if length <= 1.0:
		return PackedVector2Array()
	# Stop the stroke at the edge of each place, so it links them instead of
	# scribbling across the flat's plan or through an icon.
	var heading: Vector2 = direction / length
	var gap: float = 2.0
	var start: Vector2 = from_at + heading * (_exit_distance(heading, _link_half(from_id, unit, icon_size)) + gap)
	var end: Vector2 = to_at - heading * (_exit_distance(heading, _link_half(to_id, unit, icon_size)) + gap)
	if start.distance_to(end) < 2.0:
		return PackedVector2Array()
	var rng: RandomNumberGenerator = _wobble_for(from_id + ">" + to_id)
	_ink_line(rng, start, end, maxf(INK_WIDTH * 0.85, 0.9))
	return _sample(start, end)

## Points along a stroke, so names can steer clear of the lines as well as of the
## places. Only used for placement, never drawn.
func _sample(from: Vector2, to: Vector2) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var steps: int = clampi(int(from.distance_to(to) / 4.0), 2, 80)
	for i: int in steps + 1:
		points.append(from.lerp(to, float(i) / float(steps)))
	return points

## The flat is cleared at its walls; an icon at its own box.
func _link_half(id: String, unit: float, icon_size: float) -> Vector2:
	if id == APARTMENT_ID:
		return PLAN_SIZE * unit * 0.5
	var half: float = icon_size * 1.15
	return Vector2(half, half)

## How far a ray leaves a box of `half` extents, travelling along `heading`.
func _exit_distance(heading: Vector2, half: Vector2) -> float:
	var along_x: float = INF
	var along_y: float = INF
	if absf(heading.x) > 0.0001:
		along_x = half.x / absf(heading.x)
	if absf(heading.y) > 0.0001:
		along_y = half.y / absf(heading.y)
	var distance: float = minf(along_x, along_y)
	if not is_finite(distance):
		return minf(half.x, half.y)
	return distance

## ----- places --------------------------------------------------------------

## The flat, kept as the floor plan it always was: walls only, no fill, at the
## scale of whatever else is known.
func _draw_apartment(id: String, at: Vector2, unit: float) -> void:
	var rng: RandomNumberGenerator = _wobble_for(id + ":plan")
	var origin: Vector2 = at - PLAN_CENTRE * unit
	for wall: Vector4 in WALLS:
		var from: Vector2 = origin + Vector2(wall.x, wall.y) * unit
		var to: Vector2 = origin + Vector2(wall.z, wall.w) * unit
		_ink_line(rng, from, to, INK_WIDTH)

func _draw_icon(id: String, at: Vector2, s: float) -> void:
	var rng: RandomNumberGenerator = _wobble_for(id + ":icon")
	match FFLandmarkCatalog.icon_for(id):
		"home":
			_draw_home(rng, at, s)
		"shop":
			_draw_shop(rng, at, s)
		"park":
			_draw_park(rng, at, s)
		"cafe":
			_draw_cafe(rng, at, s)
		"stop":
			_draw_stop(rng, at, s)
		"market":
			_draw_market(rng, at, s)
		_:
			_draw_unknown(rng, at, s)

func _draw_home(rng: RandomNumberGenerator, at: Vector2, s: float) -> void:
	var bottom_left: Vector2 = at + Vector2(-s, s)
	var bottom_right: Vector2 = at + Vector2(s, s)
	var top_left: Vector2 = at + Vector2(-s, -s * 0.1)
	var top_right: Vector2 = at + Vector2(s, -s * 0.1)
	var apex: Vector2 = at + Vector2(0.0, -s)
	_ink_line(rng, bottom_left, bottom_right, INK_WIDTH)
	_ink_line(rng, bottom_left, top_left, INK_WIDTH)
	_ink_line(rng, bottom_right, top_right, INK_WIDTH)
	_ink_line(rng, top_left, apex, INK_WIDTH)
	_ink_line(rng, apex, top_right, INK_WIDTH)
	_ink_line(rng, at + Vector2(0.0, s), at + Vector2(0.0, -s * 0.2), THIN_WIDTH)

func _draw_shop(rng: RandomNumberGenerator, at: Vector2, s: float) -> void:
	var bottom_left: Vector2 = at + Vector2(-s, s)
	var bottom_right: Vector2 = at + Vector2(s, s)
	var top_left: Vector2 = at + Vector2(-s, -s * 0.15)
	var top_right: Vector2 = at + Vector2(s, -s * 0.15)
	_ink_line(rng, bottom_left, bottom_right, INK_WIDTH)
	_ink_line(rng, bottom_left, top_left, INK_WIDTH)
	_ink_line(rng, bottom_right, top_right, INK_WIDTH)
	_ink_line(rng, top_left, top_right, INK_WIDTH)
	# Awning over the front, striped enough to read as a shopfront.
	_ink_line(rng, at + Vector2(-s, -s * 0.55), at + Vector2(s, -s * 0.55), INK_WIDTH)
	for stripe: int in 3:
		var x: float = -s + 2.0 * s * (float(stripe) + 0.5) / 3.0
		_ink_line(rng, at + Vector2(x, -s * 0.55), at + Vector2(x, -s * 0.2), THIN_WIDTH)

func _draw_park(rng: RandomNumberGenerator, at: Vector2, s: float) -> void:
	var left_tree: Vector2 = at + Vector2(-s * 0.45, -s * 0.25)
	var right_tree: Vector2 = at + Vector2(s * 0.5, -s * 0.05)
	_ink_arc(rng, left_tree, s * 0.42, 0.0, TAU)
	_ink_arc(rng, right_tree, s * 0.36, 0.0, TAU)
	_ink_line(rng, left_tree + Vector2(0.0, s * 0.35), at + Vector2(-s * 0.45, s), INK_WIDTH)
	_ink_line(rng, right_tree + Vector2(0.0, s * 0.3), at + Vector2(s * 0.5, s), INK_WIDTH)
	_ink_line(rng, at + Vector2(-s, s), at + Vector2(s, s), THIN_WIDTH)

func _draw_cafe(rng: RandomNumberGenerator, at: Vector2, s: float) -> void:
	var rim_left: Vector2 = at + Vector2(-s * 0.6, -s * 0.3)
	var rim_right: Vector2 = at + Vector2(s * 0.55, -s * 0.3)
	var bowl_left: Vector2 = at + Vector2(-s * 0.45, s * 0.2)
	var bowl_right: Vector2 = at + Vector2(s * 0.4, s * 0.2)
	_ink_line(rng, rim_left, rim_right, INK_WIDTH)
	_ink_line(rng, rim_left, bowl_left, INK_WIDTH)
	_ink_line(rng, bowl_left, bowl_right, INK_WIDTH)
	_ink_line(rng, bowl_right, rim_right, INK_WIDTH)
	_ink_arc(rng, at + Vector2(s * 0.66, -s * 0.05), s * 0.3, -PI * 0.5, PI * 0.5)
	_ink_line(rng, at + Vector2(-s * 0.8, s * 0.55), at + Vector2(s * 0.85, s * 0.55), THIN_WIDTH)

func _draw_stop(rng: RandomNumberGenerator, at: Vector2, s: float) -> void:
	var sign_top: float = -s * 1.05
	var sign_bottom: float = -s * 0.35
	var middle: float = (sign_top + sign_bottom) * 0.5
	_ink_line(rng, at + Vector2(0.0, sign_bottom), at + Vector2(0.0, s), INK_WIDTH)
	_ink_line(rng, at + Vector2(-s * 0.75, sign_top), at + Vector2(s * 0.75, sign_top), INK_WIDTH)
	_ink_line(rng, at + Vector2(-s * 0.75, sign_bottom), at + Vector2(s * 0.75, sign_bottom), INK_WIDTH)
	_ink_line(rng, at + Vector2(-s * 0.75, sign_top), at + Vector2(-s * 0.75, sign_bottom), INK_WIDTH)
	_ink_line(rng, at + Vector2(s * 0.75, sign_top), at + Vector2(s * 0.75, sign_bottom), INK_WIDTH)
	_ink_line(rng, at + Vector2(-s * 0.3, middle), at + Vector2(s * 0.3, middle), THIN_WIDTH)
	_ink_line(rng, at + Vector2(-s * 0.7, s), at + Vector2(s * 0.7, s), THIN_WIDTH)

func _draw_market(rng: RandomNumberGenerator, at: Vector2, s: float) -> void:
	_ink_line(rng, at + Vector2(-s, -s * 0.55), at + Vector2(s, -s * 0.55), INK_WIDTH)
	for stripe: int in 3:
		var x: float = -s + 2.0 * s * (float(stripe) + 0.5) / 3.0
		_ink_line(rng, at + Vector2(x, -s * 0.55), at + Vector2(x, -s * 0.15), THIN_WIDTH)
	var counter_left: Vector2 = at + Vector2(-s * 0.85, s * 0.25)
	var counter_right: Vector2 = at + Vector2(s * 0.85, s * 0.25)
	_ink_line(rng, counter_left, counter_right, INK_WIDTH)
	_ink_line(rng, counter_left, at + Vector2(-s * 0.7, s), INK_WIDTH)
	_ink_line(rng, counter_right, at + Vector2(s * 0.7, s), INK_WIDTH)

## Only reached if the catalog grows an icon kind this file has no strokes for: a
## place Chris has been to still gets a mark rather than vanishing from the page.
func _draw_unknown(rng: RandomNumberGenerator, at: Vector2, s: float) -> void:
	_ink_arc(rng, at, s * 0.5, 0.0, TAU)
	_ink_line(rng, at, at + Vector2(s, 0.0), THIN_WIDTH)

## ----- names ---------------------------------------------------------------

## The box each place occupies on the page, so a name can steer clear of the
## drawings as well as of the other names.
func _place_boxes(ids: Array[String], centre: Vector2, unit: float, page_centre: Vector2, icon_size: float) -> Array[Rect2]:
	var boxes: Array[Rect2] = []
	for id: String in ids:
		var at: Vector2 = _to_page(centre, unit, page_centre, FFLandmarkCatalog.map_pos(id))
		var half: Vector2 = PLAN_SIZE * unit * 0.5 if id == APARTMENT_ID else Vector2.ONE * (icon_size * 1.15)
		boxes.append(Rect2(at - half, half * 2.0))
	return boxes

## Draws the place name and returns the box it occupies, so the next name can
## avoid it. The name is tried on one line first and, where the page is too
## crowded for that, stacked one word per line - which is how a hand keeps a
## small page readable. Slots around the place are tried in a fixed order and the
## first clear one wins; if every slot is crowded the least crowded is used, so a
## name is never dropped and never written off the page. The hand shows only in
## the tilt and the wobble, never in the position, so a redraw is identical.
func _place_label(id: String, at: Vector2, half: float, font: Font, font_size: int, view: Rect2, taken: Array[Rect2], marks: PackedVector2Array) -> Rect2:
	var text: String = FFLandmarkCatalog.label_for(id)
	var rng: RandomNumberGenerator = _wobble_for(id + ":name")
	var ascent: float = font.get_ascent(font_size)
	var step: float = ascent + font.get_descent(font_size) + 1.0
	var attempts: Array[Dictionary] = _label_attempts(text, font, font_size, step)
	var label_size: Vector2 = attempts[0]["size"] as Vector2
	var lines: PackedStringArray = attempts[0]["lines"] as PackedStringArray
	var baseline: Vector2 = Vector2.INF
	for attempt: Dictionary in attempts:
		var slot: Vector2 = _pick_slot(at, half, attempt["size"] as Vector2, ascent, view, taken, marks)
		if is_finite(slot.x):
			label_size = attempt["size"] as Vector2
			lines = attempt["lines"] as PackedStringArray
			baseline = slot
			break
	if not is_finite(baseline.x):
		# Every slot is crowded: write the name where it collides least.
		var best: float = INF
		for attempt: Dictionary in attempts:
			var attempt_size: Vector2 = attempt["size"] as Vector2
			for candidate: Vector2 in _slots(at, half, attempt_size, ascent):
				var cost: float = _crowding(_label_box(candidate, attempt_size, ascent), taken, marks, view)
				if cost < best:
					best = cost
					baseline = candidate
					label_size = attempt_size
					lines = attempt["lines"] as PackedStringArray
	baseline += Vector2(rng.randf_range(-1.5, 1.5), rng.randf_range(-1.0, 1.0))
	var half_width: float = label_size.x * 0.5
	baseline.x = clampf(baseline.x, view.position.x + half_width, maxf(view.position.x + half_width, view.end.x - half_width))
	baseline.y = clampf(baseline.y, view.position.y + ascent, maxf(view.position.y + ascent, view.end.y - font.get_descent(font_size)))
	var tilt: float = rng.randf_range(-0.03, 0.03)
	draw_set_transform(baseline, tilt, Vector2.ONE)
	for index: int in lines.size():
		var offset: Vector2 = Vector2(-half_width, step * float(index))
		draw_string(font, offset, lines[index], HORIZONTAL_ALIGNMENT_CENTER, label_size.x, font_size, INK)
		draw_string(font, offset + Vector2(0.7, 0.4), lines[index], HORIZONTAL_ALIGNMENT_CENTER, label_size.x, font_size, PENCIL)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return _label_box(baseline, label_size, ascent)

## The whole name on one line, then one word per line if it has more than one.
func _label_attempts(text: String, font: Font, font_size: int, step: float) -> Array[Dictionary]:
	var attempts: Array[Dictionary] = []
	attempts.append({
		"lines": PackedStringArray([text]),
		"size": font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size),
	})
	var words: PackedStringArray = text.split(" ", false)
	if words.size() > 1:
		var widest: float = 0.0
		for word: String in words:
			widest = maxf(widest, font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x)
		attempts.append({"lines": words, "size": Vector2(widest, step * float(words.size()))})
	return attempts

## The eight places a name can sit: below, above, right, left, then the corners.
func _slots(at: Vector2, half: float, label_size: Vector2, ascent: float) -> Array[Vector2]:
	var diagonal: float = half * 0.7 + LABEL_GAP
	var side: float = half + LABEL_GAP + label_size.x * 0.5
	return [
		Vector2(at.x, at.y + half + LABEL_GAP + ascent),
		Vector2(at.x, at.y - half - LABEL_GAP),
		Vector2(at.x + side, at.y + ascent * 0.5),
		Vector2(at.x - side, at.y + ascent * 0.5),
		Vector2(at.x + diagonal + label_size.x * 0.5, at.y + diagonal + ascent),
		Vector2(at.x - diagonal - label_size.x * 0.5, at.y + diagonal + ascent),
		Vector2(at.x + diagonal + label_size.x * 0.5, at.y - diagonal),
		Vector2(at.x - diagonal - label_size.x * 0.5, at.y - diagonal),
	]

## The first slot clear of the page edges, the places, the names already written
## and the link strokes; Vector2.INF if every slot is crowded.
func _pick_slot(at: Vector2, half: float, label_size: Vector2, ascent: float, view: Rect2, taken: Array[Rect2], marks: PackedVector2Array) -> Vector2:
	for candidate: Vector2 in _slots(at, half, label_size, ascent):
		var box: Rect2 = _label_box(candidate, label_size, ascent)
		if view.encloses(box) and not _collides(box, taken, marks):
			return candidate
	return Vector2.INF

func _label_box(baseline: Vector2, label_size: Vector2, ascent: float) -> Rect2:
	return Rect2(baseline - Vector2(label_size.x * 0.5, ascent), label_size)

func _collides(box: Rect2, taken: Array[Rect2], marks: PackedVector2Array) -> bool:
	for other: Rect2 in taken:
		if box.intersects(other):
			return true
	for mark: Vector2 in marks:
		if box.has_point(mark):
			return true
	return false

## How bad a slot is: area shared with a place or a written name, plus a little
## for every link stroke it crosses, plus a lot for any part off the page.
func _crowding(box: Rect2, taken: Array[Rect2], marks: PackedVector2Array, view: Rect2) -> float:
	var cost: float = 0.0
	for other: Rect2 in taken:
		var shared: Rect2 = box.intersection(other)
		cost += shared.size.x * shared.size.y
	for mark: Vector2 in marks:
		if box.has_point(mark):
			cost += 4.0
	var on_page: Rect2 = box.intersection(view)
	cost += (box.size.x * box.size.y - on_page.size.x * on_page.size.y) * 6.0
	return cost

## ----- deterministic jitter ------------------------------------------------

## A fresh RNG seeded from a key, so repeated calls with the same key give the
## same sequence: the sketch is imperfect but never shimmers between redraws.
func _wobble_for(key: String) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = _seed_for(key)
	return rng

## FNV-1a over the key. Deliberately not String.hash() or an instance id: this is
## stable across runs and engine versions, and a name is never a memory address.
func _seed_for(key: String) -> int:
	var value: int = 2166136261
	for index: int in key.length():
		value = (value ^ key.unicode_at(index)) & 0xFFFFFFFF
		value = (value * 16777619) & 0xFFFFFFFF
	return value
