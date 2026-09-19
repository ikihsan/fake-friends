extends Control
## Quiet cover lip, binding crease and ruled page margin, in the book palette.
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	draw_rect(Rect2(Vector2(-5, -5), size + Vector2(10, 10)), Color("654d3c"), false, 7.0)
	draw_rect(Rect2(Vector2.ZERO, Vector2(16, size.y)), Color(0.19, 0.16, 0.14, 0.16))
	draw_line(Vector2(20, 4), Vector2(20, size.y - 4), Color(0.19, 0.16, 0.14, 0.35), 1.0)
	draw_rect(Rect2(Vector2(27, 20), size - Vector2(48, 40)), Color(0.5, 0.34, 0.22, 0.16), false, 1.0)
